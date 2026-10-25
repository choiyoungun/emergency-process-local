package com.example.tesladash.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.NavState
import com.example.tesladash.data.TurnSignal
import com.example.tesladash.data.VehicleState
import kotlinx.coroutines.delay
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

private val Silver = Color(0xFFD8DADC)
private val Grey = Color(0xFF8A8F98)
private val LampOff = Color(0xFF2A2D31)
private val RedZone = Color(0xFFD11F1F)
private val Green = Color(0xFF4CD964)
private val Amber = Color(0xFFFFB300)
private val Alert = Color(0xFFFF3B30)

private const val START = 155f
private const val SWEEP = 230f

/** 클래식 레이아웃: 90년대 아날로그 계기판. 속도계, 출력계(회전계 자리), 작은 배터리/온도 게이지. */
@Composable
fun ClassicScreen(s: VehicleState, nav: NavState?) {
    val tm = rememberTextMeasurer()
    val cam = nav?.camera
    val over = cam != null && s.speedKmh > cam.limitKmh
    val clock by produceState("") {
        val fmt = DateTimeFormatter.ofPattern("HH:mm")
        while (true) {
            value = LocalTime.now().format(fmt)
            delay(1_000)
        }
    }
    BoxWithConstraints(Modifier.fillMaxSize().background(Color.Black)) {
        Canvas(Modifier.fillMaxSize()) {
            val r = min(size.height * 0.3f, size.width * 0.15f)
            val cy = size.height * 0.54f
            dial(tm, Offset(size.width * 0.33f, cy), r, 180f, 20f, 5f, null, "km/h", s.speedKmh.toFloat()) { it.roundToInt().toString() }
            dial(tm, Offset(size.width * 0.67f, cy), r, 9f, 1f, 0.5f, 7f, "x20 kW", s.powerKw / 20f) { it.roundToInt().toString() }
            val mr = r * 0.45f
            miniGauge(
                tm, Offset(size.width * 0.1f, cy + r * 0.2f), mr, -60f, 100f, 1f - s.batteryPercent / 100f,
                listOf(0f to "F", 0.5f to "1/2", 1f to "E"), if (s.batteryPercent <= 20) Alert else Silver,
            )
            miniGauge(
                tm, Offset(size.width * 0.9f, cy + r * 0.2f), mr, 140f, 100f, ((s.outsideTempC + 10f) / 50f),
                listOf(0f to "C", 1f to "H"), Silver,
            )
        }
        Box(Modifier.align(Alignment.TopCenter).fillMaxWidth(0.5f).padding(top = 8.dp)) {
            if (cam != null) CameraBar(cam, s.speedKmh) else if (nav != null) NavBanner(nav)
        }
        Row(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth(0.4f).padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text("%06d km".format(s.rangeKm), color = Grey, fontSize = 14.sp, fontFamily = FontFamily.Monospace)
            Text(
                clock, color = Color(0xFF2A2C14), fontSize = 16.sp, fontFamily = FontFamily.Monospace, fontWeight = FontWeight.Bold,
                modifier = Modifier.background(Color(0xFF8A8F5A), RoundedCornerShape(3.dp)).padding(horizontal = 8.dp),
            )
            Text("%.1f°C".format(s.outsideTempC), color = Grey, fontSize = 14.sp, fontFamily = FontFamily.Monospace)
        }
        Row(Modifier.align(Alignment.BottomStart).padding(start = 16.dp, bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Lamp("◀", s.turnSignal == TurnSignal.Left || s.turnSignal == TurnSignal.Both, Green)
            Lamp("CAM", cam != null, Amber)
        }
        Row(Modifier.align(Alignment.BottomEnd).padding(end = 16.dp, bottom = 8.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Lamp("SPD", over, Alert)
            Lamp("CHG", s.powerKw < 0, Green)
            Lamp("▶", s.turnSignal == TurnSignal.Right || s.turnSignal == TurnSignal.Both, Green)
        }
    }
}

@Composable
private fun Lamp(text: String, on: Boolean, color: Color) {
    Text(text, color = if (on) color else LampOff, fontSize = 13.sp, fontWeight = FontWeight.Bold)
}

private fun vec(deg: Float) = Offset(cos(Math.toRadians(deg.toDouble())).toFloat(), sin(Math.toRadians(deg.toDouble())).toFloat())

private fun DrawScope.text(tm: TextMeasurer, t: String, center: Offset, style: TextStyle) {
    val res = tm.measure(t, style)
    drawText(res, topLeft = center - Offset(res.size.width / 2f, res.size.height / 2f))
}

/** 눈금과 숫자가 있는 큰 원형 계기. redFrom 이상 구간은 빨간색으로 표시한다. */
private fun DrawScope.dial(
    tm: TextMeasurer, c: Offset, r: Float, max: Float, major: Float, minor: Float,
    redFrom: Float?, unit: String, value: Float, label: (Float) -> String,
) {
    fun ang(v: Float) = START + SWEEP * v / max
    if (redFrom != null) {
        val rr = r + 4.dp.toPx()
        drawArc(RedZone, ang(redFrom), SWEEP * (max - redFrom) / max, false, c - Offset(rr, rr), Size(rr * 2, rr * 2), style = Stroke(3.dp.toPx()))
    }
    val n = (max / minor).roundToInt()
    val per = (major / minor).roundToInt()
    for (i in 0..n) {
        val v = i * minor
        val mj = i % per == 0
        val d = vec(ang(v))
        val red = redFrom != null && v >= redFrom
        drawLine(
            if (red) RedZone else Color(0xFFE8E8E8), c + d * r, c + d * (r - (if (mj) 14 else 8).dp.toPx()),
            (if (mj) 2.5f else 1.2f).dp.toPx(),
        )
        if (mj) text(tm, label(v), c + d * (r - 30.dp.toPx()), TextStyle(color = Color(0xFFF2F2F2), fontSize = 15.sp, fontWeight = FontWeight.Bold))
    }
    text(tm, unit, c + Offset(0f, -r * 0.3f), TextStyle(color = Grey, fontSize = 12.sp))
    val d = vec(ang(value.coerceIn(0f, max)))
    drawLine(Silver, c - d * (r * 0.14f), c + d * (r - 12.dp.toPx()), 5.dp.toPx(), cap = StrokeCap.Round)
    drawCircle(Color(0xFF1A1C1F), 10.dp.toPx(), c)
}

/** F/E, C/H 같은 눈금이 있는 작은 반원 계기. p는 0..1 위치. */
private fun DrawScope.miniGauge(
    tm: TextMeasurer, c: Offset, r: Float, start: Float, sweep: Float, p: Float,
    labels: List<Pair<Float, String>>, needle: Color,
) {
    drawArc(Color(0xFF6B7178), start, sweep, false, c - Offset(r, r), Size(r * 2, r * 2), style = Stroke(1.5.dp.toPx()))
    labels.forEach { (q, t) ->
        val d = vec(start + sweep * q)
        drawLine(Silver, c + d * r, c + d * (r - 6.dp.toPx()), 2.dp.toPx())
        text(tm, t, c + d * (r + 14.dp.toPx()), TextStyle(color = Grey, fontSize = 11.sp))
    }
    val d = vec(start + sweep * p.coerceIn(0f, 1f))
    drawLine(needle, c, c + d * (r - 4.dp.toPx()), 3.dp.toPx(), cap = StrokeCap.Round)
    drawCircle(Color(0xFF1A1C1F), 5.dp.toPx(), c)
}
