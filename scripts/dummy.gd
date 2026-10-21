extends StaticBody3D
## 훈련용 허수아비. 레이어 2 에 있어서 기사의 칼 Hitbox 에 감지되고 take_damage() 를 받는다.

const MAX_HP := 100
const RESPAWN_TIME := 2.0

var hp := MAX_HP

@onready var mesh: MeshInstance3D = $Mesh
@onready var label: Label3D = $HpLabel


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	mesh.material_override = StandardMaterial3D.new()
	_refresh()


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = max(hp - amount, 0)
	_refresh()
	_flash()
	if hp == 0:
		await get_tree().create_timer(RESPAWN_TIME).timeout
		hp = MAX_HP
		_refresh()


func _refresh() -> void:
	label.text = "%d / %d" % [hp, MAX_HP]
	mesh.visible = hp > 0


func _flash() -> void:
	var mat := mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	mat.albedo_color = Color(0.8, 0.7, 0.5)
