package com.example.tesladash.data

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/** 회전 지점을 차례로 지나가는 가짜 길안내. */
class FakeNavSource : NavSource {
    private val steps = listOf(
        Turn.Right to "테헤란로",
        Turn.Left to "강남대로",
        Turn.Straight to "올림픽대로",
        Turn.UTurn to "잠실대교",
    )

    override fun states(): Flow<NavState?> = flow {
        var remainingKm = 12.4f
        var i = 0
        var dist = 800.0
        var camDist = 1200.0
        while (true) {
            val (turn, road) = steps[i % steps.size]
            val camera = if (camDist <= 500) CameraAlert(CameraType.Fixed, camDist.toInt(), 80) else null
            emit(NavState(turn, dist.toInt(), road, remainingKm, (remainingKm / 0.8f).toInt(), camera))
            camDist -= 15.0
            if (camDist < 0) camDist = 1200.0
            dist -= 15.0 * 0.1 * 10
            remainingKm = (remainingKm - 0.015f).coerceAtLeast(0f)
            if (dist <= 0) { i++; dist = 800.0 }
            delay(100)
        }
    }
}
