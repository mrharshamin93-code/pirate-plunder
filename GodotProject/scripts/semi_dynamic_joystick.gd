extends Control
class_name SemiDynamicJoystick

signal changed(value: Vector2)

const BASE_DIAMETER := 138.0
const KNOB_DIAMETER := 58.0
const THROW_RADIUS := 40.0
const DEAD_ZONE := 7.0
const BASE_SHIFT := 72.0

var home := Vector2.ZERO
var origin := Vector2.ZERO
var knob_offset := Vector2.ZERO
var active := false
var touch_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	call_deferred("_reset_home")

func _reset_home() -> void:
	home = Vector2(size.x * 0.5, size.y - BASE_DIAMETER * 0.5 - 8.0)
	origin = home
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not active:
		_reset_home()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and _inside_zone(event.position):
			touch_id = event.index
			_begin(event.position)
		elif not event.pressed and event.index == touch_id:
			_end()
	elif event is InputEventScreenDrag and event.index == touch_id:
		_apply(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _inside_zone(event.position):
			_begin(event.position)
		elif not event.pressed and active:
			_end()
	elif event is InputEventMouseMotion and active and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_apply(event.position)

func _inside_zone(p: Vector2) -> bool:
	return p.y >= global_position.y and p.y <= global_position.y + size.y

func _begin(screen_pos: Vector2) -> void:
	active = true
	var p := screen_pos - global_position
	var delta := p - home
	if delta.length() <= BASE_SHIFT or delta.length() == 0.0:
		origin = p
	else:
		origin = home + delta.normalized() * BASE_SHIFT
	knob_offset = Vector2.ZERO
	_apply(screen_pos)

func _apply(screen_pos: Vector2) -> void:
	var p := screen_pos - global_position
	var delta := p - origin
	var dist := delta.length()
	if dist < DEAD_ZONE:
		knob_offset = delta
		changed.emit(Vector2.ZERO)
	else:
		var dir := delta / dist
		var magnitude := minf(1.0, dist / THROW_RADIUS)
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
	var base_alpha := 0.78 if active else 0.52
	var knob_alpha := 1.0 if active else 0.72
	draw_circle(origin, BASE_DIAMETER * 0.5 - 3.0, Color(0.024, 0.125, 0.165, base_alpha))
	draw_arc(origin, BASE_DIAMETER * 0.5 - 3.0, 0.0, TAU, 48, Color(0.85, 0.96, 0.98, 0.30), 3.0)
	draw_arc(origin, BASE_DIAMETER * 0.5 - 16.0, 0.0, TAU, 48, Color(0.85, 0.96, 0.98, 0.12), 1.5)
	var knob_pos := origin + knob_offset
	draw_circle(knob_pos, KNOB_DIAMETER * 0.5 - 2.0, Color(0.85, 0.96, 0.98, knob_alpha))
	draw_arc(knob_pos, KNOB_DIAMETER * 0.5 - 2.0, 0.0, TAU, 36, Color(0.024, 0.125, 0.165, 0.35), 2.0)
	draw_circle(knob_pos + Vector2(-5, -6), 7.0, Color(1, 1, 1, 0.85))
