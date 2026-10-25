package com.example.tesladash.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CutCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.tesladash.data.TurnSignal
import kotlinx.coroutines.delay

private const val HOLD_MS = 3_000L

/** 깜빡이 방향에 맞춰 측면 카메라 창을 띄우고, 꺼진 뒤 잠시 더 보여준다. */
@Composable
fun SideCameraOverlay(signal: TurnSignal, modifier: Modifier = Modifier) {
    var side by remember { mutableStateOf<TurnSignal?>(null) }
    LaunchedEffect(signal) {
        when (signal) {
            TurnSignal.Left, TurnSignal.Right -> side = signal
            TurnSignal.Off -> {
                delay(HOLD_MS)
                side = null
            }
            TurnSignal.Both -> Unit
        }
    }
    Box(modifier.padding(24.dp)) {
        when (side) {
            TurnSignal.Left -> CameraPane("LEFT CAM", Modifier.align(Alignment.BottomStart))
            TurnSignal.Right -> CameraPane("RIGHT CAM", Modifier.align(Alignment.BottomEnd))
            else -> Unit
        }
    }
}

/** 실제 영상(RTSP/UVC 등) 연동 전까지 쓰는 자리표시 화면. */
@Composable
private fun CameraPane(label: String, modifier: Modifier) {
    val shape = CutCornerShape(topStart = 14.dp, bottomEnd = 14.dp)
    Box(
        modifier.size(width = 280.dp, height = 170.dp)
            .background(Brush.verticalGradient(listOf(Color(0xFF2B3A44), Color(0xFF0E1418))), shape)
            .border(2.dp, Color(0xFFFFD400), shape),
        contentAlignment = Alignment.Center,
    ) {
        Text("SAMPLE VIEW", color = Color(0xFF8A8F98), fontSize = 14.sp, letterSpacing = 3.sp)
        Text(
            label, color = Color(0xFFFFD400), fontSize = 14.sp, fontWeight = FontWeight.Bold,
            modifier = Modifier.align(Alignment.TopStart).padding(10.dp),
        )
    }
}
