# Tesla Dash (Android)

Kotlin + Jetpack Compose 계기판 앱. 현재는 `FakeVehicleSource`의 가짜 데이터로 동작한다.

- 실행: Android Studio에서 `tesla-dash/` 폴더를 열고 Run (가로 모드 에뮬레이터/기기)
- 연동 예정: `VehicleSource` 인터페이스를 구현한 `TeslemetrySource` 등을 만들어
  `DashViewModel` 기본값만 교체하면 UI 변경 없이 실제 차량 데이터로 전환된다.
- 길안내: `NavSource` 인터페이스 + `FakeNavSource`. TMAP SDK/API 구현체(`TmapNavSource`)로 교체 예정.
- 티맵: SDK 없이 `TmapLauncher`가 티맵 앱을 옆 창(분할 화면)으로 실행한다. 패키지명(`com.skt.tmap.ku` 등)은 실제 기기에서 확인 필요.
- 창 너비가 560dp 미만이면 `CompactScreen`(속도, 배터리, 카메라 경고)으로 자동 전환된다.
