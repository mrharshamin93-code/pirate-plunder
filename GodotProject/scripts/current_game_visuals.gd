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
const POPUP_LIFE := 0.78

var coin_sheet: Texture2D
var last_score := 0
var last_coin_pos := Vector2.ZERO
var pickup_popups: Array[Dictionary] = []

func _ready() -> void:
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png")
	z_index = 5
	var g = get_parent()
	# Hide the old procedural Game drawing while keeping its physics/state active.
	g.self_modulate = Color(1,1,1,0)
	last_score = int(g.score)
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", Vector2.ZERO)

func _process(delta: float) -> void:
	var g = get_parent()
	var current_score := int(g.score)
	if current_score > last_score:
		pickup_popups.append({"pos":last_coin_pos,"amount":current_score-last_score,"life":POPUP_LIFE})
	last_score = current_score
	if bool(g.coin.get("active", false)):
		last_coin_pos = g.coin.get("pos", last_coin_pos)
	for popup in pickup_popups:
		popup["life"] = float(popup.get("life",0.0)) - delta
	for i in range(pickup_popups.size()-1,-1,-1):
		if float(pickup_popups[i].get("life",0.0)) <= 0.0:
			pickup_popups.remove_at(i)
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
	for popup in pickup_popups:
		_draw_popup(popup)
	if not g.game_over:
		_draw_boat(g.boat_pos, g.boat_angle)

func _rot(v: Vector2, a: float, p: Vector2, s: float) -> Vector2:
	return p + (v*s).rotated(a)

func _draw_boat(p: Vector2, a: float) -> void:
	var s := BOAT_SCALE
	# Same top-down wooden boat language as the current game, at the smaller real-game scale.
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
	var tier := clampi(int(c.get("tier",0)),0,6)
	var pulse := 1.0 + sin(float(c.get("phase",0.0))) * 0.045
	var size := COIN_SIZE * pulse
	if coin_sheet:
		var sp: Vector3 = COIN_SPRITES[tier]
		var src := Rect2(sp.x-sp.z*0.5,sp.y-sp.z*0.5,sp.z,sp.z)
		var dst := Rect2(p-Vector2(size,size)*0.5,Vector2(size,size))
		draw_texture_rect_region(coin_sheet,dst,src)
	_draw_text(str(COIN_POINTS[tier]),p+Vector2(0,-size*0.5-4),15,Color("f6cf43"),1.0)

func _draw_popup(pop: Dictionary) -> void:
	var t := clampf(float(pop.get("life",0.0))/POPUP_LIFE,0.0,1.0)
	var p: Vector2 = pop.get("pos",Vector2.ZERO)
	p.y -= 27.0 + (1.0-t)*14.0
	_draw_text("+%d" % int(pop.get("amount",0)),p,18,Color("ffd34a"),t)

func _draw_text(text: String, center: Vector2, font_size: int, color: Color, alpha: float) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var origin := Vector2(center.x-width*0.5,center.y)
	var shadow := Color(0.015,0.06,0.075,0.95*alpha)
	for off in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1),Vector2(0,2)]:
		draw_string(font,origin+off,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,shadow)
	var c := color
	c.a = alpha
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,c)

func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m.get("pos",Vector2.ZERO)
	var body := 8.6
	for i in range(10):
		var a := float(i)/10.0*TAU
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

func _draw_wake(w: Dictionary, life_max: float) -> void:
	var p: Vector2 = w.get("pos",Vector2.ZERO)
	var a := float(w.get("angle",0.0))
	var alpha := clampf(float(w.get("life",0.0))/life_max,0.0,1.0)
	var f := Vector2(cos(a),sin(a))
	var side := Vector2(-f.y,f.x)
	draw_line(p-side*5,p-f*18-side*9,Color(FOAM,0.42*alpha),1.7,true)
	draw_line(p+side*5,p-f*18+side*9,Color(FOAM,0.42*alpha),1.7,true)
	draw_line(p-f*8,p-f*24,Color(FOAM,0.20*alpha),1.2,true)

func _draw_whirlpool(w: Dictionary) -> void:
	var p: Vector2 = w.get("pos",Vector2.ZERO)
	var spin := float(w.get("spin",0.0))
	for i in range(7):
		var r := 16.0+float(i)*7.0
		var alpha := 0.42-float(i)*0.045
		draw_arc(p,r,spin*0.15+float(i)*0.58,spin*0.15+float(i)*0.58+5.0,34,Color(0.70,0.91,0.94,alpha),2.5,true)
	draw_circle(p,10.0,Color(0.0,0.02,0.03,0.82))
	draw_circle(p,4.2,Color.BLACK)
