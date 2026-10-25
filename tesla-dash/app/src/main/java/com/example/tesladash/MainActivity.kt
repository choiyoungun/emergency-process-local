package com.example.tesladash

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.LaunchedEffect
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import com.example.tesladash.ui.CameraBeeper
import com.example.tesladash.ui.DashScreen
import com.example.tesladash.ui.DashViewModel

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
            DashScreen(state, nav)
        }
    }

    override fun onDestroy() {
        beeper.release()
        super.onDestroy()
    }
}
