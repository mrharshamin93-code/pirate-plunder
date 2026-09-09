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

var coin_sheet: Texture2D

func _ready() -> void:
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png")
	z_index = 5

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var g = get_parent()
	_draw_ocean()
	for wake in g.wakes:
		_draw_wake(wake, g.WAKE_LIFE)
	if bool(g.whirlpool.get("active", false)):
		_draw_whirlpool(g.whirlpool)
	if bool(g.coin.get("active", false)):
		_draw_coin(g.coin)
	for mine in g.mines:
		if bool(mine.get("active", false)):
			_draw_mine(mine)
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

func _rot(local: Vector2, angle: float, origin: Vector2) -> Vector2:
	return origin + local.rotated(angle)

func _draw_boat(p: Vector2, angle: float) -> void:
	var a = angle
	# oars
	draw_line(_rot(Vector2(-4,-9),a,p), _rot(Vector2(-17,-30),a,p), OAR, 4.0, true)
	draw_circle(_rot(Vector2(-19,-34),a,p), 5.0, WOOD_LIGHT)
	draw_line(_rot(Vector2(-4,9),a,p), _rot(Vector2(-17,30),a,p), OAR, 4.0, true)
	draw_circle(_rot(Vector2(-19,34),a,p), 5.0, WOOD_LIGHT)
	# hull/deck
	var hull = PackedVector2Array([Vector2(30,0),Vector2(22,-10),Vector2(6,-15),Vector2(-12,-15),Vector2(-24,-10),Vector2(-24,10),Vector2(-12,15),Vector2(6,15),Vector2(22,10)])
	var hp = PackedVector2Array()
	for v in hull: hp.append(_rot(v,a,p))
	draw_colored_polygon(hp, WOOD_DARK)
	draw_polyline(PackedVector2Array(hp + PackedVector2Array([hp[0]])), INK, 2.5, true)
	var deck = PackedVector2Array([Vector2(23,0),Vector2(17,-8),Vector2(4,-11.5),Vector2(-10,-11),Vector2(-19,-8),Vector2(-19,8),Vector2(-10,11),Vector2(4,11.5),Vector2(17,8)])
	var dp = PackedVector2Array()
	for v in deck: dp.append(_rot(v,a,p))
	draw_colored_polygon(dp, DECK)
	for x in [-14.0,-6.0,4.0,13.0]:
		draw_line(_rot(Vector2(x,-9),a,p), _rot(Vector2(x,9),a,p), Color(WOOD_DARK,0.55), 1.6, true)
	# sailor and details
	draw_circle(_rot(Vector2(-8,0),a,p), 7.2, SAILOR_DARK)
	draw_circle(_rot(Vector2(-4,0),a,p), 6.2, SAILOR)
	draw_arc(_rot(Vector2(-4,0),a,p), 6.2, 0, TAU, 24, INK, 1.8, true)
	draw_circle(_rot(Vector2(-10,0),a,p), 5.0, BANDANA)
	draw_circle(_rot(Vector2(-17,0),a,p), 4.7, Color("c9a227"))
	draw_line(_rot(Vector2(14,-8),a,p), _rot(Vector2(14,8),a,p), WOOD, 4.0, true)

func _draw_coin(c: Dictionary) -> void:
	var p: Vector2 = c.get("pos", Vector2.ZERO)
	var tier = clampi(int(c.get("tier",0)),0,6)
	var pulse = 1.0 + sin(float(c.get("phase",0.0))) * 0.06
	var size = 32.0 * pulse
	if coin_sheet:
		var sp: Vector3 = COIN_SPRITES[tier]
		var src = Rect2(sp.x - sp.z * 0.5, sp.y - sp.z * 0.5, sp.z, sp.z)
		var dst = Rect2(p - Vector2(size,size)*0.5, Vector2(size,size))
		draw_texture_rect_region(coin_sheet, dst, src)

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos", Vector2.ZERO)
	var body_r = 13.0
	for i in range(10):
		var a = float(i) / 10.0 * TAU
		var tip = p + Vector2(cos(a),sin(a)) * 22.0
		var b1 = p + Vector2(cos(a-0.2),sin(a-0.2)) * body_r
		var b2 = p + Vector2(cos(a+0.2),sin(a+0.2)) * body_r
		draw_colored_polygon(PackedVector2Array([tip,b1,b2]), MINE_BODY)
		draw_polyline(PackedVector2Array([tip,b1,b2,tip]), INK, 1.6, true)
	draw_circle(p, body_r, MINE_SHADE)
	draw_circle(p + Vector2(-3,-3), 10.5, MINE_BODY)
	draw_arc(p, body_r, 0, TAU, 32, INK, 2.2, true)
	draw_arc(p, body_r-1, 0.15, PI-0.15, 20, MINE_RUST, 2.6, true)
	draw_circle(p+Vector2(-6,6),1.3,MINE_LIGHT)
	draw_circle(p+Vector2(6,6),1.3,MINE_LIGHT)
	draw_circle(p+Vector2(0,-4),3.2,MINE_LAMP)
	draw_arc(p+Vector2(0,-4),3.2,0,TAU,16,INK,1.6,true)
	draw_arc(p+Vector2(-2,-4),8.0,4.0,5.2,12,Color(1,1,1,0.45),2.0,true)

func _draw_wake(w: Dictionary, wake_life: float) -> void:
	var p: Vector2 = w.get("pos", Vector2.ZERO)
	var a = float(w.get("angle",0.0))
	var alpha = clampf(float(w.get("life",0.0))/wake_life,0.0,1.0)
	var f = Vector2(cos(a),sin(a))
	var side = Vector2(-f.y,f.x)
	var pts = PackedVector2Array([p-side*14,p-f*5,p+side*14])
	draw_polyline(pts, Color(FOAM,0.58*alpha),3.0,true)
	draw_line(p-f*4-side*11,p-f*7+side*11,Color(FOAM,0.28*alpha),1.8,true)
	draw_circle(p+side*7-f*4,1.4,Color(FOAM,0.5*alpha))

func _draw_whirlpool(w: Dictionary) -> void:
	var p: Vector2 = w.get("pos", Vector2.ZERO)
	var spin = float(w.get("spin",0.0))
	# dark basin: visual radius 70, matching current app
	for i in range(14,0,-1):
		var t = float(i)/14.0
		var col = Color("07566d").lerp(Color("000205"),1.0-t)
		col.a = 0.10 + (1.0-t)*0.12
		draw_circle(p,70.0*t,col)
	var rings = [[61.0,0.20,5.5],[50.0,0.19,5.0],[39.0,0.17,4.5],[29.0,0.15,3.8]]
	for i in range(rings.size()):
		var r = rings[i][0]
		draw_arc(p,r,spin*0.15 + i*0.55,spin*0.15 + i*0.55 + 5.25,56,Color(0.65,0.90,0.93,rings[i][1]),rings[i][2],true)
	# bright foam arcs from current React Native art
	draw_arc(p,66,3.38+spin*.08,6.05+spin*.08,38,Color(0.85,0.96,0.97,0.48),4.2,true)
	draw_arc(p,63,0.18+spin*.08,2.85+spin*.08,38,Color(0.72,0.91,0.93,0.40),3.5,true)
	draw_arc(p,51,3.7+spin*.1,5.7+spin*.1,28,Color(1,1,1,0.54),3.2,true)
	draw_arc(p,50,0.65+spin*.1,2.55+spin*.1,28,Color(0.93,1,1,0.44),2.8,true)
	draw_arc(p,32,2.8+spin*.18,5.8+spin*.18,30,Color(0.48,0.79,0.83,0.58),5.2,true)
	draw_arc(p,31,-0.35+spin*.18,2.7+spin*.18,30,Color(0.66,0.89,0.91,0.50),4.7,true)
	draw_circle(p+Vector2(-2,1),11.0,Color("000306"))
	draw_circle(p,4.8,Color.BLACK)
	draw_arc(p,15.0,0,TAU,36,Color(0.31,0.62,0.67,0.18),2.0,true)
