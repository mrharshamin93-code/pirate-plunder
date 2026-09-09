extends ColorRect

const SEA_DEEP: Color = Color("082e3c")
const CREST: Color = Color("4fb6cc")
const FOAM: Color = Color("d9f4fb")
const INK: Color = Color("0a1a20")
const WOOD: Color = Color("9a6231")
const WOOD_DARK: Color = Color("6b3f1c")
const DECK: Color = Color("b47a42")
const BANDANA: Color = Color("c8322f")
const MINE_BODY: Color = Color("25292e")
const MINE_SHADE: Color = Color("12161a")
const MINE_RUST: Color = Color("8d3a24")
const MINE_LAMP: Color = Color("ffd24a")
const ACCENT: Color = Color("f6c53d")
const SAVE_PATH: String = "user://leaderboard.cfg"

const COIN_SPRITES: Array[Vector3] = [
	Vector3(164,427,306), Vector3(474,427,302), Vector3(780,427,302),
	Vector3(165,848,316), Vector3(483,849,320), Vector3(1090,427,302), Vector3(872,844,386)
]
const COIN_VALUES: Array[int] = [10,25,50,100,250,500,1000]

var play_button: Button
var coin_sheet: Texture2D

func _ready() -> void:
	color = Color(0,0,0,0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	coin_sheet = load("res://assets/treasure-coins-3d-v10.png") as Texture2D
	_build_ui()
	_set_gameplay_ui_visible(false)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_ui")
		queue_redraw()

func _label(name: String, text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label

func _build_ui() -> void:
	var title: Label = _label("GameTitle", "Pirate’s Plunder", 42, Color("f4fbfd"))
	title.add_theme_color_override("font_shadow_color", Color(0.02,0.08,0.11,0.95))
	title.add_theme_constant_override("shadow_offset_y", 3)

	var story: Label = _label("Story", "You are Captain Marlow, rowing through the wreckage\nof Blackwake Harbor. Salvage the treasure and stay\nclear of the homing mines fired from the Dreadwake.", 14, Color(0.90,0.97,0.99,0.82))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var coin_title: Label = _label("CoinTitle", "C O I N   V A L U E S", 13, Color(0.90,0.97,0.99,0.72))
	for i in range(COIN_VALUES.size()):
		_label("CoinValue%d" % i, _comma(COIN_VALUES[i]), 12, Color(0.90,0.97,0.99,0.86))

	var instructions: Label = _label("Instructions", "Push the thumbstick to point her where you want to go — she\nholds her line and answers the helm quickly. Every coin you\ntake sends another mine after you.", 13, Color(0.90,0.97,0.99,0.72))
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_label("BestTitle", "B E S T   S C O R E", 13, Color(0.90,0.97,0.99,0.72))
	var best: Label = _label("BestScore", _comma(_load_best_score()), 31, ACCENT)
	best.add_theme_constant_override("outline_size", 1)
	best.add_theme_color_override("font_outline_color", Color(0,0,0,0.2))

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "Set Sail"
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.add_theme_color_override("font_color", Color("16333b"))
	play_button.add_theme_stylebox_override("normal", _round_box(ACCENT, Color(1,1,1,0), 0, 28))
	play_button.add_theme_stylebox_override("hover", _round_box(Color("ffd454"), Color(1,1,1,0), 0, 28))
	play_button.add_theme_stylebox_override("pressed", _round_box(Color("dba92b"), Color(1,1,1,0), 0, 28))
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)
	_layout_ui()

func _layout_ui() -> void:
	var w: float = size.x
	var h: float = size.y
	var sx: float = w / 390.0
	_set_rect("GameTitle", Vector2(18.0*sx, 258.0), Vector2(w-36.0*sx, 58.0))
	_set_rect("Story", Vector2(22.0*sx, 316.0), Vector2(w-44.0*sx, 94.0))
	_set_rect("CoinTitle", Vector2(28.0*sx, 438.0), Vector2(w-56.0*sx, 24.0))
	var coin_left: float = 23.0*sx
	var coin_width: float = w-46.0*sx
	var slot: float = coin_width/7.0
	for i in range(COIN_VALUES.size()):
		_set_rect("CoinValue%d" % i, Vector2(coin_left+slot*float(i), 512.0), Vector2(slot,20.0))
	_set_rect("Instructions", Vector2(20.0*sx, 560.0), Vector2(w-40.0*sx, 92.0))
	_set_rect("BestTitle", Vector2(104.0*sx, 678.0), Vector2(w-208.0*sx, 24.0))
	_set_rect("BestScore", Vector2(104.0*sx, 708.0), Vector2(w-208.0*sx, 48.0))
	if play_button:
		play_button.position = Vector2(36.0*sx, minf(h-72.0, 780.0))
		play_button.size = Vector2(w-72.0*sx, 58.0)

func _set_rect(node_name: String, pos: Vector2, node_size: Vector2) -> void:
	var node: Control = get_node_or_null(node_name) as Control
	if node:
		node.position = pos
		node.size = node_size

func _load_best_score() -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		return int(cfg.get_value("leaderboard", "personal_best", 0))
	return 0

func _on_play_pressed() -> void:
	play_button.disabled = true
	_set_gameplay_ui_visible(true)
	visible = false
	var game: Node = get_parent().get_parent()
	if game != null and game.has_method("_start_game"):
		game.call("_start_game")

func _set_gameplay_ui_visible(show_ui: bool) -> void:
	var canvas: Node = get_parent()
	for node_name in ["HUD", "Joystick", "HudArt"]:
		var item: CanvasItem = canvas.get_node_or_null(node_name) as CanvasItem
		if item:
			item.visible = show_ui

func _round_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width_left = width
	box.border_width_right = width
	box.border_width_top = width
	box.border_width_bottom = width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box

func _draw_boat(center: Vector2, scale: float) -> void:
	var hull: PackedVector2Array = PackedVector2Array([center+Vector2(30,0)*scale,center+Vector2(18,-13)*scale,center+Vector2(-12,-15)*scale,center+Vector2(-24,0)*scale,center+Vector2(-12,15)*scale,center+Vector2(18,13)*scale])
	draw_colored_polygon(hull, WOOD_DARK)
	var deck: PackedVector2Array = PackedVector2Array([center+Vector2(22,0)*scale,center+Vector2(13,-10)*scale,center+Vector2(-10,-11)*scale,center+Vector2(-19,0)*scale,center+Vector2(-10,11)*scale,center+Vector2(13,10)*scale])
	draw_colored_polygon(deck, DECK)
	draw_polyline(PackedVector2Array([hull[0],hull[1],hull[2],hull[3],hull[4],hull[5],hull[0]]), INK, 2.2*scale, true)
	draw_line(center+Vector2(-4,-9)*scale,center+Vector2(-17,-30)*scale,WOOD,3.5*scale,true)
	draw_line(center+Vector2(-4,9)*scale,center+Vector2(-17,30)*scale,WOOD,3.5*scale,true)
	draw_circle(center+Vector2(-4,0)*scale,6.2*scale,Color("57a94a"))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-9,-5)*scale,center+Vector2(-16,-5)*scale,center+Vector2(-10,1)*scale]),BANDANA)

func _draw_mine(center: Vector2, scale: float) -> void:
	var body_r: float = 13.0*scale
	for i in range(10):
		var a: float = float(i)/10.0*TAU
		var tip: Vector2 = center+Vector2(cos(a),sin(a))*22.0*scale
		var b1: Vector2 = center+Vector2(cos(a-0.2),sin(a-0.2))*body_r
		var b2: Vector2 = center+Vector2(cos(a+0.2),sin(a+0.2))*body_r
		draw_colored_polygon(PackedVector2Array([tip,b1,b2]),MINE_BODY)
	draw_circle(center,body_r,MINE_SHADE)
	draw_circle(center+Vector2(-3,-3)*scale,10.5*scale,MINE_BODY)
	draw_arc(center,body_r,0.0,TAU,24,INK,1.6*scale,true)
	draw_arc(center,body_r-1.0,0.15,PI-0.15,16,MINE_RUST,2.3*scale,true)
	draw_circle(center+Vector2(0,-4)*scale,3.2*scale,MINE_LAMP)

func _draw_raider(center: Vector2, scale: float) -> void:
	draw_line(center+Vector2(-22,6)*scale,center+Vector2(-22,-46)*scale,INK,3.0*scale,true)
	draw_line(center+Vector2(0,8)*scale,center+Vector2(0,-56)*scale,INK,3.0*scale,true)
	draw_line(center+Vector2(22,6)*scale,center+Vector2(22,-42)*scale,INK,3.0*scale,true)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-20,-44)*scale,center+Vector2(-2,-36)*scale,center+Vector2(-20,-8)*scale]),INK)
	draw_colored_polygon(PackedVector2Array([center+Vector2(2,-54)*scale,center+Vector2(24,-42)*scale,center+Vector2(2,-6)*scale]),INK)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-56)*scale,center+Vector2(18,-50)*scale,center+Vector2(0,-46)*scale]),BANDANA)
	var hull: PackedVector2Array = PackedVector2Array([center+Vector2(-46,6)*scale,center+Vector2(46,6)*scale,center+Vector2(40,18)*scale,center+Vector2(26,26)*scale,center+Vector2(-28,26)*scale,center+Vector2(-42,22)*scale])
	draw_colored_polygon(hull,INK)

func _comma(value: int) -> String:
	var s: String = str(value)
	var out: String = ""
	while s.length()>3:
		out=","+s.substr(s.length()-3,3)+out
		s=s.substr(0,s.length()-3)
	return s+out

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO,Vector2(w,h)),SEA_DEEP)
	# soft teal center glow, approximating the original OceanBackground
	for r in range(9,0,-1):
		var radius: float = float(r)*58.0
		draw_circle(Vector2(w*0.5,h*0.48),radius,Color(0.05,0.48,0.58,0.012))
	for i in range(12):
		var y: float = 55.0+float(i)*65.0
		var x: float = 18.0+float((i*83)%330)
		var width: float = 42.0+float((i*19)%46)
		draw_arc(Vector2(x+width*0.5,y),width*0.5,PI+0.28,TAU-0.28,18,Color(CREST,0.28),2.4,true)
	for i in range(8):
		draw_circle(Vector2(30.0+float((i*71)%335),72.0+float((i*97)%690)),2.5,Color(FOAM,0.30))
	_draw_boat(Vector2(w*0.23,130.0),0.82)
	_draw_mine(Vector2(w*0.48,128.0),0.92)
	_draw_raider(Vector2(w*0.75,112.0),0.78)
	var card: Rect2 = Rect2(16.0,423.0,w-32.0,126.0)
	draw_style_box(_round_box(Color(SEA_DEEP,0.50),Color(0.90,0.97,0.99,0.18),1,20),card)
	if coin_sheet:
		var coin_left: float = 23.0
		var coin_width: float = w-46.0
		var slot: float = coin_width/7.0
		for i in range(COIN_SPRITES.size()):
			var sp: Vector3 = COIN_SPRITES[i]
			var src: Rect2 = Rect2(sp.x-sp.z*0.5,sp.y-sp.z*0.5,sp.z,sp.z)
			var cx: float = coin_left+slot*(float(i)+0.5)
			draw_texture_rect_region(coin_sheet,Rect2(cx-18.0,470.0,36.0,36.0),src)
	var best_card: Rect2 = Rect2(101.0,666.0,w-202.0,100.0)
	draw_style_box(_round_box(Color(SEA_DEEP,0.48),Color(0.90,0.97,0.99,0.16),1,18),best_card)
