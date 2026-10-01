# emergency-process-local

## 기사 공격 모션 (Godot 4.3+)
- 실행: `scenes/main.tscn` — 이동 WASD, 공격 좌클릭 / J / Space
- 모션: Mixamo `Great Sword Slash` (`assets/animations/Great_Sword_Slash.fbx`, 뼈대만 포함, 1.82초)
  - `scripts/knight.gd` 상단 상수로 배속(`ATTACK_SPEED`), 타격 판정 구간(`HIT_START`/`HIT_END`), 후딜 취소(`CANCEL_AT`) 조절
  - 모델 스케일 `MODEL_SCALE = 0.1` (FBX 뼈대가 사람 크기의 약 10배)
- 실제 기사 모델로 교체: Mixamo 리그(`mixamorig:`) 모델 `.glb/.fbx` 를 `Visual/Model` 로 바꾸고 `show_skeleton` 을 끄면 됨
- 적은 collision layer 2 에 두면 칼 `Hitbox` 가 감지하고 `take_damage(10)` 을 호출
- `docs/motion_preview.svg`: 모션 포즈 미리보기
