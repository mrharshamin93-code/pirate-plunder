extends Node2D

# Moonlit-night ocean treatment. Gameplay geometry is unchanged; this only
# replaces the daytime teal background with a deeper, luminous night sea.
const OUTER: Color = Color("020b18")
const ARENA: Color = Color("063653")
const ARENA_MID: Color = Color("075071")
const ARENA_LIGHT: Color = Color("087b9a")
const BORDER: Color = Color(0.20, 0.70, 0.86, 0.68)
const WAVE: Color = Color(0.23, 0.82, 0.96, 0.30)
const MOON_WAVE: Color = Color(0.62, 0.93, 1.0, 0.42)
const FLECK: Color = Color(0.65, 0.94, 1.0, 0.48)
const STAR: Color = Color(0.78, 0.92, 1.0, 0.55)
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

	# Layered blue glow gives the water the moonlit depth from concept 4.
	var glow_center: Vector2 = arena_rect.position + Vector2(arena_rect.size.x * 0.68, arena_rect.size.y * 0.32)
	for i in range(12, 0, -1):
		var t: float = float(i) / 12.0
		var glow: Color = ARENA_LIGHT
		glow.a = 0.055 * (1.0 - t)
		draw_circle(glow_center, arena_rect.size.x * 0.78 * t, glow)

	var lower_glow: Vector2 = arena_rect.position + Vector2(arena_rect.size.x * 0.42, arena_rect.size.y * 0.76)
	for i in range(8, 0, -1):
		var t: float = float(i) / 8.0
		var c: Color = ARENA_MID
		c.a = 0.045 * (1.0 - t)
		draw_circle(lower_glow, arena_rect.size.x * 0.54 * t, c)

	# Sparse moon glints/highlights on the playable water.
	var glints: Array[Vector3] = [
		Vector3(.08,.10,.18), Vector3(.48,.08,.13), Vector3(.70,.17,.20),
		Vector3(.19,.28,.12), Vector3(.56,.35,.22), Vector3(.82,.43,.13),
		Vector3(.05,.53,.16), Vector3(.38,.60,.18), Vector3(.69,.67,.21),
		Vector3(.16,.77,.14), Vector3(.50,.84,.20), Vector3(.78,.91,.16)
	]
	for w: Vector3 in glints:
		var x: float = arena_rect.position.x + arena_rect.size.x * w.x
		var y: float = arena_rect.position.y + arena_rect.size.y * w.y
		var ww: float = arena_rect.size.x * w.z
		var pts: PackedVector2Array = PackedVector2Array()
		for n in range(15):
			var u: float = float(n) / 14.0
			pts.append(Vector2(x + ww * u, y + sin(u * TAU * 1.5) * 1.8))
		draw_polyline(pts, WAVE, 2.0, true)

	# Brighter broken reflection beneath the implied moon direction.
	for j in range(7):
		var yy: float = arena_rect.position.y + arena_rect.size.y * (0.16 + float(j) * 0.095)
		var half_width: float = 10.0 + float(j) * 4.2
		var cx: float = arena_rect.position.x + arena_rect.size.x * 0.72
		draw_line(Vector2(cx - half_width, yy), Vector2(cx + half_width, yy), MOON_WAVE, 1.6, true)

	var flecks: Array[Vector2] = [
		Vector2(.12,.18), Vector2(.30,.09), Vector2(.51,.22), Vector2(.88,.27),
		Vector2(.21,.43), Vector2(.74,.51), Vector2(.09,.69), Vector2(.43,.73),
		Vector2(.91,.78), Vector2(.61,.93)
	]
	for f: Vector2 in flecks:
		var p: Vector2 = arena_rect.position + Vector2(arena_rect.size.x * f.x, arena_rect.size.y * f.y)
		draw_circle(p, 1.8, FLECK)
		draw_circle(p, 3.5, Color(FLECK, 0.08))

	# Tiny cool highlights around the upper water help sell the night atmosphere
	# without adding obstacles or changing gameplay readability.
	var stars: Array[Vector2] = [Vector2(.06,.04),Vector2(.24,.06),Vector2(.41,.035),Vector2(.58,.07),Vector2(.79,.045),Vector2(.94,.08)]
	for f: Vector2 in stars:
		var p: Vector2 = arena_rect.position + Vector2(arena_rect.size.x * f.x, arena_rect.size.y * f.y)
		draw_circle(p, 1.1, STAR)

	draw_line(Vector2(SIDE, field_bottom), Vector2(s.x - SIDE, field_bottom), BORDER, 2.0, true)
	var control: Rect2 = Rect2(SIDE, field_bottom + 1.0, s.x - SIDE * 2.0, CONTROL_ZONE - 1.0)
	draw_rect(control, Color(0.005, 0.025, 0.075, 0.62))
