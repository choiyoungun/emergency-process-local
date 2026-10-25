package com.example.tesladash.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
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
private val Grey = Color(0xFF8A8F98)

/** 분할 화면처럼 좁은 창용. 길안내는 티맵 앱이 하므로 속도, 배터리, 카메라 경고만 보여준다. */
@Composable
fun CompactScreen(s: VehicleState, nav: NavState?) {
    val over = nav?.camera != null && s.speedKmh > nav.camera.limitKmh
    Column(Modifier.fillMaxSize().background(Color.Black).padding(16.dp)) {
        nav?.camera?.let { CameraBar(it, s.speedKmh) }
        Row(Modifier.weight(1f).fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1.2f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    "${s.speedKmh}", color = if (over) Red else Color.White,
                    fontSize = 72.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic,
                )
                Text("KM/H", color = Grey, fontSize = 11.sp, letterSpacing = 3.sp)
                Spacer(Modifier.height(6.dp))
                Box(
                    Modifier.background(Gold, CutCornerShape(topStart = 8.dp, bottomEnd = 8.dp))
                        .padding(horizontal = 16.dp, vertical = 1.dp),
                ) { Text(s.gear.name, color = Color.Black, fontSize = 20.sp, fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic) }
            }
            Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
                Text("${s.batteryPercent}%", color = if (s.batteryPercent <= 20) Red else Color.White, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                Text("${s.rangeKm} km", color = Grey, fontSize = 14.sp)
                Spacer(Modifier.height(10.dp))
                Text(
                    "${s.powerKw.roundToInt()} kW", fontSize = 22.sp, fontWeight = FontWeight.Bold,
                    color = if (s.powerKw < 0) Green else Color.White,
                )
            }
        }
    }
}
