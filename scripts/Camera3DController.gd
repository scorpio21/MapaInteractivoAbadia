extends Camera3D

# Cámara orbital para explorar el mapa 3D
# WASD: mover, Rueda: zoom, Ratón derecho+arrastrar: rotar

@export var move_speed: float = 80.0
@export var zoom_speed: float = 5.0
@export var rotate_speed: float = 0.005
@export var min_zoom: float = 30.0
@export var max_zoom: float = 400.0

var orbit_center := Vector3(208, 0, 208)
var orbit_distance := Vector3(0, 150, 150).length()
var orbit_yaw := -0.7
var orbit_pitch := 0.6

func _ready() -> void:
	_update_transform()

func _process(delta: float) -> void:
	var move_dir := Vector3.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir -= transform.basis.z
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir += transform.basis.z
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir -= transform.basis.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir += transform.basis.x

	move_dir.y = 0
	if move_dir.length() > 0:
		orbit_center += move_dir.normalized() * move_speed * delta
		_update_transform()

func _input(event: InputEvent) -> void:
	# Zoom con rueda del ratón
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_distance = max(min_zoom, orbit_distance - zoom_speed)
			_update_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_distance = min(max_zoom, orbit_distance + zoom_speed)
			_update_transform()

	# Rotar con ratón derecho
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		orbit_yaw -= event.relative.x * rotate_speed
		orbit_pitch -= event.relative.y * rotate_speed
		orbit_pitch = clamp(orbit_pitch, 0.1, 1.5)
		_update_transform()

func _update_transform() -> void:
	var offset := Vector3(
		sin(orbit_yaw) * cos(orbit_pitch) * orbit_distance,
		sin(orbit_pitch) * orbit_distance,
		cos(orbit_yaw) * cos(orbit_pitch) * orbit_distance
	)
	position = orbit_center + offset
	look_at(orbit_center, Vector3.UP)
