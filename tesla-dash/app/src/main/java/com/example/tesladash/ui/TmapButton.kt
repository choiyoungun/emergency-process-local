package com.example.tesladash.ui

import androidx.compose.foundation.border
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun TmapButton(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val shape = RoundedCornerShape(8.dp)
    Text(
        "TMAP", color = Color(0xFFFFD400), fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.sp,
        modifier = modifier.padding(12.dp)
            .background(Color(0x99000000), shape).border(1.dp, Color(0xFFFFD400), shape)
            .clickable(onClick = onClick).padding(horizontal = 12.dp, vertical = 6.dp),
    )
}
