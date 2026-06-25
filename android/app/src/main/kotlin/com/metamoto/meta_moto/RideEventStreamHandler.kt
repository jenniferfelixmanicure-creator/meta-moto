package com.metamoto.meta_moto

import io.flutter.plugin.common.EventChannel

/**
 * Singleton que mantém o sink do EventChannel ativo.
 * O RideNotificationService chama [sendRide] para enviar corridas ao Flutter.
 */
object RideEventStreamHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Envia corrida detectada para o Flutter.
     * @param platform  Nome da plataforma ("Uber", "99", "iFood" etc.)
     * @param value     Valor em R$
     * @param distKm    Distância em km (pode ser null se não encontrado)
     */
    fun sendRide(platform: String, value: Double, distKm: Double? = null) {
        val map = mutableMapOf<String, Any>(
            "platform" to platform,
            "value"    to value
        )
        distKm?.let { map["dist_km"] = it }
        eventSink?.success(map)
    }
}
