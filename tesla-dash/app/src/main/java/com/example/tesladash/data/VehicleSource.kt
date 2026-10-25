package com.example.tesladash.data

import kotlinx.coroutines.flow.Flow

/** 계기판 데이터 공급원. 나중에 Teslemetry/Fleet API 구현체로 교체한다. */
interface VehicleSource {
    fun states(): Flow<VehicleState>
}
