extends Camera3D
## 리니지식 쿼터뷰 카메라: 대상을 고정된 각도/거리로 부드럽게 따라간다.

@export var target_path: NodePath = ^"../Knight"
@export var offset := Vector3(0, 13, 9)   # 대상 기준 카메라 위치 (뒤쪽 위)
@export var follow_speed := 8.0

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path)
	fov = 35.0
	far = 500.0
	if _target:
		global_position = _target.global_position + offset
		look_at(_target.global_position, Vector3.UP)


func _process(delta: float) -> void:
	if not _target:
		return
	var want := _target.global_position + offset
	global_position = global_position.lerp(want, clampf(follow_speed * delta, 0.0, 1.0))
	# 각도는 고정 (대상 방향으로 한 번 정한 회전을 유지)
	rotation = Basis.looking_at(-offset, Vector3.UP).get_euler()
