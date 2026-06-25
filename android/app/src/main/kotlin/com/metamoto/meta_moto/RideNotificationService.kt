package com.metamoto.meta_moto

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Serviço que lê notificações dos apps de entrega em segundo plano.
 * Extrai VALOR (R$) e DISTÂNCIA (km) de cada corrida concluída.
 *
 * Apps suportados:
 *   Uber Driver   → com.ubercab.driver
 *   99 Motorista  → com.taxis99.driver  (ou com.taxis99)
 *   iFood Courier → com.ifood.courier   (ou br.com.ifood)
 *   Lalamove      → com.lalamove.android
 *   InDrive       → sinet.startup.inDriver
 */
class RideNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "MetaMoto-NLS"

        private val SUPPORTED_PACKAGES = mapOf(
            "com.ubercab.driver"        to "Uber",
            "com.ubercab"               to "Uber",
            "com.taxis99.driver"        to "99",
            "com.taxis99"               to "99",
            "com.ifood.courier"         to "iFood",
            "br.com.ifood"              to "iFood",
            "com.lalamove.android"      to "Lalamove",
            "sinet.startup.inDriver"    to "InDrive"
        )

        // ─── Regex: extrai valor monetário ───────────────────────────────────
        // Aceita: R$ 12,50 | R$12.50 | + R$ 18,75 | BRL 15.00
        private val MONEY_REGEX = Regex(
            """(?:\+\s*)?R\$\s*(\d{1,4}(?:[.,]\d{3})*[.,]\d{2})""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // ─── Regex: extrai distância em km ───────────────────────────────────
        // Aceita: 3,2 km | 3.2km | 12 km | 0.8 km
        private val KM_REGEX = Regex(
            """(\d{1,3}[.,]\d{1,2}|\d{1,3})\s*km""",
            setOf(RegexOption.IGNORE_CASE)
        )

        // Palavras-chave que indicam corrida/entrega concluída
        private val COMPLETION_KEYWORDS = listOf(
            "conclu", "ganhou", "recebeu", "faturou", "entregue",
            "finaliz", "complete", "earned", "trip ended", "entrega feita",
            "corrida encerrada", "você recebeu", "corrida concluída",
            "viagem concluída", "pagamento", "depositado", "credita"
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

        val fullLower = "$title $text $bigText $subText".lowercase()

        // Só processa notificações de conclusão de corrida
        if (COMPLETION_KEYWORDS.none { fullLower.contains(it) }) return

        // ── Extrai valor ──────────────────────────────────────────────────────
        val rawFull = "$title $text $bigText $subText"
        val moneyMatch = MONEY_REGEX.find(rawFull)
        val value = moneyMatch?.groupValues?.get(1)
            ?.replace(".", "")
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        if (value == null || value < 1.0) {
            Log.d(TAG, "[$platform] Notificação sem valor válido: ${text.take(80)}")
            return
        }

        // ── Extrai distância (km) ─────────────────────────────────────────────
        val kmMatch = KM_REGEX.find(rawFull)
        val distKm = kmMatch?.groupValues?.get(1)
            ?.replace(",", ".")
            ?.toDoubleOrNull()

        Log.i(TAG, "[$platform] Corrida: R\$ $value | km: ${distKm ?: "não encontrado"}")
        Log.i(TAG, "  Texto original: ${text.take(120)}")

        RideEventStreamHandler.sendRide(platform, value, distKm)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) = Unit

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "NotificationListenerService conectado")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.w(TAG, "NotificationListenerService desconectado")
    }
}
