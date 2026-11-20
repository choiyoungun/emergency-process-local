extends Control
## 모바일 터치 컨트롤: 화면 왼쪽 = 가상 조이스틱, 오른쪽 아래 = 공격 버튼.
## 기존 입력 액션(move_*, attack)을 눌러 주므로 knight.gd 는 수정 없이 동작한다.

const STICK_RADIUS := 110.0
const ATTACK_RADIUS := 90.0

var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_pos := Vector2.ZERO
var _attack_id := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _attack_center() -> Vector2:
	return size - Vector2(150, 200)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(_attack_center()) <= ATTACK_RADIUS * 1.4 and _attack_id == -1:
				_attack_id = event.index
				Input.action_press("attack")
			elif event.position.x < size.x * 0.55 and _stick_id == -1:
				_stick_id = event.index
				_stick_origin = event.position
				_stick_pos = event.position
		else:
			if event.index == _attack_id:
				_attack_id = -1
				Input.action_release("attack")
			elif event.index == _stick_id:
				_stick_id = -1
				_set_move(Vector2.ZERO)
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _stick_id:
		_stick_pos = event.position
		var v := (_stick_pos - _stick_origin) / STICK_RADIUS
		_set_move(v.limit_length(1.0))
		queue_redraw()


func _set_move(v: Vector2) -> void:
	_press("move_left", maxf(-v.x, 0.0))
	_press("move_right", maxf(v.x, 0.0))
	_press("move_forward", maxf(-v.y, 0.0))
	_press("move_back", maxf(v.y, 0.0))


func _press(action: String, strength: float) -> void:
	if strength > 0.15:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	var c := _attack_center()
	var pressed := _attack_id != -1
	draw_circle(c, ATTACK_RADIUS, Color(1, 0.3, 0.3, 0.7 if pressed else 0.4))
	draw_arc(c, ATTACK_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.8), 3.0)
	if _stick_id != -1:
		draw_circle(_stick_origin, STICK_RADIUS, Color(1, 1, 1, 0.15))
		var knob := _stick_origin + (_stick_pos - _stick_origin).limit_length(STICK_RADIUS)
		draw_circle(knob, 45.0, Color(1, 1, 1, 0.5))
