extends Node3D
## 말하는 섬 블록아웃 맵. 코드로 지형/마을/숲/던전 입구/사냥터를 생성한다.
## 기사는 원점(마을 광장)에서 시작. 북쪽(-Z)이 던전, 동쪽이 늑대, 서쪽이 고블린 사냥터.

const ISLAND_RADIUS := 60.0
const GRASS_RADIUS := 52.0
const PLAZA_RADIUS := 8.0
const VILLAGE_RADIUS := 22.0
const TREE_COUNT := 140

## [이름, 각도(도, 0=동쪽, 시계 방향이 +), 광장 중심에서의 거리, 가로, 세로, 높이, 지붕 색]
const BUILDINGS := [
	["상점", 20.0, 15.0, 5.0, 4.0, 3.0, Color(0.75, 0.35, 0.25)],
	["여관", 70.0, 16.0, 6.0, 5.0, 3.5, Color(0.55, 0.35, 0.2)],
	["신전", 150.0, 17.0, 6.0, 7.0, 4.5, Color(0.85, 0.85, 0.9)],
	["대장간", 200.0, 15.0, 5.0, 4.0, 3.0, Color(0.3, 0.3, 0.35)],
	["길드", 250.0, 16.0, 6.0, 5.0, 3.5, Color(0.25, 0.4, 0.7)],
	["창고", 320.0, 15.0, 5.0, 4.0, 3.0, Color(0.5, 0.45, 0.3)],
]

## [이름, 위치, 마커 색]
const ZONES := [
	["말하는 섬 던전", Vector3(0, 0, -44), Color(0.6, 0.2, 0.8)],
	["늑대 사냥터", Vector3(34, 0, 0), Color(0.9, 0.5, 0.2)],
	["고블린 사냥터", Vector3(-34, 0, 4), Color(0.3, 0.8, 0.3)],
	["선착장", Vector3(0, 0, 46), Color(0.3, 0.6, 0.9)],
]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1993
	_build_terrain()
	_build_village()
	_build_zones()
	_build_forest()


func _build_terrain() -> void:
	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(600, 600)
	water.mesh = water_mesh
	water.position.y = -0.25
	water.material_override = _mat(Color(0.12, 0.35, 0.6))
	add_child(water)

	_add_disk("Sand", ISLAND_RADIUS, Color(0.85, 0.78, 0.55), 0.0, true)
	_add_disk("Grass", GRASS_RADIUS, Color(0.3, 0.55, 0.25), 0.02, false)
	_add_disk("Plaza", PLAZA_RADIUS, Color(0.6, 0.6, 0.62), 0.04, false)


## 윗면이 y=top 인 원판. solid=true 면 충돌도 만든다.
func _add_disk(disk_name: String, radius: float, color: Color, top: float, solid: bool) -> void:
	var m := MeshInstance3D.new()
	m.name = disk_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position.y = top - 0.5
	add_child(m)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = 1.0
		shape.shape = cyl
		body.add_child(shape)
		m.add_child(body)


func _build_village() -> void:
	for b in BUILDINGS:
		var ang := deg_to_rad(b[1])
		var pos: Vector3 = Vector3(cos(ang), 0, sin(ang)) * b[2]
		_add_house(b[0], pos, Vector3(b[3], b[5], b[4]), b[6])


func _add_house(house_name: String, pos: Vector3, size: Vector3, roof_color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = house_name
	body.position = pos
	body.rotation.y = atan2(-pos.x, -pos.z)   # 문(+Z 쪽)이 광장을 향하도록
	add_child(body)

	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	wall.position.y = size.y * 0.5
	wall.material_override = _mat(Color(0.8, 0.72, 0.58))
	body.add_child(wall)

	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(size.x * 1.15, size.y * 0.5, size.z * 1.15)
	roof.mesh = roof_mesh
	roof.position.y = size.y + size.y * 0.25
	roof.material_override = _mat(roof_color)
	body.add_child(roof)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y * 0.5
	body.add_child(shape)

	body.add_child(_label(house_name, Vector3(0, size.y * 1.6 + 0.5, 0)))


func _build_zones() -> void:
	for z in ZONES:
		var marker := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 3.0
		mesh.bottom_radius = 3.0
		mesh.height = 0.1
		marker.mesh = mesh
		marker.position = z[1] + Vector3(0, 0.06, 0)
		marker.material_override = _mat(z[2])
		add_child(marker)
		marker.add_child(_label(z[0], Vector3(0, 3.0, 0)))
	_build_dungeon_gate(ZONES[0][1])


func _build_dungeon_gate(pos: Vector3) -> void:
	var rock := _mat(Color(0.25, 0.25, 0.28))
	for side in [-1.0, 1.0]:
		_add_block(pos + Vector3(side * 3.0, 2.5, -3.0), Vector3(2, 5, 2), rock)
	_add_block(pos + Vector3(0, 5.5, -3.0), Vector3(8, 1.5, 2), rock)


func _add_block(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = mat
	body.add_child(m)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _build_forest() -> void:
	var trunk_mat := _mat(Color(0.4, 0.27, 0.15))
	var leaf_mat := _mat(Color(0.15, 0.4, 0.18))
	var placed := 0
	var tries := 0
	while placed < TREE_COUNT and tries < TREE_COUNT * 20:
		tries += 1
		var r := sqrt(_rng.randf()) * (GRASS_RADIUS - 3.0)
		var a := _rng.randf() * TAU
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if r < VILLAGE_RADIUS or _near_zone(p):
			continue
		_add_tree(p, _rng.randf_range(0.8, 1.4), trunk_mat, leaf_mat)
		placed += 1


func _near_zone(p: Vector3) -> bool:
	for z in ZONES:
		if p.distance_to(z[1]) < 7.0:
			return true
	return false


func _add_tree(pos: Vector3, s: float, trunk_mat: Material, leaf_mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.2 * s
	trunk_mesh.bottom_radius = 0.3 * s
	trunk_mesh.height = 2.0 * s
	trunk.mesh = trunk_mesh
	trunk.position.y = s
	trunk.material_override = trunk_mat
	body.add_child(trunk)
	var leaves := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 1.3 * s
	leaf_mesh.height = 2.6 * s
	leaves.mesh = leaf_mesh
	leaves.position.y = 2.8 * s
	leaves.material_override = leaf_mat
	body.add_child(leaves)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3 * s
	cyl.height = 2.0 * s
	shape.shape = cyl
	shape.position.y = s
	body.add_child(shape)
	add_child(body)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = 64
	l.pixel_size = 0.01
	l.outline_size = 12
	return l


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m
