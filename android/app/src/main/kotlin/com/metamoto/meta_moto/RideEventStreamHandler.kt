package com.metamoto.meta_moto

import io.flutter.plugin.common.EventChannel

/**
 * Singleton que mantém o sink do EventChannel ativo.
 * Envia ofertas de corrida ao Flutter para exibição no overlay.
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
     * Envia oferta de corrida detectada para o Flutter.
     * O overlay mostrará R$/km, R$/hora e valor antes do motorista aceitar.
     */
    fun sendOffer(
        platform:   String,
        valor:      Double,
        distKm:     Double? = null,
        tempMin:    Int?    = null,
        eficiencia: Double? = null,
        ganhoHora:  Double? = null,
        nota:       Double? = null,
    ) {
        val map = mutableMapOf<String, Any>(
            "platform" to platform,
            "value"    to valor,
            "tipo"     to "oferta",
        )
        distKm?.let    { map["dist_km"]    = it }
        tempMin?.let   { map["temp_min"]   = it }
        eficiencia?.let { map["eficiencia"] = it }
        ganhoHora?.let { map["ganho_hora"] = it }
        nota?.let      { map["nota"]       = it }

        eventSink?.success(map)
    }

    /** Mantém compatibilidade com o código legado de corridas concluídas. */
    fun sendRide(platform: String, value: Double, distKm: Double? = null) {
        val map = mutableMapOf<String, Any>(
            "platform" to platform,
            "value"    to value,
            "tipo"     to "conclusao",
        )
        distKm?.let { map["dist_km"] = it }
        eventSink?.success(map)
    }
}
