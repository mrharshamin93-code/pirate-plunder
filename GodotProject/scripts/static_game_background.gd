extends Node2D

const OUTER = Color("031a23")
const ARENA = Color("11677a")
const ARENA_LIGHT = Color("187d90")
const BORDER = Color(0.33, 0.72, 0.80, 0.62)
const WAVE = Color(0.42, 0.82, 0.90, 0.46)
const WAVE_SOFT = Color(0.30, 0.72, 0.82, 0.22)
const FLECK = Color(0.72, 0.94, 0.97, 0.52)
const FIELD_TOP: float = 108.0
const CONTROL_ZONE: float = 158.0
const SIDE: float = 10.0
const RADIUS: float = 18.0
const OCEAN_SPEED: float = 1.15

var ocean_time: float = 0.0

func _ready() -> void:
	z_index = -20
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	ocean_time += delta * OCEAN_SPEED
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

	# Noticeable moving light across the sea while preserving the original palette.
	var center: Vector2 = arena_rect.get_center() + Vector2(
		sin(ocean_time * 0.55) * 18.0,
		-20.0 + cos(ocean_time * 0.42) * 10.0
	)
	for i in range(10, 0, -1):
		var t: float = float(i) / 10.0
		var c: Color = ARENA_LIGHT
		c.a = 0.045 * (1.0 - t)
		draw_circle(center, arena_rect.size.x * 0.64 * t, c)

	# Multiple animated wave bands drift horizontally and rise/fall so the motion is obvious in play.
	var waves: Array[Vector3] = [
		Vector3(.05,.10,.18), Vector3(.34,.14,.15), Vector3(.66,.08,.18),
		Vector3(.14,.24,.20), Vector3(.53,.29,.17), Vector3(.79,.22,.15),
		Vector3(.02,.39,.17), Vector3(.31,.44,.19), Vector3(.68,.42,.20),
		Vector3(.12,.56,.22), Vector3(.47,.60,.16), Vector3(.76,.55,.18),
		Vector3(.03,.70,.20), Vector3(.36,.75,.18), Vector3(.66,.72,.22),
		Vector3(.16,.86,.18), Vector3(.51,.89,.21), Vector3(.80,.84,.16)
	]
	for i in range(waves.size()):
		var w: Vector3 = waves[i]
		var phase: float = float(i) * 0.61
		var drift_x: float = sin(ocean_time * (0.72 + float(i % 3) * 0.06) + phase) * 15.0
		var drift_y: float = cos(ocean_time * (0.54 + float(i % 2) * 0.08) + phase) * 6.0
		var x: float = arena_rect.position.x + arena_rect.size.x * w.x + drift_x
		var y: float = arena_rect.position.y + arena_rect.size.y * w.y + drift_y
		var ww: float = arena_rect.size.x * w.z
		var pts: PackedVector2Array = PackedVector2Array()
		for n in range(17):
			var u: float = float(n) / 16.0
			var wave_phase: float = ocean_time * 1.7 + phase + u * TAU * 1.25
			var vertical: float = sin(wave_phase) * 3.2 + sin(wave_phase * 0.52 + 1.1) * 1.1
			pts.append(Vector2(x + ww * u, y + vertical))
		var wave_color: Color = WAVE if i % 3 != 0 else WAVE_SOFT
		var width: float = 2.8 if i % 3 != 0 else 2.0
		draw_polyline(pts, wave_color, width, true)

	# Moving specular flecks make the water shimmer instead of looking painted-on.
	var flecks: Array[Vector2] = [
		Vector2(.12,.18),Vector2(.26,.31),Vector2(.52,.08),Vector2(.72,.19),Vector2(.88,.33),
		Vector2(.16,.52),Vector2(.42,.48),Vector2(.69,.58),Vector2(.84,.69),Vector2(.28,.77),
		Vector2(.57,.82),Vector2(.91,.88)
	]
	for i in range(flecks.size()):
		var f: Vector2 = flecks[i]
		var phase: float = float(i) * 0.93
		var base: Vector2 = arena_rect.position + Vector2(arena_rect.size.x * f.x, arena_rect.size.y * f.y)
		var drift: Vector2 = Vector2(
			sin(ocean_time * 0.95 + phase) * 9.0,
			cos(ocean_time * 0.72 + phase) * 5.0
		)
		var pulse: float = 1.6 + (sin(ocean_time * 2.2 + phase) + 1.0) * 0.8
		var p: Vector2 = base + drift
		draw_circle(p, pulse, FLECK)
		if i % 2 == 0:
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), Color(FLECK, 0.28), 1.2, true)

	draw_line(Vector2(SIDE, field_bottom), Vector2(s.x - SIDE, field_bottom), BORDER, 2.0, true)
	var control: Rect2 = Rect2(SIDE, field_bottom + 1.0, s.x - SIDE * 2.0, CONTROL_ZONE - 1.0)
	draw_rect(control, Color(0.01, 0.09, 0.12, 0.34))
