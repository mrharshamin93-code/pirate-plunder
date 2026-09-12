extends "res://scripts/current_game_visuals.gd"

# Cached mine art keeps mine rendering cheap on mobile.
var mine_texture: Texture2D

func _ready() -> void:
	super._ready()
	mine_texture = load("res://assets/mine-sprite.svg") as Texture2D

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	if mine_texture != null:
		var draw_size: Vector2 = Vector2(36.0, 36.0)
		draw_texture_rect(mine_texture, Rect2(p - draw_size * 0.5, draw_size), false)
	else:
		super._draw_mine(m)

func _draw_whirlpool(w: Dictionary) -> void:
	var p: Vector2 = w.get("pos", Vector2.ZERO)
	var spin: float = float(w.get("spin", 0.0))
	var pulse: float = 1.0 + sin(spin * 1.7) * 0.035
	draw_circle(p, 50.0 * pulse, Color(0.04, 0.31, 0.37, 0.22))
	draw_circle(p, 38.0 * pulse, Color(0.025, 0.23, 0.29, 0.34))
	draw_circle(p, 27.0 * pulse, Color(0.018, 0.15, 0.20, 0.52))
	draw_circle(p, 17.0 * pulse, Color(0.008, 0.075, 0.105, 0.76))
	draw_circle(p, 8.0, Color(0.0, 0.012, 0.02, 0.98))

	for arm in range(6):
		var pts := PackedVector2Array()
		for step in range(20):
			var t: float = float(step) / 19.0
			var radius: float = lerpf(51.0, 7.0, t)
			var angle: float = spin * 0.9 + float(arm) * TAU / 6.0 + t * 5.7
			pts.append(p + Vector2(cos(angle), sin(angle)) * radius)
		var arm_alpha: float = 0.23 + float(arm % 2) * 0.08
		draw_polyline(pts, Color(0.78, 0.95, 0.98, arm_alpha), 1.9 + float(arm % 2) * 0.45, true)

	for band in range(3):
		var radius: float = 29.0 + float(band) * 9.0
		for seg in range(5):
			var a0: float = spin * 0.48 + float(seg) * TAU / 5.0 + float(band) * 0.31
			var pts := PackedVector2Array()
			for k in range(5):
				var a: float = a0 + float(k) / 4.0 * 0.56
				var wobble: float = sin(a * 5.0 + spin) * 1.1
				pts.append(p + Vector2(cos(a), sin(a)) * (radius + wobble))
			draw_polyline(pts, Color(0.90, 0.985, 1.0, 0.23 - float(band) * 0.035), 1.35, true)

	for i in range(6):
		var a: float = spin * 0.7 + float(i) / 6.0 * TAU
		var r: float = 40.0 + sin(float(i) * 1.65 + spin) * 6.0
		var bubble: Vector2 = p + Vector2(cos(a), sin(a)) * r
		draw_circle(bubble, 1.1 + float(i % 3) * 0.42, Color(0.87, 0.98, 1.0, 0.40))

	draw_arc(p, 20.0, spin * 0.2, spin * 0.2 + 4.7, 22, Color(0.43, 0.82, 0.88, 0.27), 1.5, true)
	draw_arc(p, 11.0, -spin * 0.18, -spin * 0.18 + 4.9, 18, Color(0.72, 0.94, 0.97, 0.23), 1.1, true)

# Rich gold spark burst for coin pickups. Dense layered sparks, no rings or halo.
func _draw_pickup_burst(burst: Dictionary) -> void:
	var life: float = float(burst.get("life", 0.0))
	var progress: float = 1.0 - clampf(life / PICKUP_BURST_LIFE, 0.0, 1.0)
	var fade: float = pow(1.0 - progress, 1.18)
	var p: Vector2 = burst.get("pos", Vector2.ZERO)
	var tier: int = clampi(int(burst.get("tier", 0)), 0, 6)
	var strength: float = 1.0 + float(tier) * 0.065

	# Bright multi-length impact rays give a richer initial hit without a circular flash.
	var flash: float = clampf(1.0 - progress / 0.28, 0.0, 1.0)
	if flash > 0.0:
		for ray in range(12):
			var a: float = float(ray) / 12.0 * TAU + 0.10 + float(ray % 3) * 0.018
			var inner: float = 2.5 + progress * 6.0
			var outer: float = (18.0 + float(ray % 3) * 7.0) * strength * (1.0 + progress * 0.75)
			var dir := Vector2(cos(a), sin(a))
			var ray_color := Color(1.0, 0.80 + float(ray % 2) * 0.12, 0.16, 0.96 * flash)
			draw_line(p + dir * inner, p + dir * outer, ray_color, 1.35 + float(ray % 2) * 0.55, true)

	# Dense primary burst: amber cores, pale-gold glints and short streak tails.
	var particle_count: int = 18 + tier * 2
	for i in range(particle_count):
		var a: float = float(i) / float(particle_count) * TAU + float(i % 5) * 0.055 + float(tier) * 0.025
		var speed: float = 0.72 + float(i % 5) * 0.085
		var dist: float = lerpf(4.0, 48.0 * strength * speed, progress)
		var dir := Vector2(cos(a), sin(a))
		var pos: Vector2 = p + dir * dist
		var alpha: float = fade * (0.80 + float(i % 4) * 0.05)
		var radius: float = maxf(0.55, (2.45 - progress * 1.55) * (0.82 + float(i % 3) * 0.13))
		draw_circle(pos, radius, Color(1.0, 0.64 + float(i % 3) * 0.07, 0.025, alpha))
		if i % 2 == 0:
			var tail_len: float = (4.0 + float(i % 4) * 1.8) * fade
			draw_line(pos - dir * tail_len, pos, Color(1.0, 0.78, 0.12, alpha * 0.62), 1.05, true)
		if i % 4 == 0:
			_draw_star(pos, (3.1 + float(i % 3) * 0.65) * fade + 0.45, Color(1.0, 0.97, 0.68, 1.0), alpha)

	# Secondary inner sparks move on a slightly delayed curve to make the burst feel layered.
	var secondary_progress: float = clampf((progress - 0.08) / 0.92, 0.0, 1.0)
	var secondary_fade: float = pow(1.0 - secondary_progress, 1.35)
	for i in range(8):
		var a: float = float(i) / 8.0 * TAU + 0.36
		var dist: float = lerpf(3.0, (24.0 + float(i % 3) * 5.0) * strength, secondary_progress)
		var pos := p + Vector2(cos(a), sin(a)) * dist
		var alpha: float = secondary_fade * 0.88
		draw_circle(pos, 1.4 * secondary_fade + 0.45, Color(1.0, 0.91, 0.36, alpha))
		if i % 2 == 0:
			_draw_star(pos, 2.8 * secondary_fade + 0.5, Color(1.0, 1.0, 0.80, 1.0), alpha)

	# A handful of delayed premium glints keep the tail sparkling rather than fading flat.
	for i in range(6):
		var a: float = float(i) / 6.0 * TAU + 0.51
		var dist: float = lerpf(9.0, 35.0 * strength, progress)
		var glint_pos: Vector2 = p + Vector2(cos(a), sin(a)) * dist
		var glint_alpha: float = clampf(1.0 - abs(progress - (0.40 + float(i % 2) * 0.10)) * 2.7, 0.0, 1.0) * fade
		_draw_star(glint_pos, (4.1 + float(i % 2) * 1.0) * fade + 0.55, Color(1.0, 0.89, 0.24, 1.0), glint_alpha)

func _draw_boat(p: Vector2, a: float) -> void:
	var idx: int = BoatCollectibles.get_selected_index()
	if idx == 0:
		super._draw_boat(p, a)
		return
	var hull_colors: Array[Color] = [Color("9a6231"),Color("9f1f24"),Color("15191f"),Color("d9b65c"),Color("537d7b"),Color("5a2118"),Color("087e78"),Color("c58b14")]
	var sail_colors: Array[Color] = [Color("f3e5c0"),Color("d52b2f"),Color("24262c"),Color("f7f0d8"),Color("b8d4cc"),Color("e94a1b"),Color("13a69b"),Color("f7e7b0")]
	var accent_colors: Array[Color] = [Color("c8322f"),Color("ffd05a"),Color("bd1f2d"),Color("e3b62d"),Color("8ef4df"),Color("ff8a24"),Color("e8c44d"),Color("ffd34f")]
	var s: float = 0.54
	var hull := PackedVector2Array()
	for v: Vector2 in [Vector2(32,0),Vector2(20,-13),Vector2(-16,-14),Vector2(-27,-8),Vector2(-30,0),Vector2(-27,8),Vector2(-16,14),Vector2(20,13)]:
		hull.append(_rot(v,a,p,s))
	draw_colored_polygon(hull, hull_colors[idx])
	draw_polyline(PackedVector2Array([hull[0],hull[1],hull[2],hull[3],hull[4],hull[5],hull[6],hull[7],hull[0]]), Color("07151b"), 2.0, true)
	draw_line(_rot(Vector2(-10,0),a,p,s), _rot(Vector2(20,0),a,p,s), Color("5b351c"), 2.2, true)
	var sail1 := PackedVector2Array([_rot(Vector2(11,-2),a,p,s),_rot(Vector2(7,-12),a,p,s),_rot(Vector2(-8,-10),a,p,s),_rot(Vector2(-10,-2),a,p,s)])
	var sail2 := PackedVector2Array([_rot(Vector2(11,2),a,p,s),_rot(Vector2(7,12),a,p,s),_rot(Vector2(-8,10),a,p,s),_rot(Vector2(-10,2),a,p,s)])
	draw_colored_polygon(sail1, sail_colors[idx])
	draw_colored_polygon(sail2, sail_colors[idx])
	draw_polyline(PackedVector2Array([sail1[0],sail1[1],sail1[2],sail1[3],sail1[0]]), Color("07151b"), 1.2, true)
	draw_polyline(PackedVector2Array([sail2[0],sail2[1],sail2[2],sail2[3],sail2[0]]), Color("07151b"), 1.2, true)
	draw_circle(_rot(Vector2(-18,0),a,p,s), 3.2, accent_colors[idx])
	# No decorative circle/glow around any ship during gameplay.
	if idx == 5:
		draw_circle(_rot(Vector2(25,0),a,p,s), 2.5, Color("ffb126"))
