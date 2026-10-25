package com.example.tesladash.data

enum class Gear { P, R, N, D }

enum class TurnSignal { Off, Left, Right, Both }

data class VehicleState(
    val speedKmh: Int = 0,
    val gear: Gear = Gear.P,
    val batteryPercent: Int = 80,
    val rangeKm: Int = 400,
    val powerKw: Float = 0f,
    val outsideTempC: Float = 20f,
    val turnSignal: TurnSignal = TurnSignal.Off,
)
