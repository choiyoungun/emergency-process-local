package com.example.tesladash.data

enum class Turn(val arrow: String) { Straight("↑"), Left("←"), Right("→"), UTurn("↶") }

data class NavState(
    val turn: Turn = Turn.Straight,
    val distanceToTurnM: Int = 0,
    val roadName: String = "",
    val remainingKm: Float = 0f,
    val etaMinutes: Int = 0,
)
