extends CharacterBody3D
## 기사 이동 + 공격 모션 (좌클릭 / J / Space).
## 공격 애니메이션은 코드로 생성 -> 나중에 실제 모델의 AnimationPlayer 애니메이션으로 교체 가능.

const SPEED := 5.0
const GRAVITY := 20.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var shoulder: Node3D = $Visual/RightShoulder
@onready var visual: Node3D = $Visual
@onready var hitbox: Area3D = $Visual/RightShoulder/Sword/Hitbox

var attacking := false
var _hit_targets: Array = []


func _ready() -> void:
	_setup_input()
	_build_attack_animation()
	anim.animation_finished.connect(_on_animation_finished)
	hitbox.body_entered.connect(_on_hit)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("attack") and not attacking:
		attacking = true
		_hit_targets.clear()
		anim.play("attack")

	# 공격 중에는 이동 느리게
	var dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var speed := SPEED * (0.3 if attacking else 1.0)
	velocity.x = dir.x * speed
	velocity.z = dir.y * speed
	if dir != Vector2.ZERO and not attacking:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.y), 15.0 * delta)
	move_and_slide()


func _build_attack_animation() -> void:
	var a := Animation.new()
	a.length = 0.6

	# 어깨 회전(X): 대기 -> 뒤로 젖힘(0.2s) -> 내려베기(0.32s) -> 복귀
	var t := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(t, "Visual/RightShoulder:rotation")
	a.track_insert_key(t, 0.0, Vector3(deg_to_rad(-10), 0, 0))
	a.track_insert_key(t, 0.2, Vector3(deg_to_rad(110), deg_to_rad(15), 0))   # 준비(윈드업)
	a.track_insert_key(t, 0.32, Vector3(deg_to_rad(-70), deg_to_rad(-10), 0)) # 타격
	a.track_insert_key(t, 0.6, Vector3(deg_to_rad(-10), 0, 0))                # 복귀
	a.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)

	# 몸통 비틀기 + 살짝 전진 (Visual 기준)
	var tr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tr, "Visual:position")
	a.track_insert_key(tr, 0.0, Vector3.ZERO)
	a.track_insert_key(tr, 0.2, Vector3(0, 0, 0.1))
	a.track_insert_key(tr, 0.32, Vector3(0, 0, -0.35))
	a.track_insert_key(tr, 0.6, Vector3.ZERO)

	# 타격 판정 구간 (0.24 ~ 0.4s)
	var h := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(h, "Visual/RightShoulder/Sword/Hitbox:monitoring")
	a.track_set_interpolation_type(h, Animation.INTERPOLATION_NEAREST)
	a.value_track_set_update_mode(h, Animation.UPDATE_DISCRETE)
	a.track_insert_key(h, 0.0, false)
	a.track_insert_key(h, 0.24, true)
	a.track_insert_key(h, 0.4, false)

	var lib := AnimationLibrary.new()
	lib.add_animation("attack", a)
	anim.add_animation_library("", lib)


func _on_hit(body: Node3D) -> void:
	if body == self or body in _hit_targets:
		return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		body.take_damage(10)
	print("Hit: ", body.name)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		attacking = false


func _setup_input() -> void:
	_bind("move_forward", KEY_W)
	_bind("move_back", KEY_S)
	_bind("move_left", KEY_A)
	_bind("move_right", KEY_D)
	_bind("attack", KEY_J)
	_bind("attack", KEY_SPACE)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", m)


func _bind(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventKey.new()
	e.physical_keycode = key
	InputMap.action_add_event(action, e)
