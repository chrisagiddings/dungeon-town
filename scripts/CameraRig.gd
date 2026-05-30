extends Camera2D
class_name CameraRig
## Isometric camera rig.
## Pan: WASD keys, arrow keys, middle-mouse drag, or edge-scroll.
## Zoom: scroll wheel.
## Rotate: Q/E keys snap to 4 isometric angles (0°, 90°, 180°, 270°).
## Home: Return to center position.

# ── Constants ─────────────────────────────────────────────────────────────────
const KEY_PAN_SPEED:  float = 400.0
const EDGE_PAN_SPEED: float = 300.0
const EDGE_PAN_MARGIN: int  = 20
const ZOOM_STEP:  float = 0.12
const ZOOM_MIN:   float = 0.25
const ZOOM_MAX:   float = 3.0
const ZOOM_LERP:  float = 10.0
const ROTATION_ANGLES: Array[float] = [0.0, 90.0, 180.0, 270.0]
const ROTATION_LERP: float = 8.0
const HOME_POSITION: Vector2 = Vector2.ZERO

# ── State ─────────────────────────────────────────────────────────────────────
var _target_zoom: float = 1.0
var _is_dragging: bool = false
var _rotation_index: int = 0
var _target_rotation: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	zoom = Vector2.ONE
	_target_zoom = 1.0
	_rotation_index = 0
	_target_rotation = 0.0
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_handle_edge_pan(delta)
	# Smooth zoom interpolation
	var current_z: float = zoom.x
	var new_z: float = lerp(current_z, _target_zoom, ZOOM_LERP * delta)
	zoom = Vector2(new_z, new_z)
	# Smooth rotation interpolation
	rotation_degrees = lerp(rotation_degrees, _target_rotation, ROTATION_LERP * delta)

func _unhandled_input(event: InputEvent) -> void:
	_handle_middle_mouse_drag(event)
	_handle_scroll_zoom(event)

# ── Pan ───────────────────────────────────────────────────────────────────────

func _handle_keyboard_pan(delta: float) -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * KEY_PAN_SPEED * delta / zoom.x

func _handle_edge_pan(delta: float) -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var vp_size: Vector2 = get_viewport_rect().size
	var dir: Vector2 = Vector2.ZERO
	if mouse.x < EDGE_PAN_MARGIN:
		dir.x -= 1.0
	elif mouse.x > vp_size.x - EDGE_PAN_MARGIN:
		dir.x += 1.0
	if mouse.y < EDGE_PAN_MARGIN:
		dir.y -= 1.0
	elif mouse.y > vp_size.y - EDGE_PAN_MARGIN:
		dir.y += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * EDGE_PAN_SPEED * delta / zoom.x

func _handle_middle_mouse_drag(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_is_dragging = mb.pressed
	elif event is InputEventMouseMotion and _is_dragging:
		var mm := event as InputEventMouseMotion
		position -= mm.relative / zoom.x

# ── Zoom ──────────────────────────────────────────────────────────────────────

func _handle_scroll_zoom(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_target_zoom = clamp(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_target_zoom = clamp(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)

# ── Rotation ──────────────────────────────────────────────────────────────────

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_Q:
				_rotate_view(-1)
			KEY_E:
				_rotate_view(1)
			KEY_HOME:
				_return_home()

func _rotate_view(direction: int) -> void:
	_rotation_index = wrapi(_rotation_index + direction, 0, 4)
	_target_rotation = ROTATION_ANGLES[_rotation_index]

func get_current_rotation_angle() -> float:
	return ROTATION_ANGLES[_rotation_index]

# ── Home ──────────────────────────────────────────────────────────────────────

func _return_home() -> void:
	## Smoothly return camera to center position and default zoom.
	position = HOME_POSITION
	_target_zoom = 1.0
	_rotation_index = 0
	_target_rotation = 0.0
