package com.example.tesladash

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import com.example.tesladash.ui.CameraBeeper
import com.example.tesladash.ui.DashScreen
import com.example.tesladash.ui.DashViewModel
import com.example.tesladash.ui.SideCameraOverlay
import com.example.tesladash.ui.SportScreen

class MainActivity : ComponentActivity() {
    private val vm: DashViewModel by viewModels()
    private val beeper = CameraBeeper()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        WindowInsetsControllerCompat(window, window.decorView).apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        setContent {
            val state = vm.state.collectAsStateWithLifecycle().value
            val nav = vm.navState.collectAsStateWithLifecycle().value
            val camera = nav?.camera
            val overLimit = camera != null && state.speedKmh > camera.limitKmh
            LaunchedEffect(camera != null) { if (camera != null) beeper.notice() }
            LaunchedEffect(overLimit) {
                while (overLimit) {
                    beeper.warn()
                    delay(1_000)
                }
            }
            val sport = rememberSaveable { mutableStateOf(true) }
            Box(
                Modifier.fillMaxSize().clickable(
                    interactionSource = remember { MutableInteractionSource() }, indication = null,
                ) { sport.value = !sport.value },
            ) {
                if (sport.value) SportScreen(state, nav) else DashScreen(state, nav)
                SideCameraOverlay(state.turnSignal, Modifier.fillMaxSize())
            }
        }
    }

    override fun onDestroy() {
        beeper.release()
        super.onDestroy()
    }
}
