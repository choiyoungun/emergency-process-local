package com.example.tesladash.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.NavState
import com.example.tesladash.data.VehicleState
import kotlin.math.roundToInt

private val Gold = Color(0xFFFFD400)
private val Blue = Color(0xFF3FA9F5)
private val Red = Color(0xFFFF2A1A)
private val Green = Color(0xFF4CD964)
private val Grey = Color(0xFF8A8F98)
private val Track = Color(0xFF1C1C1E)

/** 내비 레이아웃: 가운데 지도/길안내, 왼쪽 속도, 오른쪽 차량 정보. */
@Composable
fun NaviScreen(s: VehicleState, nav: NavState?) {
    val over = nav?.camera != null && s.speedKmh > nav.camera.limitKmh
    Row(
        Modifier.fillMaxSize().background(Color.Black).padding(20.dp),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Column(Modifier.weight(1f).fillMaxHeight(), Arrangement.Center, Alignment.CenterHorizontally) {
            Text(
                "${s.speedKmh}", color = if (over) Red else Color.White,
                fontSize = 84.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic,
            )
            Text("KM/H", color = Grey, fontSize = 13.sp, letterSpacing = 4.sp)
            Spacer(Modifier.height(10.dp))
            Box(
                Modifier.background(Gold, CutCornerShape(topStart = 10.dp, bottomEnd = 10.dp))
                    .padding(horizontal = 20.dp, vertical = 2.dp),
            ) { Text(s.gear.name, color = Color.Black, fontSize = 24.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic) }
        }
        MapPanel(nav, s.speedKmh, Modifier.weight(2f).fillMaxHeight())
        Column(Modifier.weight(1f).fillMaxHeight(), Arrangement.Center, Alignment.CenterHorizontally) {
            Text("${s.batteryPercent}%", color = Color.White, fontSize = 40.sp, fontWeight = FontWeight.Bold)
            BatteryBar(s.batteryPercent)
            Text("${s.rangeKm} km", color = Grey, fontSize = 16.sp)
            Spacer(Modifier.height(16.dp))
            Text(
                "${s.powerKw.roundToInt()} kW", fontSize = 30.sp, fontWeight = FontWeight.Bold,
                color = if (s.powerKw < 0) Green else Color.White,
            )
            Text(if (s.powerKw < 0) "회생" else "출력", color = Grey, fontSize = 14.sp)
            Spacer(Modifier.height(12.dp))
            Text("%.0f°C".format(s.outsideTempC), color = Grey, fontSize = 18.sp)
        }
    }
}

@Composable
private fun BatteryBar(percent: Int) {
    Box(Modifier.fillMaxWidth(0.8f).padding(vertical = 6.dp).height(10.dp).background(Track, RoundedCornerShape(5.dp))) {
        Box(
            Modifier.fillMaxWidth(percent.coerceIn(0, 100) / 100f).fillMaxHeight()
                .background(if (percent <= 20) Red else Gold, RoundedCornerShape(5.dp)),
        )
    }
}

/** TMAP 지도 연동 전까지 쓰는 샘플 지도. 길안내 정보는 NavState로 위에 겹쳐 그린다. */
@Composable
internal fun MapPanel(nav: NavState?, speedKmh: Int, modifier: Modifier) {
    Box(modifier.background(Color(0xFF0F1418), RoundedCornerShape(16.dp))) {
        Canvas(Modifier.fillMaxSize()) {
            val grid = Color(0xFF1A2128)
            for (i in 1..5) drawLine(grid, Offset(size.width * i / 6, 0f), Offset(size.width * i / 6, size.height), 2f)
            for (i in 1..3) drawLine(grid, Offset(0f, size.height * i / 4), Offset(size.width, size.height * i / 4), 2f)
            val route = Path().apply {
                moveTo(size.width * 0.5f, size.height)
                lineTo(size.width * 0.5f, size.height * 0.65f)
                quadraticBezierTo(size.width * 0.5f, size.height * 0.45f, size.width * 0.7f, size.height * 0.4f)
                lineTo(size.width * 0.9f, size.height * 0.35f)
            }
            drawPath(route, Blue, style = Stroke(10.dp.toPx(), cap = StrokeCap.Round, join = StrokeJoin.Round))
            val car = Offset(size.width * 0.5f, size.height * 0.88f)
            drawCircle(Color.White, 10.dp.toPx(), car)
            drawCircle(Blue, 6.dp.toPx(), car)
        }
        Text("SAMPLE MAP", color = Color(0xFF2A333B), fontSize = 12.sp, letterSpacing = 3.sp, modifier = Modifier.align(Alignment.Center))
        if (nav != null) {
            Row(
                Modifier.align(Alignment.TopCenter).fillMaxWidth().padding(12.dp)
                    .background(Color(0x99000000), RoundedCornerShape(12.dp)).padding(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(nav.turn.arrow, color = Blue, fontSize = 40.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.width(14.dp))
                Column {
                    val dist = if (nav.distanceToTurnM >= 1000) "%.1f km".format(nav.distanceToTurnM / 1000f) else "${nav.distanceToTurnM} m"
                    Text(dist, color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Bold)
                    Text(nav.roadName, color = Grey, fontSize = 14.sp)
                }
            }
            Column(Modifier.align(Alignment.BottomCenter).fillMaxWidth().padding(12.dp)) {
                nav.camera?.let { CameraBar(it, speedKmh) }
                Spacer(Modifier.height(6.dp))
                Text(
                    "%.1f km · ${nav.etaMinutes}분".format(nav.remainingKm), color = Color.White, fontSize = 16.sp,
                    modifier = Modifier.background(Color(0x99000000), RoundedCornerShape(8.dp)).padding(horizontal = 10.dp, vertical = 4.dp),
                )
            }
        }
    }
}
