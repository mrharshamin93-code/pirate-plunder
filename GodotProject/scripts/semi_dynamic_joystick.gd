extends Control

signal changed(value: Vector2)

const BASE_DIAMETER: float = 138.0
const KNOB_DIAMETER: float = 58.0
const THROW_RADIUS: float = 40.0
const DEAD_ZONE: float = 7.0
const BASE_SHIFT: float = 72.0

var home: Vector2 = Vector2.ZERO
var origin: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO
var active: bool = false
var touch_id: int = -1
var mouse_active: bool = false

func _ready() -> void:
	# Read input at viewport level so the joystick also works reliably in Godot's
	# embedded game window. The control itself must not swallow/require GUI events.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	call_deferred("_reset_home")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not active:
		call_deferred("_reset_home")

func _reset_home() -> void:
	home = Vector2(size.x * 0.5, size.y - BASE_DIAMETER * 0.5 - 8.0)
	origin = home
	knob_offset = Vector2.ZERO
	queue_redraw()

func _screen_to_local(screen_pos: Vector2) -> Vector2:
	# CanvasLayer has no transform in this scene, so this is stable for desktop
	# mouse input and mobile touch input.
	return screen_pos - global_position

func _inside_zone(screen_pos: Vector2) -> bool:
	var p: Vector2 = _screen_to_local(screen_pos)
	return p.x >= 0.0 and p.x <= size.x and p.y >= 0.0 and p.y <= size.y

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if touch_id == -1 and _inside_zone(touch.position):
				touch_id = touch.index
				_begin(_screen_to_local(touch.position))
				get_viewport().set_input_as_handled()
		elif touch.index == touch_id:
			_end()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_id:
			_apply(_screen_to_local(drag.position))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed and _inside_zone(button.position):
				mouse_active = true
				_begin(_screen_to_local(button.position))
				get_viewport().set_input_as_handled()
			elif not button.pressed and mouse_active:
				mouse_active = false
				_end()
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if mouse_active and active:
			var motion := event as InputEventMouseMotion
			_apply(_screen_to_local(motion.position))
			get_viewport().set_input_as_handled()

func _begin(local_pos: Vector2) -> void:
	active = true
	var delta: Vector2 = local_pos - home
	var dist: float = delta.length()
	if dist <= BASE_SHIFT or is_zero_approx(dist):
		origin = local_pos
	else:
		origin = home + delta.normalized() * BASE_SHIFT
	knob_offset = Vector2.ZERO
	_apply(local_pos)

func _apply(local_pos: Vector2) -> void:
	var delta: Vector2 = local_pos - origin
	var dist: float = delta.length()
	if dist < DEAD_ZONE:
		knob_offset = delta
		changed.emit(Vector2.ZERO)
	else:
		var dir: Vector2 = delta / dist
		var magnitude: float = minf(1.0, dist / THROW_RADIUS)
		knob_offset = dir * minf(dist, THROW_RADIUS)
		changed.emit(dir * magnitude)
	queue_redraw()

func _end() -> void:
	touch_id = -1
	active = false
	origin = home
	knob_offset = Vector2.ZERO
	changed.emit(Vector2.ZERO)
	queue_redraw()

func _draw() -> void:
	var magnitude: float = minf(1.0, knob_offset.length() / THROW_RADIUS)
	var base_alpha: float = 0.78 + 0.22 * magnitude if active else 0.52
	var knob_alpha: float = 0.78 + 0.22 * magnitude if active else 0.72
	var outer_r: float = BASE_DIAMETER * 0.5 - 3.0
	var inner_r: float = BASE_DIAMETER * 0.5 - 16.0
	draw_circle(origin, outer_r, Color(0.024, 0.125, 0.165, 0.42 * base_alpha / 0.52))
	draw_arc(origin, outer_r, 0.0, TAU, 64, Color(0.85, 0.96, 0.98, 0.30), 3.0, true)
	draw_arc(origin, inner_r, 0.0, TAU, 64, Color(0.85, 0.96, 0.98, 0.12), 1.5, true)
	for deg in [0.0, 90.0, 180.0, 270.0]:
		var a: float = deg_to_rad(deg)
		var tip: Vector2 = origin + Vector2(outer_r - 6.0, 0).rotated(a)
		var b1: Vector2 = origin + Vector2(outer_r - 14.0, -5.0).rotated(a)
		var b2: Vector2 = origin + Vector2(outer_r - 14.0, 5.0).rotated(a)
		draw_colored_polygon(PackedVector2Array([tip, b1, b2]), Color(0.85, 0.96, 0.98, 0.32))
	var knob_pos: Vector2 = origin + knob_offset
	var kr: float = KNOB_DIAMETER * 0.5 - 2.0
	draw_circle(knob_pos, kr, Color(0.85, 0.96, 0.98, 0.90 * knob_alpha / 0.72))
	draw_arc(knob_pos, kr, 0.0, TAU, 48, Color(0.024, 0.125, 0.165, 0.35), 2.0, true)
	draw_circle(knob_pos + Vector2(-5.0, -6.0), 7.0, Color(1.0, 1.0, 1.0, 0.85))
	draw_circle(knob_pos, 5.0, Color(0.024, 0.125, 0.165, 0.22))
