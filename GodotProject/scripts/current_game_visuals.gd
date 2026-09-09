extends Node2D

const INK = Color("07151b")
const FOAM = Color("d9f4fb")
const WOOD_DARK = Color("6b3f1c")
const WOOD = Color("9a6231")
const DECK = Color("b47a42")
const WOOD_LIGHT = Color("c58c50")
const OAR = Color("8a5527")
const SAILOR = Color("57a94a")
const BANDANA = Color("c8322f")
const MINE_BODY = Color("242a30")
const MINE_SHADE = Color("10151a")
const MINE_LIGHT = Color("59636d")
const MINE_RUST = Color("8d3a24")
const MINE_LAMP = Color("ffd24a")
const COIN_POINTS = [10, 25, 50, 100, 250, 500, 1000]
const COIN_SPRITES = [
	Vector3(164,427,306), Vector3(474,427,302), Vector3(780,427,302),
	Vector3(165,848,316), Vector3(483,849,320), Vector3(1090,427,302), Vector3(872,844,386)
]
const BOAT_SCALE := 0.54
const COIN_SIZE := 34.0
const POPUP_LIFE := 0.90
const PICKUP_BURST_LIFE := 0.72
const EXPLOSION_LIFE := 0.52

var coin_sheet: Texture2D
var last_score := 0
var last_coin_pos := Vector2.ZERO
var last_coin_tier: int = 0
var pickup_popups: Array[Dictionary] = []
var pickup_bursts: Array[Dictionary] = []
var explosions: Array[Dictionary] = []

func _ready() -> void:
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png")
	z_index = 5
	var g = get_parent()
	g.self_modulate = Color(1,1,1,0)
	if g.has_signal("explosion_requested"):
		g.connect("explosion_requested", Callable(self, "_on_explosion_requested"))
	last_score = int(g.score)
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", Vector2.ZERO)
		last_coin_tier = clampi(int(g.coin.get("tier", 0)), 0, 6)

func _on_explosion_requested(position: Vector2, scale: float) -> void:
	explosions.append({"pos": position, "life": EXPLOSION_LIFE, "scale": scale})
	queue_redraw()

func _process(delta: float) -> void:
	var g = get_parent()
	var current_score := int(g.score)
	if current_score > last_score:
		var amount: int = current_score - last_score
		pickup_popups.append({"pos":last_coin_pos,"amount":amount,"life":POPUP_LIFE})
		pickup_bursts.append({"pos":last_coin_pos,"amount":amount,"tier":last_coin_tier,"life":PICKUP_BURST_LIFE})
	last_score = current_score
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", last_coin_pos)
		last_coin_tier = clampi(int(g.coin.get("tier", last_coin_tier)), 0, 6)
	for popup in pickup_popups:
		popup["life"] = float(popup.get("life",0.0)) - delta
	for i in range(pickup_popups.size()-1,-1,-1):
		if float(pickup_popups[i].get("life",0.0)) <= 0.0:
			pickup_popups.remove_at(i)
	for burst in pickup_bursts:
		burst["life"] = float(burst.get("life",0.0)) - delta
	for i in range(pickup_bursts.size()-1,-1,-1):
		if float(pickup_bursts[i].get("life",0.0)) <= 0.0:
			pickup_bursts.remove_at(i)
	for explosion in explosions:
		explosion["life"] = float(explosion.get("life",0.0)) - delta
	for i in range(explosions.size()-1,-1,-1):
		if float(explosions[i].get("life",0.0)) <= 0.0:
			explosions.remove_at(i)
	queue_redraw()

func _draw() -> void:
	var g = get_parent()
	for wake in g.wakes:
		_draw_wake(wake, g.WAKE_LIFE)
	if bool(g.whirlpool.get("active", false)):
		_draw_whirlpool(g.whirlpool)
	if bool(g.coin.get("active", false)):
		_draw_coin(g.coin)
	for mine in g.mines:
		if bool(mine.get("active", false)):
			_draw_mine(mine)
	for burst in pickup_bursts:
		_draw_pickup_burst(burst)
	for popup in pickup_popups:
		_draw_popup(popup)
	for explosion in explosions:
		_draw_explosion(explosion)
	if not g.game_over:
		_draw_boat(g.boat_pos, g.boat_angle)

func _rot(v: Vector2, a: float, p: Vector2, s: float) -> Vector2:
	return p + (v*s).rotated(a)

func _draw_boat(p: Vector2, a: float) -> void:
	var s := BOAT_SCALE
	draw_line(_rot(Vector2(-4,-9),a,p,s),_rot(Vector2(-17,-30),a,p,s),OAR,2.4,true)
	draw_line(_rot(Vector2(-4,9),a,p,s),_rot(Vector2(-17,30),a,p,s),OAR,2.4,true)
	draw_circle(_rot(Vector2(-19,-34),a,p,s),3.0,WOOD_LIGHT)
	draw_circle(_rot(Vector2(-19,34),a,p,s),3.0,WOOD_LIGHT)
	var hull = [Vector2(30,0),Vector2(22,-10),Vector2(6,-15),Vector2(-12,-15),Vector2(-24,-10),Vector2(-24,10),Vector2(-12,15),Vector2(6,15),Vector2(22,10)]
	var hp := PackedVector2Array()
	for v in hull: hp.append(_rot(v,a,p,s))
	draw_colored_polygon(hp,WOOD_DARK)
	draw_polyline(PackedVector2Array(hp + PackedVector2Array([hp[0]])),INK,1.7,true)
	var deck = [Vector2(23,0),Vector2(17,-8),Vector2(4,-11),Vector2(-10,-11),Vector2(-19,-8),Vector2(-19,8),Vector2(-10,11),Vector2(4,11),Vector2(17,8)]
	var dp := PackedVector2Array()
	for v in deck: dp.append(_rot(v,a,p,s))
	draw_colored_polygon(dp,DECK)
	draw_circle(_rot(Vector2(-5,0),a,p,s),4.0,SAILOR)
	draw_circle(_rot(Vector2(-10,0),a,p,s),3.2,BANDANA)
	draw_circle(_rot(Vector2(-17,0),a,p,s),3.0,Color("c9a227"))
	draw_line(_rot(Vector2(14,-8),a,p,s),_rot(Vector2(14,8),a,p,s),WOOD,2.5,true)

func _draw_coin(c: Dictionary) -> void:
	var p: Vector2 = c.get("pos",Vector2.ZERO)
	var tier: int = clampi(int(c.get("tier",0)),0,6)
	var phase: float = float(c.get("phase",0.0))
	var pulse: float = 1.0 + sin(phase) * 0.045
	var size: float = COIN_SIZE * pulse
	# Coin stays completely normal until collected.
	if coin_sheet:
		var sp: Vector3 = COIN_SPRITES[tier]
		var src := Rect2(sp.x-sp.z*0.5,sp.y-sp.z*0.5,sp.z,sp.z)
		var dst := Rect2(p-Vector2(size,size)*0.5,Vector2(size,size))
		draw_texture_rect_region(coin_sheet,dst,src)
	_draw_text(str(COIN_POINTS[tier]),p+Vector2(0,-size*0.5-4),15,Color("f6cf43"),1.0)

func _draw_star(center: Vector2, radius: float, color: Color, alpha: float) -> void:
	var c: Color = color
	c.a *= alpha
	draw_line(center + Vector2(-radius,0), center + Vector2(radius,0), c, 1.6, true)
	draw_line(center + Vector2(0,-radius), center + Vector2(0,radius), c, 1.6, true)
	draw_line(center + Vector2(-radius*0.58,-radius*0.58), center + Vector2(radius*0.58,radius*0.58), c, 1.0, true)
	draw_line(center + Vector2(radius*0.58,-radius*0.58), center + Vector2(-radius*0.58,radius*0.58), c, 1.0, true)

func _draw_pickup_burst(burst: Dictionary) -> void:
	var life: float = float(burst.get("life", 0.0))
	var progress: float = 1.0 - clampf(life / PICKUP_BURST_LIFE, 0.0, 1.0)
	var fade: float = 1.0 - progress
	var p: Vector2 = burst.get("pos", Vector2.ZERO)
	var tier: int = clampi(int(burst.get("tier", 0)), 0, 6)
	var amount: int = int(burst.get("amount", 0))
	var value_strength: float = float(tier) / 6.0

	# Immediate impact glow/flash only after the coin is hit.
	if progress < 0.24:
		var flash_t: float = progress / 0.24
		var flash_alpha: float = (1.0 - flash_t) * (0.72 + value_strength * 0.22)
		draw_circle(p, lerpf(9.0, 30.0 + value_strength * 8.0, flash_t), Color(1.0,0.94,0.52,flash_alpha))
		for ray in range(12):
			var ray_angle: float = float(ray) / 12.0 * TAU + float(tier) * 0.11
			var ray_inner: float = lerpf(8.0, 13.0, flash_t)
			var ray_outer: float = lerpf(22.0, 44.0 + value_strength * 14.0, flash_t)
			var ray_alpha: float = flash_alpha * (0.70 if ray % 2 == 0 else 0.42)
			draw_line(p + Vector2(cos(ray_angle),sin(ray_angle))*ray_inner, p + Vector2(cos(ray_angle),sin(ray_angle))*ray_outer, Color(1.0,0.82,0.20,ray_alpha), 1.3 + value_strength*0.7, true)

	# Gold sparkle outburst.
	var particle_count: int = 10 + tier * 2
	for i in range(particle_count):
		var a: float = float(i) / float(particle_count) * TAU + float(tier) * 0.17
		var speed_scale: float = 0.78 + float(i % 4) * 0.09
		var dist: float = lerpf(5.0, (34.0 + value_strength * 25.0) * speed_scale, progress)
		var particle_pos: Vector2 = p + Vector2(cos(a), sin(a)) * dist
		var radius: float = (1.3 + float(i % 3) * 0.55 + value_strength * 0.8) * fade + 0.25
		draw_circle(particle_pos, radius, Color(1.0,0.82,0.16,0.92*fade))
		if i % 3 == 0:
			_draw_star(particle_pos, 2.0 + value_strength * 1.8, Color(1.0,0.97,0.68,1.0), 0.78*fade)

	# 25+ coins get a visible expanding ring; high-value coins get a stronger ring.
	if amount >= 25:
		var ring_radius: float = lerpf(11.0, 40.0 + value_strength * 18.0, progress)
		var ring_alpha: float = (0.70 + value_strength * 0.18) * fade
		draw_arc(p, ring_radius, 0.0, TAU, 36, Color(1.0,0.79,0.16,ring_alpha), 2.0 + value_strength*1.5, true)
		if amount >= 500:
			draw_arc(p, ring_radius * 0.72, 0.0, TAU, 32, Color(1.0,0.94,0.55,0.42*fade), 1.2, true)

	# 500/1000 coins throw additional starbursts and gold shard streaks.
	if amount >= 500:
		for i in range(8):
			var a: float = float(i) / 8.0 * TAU + 0.28
			var d: float = lerpf(12.0, 54.0 + value_strength * 16.0, progress)
			var star_pos: Vector2 = p + Vector2(cos(a), sin(a)) * d
			_draw_star(star_pos, (3.5 + float(i % 3)) * fade + 0.8, Color(1.0,0.88,0.28,1.0), 0.88*fade)
			var shard_start: Vector2 = p + Vector2(cos(a),sin(a)) * (d - 8.0)
			draw_line(shard_start, star_pos, Color(1.0,0.66,0.08,0.64*fade), 1.7, true)

	# 1000 coin: short premium multicolor celebration layered over the gold burst.
	if amount >= 1000:
		var premium_colors: Array[Color] = [
			Color(1.0,0.32,0.78,1.0), Color(0.42,0.78,1.0,1.0),
			Color(0.72,0.48,1.0,1.0), Color(1.0,0.88,0.28,1.0)
		]
		for i in range(12):
			var a: float = float(i) / 12.0 * TAU + 0.16
			var d: float = lerpf(10.0, 62.0 + float(i % 3) * 7.0, progress)
			var premium_pos: Vector2 = p + Vector2(cos(a), sin(a)) * d
			var premium_color: Color = premium_colors[i % premium_colors.size()]
			_draw_star(premium_pos, 4.2 * fade + 1.0, premium_color, 0.92*fade)
		# Brief vertical jackpot beam.
		var beam_alpha: float = maxf(0.0, 1.0 - progress * 1.35) * 0.34
		draw_rect(Rect2(p + Vector2(-7.0,-82.0), Vector2(14.0,164.0)), Color(1.0,0.76,0.18,beam_alpha))
		draw_rect(Rect2(p + Vector2(-3.0,-96.0), Vector2(6.0,192.0)), Color(1.0,0.96,0.72,beam_alpha*0.85))

func _draw_popup(pop: Dictionary) -> void:
	var t: float = clampf(float(pop.get("life",0.0))/POPUP_LIFE,0.0,1.0)
	var p: Vector2 = pop.get("pos",Vector2.ZERO)
	p.y -= 27.0 + (1.0-t)*19.0
	var amount: int = int(pop.get("amount",0))
	var popup_size: int = 18
	if amount >= 500:
		popup_size = 22
	if amount >= 1000:
		popup_size = 26
	_draw_text("+%d" % amount,p,popup_size,Color("ffd34a"),t)

func _draw_text(text: String, center: Vector2, font_size: int, color: Color, alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var origin := Vector2(center.x-width*0.5,center.y)
	var shadow := Color(0.015,0.06,0.075,0.95*alpha)
	for off in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1),Vector2(0,2)]:
		draw_string(font,origin+off,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,shadow)
	var c := color
	c.a = alpha
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,c)

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos",Vector2.ZERO)
	var body: float = 8.6
	for i in range(10):
		var a: float = float(i)/10.0*TAU
		var tip := p+Vector2(cos(a),sin(a))*15.5
		var b1 := p+Vector2(cos(a-0.22),sin(a-0.22))*body
		var b2 := p+Vector2(cos(a+0.22),sin(a+0.22))*body
		draw_colored_polygon(PackedVector2Array([tip,b1,b2]),MINE_BODY)
		draw_polyline(PackedVector2Array([tip,b1,b2,tip]),INK,1.1,true)
	draw_circle(p,body,MINE_SHADE)
	draw_circle(p+Vector2(-2,-2),6.7,MINE_BODY)
	draw_circle(p+Vector2(-3.7,-3.8),2.0,Color(MINE_LIGHT,0.46))
	draw_arc(p,body,0,TAU,24,INK,1.6,true)
	draw_arc(p,body-0.6,0.18,PI-0.18,16,MINE_RUST,1.8,true)
	draw_circle(p+Vector2(0,-2.8),2.1,MINE_LAMP)
	draw_arc(p+Vector2(0,-2.8),2.1,0,TAU,12,INK,1.0,true)

func _draw_explosion(explosion: Dictionary) -> void:
	var p: Vector2 = explosion.get("pos", Vector2.ZERO)
	var life: float = float(explosion.get("life", 0.0))
	var scale_value: float = float(explosion.get("scale", 1.0))
	var progress: float = 1.0 - clampf(life / EXPLOSION_LIFE, 0.0, 1.0)
	var fade: float = 1.0 - progress
	var flash_radius: float = lerpf(5.0, 31.0, progress) * scale_value
	var ring_radius: float = lerpf(8.0, 42.0, progress) * scale_value
	if progress < 0.32:
		var flash_alpha: float = (1.0 - progress / 0.32) * 0.95
		draw_circle(p, flash_radius, Color(1.0, 0.94, 0.62, flash_alpha))
	draw_circle(p, flash_radius * 0.68, Color(1.0, 0.34, 0.08, 0.72 * fade))
	draw_arc(p, ring_radius, 0.0, TAU, 32, Color(1.0, 0.72, 0.18, 0.88 * fade), 3.0 * scale_value, true)
	for i in range(12):
		var a: float = float(i) / 12.0 * TAU + 0.17
		var inner: float = lerpf(5.0, 13.0, progress) * scale_value
		var outer: float = lerpf(14.0, 50.0, progress) * scale_value
		var p1 := p + Vector2(cos(a), sin(a)) * inner
		var p2 := p + Vector2(cos(a), sin(a)) * outer
		draw_line(p1, p2, Color(1.0, 0.48, 0.10, 0.82 * fade), 2.0 * scale_value, true)
	for i in range(8):
		var a: float = float(i) / 8.0 * TAU + 0.39
		var debris_dist: float = lerpf(9.0, 38.0, progress) * scale_value
		var debris_pos := p + Vector2(cos(a), sin(a)) * debris_dist
		draw_circle(debris_pos, 2.2 * scale_value * fade + 0.6, Color(0.12, 0.10, 0.08, 0.85 * fade))

func _draw_wake(w: Dictionary, life_max: float) -> void:
	var p: Vector2 = w.get("pos",Vector2.ZERO)
	var a: float = float(w.get("angle",0.0))
	var alpha: float = clampf(float(w.get("life",0.0))/life_max,0.0,1.0)
	var f := Vector2(cos(a),sin(a))
	var side := Vector2(-f.y,f.x)
	draw_line(p-side*5,p-f*18-side*9,Color(FOAM,0.42*alpha),1.7,true)
	draw_line(p+side*5,p-f*18+side*9,Color(FOAM,0.42*alpha),1.7,true)
	draw_line(p-f*8,p-f*24,Color(FOAM,0.20*alpha),1.2,true)

func _ellipse_points(center: Vector2, rx: float, ry: float, rotation: float, steps: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(steps + 1):
		var a: float = float(i) / float(steps) * TAU
		var local := Vector2(cos(a) * rx, sin(a) * ry).rotated(rotation)
		pts.append(center + local)
	return pts

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
		var pts: PackedVector2Array = PackedVector2Array()
		for step in range(38):
			var t: float = float(step) / 37.0
			var radius: float = lerpf(51.0, 7.0, t)
			var angle: float = spin * 0.9 + float(arm) * TAU / 6.0 + t * 5.7
			pts.append(p + Vector2(cos(angle), sin(angle)) * radius)
		var arm_alpha: float = 0.23 + float(arm % 2) * 0.08
		draw_polyline(pts, Color(0.78, 0.95, 0.98, arm_alpha), 1.9 + float(arm % 2) * 0.45, true)
	for band in range(3):
		var radius: float = 29.0 + float(band) * 9.0
		for seg in range(5):
			var a0: float = spin * 0.48 + float(seg) * TAU / 5.0 + float(band) * 0.31
			var pts: PackedVector2Array = PackedVector2Array()
			for k in range(9):
				var a: float = a0 + float(k) / 8.0 * 0.56
				var wobble: float = sin(a * 5.0 + spin) * 1.1
				pts.append(p + Vector2(cos(a), sin(a)) * (radius + wobble))
			draw_polyline(pts, Color(0.90, 0.985, 1.0, 0.23 - float(band) * 0.035), 1.35, true)
	for i in range(10):
		var a: float = spin * 0.7 + float(i) / 10.0 * TAU
		var r: float = 40.0 + sin(float(i) * 1.65 + spin) * 6.0
		var bubble: Vector2 = p + Vector2(cos(a), sin(a)) * r
		draw_circle(bubble, 1.1 + float(i % 3) * 0.42, Color(0.87, 0.98, 1.0, 0.40))
	draw_arc(p, 20.0, spin * 0.2, spin * 0.2 + 4.7, 38, Color(0.43, 0.82, 0.88, 0.27), 1.5, true)
	draw_arc(p, 11.0, -spin * 0.18, -spin * 0.18 + 4.9, 32, Color(0.72, 0.94, 0.97, 0.23), 1.1, true)
