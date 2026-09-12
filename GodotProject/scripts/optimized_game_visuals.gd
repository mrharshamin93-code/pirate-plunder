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

# Bright candy-style burst: glossy rainbow sparks, confetti and star glints.
# 500 and 1000-point coins get progressively bigger jackpot-style hits.
func _draw_pickup_burst(burst: Dictionary) -> void:
	var life: float = float(burst.get("life", 0.0))
	var progress: float = 1.0 - clampf(life / PICKUP_BURST_LIFE, 0.0, 1.0)
	var fade: float = pow(1.0 - progress, 1.12)
	var p: Vector2 = burst.get("pos", Vector2.ZERO)
	var tier: int = clampi(int(burst.get("tier", 0)), 0, 6)
	var amount: int = int(burst.get("amount", 0))
	var premium_scale: float = 1.0
	if amount >= 1000:
		premium_scale = 1.65
	elif amount >= 500:
		premium_scale = 1.32
	var strength: float = (1.0 + float(tier) * 0.06) * premium_scale
	var candy_colors: Array[Color] = [
		Color("ff4f9a"), Color("55c8ff"), Color("8f5cff"),
		Color("45e6a8"), Color("ffd84a"), Color("ff7b35"), Color("ff5f66")
	]

	# Fast white/color impact rays.
	var flash: float = clampf(1.0 - progress / (0.34 if amount >= 500 else 0.28), 0.0, 1.0)
	if flash > 0.0:
		var ray_count: int = 14
		if amount >= 500: ray_count = 20
		if amount >= 1000: ray_count = 26
		for ray in range(ray_count):
			var a: float = float(ray) / float(ray_count) * TAU + 0.08
			var dir := Vector2(cos(a), sin(a))
			var inner: float = 2.0 + progress * 5.5
			var outer: float = (18.0 + float(ray % 4) * 6.0) * strength * (1.0 + progress * 0.72)
			var ray_color: Color = candy_colors[(ray + tier) % candy_colors.size()]
			ray_color.a = 0.96 * flash
			draw_line(p + dir * inner, p + dir * outer, ray_color, (1.5 + float(ray % 2) * 0.55) * minf(premium_scale, 1.35), true)
			if ray % 3 == 0:
				draw_line(p + dir * (inner + 1.0), p + dir * (outer * 0.72), Color(1.0,1.0,1.0,0.78*flash), 1.0, true)

	# Main glossy candy burst.
	var particle_count: int = 22 + tier * 2
	if amount >= 500: particle_count += 12
	if amount >= 1000: particle_count += 18
	for i in range(particle_count):
		var a: float = float(i) / float(particle_count) * TAU + float(i % 5) * 0.06
		var speed: float = 0.70 + float(i % 6) * 0.075
		var dist: float = lerpf(4.0, 52.0 * strength * speed, progress)
		var dir := Vector2(cos(a), sin(a))
		var pos: Vector2 = p + dir * dist
		var alpha: float = fade * (0.82 + float(i % 3) * 0.06)
		var c: Color = candy_colors[(i + tier * 2) % candy_colors.size()]
		c.a = alpha
		var radius: float = maxf(0.6, (2.8 - progress * 1.65) * (0.86 + float(i % 3) * 0.14) * minf(premium_scale, 1.30))
		draw_circle(pos, radius, c)
		if i % 2 == 0:
			draw_circle(pos + Vector2(-radius*0.25,-radius*0.25), maxf(0.35,radius*0.32), Color(1.0,1.0,1.0,alpha*0.78))
		if i % 3 == 0:
			var tail_color: Color = c
			tail_color.a *= 0.58
			draw_line(pos - dir * (5.0 + float(i % 4) * 1.6) * fade * premium_scale, pos, tail_color, 1.15, true)
		if i % 5 == 0:
			_draw_star(pos, (3.0 + float(i % 3) * 0.75) * fade * minf(premium_scale, 1.35) + 0.45, Color(1.0,1.0,1.0,1.0), alpha)

	# Color confetti.
	var confetti_progress: float = clampf((progress - 0.04) / 0.96, 0.0, 1.0)
	var confetti_fade: float = pow(1.0 - confetti_progress, 1.30)
	var confetti_count: int = 12
	if amount >= 500: confetti_count = 20
	if amount >= 1000: confetti_count = 30
	for i in range(confetti_count):
		var a: float = float(i) / float(confetti_count) * TAU + 0.31
		var dist: float = lerpf(6.0, (28.0 + float(i % 4) * 7.0) * strength, confetti_progress)
		var cp: Vector2 = p + Vector2(cos(a), sin(a)) * dist
		var c: Color = candy_colors[(i + 3) % candy_colors.size()]
		c.a = 0.94 * confetti_fade
		var s: float = (1.7 + float(i % 3) * 0.55) * minf(premium_scale, 1.28)
		draw_colored_polygon(PackedVector2Array([
			cp + Vector2(0,-s), cp + Vector2(s,0), cp + Vector2(0,s), cp + Vector2(-s,0)
		]), c)

	# Delayed glints.
	var glint_count: int = 7
	if amount >= 500: glint_count = 12
	if amount >= 1000: glint_count = 18
	for i in range(glint_count):
		var a: float = float(i) / float(glint_count) * TAU + 0.47
		var dist: float = lerpf(10.0, 38.0 * strength, progress)
		var glint_pos: Vector2 = p + Vector2(cos(a), sin(a)) * dist
		var glint_alpha: float = clampf(1.0 - abs(progress - (0.38 + float(i % 3) * 0.055)) * 2.6, 0.0, 1.0) * fade
		var glint_color: Color = candy_colors[(i + tier) % candy_colors.size()]
		_draw_star(glint_pos, (4.0 + float(i % 2) * 1.2) * fade * minf(premium_scale, 1.42) + 0.55, glint_color, glint_alpha)
		_draw_star(glint_pos, (2.0 + float(i % 2) * 0.6) * fade + 0.35, Color(1.0,1.0,1.0,1.0), glint_alpha*0.94)

	# Premium jackpot accents: 500 gets a second punch; 1000 gets a huge white/rainbow starburst.
	if amount >= 500:
		var punch: float = clampf(1.0 - abs(progress - 0.16) / 0.16, 0.0, 1.0)
		for i in range(8 if amount < 1000 else 12):
			var a: float = float(i) / float(8 if amount < 1000 else 12) * TAU + 0.19
			var dir := Vector2(cos(a), sin(a))
			var d1: float = 10.0 * premium_scale
			var d2: float = (42.0 if amount < 1000 else 62.0) * premium_scale
			var cc: Color = candy_colors[(i + 1) % candy_colors.size()]
			cc.a = 0.82 * punch
			draw_line(p + dir*d1, p + dir*d2, cc, 2.0 if amount < 1000 else 2.6, true)
	if amount >= 1000:
		var jackpot: float = clampf(1.0 - progress / 0.42, 0.0, 1.0)
		_draw_star(p, 18.0 + (1.0-jackpot)*10.0, Color(1.0,1.0,1.0,1.0), jackpot)
		for i in range(10):
			var a: float = float(i) / 10.0 * TAU + 0.27
			var jp: Vector2 = p + Vector2(cos(a), sin(a)) * lerpf(18.0, 72.0, progress)
			_draw_star(jp, 6.0 * fade + 1.0, candy_colors[i % candy_colors.size()], fade)

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
