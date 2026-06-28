package com.metamoto.meta_moto

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Lê notificações dos apps de corrida e exibe o overlay antes de aceitar.
 *
 * Estratégia: SEM filtro de keywords — qualquer notificação dos pacotes
 * suportados com valor em R$ dispara o overlay. Logs detalhados para debug.
 */
class RideNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "MetaMoto-NLS"

        private val SUPPORTED_PACKAGES = mapOf(
            "com.ubercab.driver"     to "Uber",
            "com.ubercab"            to "Uber",
            "com.taxis99.driver"     to "99",
            "com.taxis99"            to "99",
            "com.ifood.courier"      to "iFood",
            "br.com.ifood"           to "iFood",
            "com.lalamove.android"   to "Lalamove",
            "sinet.startup.inDriver" to "InDrive",
        )

        // Notificações que claramente NÃO são ofertas — só as mais óbvias
        private val SKIP_KEYWORDS = listOf(
            "avalie sua viagem", "rate your trip", "avalie o motorista",
            "sua avaliação", "viagem avaliada", "promoção", "desconto",
            "cashback", "indique um amigo", "refer a friend",
        )

        // R$ 12,02 | R$12.50 | +R$ 18,75
        private val MONEY_REGEX = Regex(
            """R\$\s*(\d{1,4}[.,]\d{2})""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // 3,2 km | 3.2km | 12 km | 0.8 km
        private val KM_REGEX = Regex(
            """(\d{1,3}[.,]?\d{0,2})\s*km""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // 10 min | 15 mins | 5 minutos
        private val MIN_REGEX = Regex(
            """(\d{1,3})\s*min""",
            setOf(RegexOption.IGNORE_CASE)
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val pkg      = sbn.packageName ?: return
        val platform = SUPPORTED_PACKAGES[pkg] ?: return

        val extras  = sbn.notification?.extras ?: return
        val title   = extras.getCharSequence("android.title")?.toString()  ?: ""
        val text    = extras.getCharSequence("android.text")?.toString()   ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val subText = extras.getCharSequence("android.subText")?.toString() ?: ""

        val fullText  = "$title $text $bigText $subText".trim()
        val fullLower = fullText.lowercase()

        // ── Log TUDO que vem do Uber/99 (para debug com adb logcat) ──────────
        Log.d(TAG, "[$platform] pkg=$pkg")
        Log.d(TAG, "  title   : $title")
        Log.d(TAG, "  text    : $text")
        Log.d(TAG, "  bigText : $bigText")
        Log.d(TAG, "  subText : $subText")

        // Pula notificações claramente fora do escopo (avaliações, promoções)
        if (SKIP_KEYWORDS.any { fullLower.contains(it) }) {
            Log.d(TAG, "  → IGNORADO (skip keyword)")
            return
        }

        // ── Extrai valor monetário ────────────────────────────────────────────
        val moneyMatch = MONEY_REGEX.find(fullText)
        val valor = moneyMatch?.groupValues?.get(1)
            ?.replace(".", "")
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        if (valor == null || valor < 1.0) {
            Log.d(TAG, "  → IGNORADO (sem valor R$)")
            return
        }

        // ── Extrai todos os valores de km (pega o maior = distância da viagem) ─
        val distKm = KM_REGEX.findAll(fullText)
            .mapNotNull { it.groupValues[1].replace(",", ".").toDoubleOrNull() }
            .filter { it > 0 }
            .maxOrNull()

        // ── Extrai tempo em minutos (pega o maior) ────────────────────────────
        val tempMin = MIN_REGEX.findAll(fullText)
            .mapNotNull { it.groupValues[1].toIntOrNull() }
            .filter { it in 1..120 }
            .maxOrNull()

        // ── Calcula R$/km ─────────────────────────────────────────────────────
        val eficiencia = if (distKm != null && distKm > 0) valor / distKm else null

        // ── Calcula R$/hora ───────────────────────────────────────────────────
        val ganhoHora = when {
            tempMin != null && tempMin > 0 -> (valor / tempMin) * 60.0
            eficiencia != null             -> eficiencia * 25.0  // ~25 km/h urbano
            else                           -> null
        }

        Log.i(TAG, "  → OFERTA DETECTADA: R\$ $valor | km=$distKm | " +
            "min=$tempMin | R\$/km=$eficiencia | R\$/h=$ganhoHora")

        RideEventStreamHandler.sendOffer(
            platform   = platform,
            valor      = valor,
            distKm     = distKm,
            tempMin    = tempMin,
            eficiencia = eficiencia,
            ganhoHora  = ganhoHora,
            nota       = null,
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "✓ NotificationListenerService conectado")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "✗ NotificationListenerService desconectado")
    }
}
