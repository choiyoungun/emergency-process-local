package com.example.tesladash.data

enum class Gear { P, R, N, D }

data class VehicleState(
    val speedKmh: Int = 0,
    val gear: Gear = Gear.P,
    val batteryPercent: Int = 80,
    val rangeKm: Int = 400,
    val powerKw: Float = 0f,
    val outsideTempC: Float = 20f,
)
