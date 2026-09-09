extends Node2D

const OUTER = Color("031a23")
const ARENA = Color("11677a")
const ARENA_LIGHT = Color("187d90")
const BORDER = Color(0.33, 0.72, 0.80, 0.62)
const WAVE = Color(0.32, 0.72, 0.80, 0.24)
const FLECK = Color(0.67, 0.88, 0.92, 0.34)
const FIELD_TOP: float = 108.0
const CONTROL_ZONE: float = 158.0
const SIDE: float = 10.0
const RADIUS: float = 18.0

func _ready() -> void:
	z_index = -20
	queue_redraw()

func _draw() -> void:
	var s: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), OUTER)
	var field_bottom: float = s.y - CONTROL_ZONE
	var arena_rect: Rect2 = Rect2(SIDE, FIELD_TOP, s.x - SIDE * 2.0, field_bottom - FIELD_TOP)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = ARENA
	box.border_color = BORDER
	box.set_border_width_all(2)
	box.corner_radius_top_left = int(RADIUS)
	box.corner_radius_top_right = int(RADIUS)
	box.corner_radius_bottom_left = int(RADIUS)
	box.corner_radius_bottom_right = int(RADIUS)
	draw_style_box(box, arena_rect)

	var center: Vector2 = arena_rect.get_center() + Vector2(0.0, -20.0)
	for i in range(10, 0, -1):
		var t: float = float(i) / 10.0
		var c: Color = ARENA_LIGHT
		c.a = 0.018 * (1.0 - t)
		draw_circle(center, arena_rect.size.x * 0.62 * t, c)

	var waves: Array[Vector3] = [
		Vector3(.10,.16,.14), Vector3(.55,.10,.16), Vector3(.74,.24,.11),
		Vector3(.06,.36,.18), Vector3(.46,.48,.14), Vector3(.78,.58,.12),
		Vector3(.17,.70,.20), Vector3(.58,.82,.15), Vector3(.10,.92,.16)
	]
	for w: Vector3 in waves:
		var x: float = arena_rect.position.x + arena_rect.size.x * w.x
		var y: float = arena_rect.position.y + arena_rect.size.y * w.y
		var ww: float = arena_rect.size.x * w.z
		var pts: PackedVector2Array = PackedVector2Array()
		for n in range(13):
			var u: float = float(n) / 12.0
			pts.append(Vector2(x + ww * u, y + sin(u * TAU) * 2.1))
		draw_polyline(pts, WAVE, 2.5, true)

	var flecks: Array[Vector2] = [Vector2(.22,.22),Vector2(.52,.05),Vector2(.88,.32),Vector2(.16,.62),Vector2(.72,.73),Vector2(.91,.84)]
	for f: Vector2 in flecks:
		draw_circle(arena_rect.position + Vector2(arena_rect.size.x * f.x, arena_rect.size.y * f.y), 2.2, FLECK)

	draw_line(Vector2(SIDE, field_bottom), Vector2(s.x - SIDE, field_bottom), BORDER, 2.0, true)
	var control: Rect2 = Rect2(SIDE, field_bottom + 1.0, s.x - SIDE * 2.0, CONTROL_ZONE - 1.0)
	draw_rect(control, Color(0.01, 0.09, 0.12, 0.34))
