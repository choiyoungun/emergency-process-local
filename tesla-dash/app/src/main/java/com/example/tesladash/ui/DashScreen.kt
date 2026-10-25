package com.example.tesladash.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.Gear
import com.example.tesladash.data.NavState
import com.example.tesladash.data.VehicleState

private val Accent = Color(0xFF3FA9F5)
private val Dim = Color(0xFF8A8F98)

@Composable
fun DashScreen(s: VehicleState, nav: NavState?) {
    Column(Modifier.fillMaxSize().background(Color.Black).padding(24.dp)) {
    if (nav != null) NavBanner(nav)
    Row(
        Modifier.weight(1f).fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
            Text("${s.batteryPercent}%", color = Color.White, fontSize = 48.sp, fontWeight = FontWeight.Bold)
            Text("${s.rangeKm} km", color = Dim, fontSize = 22.sp)
            Spacer(Modifier.height(16.dp))
            Text("%.0f°C".format(s.outsideTempC), color = Dim, fontSize = 22.sp)
        }
        Box(Modifier.weight(1.4f), contentAlignment = Alignment.Center) {
            SpeedArc(s.speedKmh)
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("${s.speedKmh}", color = Color.White, fontSize = 110.sp, fontWeight = FontWeight.Bold)
                Text("km/h", color = Dim, fontSize = 20.sp)
            }
        }
        Column(Modifier.weight(1f), horizontalAlignment = Alignment.CenterHorizontally) {
            GearRow(s.gear)
            Spacer(Modifier.height(24.dp))
            Text("%.0f kW".format(s.powerKw), color = if (s.powerKw < 0) Color(0xFF4CD964) else Color.White,
                fontSize = 40.sp, fontWeight = FontWeight.Bold)
            Text(if (s.powerKw < 0) "회생" else "출력", color = Dim, fontSize = 18.sp)
        }
    }
    }
}

@Composable
private fun NavBanner(n: NavState) {
    Row(
        Modifier.fillMaxWidth().background(Color(0xFF111316), RoundedCornerShape(12.dp)).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(n.turn.arrow, color = Accent, fontSize = 40.sp, fontWeight = FontWeight.Bold)
        Spacer(Modifier.width(16.dp))
        Column(Modifier.weight(1f)) {
            val dist = if (n.distanceToTurnM >= 1000) "%.1f km".format(n.distanceToTurnM / 1000f) else "${n.distanceToTurnM} m"
            Text(dist, color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Bold)
            Text(n.roadName, color = Dim, fontSize = 16.sp)
        }
        Column(horizontalAlignment = Alignment.End) {
            Text("%.1f km".format(n.remainingKm), color = Color.White, fontSize = 20.sp)
            Text("${n.etaMinutes}분", color = Dim, fontSize = 16.sp)
        }
    }
}

@Composable
private fun SpeedArc(speed: Int, maxSpeed: Int = 180) {
    Canvas(Modifier.size(300.dp)) {
        val stroke = 18.dp.toPx()
        val inset = stroke / 2
        val size = Size(this.size.width - stroke, this.size.height - stroke)
        val top = Offset(inset, inset)
        drawArc(Color(0xFF222428), 135f, 270f, false, top, size, style = Stroke(stroke, cap = StrokeCap.Round))
        drawArc(Accent, 135f, 270f * (speed.coerceIn(0, maxSpeed) / maxSpeed.toFloat()), false, top, size,
            style = Stroke(stroke, cap = StrokeCap.Round))
    }
}

@Composable
private fun GearRow(current: Gear) {
    Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
        Gear.values().forEach {
            Text(it.name, fontSize = 30.sp, fontWeight = FontWeight.Bold,
                color = if (it == current) Color.White else Color(0xFF3A3D42))
        }
    }
}
