package com.thomaspeterson.bikerouter.wear

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Mirrors the Dart `WatchTurnDirection` enum verbatim — the string IDs
 * are the wire format the phone-side bridge ships.
 */
enum class TurnDirection(val id: String) {
    IDLE("idle"),
    STRAIGHT("straight"),
    SLIGHT_LEFT("slight_left"),
    LEFT("left"),
    SHARP_LEFT("sharp_left"),
    U_TURN("u_turn"),
    SHARP_RIGHT("sharp_right"),
    RIGHT("right"),
    SLIGHT_RIGHT("slight_right"),
    ARRIVED("arrived");

    companion object {
        fun fromId(id: String?): TurnDirection =
            entries.firstOrNull { it.id == id } ?: IDLE
    }
}

/** Snapshot of the latest navigation glance shown on the watch face. */
data class NavigationSnapshot(
    val direction: TurnDirection = TurnDirection.IDLE,
    val distanceToTurnMeters: Int = 0,
    val remainingKm: Double = 0.0,
    val remainingMinutes: Int = 0,
    val streetName: String? = null,
)

/**
 * Process-wide flow updated by [WearableMessageListener] and observed by
 * the Compose UI. Static singleton because both writer and reader live in
 * the same process and a Compose-for-Wear app this small doesn't need
 * fancier DI.
 */
object NavigationStateHolder {
    private val _state = MutableStateFlow(NavigationSnapshot())
    val state: StateFlow<NavigationSnapshot> get() = _state

    fun apply(payload: Map<String, Any?>) {
        val current = _state.value
        _state.value = NavigationSnapshot(
            direction = TurnDirection.fromId(payload["direction"] as? String),
            distanceToTurnMeters =
                (payload["distanceMeters"] as? Number)?.toInt() ?: current.distanceToTurnMeters,
            remainingKm =
                (payload["remainingKm"] as? Number)?.toDouble() ?: current.remainingKm,
            remainingMinutes =
                (payload["remainingMinutes"] as? Number)?.toInt() ?: current.remainingMinutes,
            streetName = payload["streetName"] as? String ?: current.streetName,
        )
    }
}
