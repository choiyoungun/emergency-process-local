package com.example.tesladash.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.NavState
import com.example.tesladash.data.VehicleState
import kotlin.math.roundToInt

private val Gold = Color(0xFFFFD400)
private val Red = Color(0xFFFF2A1A)
private val Green = Color(0xFF4CD964)
private val Off = Color(0xFF1C1C1E)
private val Grey = Color(0xFF8A8F98)

private const val SEGMENTS = 24
private const val SWEEP = 140f

/** 스포츠 레이아웃: 왼쪽 출력(kW) 게이지, 가운데 큰 속도, 오른쪽 배터리 게이지. */
@Composable
fun SportScreen(s: VehicleState, nav: NavState?) {
    val over = nav?.camera != null && s.speedKmh > nav.camera.limitKmh
    Column(Modifier.fillMaxSize().background(Color.Black).padding(20.dp)) {
        if (nav != null) NavBanner(nav)
        nav?.camera?.let { CameraBar(it, s.speedKmh) }
        Row(Modifier.weight(1f).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            SegGauge(Modifier.weight(1f), startAngle = 110f, litAt = { i -> powerColor(i, s.powerKw) }) {
                Text("${s.powerKw.roundToInt()}", color = Color.White, fontSize = 36.sp, fontWeight = FontWeight.Bold)
                Text("kW POWER", color = Grey, fontSize = 12.sp, letterSpacing = 2.sp)
            }
            Column(Modifier.weight(1.2f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "${s.speedKmh}", color = if (over) Red else Color.White,
                    fontSize = 120.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic,
                )
                Text("KM/H", color = Grey, fontSize = 14.sp, letterSpacing = 4.sp)
                Spacer(Modifier.height(8.dp))
                Box(
                    Modifier.background(Gold, CutCornerShape(topStart = 12.dp, bottomEnd = 12.dp))
                        .padding(horizontal = 24.dp, vertical = 2.dp),
                ) {
                    Text(s.gear.name, color = Color.Black, fontSize = 28.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic)
                }
            }
            SegGauge(Modifier.weight(1f), startAngle = 290f, litAt = { i -> batteryColor(i, s.batteryPercent) }) {
                Text("${s.batteryPercent}%", color = Color.White, fontSize = 36.sp, fontWeight = FontWeight.Bold)
                Text("${s.rangeKm} km", color = Grey, fontSize = 14.sp)
            }
        }
    }
}

private fun powerColor(i: Int, kw: Float): Color? = when {
    kw < 0 -> if (i < ((-kw / 60f * 6).toInt()).coerceAtLeast(1)) Green else null
    i < (kw / 150f * SEGMENTS).toInt() -> if (i >= SEGMENTS * 3 / 4) Red else Gold
    else -> null
}

/** 위쪽(i=0)부터 그려지므로 아래쪽부터 채워지도록 뒤에서 센다. */
private fun batteryColor(i: Int, percent: Int): Color? =
    if (i >= SEGMENTS - (percent / 100f * SEGMENTS).toInt()) (if (percent <= 20) Red else Gold) else null

@Composable
private fun SegGauge(
    modifier: Modifier,
    startAngle: Float,
    litAt: (Int) -> Color?,
    content: @Composable ColumnScope.() -> Unit,
) {
    Box(modifier.aspectRatio(1f), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val w = 14.dp.toPx()
            val d = size.minDimension - w
            val step = SWEEP / SEGMENTS
            for (i in 0 until SEGMENTS) {
                drawArc(
                    litAt(i) ?: Off, startAngle + i * step, step * 0.78f, false,
                    Offset(w / 2, w / 2), Size(d, d), style = Stroke(w),
                )
            }
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally, content = content)
    }
}
