package com.example.tesladash.data

import kotlinx.coroutines.flow.Flow

/** 길안내 데이터 공급원. 나중에 TMAP SDK/API 구현체로 교체한다. */
interface NavSource {
    fun states(): Flow<NavState?>
}
