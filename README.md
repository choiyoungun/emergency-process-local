# emergency-process-local

## 기사 공격 모션 (Godot 4.3+)
- 실행: `scenes/main.tscn` — 이동: 땅 클릭(터치) 또는 WASD, 공격: 적 클릭(다가가서 자동 공격) 또는 J / Space
- 카메라: `scripts/quarter_camera.gd` 쿼터뷰(고정 각도, 기사를 부드럽게 추적). `offset`/`follow_speed` 로 조절
- 클릭 이동은 직선 이동(길찾기 없음) — 건물/벽에 막히면 멈춤
- 모션: Mixamo `Great Sword Slash` (`assets/animations/Great_Sword_Slash.fbx`, 뼈대만 포함, 1.82초)
  - `scripts/knight.gd` 상단 상수로 배속(`ATTACK_SPEED`), 시작 지점(`ATTACK_START`, 준비 동작 생략), 타격 판정 구간(`HIT_START`/`HIT_END`), 후딜 취소(`CANCEL_AT`) 조절. 현재 값은 리니지 영상 기준 공격 주기 약 0.5초, 타격 약 0.17~0.27초
  - 모델 스케일 `MODEL_SCALE = 0.1` (FBX 뼈대가 사람 크기의 약 10배)
- 실제 기사 모델로 교체: Mixamo 리그(`mixamorig:`) 모델 `.glb/.fbx` 를 `Visual/Model` 로 바꾸고 `show_skeleton` 을 끄면 됨
- 적은 collision layer 2 에 두면 칼 `Hitbox` 가 감지하고 `take_damage(10)` 을 호출
- `docs/motion_preview.svg`: 모션 포즈 미리보기
- 허수아비: `scenes/dummy.tscn` (HP 100, 맞으면 붉게 깜빡이고 0이 되면 2초 뒤 부활). 기사 앞 2m 에 배치됨

## 말하는 섬 (블록아웃)
- 배치 기준: 리니지M 인벤 말하는 섬 지도(2000x1022, 저장소에는 포함하지 않음). 윤곽/지점/사냥터 좌표는 그 지도의 픽셀 좌표를 상수로 옮긴 것 (`OUTLINE_PX`, `POIS`, `REGIONS`, `VILLAGE_PX`, `PX_SCALE=0.1m/px`)
- `scripts/talking_island.gd` 가 코드로 지형(북쪽 만, 북서 반도)/마을/흙길/13개 지점/속성별 사냥터 색 구역(불=빨강, 물=파랑, 땅=노랑, 흑기사단=회색)/숲/던전 입구/선착장을 생성 (`main.tscn` 의 `Island` 노드)
- 월드 원점 = 마을 광장(기사 시작). `SHOW_REGIONS` 로 사냥터 색 구역 on/off
- 나무는 MultiMesh(모바일 성능), 충돌 없음. 모델/텍스처는 아직 임시 도형
