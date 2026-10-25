package com.example.tesladash.ui

import android.media.AudioManager
import android.media.ToneGenerator

/** 단속카메라 경고음. 진입 시 짧은 안내음, 과속 중에는 더 높은 경고음. */
class CameraBeeper {
    private val tone = ToneGenerator(AudioManager.STREAM_MUSIC, 100)

    fun notice() { tone.startTone(ToneGenerator.TONE_PROP_BEEP2, 300) }

    fun warn() { tone.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 400) }

    fun release() = tone.release()
}
