extends Node2D

const INK = Color("0a1a20")
const SEA_LIGHT = Color("1f7d92")
const SEA_MID = Color("125a6e")
const SEA_DEEP = Color("082e3c")
const CREST = Color("4fb6cc")
const FOAM = Color("d9f4fb")
const WOOD = Color("9a6231")
const WOOD_DARK = Color("6b3f1c")
const WOOD_LIGHT = Color("c58c50")
const DECK = Color("b47a42")
const OAR = Color("8a5527")
const SAILOR = Color("57a94a")
const SAILOR_DARK = Color("3b7a32")
const BANDANA = Color("c8322f")
const MINE_BODY = Color("25292e")
const MINE_SHADE = Color("12161a")
const MINE_LIGHT = Color("555f68")
const MINE_RUST = Color("8d3a24")
const MINE_LAMP = Color("ffd24a")
const COIN_SHEET_SIZE = 1254.0
const COIN_POINTS = [10, 25, 50, 100, 250, 500, 1000]
const COIN_SPRITES = [
	Vector3(164, 427, 306), Vector3(474, 427, 302), Vector3(780, 427, 302),
	Vector3(165, 848, 316), Vector3(483, 849, 320), Vector3(1090, 427, 302),
	Vector3(872, 844, 386)
]
const WAVES = [
	Vector3(0.10,0.12,0.16), Vector3(0.62,0.09,0.20), Vector3(0.30,0.22,0.12),
	Vector3(0.76,0.28,0.14), Vector3(0.08,0.37,0.18), Vector3(0.46,0.44,0.14),
	Vector3(0.82,0.50,0.12), Vector3(0.20,0.57,0.20), Vector3(0.58,0.65,0.16),
	Vector3(0.12,0.74,0.13), Vector3(0.70,0.80,0.18), Vector3(0.36,0.88,0.15)
]
const FLECKS = [Vector2(.24,.31),Vector2(.53,.19),Vector2(.86,.40),Vector2(.17,.63),Vector2(.66,.55),Vector2(.42,.77),Vector2(.90,.68),Vector2(.30,.95)]
const BOAT_SCALE = 0.72
const GAME_COIN_SIZE = 28.0
const CONTROL_ZONE_HEIGHT = 158.0
const POPUP_LIFE = 0.75

var coin_sheet: Texture2D
var last_score := 0
var last_coin_pos := Vector2.ZERO
var pickup_popups: Array[Dictionary] = []

func _ready() -> void:
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png")
	z_index = 5
	var g = get_parent()
	last_score = int(g.score)
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", Vector2.ZERO)

func _process(delta: float) -> void:
	var g = get_parent()
	var current_score = int(g.score)
	if current_score > last_score:
		pickup_popups.append({
			"pos": last_coin_pos,
			"amount": current_score - last_score,
			"life": POPUP_LIFE
		})
	last_score = current_score
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", last_coin_pos)
	for popup in pickup_popups:
		popup["life"] = float(popup.get("life", 0.0)) - delta
	for i in range(pickup_popups.size() - 1, -1, -1):
		if float(pickup_popups[i].get("life", 0.0)) <= 0.0:
			pickup_popups.remove_at(i)
	queue_redraw()

func _draw() -> void:
	var g = get_parent()
	_draw_ocean()
	_draw_control_zone_divider()
	for wake in g.wakes:
		_draw_wake(wake, g.WAKE_LIFE)
	if bool(g.whirlpool.get("active", false)):
		_draw_whirlpool(g.whirlpool)
	if bool(g.coin.get("active", false)):
		_draw_coin(g.coin)
	for mine in g.mines:
		if bool(mine.get("active", false)):
			_draw_mine(mine)
	for popup in pickup_popups:
		_draw_pickup_popup(popup)
	if not g.game_over:
		_draw_boat(g.boat_pos, g.boat_angle)

func _draw_ocean() -> void:
	var s = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), SEA_DEEP)
	var center = Vector2(s.x * 0.5, s.y * 0.42)
	var max_r = max(s.x, s.y) * 0.82
	for i in range(18, 0, -1):
		var t = float(i) / 18.0
		var c = SEA_MID.lerp(SEA_LIGHT, 1.0 - t)
		c.a = 0.12
		draw_circle(center, max_r * t, c)
	for w in WAVES:
		var x = s.x * w.x
		var y = s.y * w.y
		var ww = s.x * w.z
		var pts = PackedVector2Array()
		for i in range(17):
			var t = float(i) / 16.0
			pts.append(Vector2(x + ww * t, y - sin(t * TAU) * 2.5))
		draw_polyline(pts, Color(CREST, 0.28), 3.0, true)
	for f in FLECKS:
		draw_circle(Vector2(s.x * f.x, s.y * f.y), 2.5, Color(FOAM, 0.30))
	for i in range(10):
		var a = 0.07 * float(i)
		draw_rect(Rect2(0, float(i) * 17.0, s.x, 17.0), Color(SEA_DEEP, 0.12 - a * 0.08))

func _draw_control_zone_divider() -> void:
	var s = get_viewport_rect().size
	var y = s.y - CONTROL_ZONE_HEIGHT
	# Slightly darker dedicated joystick/control area, exactly separated from gameplay.
	draw_rect(Rect2(0.0, y, s.x, CONTROL_ZONE_HEIGHT), Color(SEA_DEEP, 0.27))
	draw_line(Vector2(0.0, y), Vector2(s.x, y), Color(0.78, 0.94, 0.97, 0.78), 1.5, true)
	draw_line(Vector2(0.0, y + 2.0), Vector2(s.x, y + 2.0), Color(0.08, 0.32, 0.40, 0.30), 1.0, true)

func _rot(local: Vector2, angle: float, origin: Vector2, scale: float = 1.0) -> Vector2:
	return origin + (local * scale).rotated(angle)

func _draw_boat(p: Vector2, angle: float) -> void:
	var a = angle
	var s = BOAT_SCALE
	# Smaller version of the current app boat, keeping all the same recognizable details.
	draw_line(_rot(Vector2(-4,-9),a,p,s), _rot(Vector2(-17,-30),a,p,s), OAR, 3.0, true)
	draw_circle(_rot(Vector2(-19,-34),a,p,s), 3.8, WOOD_LIGHT)
	draw_line(_rot(Vector2(-4,9),a,p,s), _rot(Vector2(-17,30),a,p,s), OAR, 3.0, true)
	draw_circle(_rot(Vector2(-19,34),a,p,s), 3.8, WOOD_LIGHT)
	var hull = PackedVector2Array([Vector2(30,0),Vector2(22,-10),Vector2(6,-15),Vector2(-12,-15),Vector2(-24,-10),Vector2(-24,10),Vector2(-12,15),Vector2(6,15),Vector2(22,10)])
	var hp = PackedVector2Array()
	for v in hull: hp.append(_rot(v,a,p,s))
	draw_colored_polygon(hp, WOOD_DARK)
	draw_polyline(PackedVector2Array(hp + PackedVector2Array([hp[0]])), INK, 2.0, true)
	var deck = PackedVector2Array([Vector2(23,0),Vector2(17,-8),Vector2(4,-11.5),Vector2(-10,-11),Vector2(-19,-8),Vector2(-19,8),Vector2(-10,11),Vector2(4,11.5),Vector2(17,8)])
	var dp = PackedVector2Array()
	for v in deck: dp.append(_rot(v,a,p,s))
	draw_colored_polygon(dp, DECK)
	for x in [-14.0,-6.0,4.0,13.0]:
		draw_line(_rot(Vector2(x,-9),a,p,s), _rot(Vector2(x,9),a,p,s), Color(WOOD_DARK,0.55), 1.2, true)
	draw_circle(_rot(Vector2(-8,0),a,p,s), 5.2, SAILOR_DARK)
	draw_circle(_rot(Vector2(-4,0),a,p,s), 4.5, SAILOR)
	draw_arc(_rot(Vector2(-4,0),a,p,s), 4.5, 0, TAU, 20, INK, 1.4, true)
	draw_circle(_rot(Vector2(-10,0),a,p,s), 3.7, BANDANA)
	draw_circle(_rot(Vector2(-17,0),a,p,s), 3.5, Color("c9a227"))
	draw_line(_rot(Vector2(14,-8),a,p,s), _rot(Vector2(14,8),a,p,s), WOOD, 3.0, true)

func _draw_coin(c: Dictionary) -> void:
	var p: Vector2 = c.get("pos", Vector2.ZERO)
	var tier = clampi(int(c.get("tier",0)),0,6)
	var pulse = 1.0 + sin(float(c.get("phase",0.0))) * 0.055
	var size = GAME_COIN_SIZE * pulse
	if coin_sheet:
		var sp: Vector3 = COIN_SPRITES[tier]
		var src = Rect2(sp.x - sp.z * 0.5, sp.y - sp.z * 0.5, sp.z, sp.z)
		var dst = Rect2(p - Vector2(size,size)*0.5, Vector2(size,size))
		draw_texture_rect_region(coin_sheet, dst, src)
	# Value sits immediately above the original coin sprite, like the current game.
	_draw_centered_text(str(COIN_POINTS[tier]), p + Vector2(0,-size*0.5-5.0), 14, Color.WHITE)

func _draw_pickup_popup(popup: Dictionary) -> void:
	var life = clampf(float(popup.get("life",0.0)) / POPUP_LIFE, 0.0, 1.0)
	var base: Vector2 = popup.get("pos", Vector2.ZERO)
	var pos = base + Vector2(0.0, -24.0 - (1.0-life)*15.0)
	var amount = int(popup.get("amount",0))
	var color = Color(1.0, 0.84, 0.22, life)
	_draw_centered_text("+%d" % amount, pos, 18, color)

func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin = Vector2(center.x - width * 0.5, center.y)
	# Dark outline/shadow for readability against water.
	for off in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1),Vector2(1,1)]:
		draw_string(font, origin + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.02,0.08,0.10,color.a*0.95))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	var body_r = 11.5
	# Current-app mine: compact spherical body, 10 chunky triangular spikes, rust seam and lamp.
	for i in range(10):
		var a = float(i) / 10.0 * TAU
		var tip = p + Vector2(cos(a),sin(a)) * 20.0
		var b1 = p + Vector2(cos(a-0.21),sin(a-0.21)) * body_r
		var b2 = p + Vector2(cos(a+0.21),sin(a+0.21)) * body_r
		draw_colored_polygon(PackedVector2Array([tip,b1,b2]), MINE_BODY)
		draw_polyline(PackedVector2Array([tip,b1,b2,tip]), INK, 1.4, true)
	draw_circle(p, body_r, MINE_SHADE)
	draw_circle(p + Vector2(-2.5,-2.5), 9.2, MINE_BODY)
	draw_circle(p + Vector2(-5.0,-5.0), 3.0, Color(MINE_LIGHT,0.42))
	draw_arc(p, body_r, 0, TAU, 32, INK, 2.0, true)
	draw_arc(p, body_r-0.8, 0.14, PI-0.14, 20, MINE_RUST, 2.4, true)
	draw_circle(p+Vector2(-5.3,5.1),1.1,MINE_LIGHT)
	draw_circle(p+Vector2(5.3,5.1),1.1,MINE_LIGHT)
	draw_circle(p+Vector2(0,-3.8),3.0,MINE_LAMP)
	draw_arc(p+Vector2(0,-3.8),3.0,0,TAU,16,INK,1.4,true)
	draw_arc(p+Vector2(-1.8,-3.8),7.3,4.05,5.2,12,Color(1,1,1,0.42),1.8,true)

func _draw_wake(w: Dictionary, wake_life: float) -> void:
	var p: Vector2 = w.get("pos", Vector2.ZERO)
	var a = float(w.get("angle",0.0))
	var alpha = clampf(float(w.get("life",0.0))/wake_life,0.0,1.0)
	var f = Vector2(cos(a),sin(a))
	var side = Vector2(-f.y,f.x)
	var pts = PackedVector2Array([p-side*11,p-f*7,p+side*11])
	draw_polyline(pts, Color(FOAM,0.62*alpha),2.5,true)
	draw_line(p-f*5-side*9,p-f*11+side*9,Color(FOAM,0.34*alpha),1.6,true)
	draw_circle(p+side*6-f*7,1.2,Color(FOAM,0.55*alpha))

func _draw_whirlpool(w: Dictionary) -> void:
	var p: Vector2 = w.get("pos", Vector2.ZERO)
	var spin = float(w.get("spin",0.0))
	for i in range(14,0,-1):
		var t = float(i)/14.0
		var col = Color("07566d").lerp(Color("000205"),1.0-t)
		col.a = 0.10 + (1.0-t)*0.12
		draw_circle(p,70.0*t,col)
	var rings = [[61.0,0.20,5.5],[50.0,0.19,5.0],[39.0,0.17,4.5],[29.0,0.15,3.8]]
	for i in range(rings.size()):
		var r = rings[i][0]
		draw_arc(p,r,spin*0.15 + i*0.55,spin*0.15 + i*0.55 + 5.25,56,Color(0.65,0.90,0.93,rings[i][1]),rings[i][2],true)
	draw_arc(p,66,3.38+spin*.08,6.05+spin*.08,38,Color(0.85,0.96,0.97,0.48),4.2,true)
	draw_arc(p,63,0.18+spin*.08,2.85+spin*.08,38,Color(0.72,0.91,0.93,0.40),3.5,true)
	draw_arc(p,51,3.7+spin*.1,5.7+spin*.1,28,Color(1,1,1,0.54),3.2,true)
	draw_arc(p,50,0.65+spin*.1,2.55+spin*.1,28,Color(0.93,1,1,0.44),2.8,true)
	draw_arc(p,32,2.8+spin*.18,5.8+spin*.18,30,Color(0.48,0.79,0.83,0.58),5.2,true)
	draw_arc(p,31,-0.35+spin*.18,2.7+spin*.18,30,Color(0.66,0.89,0.91,0.50),4.7,true)
	draw_circle(p+Vector2(-2,1),11.0,Color("000306"))
	draw_circle(p,4.8,Color.BLACK)
	draw_arc(p,15.0,0,TAU,36,Color(0.31,0.62,0.67,0.18),2.0,true)
