package com.metamoto.app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class RideNotificationService : NotificationListenerService() {

    companion object {
        // Package names of delivery/ride apps
        val RIDE_APPS = mapOf(
            // Uber Driver
            "com.ubercab.driver" to "Uber",
            // 99 Driver
            "com.taxis99.driver" to "99",
            "br.com.taxis99.driver" to "99",
            // iFood courier
            "com.ifood.courier" to "iFood",
            // Lalamove driver
            "com.lalamove.huolala.driver" to "Lalamove",
            // InDrive
            "sinet.startup.inDriver" to "InDrive",
            // Rappi
            "com.rappi.deliv" to "Outro",
        )

        val AMOUNT_REGEX = Regex("R\\$\\s?([\\d.]+,[\\d]{2})|([\\d]+,[\\d]{2})")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val platform = RIDE_APPS[sbn.packageName] ?: return

        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""

        val fullText = "$title $text $bigText"

        // Only process payment/earnings notifications
        val paymentKeywords = listOf(
            "recebeu", "ganhou", "corrida", "entrega", "pagamento",
            "recebido", "receber", "faturou", "R$", "viagem"
        )
        val hasPaymentKeyword = paymentKeywords.any { fullText.contains(it, ignoreCase = true) }
        if (!hasPaymentKeyword) return

        val match = AMOUNT_REGEX.find(fullText) ?: return
        val amountStr = (match.groupValues[1].ifEmpty { match.groupValues[2] })
            .replace(".", "")
            .replace(",", ".")
        val amount = amountStr.toDoubleOrNull() ?: return
        if (amount <= 0.5) return  // ignore tiny amounts (cents)

        NotificationListenerModule.sendRideDetected(platform, amount, fullText.trim())
    }
}
