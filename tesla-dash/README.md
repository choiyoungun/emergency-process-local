# Tesla Dash (Android)

Kotlin + Jetpack Compose 계기판 앱. 현재는 `FakeVehicleSource`의 가짜 데이터로 동작한다.

- 실행: Android Studio에서 `tesla-dash/` 폴더를 열고 Run (가로 모드 에뮬레이터/기기)
- 연동 예정: `VehicleSource` 인터페이스를 구현한 `TeslemetrySource` 등을 만들어
  `DashViewModel` 기본값만 교체하면 UI 변경 없이 실제 차량 데이터로 전환된다.
