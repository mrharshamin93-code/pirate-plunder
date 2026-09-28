extends Node2D

const COIN_SHEET_SIZE = 1254.0
const COIN_SPRITES = [
	Vector3(164, 427, 306), Vector3(474, 427, 302), Vector3(780, 427, 302),
	Vector3(165, 848, 316), Vector3(483, 849, 320), Vector3(1090, 427, 302),
	Vector3(872, 844, 386)
]
const INK = Color("0a1a20")
const MINE_BODY = Color("25292e")
const MINE_SHADE = Color("12161a")
const MINE_LIGHT = Color("555f68")
const MINE_RUST = Color("8d3a24")
const MINE_LAMP = Color("ffd24a")
var coin_sheet: Texture2D

func _ready() -> void:
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png")
	z_index = 30

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var g = get_node("../..")
	var tier = clampi(int(g.coin.get("tier",0)),0,6)
	if coin_sheet:
		var sp: Vector3 = COIN_SPRITES[tier]
		var src = Rect2(sp.x-sp.z*.5,sp.y-sp.z*.5,sp.z,sp.z)
		draw_texture_rect_region(coin_sheet,Rect2(301,25,24,24),src)
	_draw_mine(Vector2(313,73),29.0/56.0)

func _draw_mine(p: Vector2, scale: float) -> void:
	var r = 13.0*scale
	for i in range(10):
		var a = float(i)/10.0*TAU
		var tip = p + Vector2(cos(a),sin(a))*22.0*scale
		var b1 = p + Vector2(cos(a-.2),sin(a-.2))*r
		var b2 = p + Vector2(cos(a+.2),sin(a+.2))*r
		draw_colored_polygon(PackedVector2Array([tip,b1,b2]),MINE_BODY)
	draw_circle(p,r,MINE_SHADE)
	draw_circle(p+Vector2(-3,-3)*scale,10.5*scale,MINE_BODY)
	draw_arc(p,r,0,TAU,24,INK,1.6*scale,true)
	draw_arc(p,r-1,0.15,PI-0.15,16,MINE_RUST,2.3*scale,true)
	draw_circle(p+Vector2(0,-4)*scale,3.2*scale,MINE_LAMP)
