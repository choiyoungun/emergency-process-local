extends CharacterBody3D
## 기사를 쫓아와 접촉 공격하는 간단한 적. 레이어 2 (기사 칼 Hitbox 가 감지).

signal killed

const SPEED := 2.5
const ATTACK_RANGE := 1.3
const ATTACK_DAMAGE := 8
const ATTACK_COOLDOWN := 1.0
const GRAVITY := 20.0

var hp := 20
var target: Node3D
var _cooldown := 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("enemy")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	shape.shape = cap
	shape.position.y = 1.0
	add_child(shape)
	_mesh = MeshInstance3D.new()
	_mesh.mesh = CapsuleMesh.new()
	_mesh.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.2)
	_mesh.material_override = mat
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_instance_valid(target):
		var to := target.global_position - global_position
		to.y = 0.0
		if to.length() > ATTACK_RANGE:
			var d := to.normalized()
			velocity.x = d.x * SPEED
			velocity.z = d.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			if _cooldown == 0.0 and target.has_method("take_damage"):
				_cooldown = ATTACK_COOLDOWN
				target.take_damage(ATTACK_DAMAGE)
	move_and_slide()


func take_damage(amount: int) -> void:
	hp -= amount
	var mat := _mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color.WHITE
	get_tree().create_timer(0.1).timeout.connect(func():
		if is_instance_valid(self):
			mat.albedo_color = Color(0.8, 0.2, 0.2))
	# 넉백
	if is_instance_valid(target):
		var away := global_position - target.global_position
		away.y = 0.0
		global_position += away.normalized() * 0.5
	if hp <= 0:
		killed.emit()
		queue_free()
