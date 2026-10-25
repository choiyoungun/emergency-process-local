package com.example.tesladash.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.tesladash.data.FakeNavSource
import com.example.tesladash.data.FakeVehicleSource
import com.example.tesladash.data.NavSource
import com.example.tesladash.data.NavState
import com.example.tesladash.data.VehicleSource
import com.example.tesladash.data.VehicleState
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

class DashViewModel(
    vehicle: VehicleSource = FakeVehicleSource(),
    nav: NavSource = FakeNavSource(),
) : ViewModel() {
    val state: StateFlow<VehicleState> =
        vehicle.states().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), VehicleState())

    val navState: StateFlow<NavState?> =
        nav.states().stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)
}
