package com.metamoto.meta_moto

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Lê a tela do Uber/99 em tempo real.
 * Quando detecta a tela de oferta de corrida (tem R$, km, botão aceitar),
 * envia os dados para o overlay via RideEventStreamHandler.
 *
 * É assim que o JetMax funciona.
 */
class TripAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MetaMoto-A11y"

        private val WATCHED_PACKAGES = setOf(
            "com.ubercab.driver",
            "com.ubercab",
            "com.taxis99.driver",
            "com.taxis99",
        )

        // Texto dos botões de aceitar nas apps monitoradas
        private val ACCEPT_TEXTS = setOf(
            "aceitar", "accept", "aceite", "pegar corrida",
            "confirmar", "ir buscar", "aceitar corrida",
        )

        // Palavras que indicam que NÃO é tela de oferta
        private val NOT_OFFER_TEXTS = setOf(
            "avalie", "rate", "promoção", "cashback", "indique",
        )

        private val MONEY_REGEX = Regex("""R\$\s*(\d{1,4}[.,]\d{2})""")
        private val KM_REGEX    = Regex("""(\d{1,3}[.,]?\d{0,2})\s*km""", RegexOption.IGNORE_CASE)
        private val MIN_REGEX   = Regex("""(\d{1,3})\s*min""", RegexOption.IGNORE_CASE)

        // Evita disparar múltiplas vezes para a mesma oferta
        private var lastSentValue: Double = 0.0
        private var lastSentTime:  Long   = 0L
        private const val DEBOUNCE_MS = 4_000L
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
            feedbackType    = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags           = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                              AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 200
            packageNames = WATCHED_PACKAGES.toTypedArray()
        }
        Log.i(TAG, "✓ AccessibilityService conectado — monitorando ${WATCHED_PACKAGES.joinToString()}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        event ?: return
        val pkg = event.packageName?.toString() ?: return
        if (pkg !in WATCHED_PACKAGES) return

        val root = rootInActiveWindow ?: return
        try {
            processScreen(root, pkg)
        } finally {
            root.recycle()
        }
    }

    private fun processScreen(root: AccessibilityNodeInfo, pkg: String) {
        // Coleta todo o texto visível na tela
        val allTexts = mutableListOf<String>()
        collectTexts(root, allTexts)

        val fullText  = allTexts.joinToString(" ")
        val fullLower = fullText.lowercase()

        // Ignora se não for tela de oferta
        if (NOT_OFFER_TEXTS.any { fullLower.contains(it) }) return

        // Precisa ter botão de aceitar para confirmar que é tela de oferta
        val hasAccept = ACCEPT_TEXTS.any { fullLower.contains(it) }
        // OU o pacote emitiu TYPE_WINDOW_STATE_CHANGED com R$ (Uber às vezes não tem "aceitar" no texto)
        val hasMoney  = MONEY_REGEX.containsMatchIn(fullText)

        if (!hasAccept && !hasMoney) return

        // Extrai valor
        val valor = MONEY_REGEX.findAll(fullText)
            .mapNotNull { it.groupValues[1].replace(",", ".").replace(".", "").let { raw ->
                // "12,02" → remove separador de milhar se houver, mantém decimais
                val cleaned = it.groupValues[1]
                    .replace(".", "")   // remove ponto de milhar
                    .replace(",", ".") // vírgula → ponto decimal
                cleaned.toDoubleOrNull()
            }}
            .filter { it >= 1.0 }
            .maxOrNull() ?: return  // sem valor = não é oferta

        // Debounce: ignora se enviou o mesmo valor nos últimos 4 segundos
        val now = System.currentTimeMillis()
        if (valor == lastSentValue && (now - lastSentTime) < DEBOUNCE_MS) return
        lastSentValue = valor
        lastSentTime  = now

        // Extrai km (pega o maior = distância da viagem, não da busca)
        val distKm = KM_REGEX.findAll(fullText)
            .mapNotNull { it.groupValues[1].replace(",", ".").toDoubleOrNull() }
            .filter { it > 0 }
            .maxOrNull()

        // Extrai minutos (pega o maior)
        val tempMin = MIN_REGEX.findAll(fullText)
            .mapNotNull { it.groupValues[1].toIntOrNull() }
            .filter { it in 1..120 }
            .maxOrNull()

        // Calcula métricas
        val eficiencia = if (distKm != null && distKm > 0) valor / distKm else null
        val ganhoHora  = when {
            tempMin != null && tempMin > 0 -> (valor / tempMin) * 60.0
            eficiencia != null             -> eficiencia * 25.0
            else                           -> null
        }

        val baixa = eficiencia != null && eficiencia < 2.0

        Log.i(TAG, "[$pkg] OFERTA DETECTADA → R\$ $valor | km=$distKm | " +
            "min=$tempMin | R\$/km=$eficiencia | R\$/h=$ganhoHora | baixa=$baixa")
        Log.d(TAG, "  textos: ${fullText.take(200)}")

        vibrar(baixa)
        acordarTela()

        RideEventStreamHandler.sendOffer(
            platform        = if (pkg.contains("uber")) "Uber" else "99",
            valor           = valor,
            distKm          = distKm,
            tempMin         = tempMin,
            eficiencia      = eficiencia,
            ganhoHora       = ganhoHora,
            nota            = null,
            baixaEficiencia = baixa,
        )
    }

    /**
     * 2 pulsos curtos = boa oferta (≥ R$2/km)
     * 3 pulsos longos = oferta ruim (< R$2/km)
     */
    private fun vibrar(baixaEficiencia: Boolean) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val v = vm.defaultVibrator
                if (baixaEficiencia) {
                    // 3 pulsos longos: aviso
                    v.vibrate(VibrationEffect.createWaveform(
                        longArrayOf(0, 200, 100, 200, 100, 200), -1))
                } else {
                    // 2 pulsos curtos: boa oferta
                    v.vibrate(VibrationEffect.createWaveform(
                        longArrayOf(0, 80, 80, 80), -1))
                }
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (baixaEficiencia) {
                    @Suppress("DEPRECATION")
                    v.vibrate(longArrayOf(0, 200, 100, 200, 100, 200), -1)
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(longArrayOf(0, 80, 80, 80), -1)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vibração falhou: ${e.message}")
        }
    }

    /** Acende a tela se estiver desligada (WakeLock de 3 segundos). */
    private fun acordarTela() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            @Suppress("DEPRECATION")
            val wl = pm.newWakeLock(
                PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "MetaMoto:OfertaWakeLock"
            )
            wl.acquire(3_000L)
        } catch (e: Exception) {
            Log.w(TAG, "WakeLock falhou: ${e.message}")
        }
    }

    /** Percorre recursivamente a árvore de views e coleta textos não-vazios. */
    private fun collectTexts(node: AccessibilityNodeInfo, out: MutableList<String>) {
        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty()) out.add(text)

        val desc = node.contentDescription?.toString()?.trim()
        if (!desc.isNullOrEmpty() && desc != text) out.add(desc)

        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                collectTexts(child, out)
                child.recycle()
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "AccessibilityService interrompido")
    }
}
