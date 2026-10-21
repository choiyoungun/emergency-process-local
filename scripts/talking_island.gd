extends Node3D
## 말하는 섬 블록아웃 맵 (docs/talking_island_reference.jpg 윤곽/배치 기준).
## 참고 이미지의 픽셀 좌표를 그대로 상수로 두고 PX_SCALE 로 미터 변환한다.
## 월드 원점 = 마을 광장 (기사 시작 위치). 북쪽 = -Z.

const PX_SCALE := 0.1                  # 참고 지도 1px = 0.1m (섬 가로 약 175m)
const VILLAGE_PX := Vector2(935, 375)  # 마을 광장 위치 (참고 지도 좌표, 2000x1022)
const BEACH_WIDTH := 3.0               # m
const PLAZA_RADIUS := 8.0
const VILLAGE_CLEAR := 20.0            # 이 반경 안에는 나무 없음
const TREE_COUNT := 450
const SHOW_REGIONS := true             # 속성별 사냥터 색 구역 표시

## 섬 윤곽 (참고 지도 좌표, 시계 방향). 북쪽에 만(bay)이 있고 북서 갈고리 모양 반도가 감싼다.
const OUTLINE_PX := [
	Vector2(325, 240), Vector2(400, 225), Vector2(470, 235), Vector2(545, 195),
	Vector2(580, 130), Vector2(640, 100), Vector2(730, 85), Vector2(800, 95),
	Vector2(880, 70), Vector2(940, 55), Vector2(1010, 55), Vector2(1070, 70),
	Vector2(1115, 105), Vector2(1120, 150), Vector2(1085, 180), Vector2(1020, 188),
	Vector2(950, 190), Vector2(895, 185), Vector2(860, 200), Vector2(850, 240),
	Vector2(865, 285), Vector2(920, 300), Vector2(990, 300), Vector2(1050, 290),
	Vector2(1110, 270), Vector2(1170, 262), Vector2(1215, 290), Vector2(1240, 335),
	Vector2(1235, 385), Vector2(1290, 395), Vector2(1330, 375), Vector2(1390, 375),
	Vector2(1450, 365), Vector2(1520, 355), Vector2(1600, 345), Vector2(1700, 335),
	Vector2(1800, 335), Vector2(1890, 355), Vector2(1950, 410), Vector2(1980, 470),
	Vector2(1965, 540), Vector2(1900, 620), Vector2(1820, 690), Vector2(1720, 740),
	Vector2(1620, 775), Vector2(1540, 790), Vector2(1480, 815), Vector2(1430, 870),
	Vector2(1380, 915), Vector2(1250, 905), Vector2(1170, 885), Vector2(1090, 915),
	Vector2(1000, 928), Vector2(900, 930), Vector2(800, 935), Vector2(700, 935),
	Vector2(600, 925), Vector2(520, 905), Vector2(440, 860), Vector2(380, 810),
	Vector2(350, 740), Vector2(300, 660), Vector2(250, 590), Vector2(228, 530),
	Vector2(228, 470), Vector2(240, 420), Vector2(265, 375), Vector2(290, 345),
	Vector2(325, 300),
]

## 마을 광장 둘레 건물. [이름, 각도(도, 0=동쪽, 시계 방향이 +), 광장에서 거리, 가로, 세로, 높이, 지붕 색]
const BUILDINGS := [
	["상점", 20.0, 15.0, 5.0, 4.0, 3.0, Color(0.75, 0.35, 0.25)],
	["여관", 70.0, 16.0, 6.0, 5.0, 3.5, Color(0.55, 0.35, 0.2)],
	["신전", 150.0, 17.0, 6.0, 7.0, 4.5, Color(0.85, 0.85, 0.9)],
	["대장간", 200.0, 15.0, 5.0, 4.0, 3.0, Color(0.3, 0.3, 0.35)],
	["길드", 250.0, 16.0, 6.0, 5.0, 3.5, Color(0.25, 0.4, 0.7)],
	["창고", 320.0, 15.0, 5.0, 4.0, 3.0, Color(0.5, 0.45, 0.3)],
]

## 지도의 번호 지점. [번호+이름, 지도 좌표, 마커 색, 길을 낼지]
const POIS := [
	["01.거미숲", Vector2(910, 665), Color(0.7, 0.8, 0.2), true],
	["02.검은 기사단 선착장", Vector2(1233, 860), Color(0.3, 0.6, 0.9), true],
	["03.검은 기사단 야영지", Vector2(1840, 460), Color(0.7, 0.7, 0.7), true],
	["04.골렘의 집", Vector2(1255, 577), Color(0.9, 0.5, 0.2), true],
	["05.군터의 집", Vector2(538, 355), Color(0.3, 0.8, 0.5), true],
	["06.난쟁이 부락(동)", Vector2(1421, 388), Color(0.9, 0.5, 0.2), true],
	["07.난쟁이 부락(서)", Vector2(660, 448), Color(0.9, 0.5, 0.2), true],
	["08.말하는 섬 던전", Vector2(418, 373), Color(0.6, 0.2, 0.8), true],
	["10.버려진 마을", Vector2(663, 614), Color(0.6, 0.5, 0.4), true],
	["11.복섬", Vector2(980, 100), Color(0.9, 0.5, 0.2), false],
	["12.오크망루", Vector2(423, 563), Color(0.3, 0.3, 0.9), true],
	["13.오크부락", Vector2(424, 303), Color(0.3, 0.3, 0.9), true],
]
const DUNGEON_INDEX := 7
const DOCK_INDEX := 1

## 속성별 사냥터. [이름/몬스터, 색, 지도 좌표 다각형]
## 빨강=불 취약, 파랑=물 취약, 노랑=땅 취약, 회색=흑기사단
const RED := Color(0.85, 0.3, 0.3, 0.38)
const BLUE := Color(0.35, 0.3, 0.9, 0.38)
const YELLOW := Color(0.8, 0.8, 0.2, 0.45)
const GRAY := Color(0.8, 0.8, 0.8, 0.30)
const REGIONS := [
	["늑대인간\n라이칸스로프, 골렘", RED, [Vector2(560, 200), Vector2(620, 110), Vector2(700, 95), Vector2(780, 100), Vector2(840, 140), Vector2(850, 230), Vector2(790, 255), Vector2(700, 255), Vector2(620, 245), Vector2(560, 215)]],
	["복섬", RED, [Vector2(830, 110), Vector2(900, 70), Vector2(980, 65), Vector2(1060, 75), Vector2(1100, 110), Vector2(1090, 170), Vector2(1020, 185), Vector2(930, 185), Vector2(870, 170), Vector2(830, 150)]],
	["오크부락\n오크 계열", BLUE, [Vector2(325, 240), Vector2(400, 228), Vector2(470, 235), Vector2(545, 300), Vector2(500, 330), Vector2(430, 320), Vector2(350, 320), Vector2(325, 290)]],
	["던전 앞 오크\n오크, 창병, 궁수, 마법사, 좀비, 전사", BLUE, [Vector2(270, 375), Vector2(300, 340), Vector2(430, 350), Vector2(560, 345), Vector2(720, 310), Vector2(700, 350), Vector2(600, 400), Vector2(480, 480), Vector2(272, 505)]],
	["난쟁이(서)\n드워프 창병, 검사, 궁수, 주술사", RED, [Vector2(470, 485), Vector2(600, 420), Vector2(690, 330), Vector2(780, 330), Vector2(840, 420), Vector2(870, 490), Vector2(830, 560), Vector2(740, 600), Vector2(640, 590), Vector2(560, 560), Vector2(480, 500)]],
	["오크망루\n괴물 눈, 골렘, 오크 전 계열", BLUE, [Vector2(235, 520), Vector2(470, 490), Vector2(615, 540), Vector2(600, 590), Vector2(520, 660), Vector2(480, 730), Vector2(400, 725), Vector2(330, 650), Vector2(255, 570)]],
	["셀로브, 웅골리언트", RED, [Vector2(850, 470), Vector2(920, 445), Vector2(1030, 455), Vector2(1130, 510), Vector2(1185, 555), Vector2(1160, 595), Vector2(1070, 610), Vector2(960, 600), Vector2(850, 600), Vector2(745, 600), Vector2(780, 540)]],
	["거미숲\n떠도는 유령, 원한의 망령", YELLOW, [Vector2(785, 640), Vector2(830, 605), Vector2(1000, 600), Vector2(1145, 605), Vector2(1145, 660), Vector2(1060, 680), Vector2(940, 690), Vector2(830, 685), Vector2(790, 665)]],
	["셀로브, 웅골리언트\n흑기사 정찰병", RED, [Vector2(800, 695), Vector2(1100, 680), Vector2(1160, 625), Vector2(1270, 640), Vector2(1290, 700), Vector2(1260, 760), Vector2(1190, 830), Vector2(1160, 870), Vector2(1075, 915), Vector2(1070, 790), Vector2(1000, 770), Vector2(920, 745), Vector2(800, 720)]],
	["남서 오크\n오크, 창병, 궁수, 마법사, 좀비", BLUE, [Vector2(365, 800), Vector2(480, 730), Vector2(600, 715), Vector2(785, 720), Vector2(790, 925), Vector2(520, 905), Vector2(440, 860), Vector2(380, 820)]],
	["남쪽 오크\n변종 셀로브, 웅골리언트, 오크 전 계열", BLUE, [Vector2(795, 725), Vector2(1000, 780), Vector2(1070, 800), Vector2(1075, 915), Vector2(930, 930), Vector2(800, 930), Vector2(760, 800)]],
	["난쟁이(동)\n드워프 창병, 검사, 궁수, 주술사", RED, [Vector2(1195, 420), Vector2(1330, 395), Vector2(1430, 385), Vector2(1520, 360), Vector2(1610, 355), Vector2(1600, 430), Vector2(1520, 500), Vector2(1420, 580), Vector2(1300, 570), Vector2(1195, 460)]],
	["검은 기사단 야영지\n장로, 흑기사, 다이어울프", GRAY, [Vector2(1660, 385), Vector2(1820, 380), Vector2(1960, 420), Vector2(1980, 480), Vector2(1930, 560), Vector2(1800, 650), Vector2(1700, 730), Vector2(1560, 780), Vector2(1440, 740), Vector2(1400, 640), Vector2(1500, 580), Vector2(1640, 500), Vector2(1670, 430)]],
	["선착장", GRAY, [Vector2(1170, 700), Vector2(1300, 700), Vector2(1420, 740), Vector2(1400, 830), Vector2(1330, 880), Vector2(1230, 880), Vector2(1170, 860)]],
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
	_add_disk("Plaza", Vector3.ZERO, PLAZA_RADIUS, Color(0.6, 0.6, 0.62), 0.14)
	if SHOW_REGIONS:
		_build_regions(sand)
	_build_paths()
	_build_village()
	_build_pois()
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
	for z in POIS:
		if not z[3]:
			continue
		var a := Vector3.ZERO
		var b := _px(z[1])
		var length := a.distance_to(b)
		if length < 1.0:
			continue
		var path := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(1.6, 0.04, length)
		path.mesh = mesh
		path.material_override = dirt
		path.position = (a + b) * 0.5 + Vector3(0, 0.24, 0)
		path.rotation.y = atan2(-(b - a).x, -(b - a).z)
		add_child(path)




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




## 속성별 사냥터를 반투명 색으로 덮고 이름/몬스터를 라벨로 표시 (섬 밖은 잘라냄)
func _build_regions(land: PackedVector2Array) -> void:
	for r in REGIONS:
		var poly := _to_world(r[2])
		var clipped := Geometry2D.intersect_polygons(poly, land)
		for part in clipped:
			var idx := Geometry2D.triangulate_polygon(part)
			if idx.is_empty():
				continue
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in idx:
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(part[i].x, 0.16, part[i].y))
			var m := MeshInstance3D.new()
			m.mesh = st.commit()
			var mat := _mat(r[1])
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.material_override = mat
			add_child(m)
		var c := Vector2.ZERO
		for p in poly:
			c += p
		c /= poly.size()
		var l := _label(r[0], Vector3(c.x, 2.5, c.y))
		l.font_size = 40
		add_child(l)


func _build_pois() -> void:
	for z in POIS:
		var pos := _px(z[1])
		var marker := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 2.0
		mesh.bottom_radius = 2.0
		mesh.height = 0.1
		marker.mesh = mesh
		marker.position = pos + Vector3(0, 0.34, 0)
		marker.material_override = _mat(z[2])
		add_child(marker)
		marker.add_child(_label(z[0], Vector3(0, 4.0, 0)))
	_build_dungeon_gate(_px(POIS[DUNGEON_INDEX][1]))
	_build_dock(_px(POIS[DOCK_INDEX][1]))


func _build_dungeon_gate(pos: Vector3) -> void:
	var rock := _mat(Color(0.25, 0.25, 0.28))
	for side in [-1.0, 1.0]:
		_add_block(pos + Vector3(side * 3.0, 2.5, -3.0), Vector3(2, 5, 2), rock)
	_add_block(pos + Vector3(0, 5.5, -3.0), Vector3(8, 1.5, 2), rock)


## 선착장 부두 + 배(단순 상자). 부두는 남쪽 바다로 뻗고 배는 그 옆에 정박
func _build_dock(pos: Vector3) -> void:
	_add_block(pos + Vector3(0, 0.1, 8), Vector3(3, 0.2, 10), _mat(Color(0.45, 0.32, 0.2)), false)
	_add_block(pos + Vector3(7, 1.5, 15), Vector3(6, 3.0, 14), _mat(Color(0.55, 0.15, 0.12)), false)


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


## 나무는 MultiMesh(모바일 성능) + 충돌 없음.
func _build_forest() -> void:
	var spots: Array[Vector3] = []
	var scales: Array[float] = []
	var tries := 0
	while spots.size() < TREE_COUNT and tries < TREE_COUNT * 40:
		tries += 1
		var p := Vector2(_rng.randf_range(-75, 105), _rng.randf_range(-33, 56))
		if not Geometry2D.is_point_in_polygon(p, _grass):
			continue
		var v := Vector3(p.x, 0, p.y)
		if v.length() < VILLAGE_CLEAR or _near_zone(v):
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
	for z in POIS:
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
