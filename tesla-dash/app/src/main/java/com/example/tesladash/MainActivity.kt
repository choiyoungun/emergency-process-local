package com.example.tesladash

import android.os.Bundle
import android.view.WindowManager
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.delay
import com.example.tesladash.ui.CameraBeeper
import com.example.tesladash.ui.ClassicScreen
import com.example.tesladash.ui.ClusterScreen
import com.example.tesladash.ui.CompactScreen
import com.example.tesladash.ui.DashScreen
import com.example.tesladash.ui.DashViewModel
import com.example.tesladash.ui.NaviScreen
import com.example.tesladash.ui.SideCameraOverlay
import com.example.tesladash.ui.SportScreen
import com.example.tesladash.ui.TmapButton
import com.example.tesladash.util.TmapLauncher

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
            val layout = rememberSaveable { mutableStateOf(3) } // 0=스포츠, 1=기본, 2=내비, 3=클러스터, 4=클래식
            BoxWithConstraints(
                Modifier.fillMaxSize().clickable(
                    interactionSource = remember { MutableInteractionSource() }, indication = null,
                ) { layout.value = (layout.value + 1) % 5 },
            ) {
                // 분할 화면처럼 창이 좁으면 간단한 레이아웃으로 바꾼다.
                if (maxWidth < 560.dp) {
                    CompactScreen(state, nav)
                } else when (layout.value) {
                    0 -> SportScreen(state, nav)
                    1 -> DashScreen(state, nav)
                    2 -> NaviScreen(state, nav)
                    3 -> ClusterScreen(state, nav)
                    else -> ClassicScreen(state, nav)
                }
                SideCameraOverlay(state.turnSignal, Modifier.fillMaxSize())
                TmapButton(
                    onClick = {
                        if (!TmapLauncher.launch(this@MainActivity)) {
                            Toast.makeText(this@MainActivity, "티맵 앱을 찾을 수 없습니다", Toast.LENGTH_SHORT).show()
                        }
                    },
                    modifier = Modifier.align(Alignment.TopEnd),
                )
            }
        }
    }

    override fun onDestroy() {
        beeper.release()
        super.onDestroy()
    }
}
