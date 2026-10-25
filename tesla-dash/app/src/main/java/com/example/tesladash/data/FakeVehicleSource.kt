package com.example.tesladash.data

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlin.math.sin

/** 가속 -> 순항 -> 회생제동 -> 정차를 반복하는 가짜 주행 데이터. */
class FakeVehicleSource : VehicleSource {
    override fun states(): Flow<VehicleState> = flow {
        var t = 0.0
        var battery = 80f
        while (true) {
            val speed = (60 + 60 * sin(t / 8.0 - 1.5)).coerceAtLeast(0.0)
            val accel = 60.0 / 8.0 * kotlin.math.cos(t / 8.0 - 1.5)
            val power = (accel * 6.0 + speed * 0.15).toFloat().coerceIn(-60f, 150f)
            battery = (battery - power / 40000f).coerceIn(5f, 100f)
            emit(
                VehicleState(
                    speedKmh = speed.toInt(),
                    gear = if (speed < 1) Gear.P else Gear.D,
                    batteryPercent = battery.toInt(),
                    rangeKm = (battery * 5.2f).toInt(),
                    powerKw = power,
                    outsideTempC = 18.5f,
                )
            )
            t += 0.1
            delay(100)
        }
    }
}
