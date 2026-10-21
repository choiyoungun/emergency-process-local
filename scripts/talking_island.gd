extends Node3D
## 말하는 섬 블록아웃 맵 (docs/talking_island_reference.jpg 윤곽/배치 기준).
## 참고 이미지의 픽셀 좌표를 그대로 상수로 두고 PX_SCALE 로 미터 변환한다.
## 월드 원점 = 마을 광장 (기사 시작 위치). 북쪽 = -Z.

const PX_SCALE := 0.3                  # 참고 이미지 1px = 0.3m
const VILLAGE_PX := Vector2(330, 890)  # 마을 광장 위치 (이미지 좌표)
const BEACH_WIDTH := 4.0               # m
const PLAZA_RADIUS := 8.0
const VILLAGE_CLEAR := 22.0            # 이 반경 안에는 나무 없음
const TREE_COUNT := 260

## 섬 윤곽 (이미지 좌표, 시계 방향). 북쪽의 만(bay)이 안으로 파고든 모양.
const OUTLINE_PX := [
	Vector2(165, 935), Vector2(180, 885), Vector2(215, 840), Vector2(260, 820),
	Vector2(300, 805), Vector2(335, 790), Vector2(355, 780), Vector2(372, 805),
	Vector2(385, 840), Vector2(420, 848), Vector2(452, 832), Vector2(472, 852),
	Vector2(520, 870), Vector2(565, 870), Vector2(600, 880), Vector2(640, 885),
	Vector2(680, 895), Vector2(712, 915), Vector2(700, 945), Vector2(670, 960),
	Vector2(630, 975), Vector2(590, 985), Vector2(560, 990), Vector2(530, 1002),
	Vector2(500, 1030), Vector2(470, 1045), Vector2(400, 1050), Vector2(330, 1050),
	Vector2(270, 1040), Vector2(220, 1010), Vector2(180, 985), Vector2(160, 960),
]

## 북쪽 만 안쪽의 작은 섬 [중심(이미지 좌표), 반경(px)]
const ISLET_PX := [Vector2(412, 775), 22.0]

## [이름, 각도(도, 0=동쪽, 시계 방향이 +), 광장 중심에서의 거리, 가로, 세로, 높이, 지붕 색]
const BUILDINGS := [
	["상점", 20.0, 15.0, 5.0, 4.0, 3.0, Color(0.75, 0.35, 0.25)],
	["여관", 70.0, 16.0, 6.0, 5.0, 3.5, Color(0.55, 0.35, 0.2)],
	["신전", 150.0, 17.0, 6.0, 7.0, 4.5, Color(0.85, 0.85, 0.9)],
	["대장간", 200.0, 15.0, 5.0, 4.0, 3.0, Color(0.3, 0.3, 0.35)],
	["길드", 250.0, 16.0, 6.0, 5.0, 3.5, Color(0.25, 0.4, 0.7)],
	["창고", 320.0, 15.0, 5.0, 4.0, 3.0, Color(0.5, 0.45, 0.3)],
]

## [이름, 이미지 좌표, 마커 색]
const ZONES := [
	["말하는 섬 던전", Vector2(255, 828), Color(0.6, 0.2, 0.8)],
	["밭", Vector2(240, 925), Color(0.55, 0.4, 0.2)],
	["고블린 사냥터", Vector2(400, 1005), Color(0.3, 0.8, 0.3)],
	["늑대 사냥터", Vector2(620, 928), Color(0.9, 0.5, 0.2)],
	["선착장", Vector2(515, 1008), Color(0.3, 0.6, 0.9)],
]

var _rng := RandomNumberGenerator.new()
var _grass: PackedVector2Array   # 월드 좌표(x, z) 잔디 영역


func _ready() -> void:
	_rng.seed = 1993
	var sand := _to_world(OUTLINE_PX)
	var inner := Geometry2D.offset_polygon(sand, -BEACH_WIDTH)
	_grass = inner[0] if inner.size() > 0 else sand
	_build_water()
	_add_land("Sand", sand, Color(0.85, 0.78, 0.55), 0.0, true)
	_add_land("Grass", _grass, Color(0.3, 0.55, 0.25), 0.08, false)
	_build_islet()
	_add_disk("Plaza", Vector3.ZERO, PLAZA_RADIUS, Color(0.6, 0.6, 0.62), 0.14)
	_build_paths()
	_build_farm()
	_build_village()
	_build_zones()
	_build_forest()


func _px(p: Vector2) -> Vector3:
	var w := (p - VILLAGE_PX) * PX_SCALE
	return Vector3(w.x, 0, w.y)


func _to_world(px_points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in px_points:
		var w := _px(p)
		out.append(Vector2(w.x, w.z))
	return out


func _build_water() -> void:
	var water := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(800, 800)
	water.mesh = mesh
	water.position.y = -0.25
	water.material_override = _mat(Color(0.12, 0.35, 0.6))
	add_child(water)


## 다각형 땅. solid 면 충돌(양면 트라이메시)도 만든다.
func _add_land(land_name: String, poly: PackedVector2Array, color: Color, top: float, solid: bool) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(poly[i].x, top, poly[i].y))
	var m := MeshInstance3D.new()
	m.name = land_name
	m.mesh = st.commit()
	var mat := _mat(color)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	add_child(m)
	if solid:
		var shape: ConcavePolygonShape3D = m.mesh.create_trimesh_shape()
		shape.backface_collision = true
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = shape
		body.add_child(cs)
		m.add_child(body)


func _build_islet() -> void:
	var c := _px(ISLET_PX[0])
	var r: float = ISLET_PX[1] * PX_SCALE
	_add_disk("IsletSand", c, r, Color(0.85, 0.78, 0.55), 0.0, true)
	_add_disk("IsletGrass", c, r * 0.65, Color(0.3, 0.55, 0.25), 0.08)


## 윗면이 y=top 인 원판 (solid 면 충돌 포함)
func _add_disk(disk_name: String, center: Vector3, radius: float, color: Color, top: float, solid := false) -> void:
	var m := MeshInstance3D.new()
	m.name = disk_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 1.0
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position = Vector3(center.x, top - 0.5, center.z)
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


## 마을 광장에서 각 구역으로 가는 흙길
func _build_paths() -> void:
	var dirt := _mat(Color(0.6, 0.48, 0.3))
	for z in ZONES:
		var a := Vector3.ZERO
		var b := _px(z[1])
		var length := a.distance_to(b)
		if length < 1.0:
			continue
		var path := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(3.0, 0.04, length)
		path.mesh = mesh
		path.material_override = dirt
		path.position = (a + b) * 0.5 + Vector3(0, 0.2, 0)
		path.rotation.y = atan2(-(b - a).x, -(b - a).z)
		add_child(path)


## 서쪽의 갈색 밭 구획
func _build_farm() -> void:
	var soil := _mat(Color(0.4, 0.28, 0.15))
	var c := _px(ZONES[1][1])
	for ix in 2:
		for iz in 2:
			var plot := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(9, 0.04, 6)
			plot.mesh = mesh
			plot.material_override = soil
			plot.position = c + Vector3(ix * 11 - 5.5, 0.2, iz * 8 - 4)
			add_child(plot)


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
		var pos := _px(z[1])
		var marker := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 3.0
		mesh.bottom_radius = 3.0
		mesh.height = 0.1
		marker.mesh = mesh
		marker.position = pos + Vector3(0, 0.3, 0)
		marker.material_override = _mat(z[2])
		add_child(marker)
		marker.add_child(_label(z[0], Vector3(0, 3.0, 0)))
	_build_dungeon_gate(_px(ZONES[0][1]))
	_build_dock(_px(ZONES[4][1]))


func _build_dungeon_gate(pos: Vector3) -> void:
	var rock := _mat(Color(0.25, 0.25, 0.28))
	for side in [-1.0, 1.0]:
		_add_block(pos + Vector3(side * 3.0, 2.5, -3.0), Vector3(2, 5, 2), rock)
	_add_block(pos + Vector3(0, 5.5, -3.0), Vector3(8, 1.5, 2), rock)


## 선착장 부두 + 배(단순 상자)
func _build_dock(pos: Vector3) -> void:
	_add_block(pos + Vector3(0, 0.1, 6), Vector3(4, 0.2, 10), _mat(Color(0.45, 0.32, 0.2)), false)
	_add_block(pos + Vector3(0, 1.2, 14), Vector3(7, 2.4, 14), _mat(Color(0.55, 0.15, 0.12)), false)


func _add_block(pos: Vector3, size: Vector3, mat: Material, solid := true) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = mat
	body.add_child(m)
	if solid:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
	add_child(body)


## 나무는 MultiMesh(모바일 성능) + 충돌 없음. 남쪽(+Z)일수록 빽빽하게.
func _build_forest() -> void:
	var spots: Array[Vector3] = []
	var scales: Array[float] = []
	var tries := 0
	while spots.size() < TREE_COUNT and tries < TREE_COUNT * 40:
		tries += 1
		var p := Vector2(_rng.randf_range(-60, 120), _rng.randf_range(-35, 50))
		if not Geometry2D.is_point_in_polygon(p, _grass):
			continue
		var v := Vector3(p.x, 0, p.y)
		if v.length() < VILLAGE_CLEAR or _near_zone(v):
			continue
		var south_bias := clampf((p.y + 10.0) / 40.0, 0.1, 1.0)
		if _rng.randf() > south_bias:
			continue
		spots.append(v)
		scales.append(_rng.randf_range(0.8, 1.4))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.2
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 2.0
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 1.3
	leaf_mesh.height = 2.6
	_add_multimesh("Trunks", trunk_mesh, _mat(Color(0.4, 0.27, 0.15)), spots, scales, 1.0)
	_add_multimesh("Leaves", leaf_mesh, _mat(Color(0.15, 0.4, 0.18)), spots, scales, 2.8)


func _add_multimesh(mm_name: String, mesh: Mesh, mat: Material, spots: Array[Vector3], scales: Array[float], height: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = spots.size()
	for i in spots.size():
		var s := scales[i]
		var t := Transform3D(Basis.from_scale(Vector3(s, s, s)), spots[i] + Vector3(0, height * s, 0))
		mm.set_instance_transform(i, t)
	var inst := MultiMeshInstance3D.new()
	inst.name = mm_name
	inst.multimesh = mm
	inst.material_override = mat
	add_child(inst)


func _near_zone(p: Vector3) -> bool:
	for z in ZONES:
		if p.distance_to(_px(z[1])) < 7.0:
			return true
	return false


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
