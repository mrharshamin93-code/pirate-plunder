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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and touch_id == -1 and _inside_zone(touch.position):
			touch_id = touch.index
			_begin(touch.position)
		elif not touch.pressed and touch.index == touch_id:
			_end()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == touch_id:
			_apply(drag.position)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed and _inside_zone(button.position):
				_begin(button.position)
			elif not button.pressed and active:
				_end()
	elif event is InputEventMouseMotion and active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var motion := event as InputEventMouseMotion
		_apply(motion.position)

func _inside_zone(screen_pos: Vector2) -> bool:
	var local := screen_pos - global_position
	return local.x >= 0.0 and local.x <= size.x and local.y >= 0.0 and local.y <= size.y

func _begin(screen_pos: Vector2) -> void:
	active = true
	var p: Vector2 = screen_pos - global_position
	var delta: Vector2 = p - home
	if delta.length() <= BASE_SHIFT or is_zero_approx(delta.length()):
		origin = p
	else:
		origin = home + delta.normalized() * BASE_SHIFT
	knob_offset = Vector2.ZERO
	_apply(screen_pos)

func _apply(screen_pos: Vector2) -> void:
	var p: Vector2 = screen_pos - global_position
	var delta: Vector2 = p - origin
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
	var base_alpha: float = 0.78 if active else 0.52
	var knob_alpha: float = 1.0 if active else 0.72
	draw_circle(origin, BASE_DIAMETER * 0.5 - 3.0, Color(0.024, 0.125, 0.165, base_alpha))
	draw_arc(origin, BASE_DIAMETER * 0.5 - 3.0, 0.0, TAU, 48, Color(0.85, 0.96, 0.98, 0.30), 3.0)
	draw_arc(origin, BASE_DIAMETER * 0.5 - 16.0, 0.0, TAU, 48, Color(0.85, 0.96, 0.98, 0.12), 1.5)
	var knob_pos: Vector2 = origin + knob_offset
	draw_circle(knob_pos, KNOB_DIAMETER * 0.5 - 2.0, Color(0.85, 0.96, 0.98, knob_alpha))
	draw_arc(knob_pos, KNOB_DIAMETER * 0.5 - 2.0, 0.0, TAU, 36, Color(0.024, 0.125, 0.165, 0.35), 2.0)
	draw_circle(knob_pos + Vector2(-5.0, -6.0), 7.0, Color(1.0, 1.0, 1.0, 0.85))
