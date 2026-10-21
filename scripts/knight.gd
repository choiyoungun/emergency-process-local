extends CharacterBody3D
## 기사 이동(WASD / 클릭 이동) + Mixamo "Great Sword Slash" 공격 (J / Space / 적 클릭).
## Model 은 뼈대만 있는 FBX 이므로 실제 기사 모델(Mixamo 리그)로 교체하면 그대로 동작한다.

const SPEED := 5.0
const GRAVITY := 20.0

const MODEL_SCALE := 0.1       # FBX 뼈대가 사람 크기의 약 10배 -> Model 노드 스케일과 동일해야 함
## 리니지 영상 기준 박자: 공격 주기 0.5초, 타격은 시작 후 약 0.15~0.23초.
const ATTACK_SPEED := 2.0      # 원본 1.82초는 느려서 배속 재생
const ATTACK_START := 0.6      # 애니메이션 앞부분(준비 동작)을 건너뛰고 이 시점부터 재생 (초)
const HIT_START := 0.88        # 타격 판정 구간 (애니메이션 시간 기준, 초)
const HIT_END := 1.06
const CANCEL_AT := 1.6         # 이 시점부터 다음 행동 가능 (후딜 취소) -> 주기 (1.6-0.6)/2.0 = 0.5초
const ATTACK_RANGE := 1.6      # m, 클릭한 적에게 이 거리까지 다가가서 공격
const ARRIVE_DIST := 0.15      # m, 클릭 이동 도착 판정
const SWORD_LENGTH := 1.2      # m
const GRIP_OFFSET := 0.05      # m, 손목에서 칼날 시작까지

## 실제 모델을 쓸 때는 끄세요 (뼈대 디버그 선)
@export var show_skeleton := true

@onready var visual: Node3D = $Visual
@onready var model: Node3D = $Visual/Model

var anim: AnimationPlayer
var skeleton: Skeleton3D
var hitbox: Area3D
var attack_anim: StringName
var attacking := false
var _hit_targets: Array = []
var _move_target := Vector3.ZERO
var _has_move_target := false
var _attack_target: Node3D
var _click_marker: MeshInstance3D
var _debug_mesh: ImmediateMesh


func _ready() -> void:
	_setup_input()
	skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	for n in anim.get_animation_list():
		if n != "RESET":
			attack_anim = n
	anim.get_animation(attack_anim).loop_mode = Animation.LOOP_NONE
	anim.animation_finished.connect(_on_animation_finished)
	_build_sword()
	_build_click_marker()
	if show_skeleton:
		_build_debug_skeleton()
	_to_ready_pose()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("attack") and not attacking:
		_start_attack()

	if attacking:
		var t := anim.current_animation_position
		var active := t >= HIT_START and t <= HIT_END
		if hitbox.monitoring != active:
			hitbox.set_deferred("monitoring", active)
		if t >= CANCEL_AT:
			attacking = false
			hitbox.set_deferred("monitoring", false)

	# 이동 방향: 키보드(WASD)가 우선, 없으면 클릭 이동
	var dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if dir != Vector2.ZERO:
		_clear_click_target()
	else:
		dir = _click_move_dir()

	# 공격 중에는 이동 느리게
	var speed := SPEED * (0.3 if attacking else 1.0)
	velocity.x = dir.x * speed
	velocity.z = dir.y * speed
	if dir != Vector2.ZERO and not attacking:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.y), 15.0 * delta)
	move_and_slide()


## 클릭한 위치/적을 향한 이동 방향(XZ). 도착했거나 목표가 없으면 ZERO.
func _click_move_dir() -> Vector2:
	if _attack_target:
		if not is_instance_valid(_attack_target) or _attack_target.get("hp") == 0:
			_clear_click_target()
			return Vector2.ZERO
		var to_enemy := _attack_target.global_position - global_position
		to_enemy.y = 0.0
		if to_enemy.length() <= ATTACK_RANGE:
			if not attacking:
				visual.rotation.y = atan2(-to_enemy.x, -to_enemy.z)
				_start_attack()
			return Vector2.ZERO
		return Vector2(to_enemy.x, to_enemy.z).normalized()
	if _has_move_target:
		var to_point := _move_target - global_position
		to_point.y = 0.0
		if to_point.length() <= ARRIVE_DIST:
			_clear_click_target()
			return Vector2.ZERO
		return Vector2(to_point.x, to_point.z).normalized()
	return Vector2.ZERO


func _clear_click_target() -> void:
	_has_move_target = false
	_attack_target = null
	_click_marker.visible = false


## 마우스 왼쪽 클릭 / 터치(마우스로 에뮬레이션): 땅이면 이동, 적이면 추적 공격
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(event.position)
	var to := from + cam.project_ray_normal(event.position) * 500.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 2)   # 땅(1) + 적(2)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit["collider"]
	if collider.has_method("take_damage"):
		_attack_target = collider
		_has_move_target = false
		_click_marker.visible = false
	else:
		_attack_target = null
		_move_target = hit["position"]
		_has_move_target = true
		_click_marker.global_position = _move_target + Vector3(0, 0.3, 0)
		_click_marker.visible = true


func _build_click_marker() -> void:
	_click_marker = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.25
	mesh.outer_radius = 0.4
	_click_marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	_click_marker.material_override = mat
	_click_marker.top_level = true
	_click_marker.visible = false
	add_child(_click_marker)


func _process(_delta: float) -> void:
	if _debug_mesh:
		_draw_skeleton()


func _start_attack() -> void:
	attacking = true
	_hit_targets.clear()
	anim.speed_scale = ATTACK_SPEED
	anim.stop()
	anim.play(attack_anim)
	anim.seek(ATTACK_START, true)


## 대기 자세 = 공격 애니메이션 첫 프레임(준비 자세)에서 정지
func _to_ready_pose() -> void:
	anim.speed_scale = 1.0
	anim.play(attack_anim)
	anim.seek(0.0, true)
	anim.pause()


func _on_animation_finished(_name: StringName) -> void:
	attacking = false
	hitbox.set_deferred("monitoring", false)
	_to_ready_pose.call_deferred()


func _on_hit(body: Node3D) -> void:
	if body == self or body in _hit_targets:
		return
	_hit_targets.append(body)
	if body.has_method("take_damage"):
		body.take_damage(10)
	print("Hit: ", body.name)


## 오른손 본에 칼 + 타격 판정(Hitbox) 부착. 뼈대가 스케일(MODEL_SCALE)되어 있어 크기를 보정한다.
func _build_sword() -> void:
	var hand := skeleton.find_bone("mixamorig_RightHand")
	if hand < 0:
		hand = skeleton.find_bone("mixamorig:RightHand")
	var socket := BoneAttachment3D.new()
	socket.name = "SwordSocket"
	socket.bone_name = skeleton.get_bone_name(hand)
	skeleton.add_child(socket)

	var k := 1.0 / MODEL_SCALE
	var center := (GRIP_OFFSET + SWORD_LENGTH * 0.5) * k

	var blade := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, SWORD_LENGTH, 0.015) * k
	blade.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.78, 0.85)
	mat.metallic = 0.8
	mat.roughness = 0.3
	blade.material_override = mat
	blade.position = Vector3(0, center, 0)
	socket.add_child(blade)

	hitbox = Area3D.new()
	hitbox.name = "Hitbox"
	hitbox.monitoring = false
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2   # 적은 레이어 2 에 두세요
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, SWORD_LENGTH + 0.1, 0.4) * k
	shape.shape = box
	hitbox.add_child(shape)
	hitbox.position = Vector3(0, center, 0)
	hitbox.body_entered.connect(_on_hit)
	socket.add_child(hitbox)


## 메시가 없는 FBX 를 눈으로 확인하기 위한 뼈대 선
func _build_debug_skeleton() -> void:
	_debug_mesh = ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = _debug_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.3, 0.9, 1.0)
	mi.material_override = mat
	mi.extra_cull_margin = 100.0
	skeleton.add_child(mi)


func _draw_skeleton() -> void:
	_debug_mesh.clear_surfaces()
	_debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in skeleton.get_bone_count():
		var p := skeleton.get_bone_parent(i)
		if p >= 0:
			_debug_mesh.surface_add_vertex(skeleton.get_bone_global_pose(p).origin)
			_debug_mesh.surface_add_vertex(skeleton.get_bone_global_pose(i).origin)
	_debug_mesh.surface_end()


func _setup_input() -> void:
	_bind("move_forward", KEY_W)
	_bind("move_back", KEY_S)
	_bind("move_left", KEY_A)
	_bind("move_right", KEY_D)
	_bind("attack", KEY_J)
	_bind("attack", KEY_SPACE)


func _bind(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventKey.new()
	e.physical_keycode = key
	InputMap.action_add_event(action, e)
