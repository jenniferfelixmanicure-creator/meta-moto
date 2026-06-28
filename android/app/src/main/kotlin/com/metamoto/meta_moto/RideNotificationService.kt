package com.metamoto.meta_moto

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Lê notificações dos apps de transporte/entrega.
 * Detecta OFERTAS de corrida (antes de aceitar) para exibir o overlay
 * com R$/km, R$/hora e valor — igual ao JetMax.
 *
 * Apps suportados:
 *   Uber Driver   → com.ubercab.driver
 *   99 Motorista  → com.taxis99.driver / com.taxis99
 *   iFood Courier → com.ifood.courier / br.com.ifood
 *   Lalamove      → com.lalamove.android
 *   InDrive       → sinet.startup.inDriver
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
            "sinet.startup.inDriver" to "InDrive"
        )

        // ── Palavras-chave de OFERTA de corrida (antes de aceitar) ────────────
        private val OFFER_KEYWORDS = listOf(
            // Uber Driver (pt-BR)
            "nova corrida", "novo pedido", "nova solicitação", "nova viagem",
            "corrida disponível", "pedido disponível", "aceitar corrida",
            // Uber Driver (en)
            "new trip", "trip request", "new request", "incoming trip",
            // 99
            "nova chamada", "corrida perto", "chamada próxima",
            // iFood
            "novo pedido", "pedido próximo",
            // Genérico
            "aceitar", "accept", "novo", "new"
        )

        // ── Palavras que NÃO são ofertas (ignorar) ────────────────────────────
        private val IGNORE_KEYWORDS = listOf(
            "conclu", "finaliz", "entregue", "cancelad", "cancel",
            "avalia", "rating", "chegou", "chegando", "a caminho",
            "on the way", "arriving"
        )

        // R$ 12,02 | R$12.50 | + R$ 18,75
        private val MONEY_REGEX = Regex(
            """(?:\+\s*)?R\$\s*(\d{1,4}(?:[.,]\d{3})*[.,]\d{2})""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // 3,2 km | 3.2km | 12 km
        private val KM_REGEX = Regex(
            """(\d{1,3}[.,]\d{1,2}|\d{1,3})\s*km""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // "10 min" | "15 mins" | "5 minutos"
        private val MIN_REGEX = Regex(
            """(\d{1,3})\s*min(?:s|utos?)?""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // R$/km já calculado pelo app: "3,08/km" ou "3.08/km"
        private val RPM_REGEX = Regex(
            """(\d{1,3}[.,]\d{2})\s*/\s*km""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // Nota/rating: "4,97" ou "★ 4.97"
        private val NOTA_REGEX = Regex(
            """[★*]?\s*([4-5][.,]\d{2})""",
            setOf(RegexOption.IGNORE_CASE)
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        val pkg = sbn.packageName ?: return
        val platform = SUPPORTED_PACKAGES[pkg] ?: return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title   = extras.getCharSequence("android.title")?.toString() ?: ""
        val text    = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val subText = extras.getCharSequence("android.subText")?.toString() ?: ""

        val fullText = "$title $text $bigText $subText"
        val fullLower = fullText.lowercase()

        // Ignora notificações que não são ofertas
        if (IGNORE_KEYWORDS.any { fullLower.contains(it) }) return

        // Precisa ter pelo menos uma palavra-chave de oferta
        val isOffer = OFFER_KEYWORDS.any { fullLower.contains(it) }
        // Ou ter valor monetário no texto (Uber às vezes não tem palavra-chave clara)
        val hasMoney = MONEY_REGEX.containsMatchIn(fullText)

        if (!isOffer && !hasMoney) return

        // ── Extrai valor ──────────────────────────────────────────────────────
        val moneyMatch = MONEY_REGEX.find(fullText)
        val valor = moneyMatch?.groupValues?.get(1)
            ?.replace(".", "")
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        if (valor == null || valor < 1.0) {
            Log.d(TAG, "[$platform] Oferta sem valor válido: ${fullText.take(100)}")
            return
        }

        // ── Extrai distância da VIAGEM (km) ───────────────────────────────────
        // Pode haver 2 ocorrências de km: "0.8 km para busca · 3.1 km de viagem"
        // Pega o MAIOR valor (distância da viagem, não da busca)
        val kmMatches = KM_REGEX.findAll(fullText).toList()
        val distKm = kmMatches
            .mapNotNull { it.groupValues[1].replace(",", ".").toDoubleOrNull() }
            .maxOrNull()

        // ── Extrai tempo estimado (min) ───────────────────────────────────────
        val minMatches = MIN_REGEX.findAll(fullText).toList()
        val tempMin = minMatches
            .mapNotNull { it.groupValues[1].toIntOrNull() }
            .maxOrNull()

        // ── R$/km (já calculado pelo app, se disponível) ──────────────────────
        val rpmMatch = RPM_REGEX.find(fullText)
        val rpmPronto = rpmMatch?.groupValues?.get(1)
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        // ── Nota do motorista ─────────────────────────────────────────────────
        val notaMatch = NOTA_REGEX.find(fullText)
        val nota = notaMatch?.groupValues?.get(1)
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        // ── Calcula R$/km se não veio pronto ─────────────────────────────────
        val eficiencia = rpmPronto
            ?: if (distKm != null && distKm > 0) valor / distKm else null

        // ── Calcula R$/hora (R$/km × média de velocidade, ou por tempo) ───────
        // Se temos valor e tempo em minutos, calculamos diretamente
        val ganhoHora = when {
            tempMin != null && tempMin > 0 -> (valor / tempMin) * 60.0
            eficiencia != null -> eficiencia * 25.0 // ~25 km/h média urbana
            else -> null
        }

        Log.i(TAG, "[$platform] OFERTA → R\$ $valor | ${distKm ?: "?"}km | " +
            "${tempMin ?: "?"}min | R\$/km: ${eficiencia ?: "?"} | R\$/h: ${ganhoHora ?: "?"}")

        RideEventStreamHandler.sendOffer(
            platform   = platform,
            valor      = valor,
            distKm     = distKm,
            tempMin    = tempMin,
            eficiencia = eficiencia,
            ganhoHora  = ganhoHora,
            nota       = nota,
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "NotificationListenerService conectado ✓")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "NotificationListenerService desconectado")
    }
}
