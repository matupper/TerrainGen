extends Camera3D

@export var move_speed: float = 20.0
@export var fast_multiplier: float = 3.0
@export var mouse_sensitivity: float = 0.002

var _rotation_x := 0.0
var _rotation_y := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_rotation_y = rotation.y
	_rotation_x = rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_rotation_y -= event.relative.x * mouse_sensitivity
		_rotation_x -= event.relative.y * mouse_sensitivity
		_rotation_x = clamp(_rotation_x, deg_to_rad(-89), deg_to_rad(89))
		rotation = Vector3(_rotation_x, _rotation_y, 0.0)

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	var dir := Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		dir += transform.basis.x
	if Input.is_action_pressed("move_down"):
		dir -= transform.basis.y
	if Input.is_action_pressed("move_up"):
		dir += transform.basis.y

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var speed := move_speed
	if Input.is_action_pressed("move_fast"):
		speed *= fast_multiplier

	position += dir * speed * delta
