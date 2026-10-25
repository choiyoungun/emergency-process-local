package com.example.tesladash.util

import android.content.Context
import android.content.Intent

/**
 * 티맵 앱을 계기판 옆 창(분할 화면)으로 실행한다.
 * 패키지명은 확인이 필요하다. 기기에 설치된 첫 번째 후보를 쓴다.
 */
object TmapLauncher {
    private val packages = listOf("com.skt.tmap.ku", "com.skt.skaf.l001mtm091")

    fun launch(context: Context): Boolean {
        val pm = context.packageManager
        val intent = packages.firstNotNullOfOrNull { pm.getLaunchIntentForPackage(it) } ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_LAUNCH_ADJACENT)
        context.startActivity(intent)
        return true
    }
}
