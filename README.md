# emergency-process-local

## 기사 공격 모션 (Godot 4.3+)
- 실행: `scenes/main.tscn` — 이동 WASD, 공격 좌클릭 / J / Space
- 모션: Mixamo `Great Sword Slash` (`assets/animations/Great_Sword_Slash.fbx`, 뼈대만 포함, 1.82초)
  - `scripts/knight.gd` 상단 상수로 배속(`ATTACK_SPEED`), 타격 판정 구간(`HIT_START`/`HIT_END`), 후딜 취소(`CANCEL_AT`) 조절
  - 모델 스케일 `MODEL_SCALE = 0.1` (FBX 뼈대가 사람 크기의 약 10배)
- 실제 기사 모델로 교체: Mixamo 리그(`mixamorig:`) 모델 `.glb/.fbx` 를 `Visual/Model` 로 바꾸고 `show_skeleton` 을 끄면 됨
- 적은 collision layer 2 에 두면 칼 `Hitbox` 가 감지하고 `take_damage(10)` 을 호출
- `docs/motion_preview.svg`: 모션 포즈 미리보기
- 허수아비: `scenes/dummy.tscn` (HP 100, 맞으면 붉게 깜빡이고 0이 되면 2초 뒤 부활). 기사 앞 2m 에 배치됨

## 말하는 섬 (블록아웃)
- `scripts/talking_island.gd` 가 코드로 지형/마을/숲/던전 입구/사냥터를 생성 (`main.tscn` 의 `Island` 노드)
- 광장(원점)에서 시작. 북쪽 던전 입구, 동쪽 늑대/서쪽 고블린 사냥터, 남쪽 선착장
- 건물/사냥터 위치는 스크립트 상단 `BUILDINGS`, `ZONES` 상수로 조절
- 임시 형태이므로 참고 지도에 맞춰 배치를 수정할 예정
