extends Node3D
## 생존 모드: 적이 계속 몰려오고 기사 HP 가 0 이 되면 게임 오버 (터치하면 재시작).

const SPAWN_RADIUS := 8.0
const ARENA_HALF := 9.0
const MAX_ENEMIES := 12

var score := 0
var elapsed := 0.0
var spawn_timer := 0.0
var over := false

@onready var knight: CharacterBody3D = $Knight
@onready var camera: Camera3D = $Camera3D

var hud: Label
var over_label: Label


func _ready() -> void:
	# 세로 화면: 가로 기준 시야 + 위에서 내려다보는 카메라
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.look_at_from_position(Vector3(0, 15, 9), Vector3(0, 0, 1.5))
	knight.hp_changed.connect(func(_h): _update_hud())
	knight.died.connect(_on_died)

	var layer := CanvasLayer.new()
	add_child(layer)
	var touch := Control.new()
	touch.set_script(load("res://scripts/touch_controls.gd"))
	layer.add_child(touch)
	hud = Label.new()
	hud.position = Vector2(24, 24)
	hud.add_theme_font_size_override("font_size", 42)
	layer.add_child(hud)
	over_label = Label.new()
	over_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	over_label.add_theme_font_size_override("font_size", 64)
	over_label.visible = false
	layer.add_child(over_label)
	_update_hud()


func _process(delta: float) -> void:
	if over:
		return
	elapsed += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0 and get_tree().get_nodes_in_group("enemy").size() < MAX_ENEMIES:
		_spawn_enemy()
		# 시간이 지날수록 더 자주 등장
		spawn_timer = maxf(2.0 - elapsed * 0.02, 0.5)


func _spawn_enemy() -> void:
	var e := CharacterBody3D.new()
	e.set_script(load("res://scripts/enemy.gd"))
	var a := randf() * TAU
	var p := knight.global_position + Vector3(cos(a), 0, sin(a)) * SPAWN_RADIUS
	p.x = clampf(p.x, -ARENA_HALF, ARENA_HALF)
	p.z = clampf(p.z, -ARENA_HALF, ARENA_HALF)
	e.position = p
	e.target = knight
	e.killed.connect(_on_enemy_killed)
	add_child(e)


func _on_enemy_killed() -> void:
	score += 1
	_update_hud()


func _on_died() -> void:
	over = true
	over_label.text = "GAME OVER\n처치 %d\n화면을 터치해 재시작" % score
	over_label.visible = true


func _input(event: InputEvent) -> void:
	if over and (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey) and event.is_pressed():
		get_tree().reload_current_scene()


func _update_hud() -> void:
	hud.text = "HP %d   처치 %d" % [knight.hp, score]
