package com.example.tesladash.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.NavState
import com.example.tesladash.data.VehicleState
import kotlinx.coroutines.delay
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

private val Cyan = Color(0xFF2A9DFF)
private val Red = Color(0xFFFF2A1A)
private val Green = Color(0xFF4CD964)
private val Grey = Color(0xFF8A8F98)
private val Track = Color(0xFF14202B)

private const val SWEEP = 150f
private const val MAX_SPEED = 240
private const val MIN_KW = -60f
private const val MAX_KW = 150f

/** 클러스터 레이아웃: 양쪽 곡선 게이지(속도/출력), 가운데 지도, 아래 한 줄 정보. */
@Composable
fun ClusterScreen(s: VehicleState, nav: NavState?) {
    val tm = rememberTextMeasurer()
    val over = nav?.camera != null && s.speedKmh > nav.camera.limitKmh
    val clock by produceState("") {
        val fmt = DateTimeFormatter.ofPattern("HH:mm")
        while (true) {
            value = LocalTime.now().format(fmt)
            delay(1_000)
        }
    }
    BoxWithConstraints(Modifier.fillMaxSize().background(Color.Black)) {
        Canvas(Modifier.fillMaxSize()) {
            val r = min(size.height * 0.46f, size.width * 0.23f)
            val cy = size.height * 0.5f
            speedGauge(tm, Offset(size.width * 0.26f, cy), r, s.speedKmh)
            powerGauge(tm, Offset(size.width * 0.74f, cy), r, s.powerKw)
        }
        Row(
            Modifier.fillMaxSize().padding(horizontal = maxWidth * 0.2f, vertical = 12.dp).padding(bottom = 28.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("${s.speedKmh}", color = if (over) Red else Color.White, fontSize = 40.sp, fontWeight = FontWeight.Bold)
                Text("km/h", color = Grey, fontSize = 12.sp)
            }
            MapPanel(nav, s.speedKmh, Modifier.weight(2.2f).fillMaxHeight())
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(s.gear.name, color = Color.White, fontSize = 40.sp, fontWeight = FontWeight.Bold)
                Text(if (s.powerKw < 0) "회생" else "", color = Green, fontSize = 12.sp)
            }
        }
        Row(
            Modifier.align(Alignment.BottomCenter).fillMaxWidth(0.44f).padding(bottom = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Text("${s.rangeKm} km", color = Grey, fontSize = 14.sp)
            Text(clock, color = Grey, fontSize = 14.sp)
            Text("%.1f°C".format(s.outsideTempC), color = Grey, fontSize = 14.sp)
        }
    }
}

private fun dir(deg: Float) = Offset(cos(Math.toRadians(deg.toDouble())).toFloat(), sin(Math.toRadians(deg.toDouble())).toFloat())

/** 왼쪽 "(" 모양 속도 게이지. 아래(115°)에서 시계방향으로 올라간다. */
private fun DrawScope.speedGauge(tm: TextMeasurer, c: Offset, r: Float, speed: Int) {
    val start = 115f
    val stroke = 6.dp.toPx()
    val tl = c - Offset(r, r)
    val box = Size(r * 2, r * 2)
    drawArc(Track, start, SWEEP, false, tl, box, style = Stroke(stroke))
    val fill = SWEEP * speed.coerceIn(0, MAX_SPEED) / MAX_SPEED
    if (fill > 0f) {
        drawArc(Cyan.copy(alpha = 0.25f), start, fill, false, tl, box, style = Stroke(stroke * 2.6f))
        drawArc(Cyan, start, fill, false, tl, box, style = Stroke(stroke))
    }
    for (i in 0..12) {
        val a = start + SWEEP * (i * 20) / MAX_SPEED
        val d = dir(a)
        drawLine(Color(0xFF4A5560), c + d * (r - 10.dp.toPx()), c + d * (r - (if (i % 2 == 0) 16 else 12).dp.toPx()), 1.5.dp.toPx())
        if (i % 2 == 0) tickLabel(tm, "${i * 20}", c + d * (r - 30.dp.toPx()))
    }
    val na = start + fill
    drawLine(Color.White, c + dir(na) * (r * 0.62f), c + dir(na) * (r - 6.dp.toPx()), 2.dp.toPx())
}

/** 오른쪽 ")" 모양 출력 게이지. 0kW 지점에서 위로 파란색, 아래로 초록색(회생)이 채워진다. */
private fun DrawScope.powerGauge(tm: TextMeasurer, c: Offset, r: Float, kw: Float) {
    val top = -85f
    val stroke = 6.dp.toPx()
    val tl = c - Offset(r, r)
    val box = Size(r * 2, r * 2)
    fun angleAt(kwv: Float) = top + SWEEP * (1f - (kwv.coerceIn(MIN_KW, MAX_KW) - MIN_KW) / (MAX_KW - MIN_KW))
    drawArc(Track, top, SWEEP, false, tl, box, style = Stroke(stroke))
    val zero = angleAt(0f)
    val now = angleAt(kw)
    if (kw > 0.5f) {
        drawArc(Cyan.copy(alpha = 0.25f), now, zero - now, false, tl, box, style = Stroke(stroke * 2.6f))
        drawArc(Cyan, now, zero - now, false, tl, box, style = Stroke(stroke))
    } else if (kw < -0.5f) {
        drawArc(Green.copy(alpha = 0.25f), zero, now - zero, false, tl, box, style = Stroke(stroke * 2.6f))
        drawArc(Green, zero, now - zero, false, tl, box, style = Stroke(stroke))
    }
    for (v in listOf(-50f, 0f, 50f, 100f, 150f)) {
        val d = dir(angleAt(v))
        drawLine(Color(0xFF4A5560), c + d * (r - 10.dp.toPx()), c + d * (r - 16.dp.toPx()), 1.5.dp.toPx())
        tickLabel(tm, "${v.roundToInt()}", c + d * (r - 30.dp.toPx()))
    }
    drawLine(Color.White, c + dir(now) * (r * 0.62f), c + dir(now) * (r - 6.dp.toPx()), 2.dp.toPx())
}

private fun DrawScope.tickLabel(tm: TextMeasurer, text: String, center: Offset) {
    val res = tm.measure(text, TextStyle(color = Grey, fontSize = 11.sp))
    drawText(res, topLeft = center - Offset(res.size.width / 2f, res.size.height / 2f))
}
