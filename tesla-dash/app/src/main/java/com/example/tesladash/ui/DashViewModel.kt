package com.example.tesladash.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.tesladash.data.FakeVehicleSource
import com.example.tesladash.data.VehicleSource
import com.example.tesladash.data.VehicleState
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class DashViewModel(source: VehicleSource = FakeVehicleSource()) : ViewModel() {
    val state: StateFlow<VehicleState> =
        source.states().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), VehicleState())
}
