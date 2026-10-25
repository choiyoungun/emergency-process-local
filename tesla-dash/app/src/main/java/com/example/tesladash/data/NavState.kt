package com.example.tesladash.data

enum class Turn(val arrow: String) { Straight("↑"), Left("←"), Right("→"), UTurn("↶") }

enum class CameraType(val label: String) { Fixed("고정식"), Section("구간단속"), Signal("신호위반") }

data class CameraAlert(val type: CameraType, val distanceM: Int, val limitKmh: Int)

data class NavState(
    val turn: Turn = Turn.Straight,
    val distanceToTurnM: Int = 0,
    val roadName: String = "",
    val remainingKm: Float = 0f,
    val etaMinutes: Int = 0,
    val camera: CameraAlert? = null,
)
