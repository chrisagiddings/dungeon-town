extends Camera2D
class_name CameraRig
## Isometric camera rig.
## Pan: WASD keys, arrow keys, middle-mouse drag, or edge-scroll.
## Zoom: scroll wheel.

# ── Constants ─────────────────────────────────────────────────────────────────
const KEY_PAN_SPEED:  float = 400.0
const EDGE_PAN_SPEED: float = 300.0
const EDGE_PAN_MARGIN: int  = 20
const ZOOM_STEP:  float = 0.12
const ZOOM_MIN:   float = 0.25
const ZOOM_MAX:   float = 3.0
const ZOOM_LERP:  float = 10.0

# ── State ─────────────────────────────────────────────────────────────────────
var _target_zoom: float = 1.0
var _is_dragging: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	zoom = Vector2.ONE
	_target_zoom = 1.0
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0

func _process(delta: float) -> void:
	_handle_keyboard_pan(delta)
	_handle_edge_pan(delta)
	# Smooth zoom interpolation
	var current_z: float = zoom.x
	var new_z: float = lerp(current_z, _target_zoom, ZOOM_LERP * delta)
	zoom = Vector2(new_z, new_z)

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
