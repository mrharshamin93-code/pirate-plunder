extends ColorRect

const SEA_DEEP: Color = Color("082e3c")
const SEA_MID: Color = Color("125a6e")
const SEA_LIGHT: Color = Color("1f7d92")
const CREST: Color = Color("4fb6cc")
const FOAM: Color = Color("d9f4fb")
const INK: Color = Color("0a1a20")
const WOOD: Color = Color("9a6231")
const WOOD_DARK: Color = Color("6b3f1c")
const WOOD_LIGHT: Color = Color("c58c50")
const DECK: Color = Color("b47a42")
const BANDANA: Color = Color("c8322f")
const MINE_BODY: Color = Color("25292e")
const MINE_SHADE: Color = Color("12161a")
const MINE_LIGHT: Color = Color("555f68")
const MINE_RUST: Color = Color("8d3a24")
const MINE_LAMP: Color = Color("ffd24a")
const ACCENT: Color = Color("f4c64d")

const COIN_SPRITES: Array[Vector3] = [
	Vector3(164, 427, 306), Vector3(474, 427, 302), Vector3(780, 427, 302),
	Vector3(165, 848, 316), Vector3(483, 849, 320), Vector3(1090, 427, 302),
	Vector3(872, 844, 386)
]
const COIN_VALUES: Array[int] = [10, 25, 50, 100, 250, 500, 1000]

var play_button: Button
var coin_sheet: Texture2D

func _ready() -> void:
	color = Color(0, 0, 0, 0)
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

func _build_ui() -> void:
	var title: Label = Label.new()
	title.name = "GameTitle"
	title.text = "Pirate’s Plunder"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 43)
	title.add_theme_color_override("font_color", Color("f4fbfd"))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.08, 0.11, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 3)
	add_child(title)

	var story: Label = Label.new()
	story.name = "Story"
	story.text = "You are Captain Marlow, rowing through the wreckage of Blackwake Harbor. Salvage the treasure and stay clear of the homing mines fired from the Dreadwake."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 14)
	story.add_theme_color_override("font_color", Color(0.90, 0.97, 0.99, 0.82))
	add_child(story)

	var coin_title: Label = Label.new()
	coin_title.name = "CoinTitle"
	coin_title.text = "COIN VALUES"
	coin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coin_title.add_theme_font_size_override("font_size", 13)
	coin_title.add_theme_color_override("font_color", Color(0.90, 0.97, 0.99, 0.72))
	add_child(coin_title)

	for i in range(COIN_VALUES.size()):
		var value_label: Label = Label.new()
		value_label.name = "CoinValue%d" % i
		value_label.text = _comma(COIN_VALUES[i])
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", Color(0.90, 0.97, 0.99, 0.78))
		add_child(value_label)

	var instructions: Label = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Push the thumbstick to point her where you want to go — she holds her line and answers the helm quickly. Every coin you take sends another mine after you."
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 13)
	instructions.add_theme_color_override("font_color", Color(0.90, 0.97, 0.99, 0.72))
	add_child(instructions)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "Set Sail"
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.add_theme_color_override("font_color", Color("f6fbfc"))
	play_button.add_theme_stylebox_override("normal", _round_box(Color("14758a"), Color(0.85, 0.96, 0.99, 0.22), 1, 14))
	play_button.add_theme_stylebox_override("hover", _round_box(Color("18869c"), Color(0.90, 0.98, 1.0, 0.36), 1, 14))
	play_button.add_theme_stylebox_override("pressed", _round_box(Color("0d596c"), Color(0.78, 0.93, 0.97, 0.22), 1, 14))
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

	_layout_ui()

func _layout_ui() -> void:
	var w: float = size.x
	var h: float = size.y
	var sx: float = w / 390.0
	var title: Control = get_node_or_null("GameTitle") as Control
	if title:
		title.position = Vector2(20.0 * sx, 218.0)
		title.size = Vector2(w - 40.0 * sx, 58.0)
	var story: Control = get_node_or_null("Story") as Control
	if story:
		story.position = Vector2(24.0 * sx, 278.0)
		story.size = Vector2(w - 48.0 * sx, 92.0)
	var coin_title: Control = get_node_or_null("CoinTitle") as Control
	if coin_title:
		coin_title.position = Vector2(28.0 * sx, 397.0)
		coin_title.size = Vector2(w - 56.0 * sx, 24.0)
	var coin_left: float = 24.0 * sx
	var coin_width: float = w - 48.0 * sx
	var slot: float = coin_width / 7.0
	for i in range(COIN_VALUES.size()):
		var value_label: Control = get_node_or_null("CoinValue%d" % i) as Control
		if value_label:
			value_label.position = Vector2(coin_left + slot * float(i), 473.0)
			value_label.size = Vector2(slot, 20.0)
	var instructions: Control = get_node_or_null("Instructions") as Control
	if instructions:
		instructions.position = Vector2(25.0 * sx, 535.0)
		instructions.size = Vector2(w - 50.0 * sx, 86.0)
	if play_button:
		play_button.position = Vector2(46.0 * sx, minf(h - 112.0, 665.0))
		play_button.size = Vector2(w - 92.0 * sx, 54.0)

func _on_play_pressed() -> void:
	play_button.disabled = true
	_set_gameplay_ui_visible(true)
	visible = false
	var game: Node = get_parent().get_parent()
	if game != null and game.has_method("_start_game"):
		game.call("_start_game")

func _set_gameplay_ui_visible(show_ui: bool) -> void:
	var canvas: Node = get_parent()
	var hud: CanvasItem = canvas.get_node_or_null("HUD") as CanvasItem
	var joystick: CanvasItem = canvas.get_node_or_null("Joystick") as CanvasItem
	var hud_art: CanvasItem = canvas.get_node_or_null("HudArt") as CanvasItem
	if hud:
		hud.visible = show_ui
	if joystick:
		joystick.visible = show_ui
	if hud_art:
		hud_art.visible = show_ui

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
	box.content_margin_left = 10.0
	box.content_margin_right = 10.0
	return box

func _draw_boat(center: Vector2, scale: float) -> void:
	var hull: PackedVector2Array = PackedVector2Array([
		center + Vector2(30,0) * scale,
		center + Vector2(18,-13) * scale,
		center + Vector2(-12,-15) * scale,
		center + Vector2(-24,0) * scale,
		center + Vector2(-12,15) * scale,
		center + Vector2(18,13) * scale
	])
	draw_colored_polygon(hull, WOOD_DARK)
	var deck: PackedVector2Array = PackedVector2Array([
		center + Vector2(22,0) * scale,
		center + Vector2(13,-10) * scale,
		center + Vector2(-10,-11) * scale,
		center + Vector2(-19,0) * scale,
		center + Vector2(-10,11) * scale,
		center + Vector2(13,10) * scale
	])
	draw_colored_polygon(deck, DECK)
	draw_polyline(PackedVector2Array([hull[0], hull[1], hull[2], hull[3], hull[4], hull[5], hull[0]]), INK, 2.2 * scale, true)
	draw_line(center + Vector2(-4,-9) * scale, center + Vector2(-17,-30) * scale, WOOD, 3.5 * scale, true)
	draw_line(center + Vector2(-4,9) * scale, center + Vector2(-17,30) * scale, WOOD, 3.5 * scale, true)
	draw_circle(center + Vector2(-4,0) * scale, 6.2 * scale, Color("57a94a"))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9,-5)*scale, center + Vector2(-16,-5)*scale, center + Vector2(-10,1)*scale]), BANDANA)

func _draw_mine(center: Vector2, scale: float) -> void:
	var body_r: float = 13.0 * scale
	for i in range(10):
		var a: float = float(i) / 10.0 * TAU
		var tip: Vector2 = center + Vector2(cos(a), sin(a)) * 22.0 * scale
		var b1: Vector2 = center + Vector2(cos(a - 0.2), sin(a - 0.2)) * body_r
		var b2: Vector2 = center + Vector2(cos(a + 0.2), sin(a + 0.2)) * body_r
		draw_colored_polygon(PackedVector2Array([tip, b1, b2]), MINE_BODY)
	draw_circle(center, body_r, MINE_SHADE)
	draw_circle(center + Vector2(-3,-3) * scale, 10.5 * scale, MINE_BODY)
	draw_arc(center, body_r, 0.0, TAU, 24, INK, 1.6 * scale, true)
	draw_arc(center, body_r - 1.0, 0.15, PI - 0.15, 16, MINE_RUST, 2.3 * scale, true)
	draw_circle(center + Vector2(0,-4) * scale, 3.2 * scale, MINE_LAMP)

func _draw_raider(center: Vector2, scale: float) -> void:
	draw_line(center + Vector2(-22,6)*scale, center + Vector2(-22,-46)*scale, INK, 3.0*scale, true)
	draw_line(center + Vector2(0,8)*scale, center + Vector2(0,-56)*scale, INK, 3.0*scale, true)
	draw_line(center + Vector2(22,6)*scale, center + Vector2(22,-42)*scale, INK, 3.0*scale, true)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-20,-44)*scale, center+Vector2(-2,-36)*scale, center+Vector2(-20,-8)*scale]), INK)
	draw_colored_polygon(PackedVector2Array([center+Vector2(2,-54)*scale, center+Vector2(24,-42)*scale, center+Vector2(2,-6)*scale]), INK)
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-56)*scale, center+Vector2(18,-50)*scale, center+Vector2(0,-46)*scale]), BANDANA)
	var hull: PackedVector2Array = PackedVector2Array([center+Vector2(-46,6)*scale, center+Vector2(46,6)*scale, center+Vector2(40,18)*scale, center+Vector2(26,26)*scale, center+Vector2(-28,26)*scale, center+Vector2(-42,22)*scale])
	draw_colored_polygon(hull, INK)
	draw_line(center+Vector2(-44,10)*scale, center+Vector2(44,10)*scale, WOOD_DARK, 2.5*scale, true)

func _comma(value: int) -> String:
	var s: String = str(value)
	var out: String = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# Layered sea field matching the original menu's OceanBackground.
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), SEA_DEEP)
	for i in range(12):
		var y: float = 55.0 + float(i) * 65.0
		var x: float = 18.0 + float((i * 83) % 330)
		var width: float = 42.0 + float((i * 19) % 46)
		draw_arc(Vector2(x + width * 0.5, y), width * 0.5, PI + 0.28, TAU - 0.28, 18, Color(CREST, 0.28), 2.4, true)
	for i in range(8):
		var fx: float = 30.0 + float((i * 71) % 335)
		var fy: float = 72.0 + float((i * 97) % 690)
		draw_circle(Vector2(fx, fy), 2.5, Color(FOAM, 0.30))
	# Original hero collage: Marlow's boat, mine, and the Dreadwake raider ship.
	_draw_boat(Vector2(w * 0.22, 132.0), 0.82)
	_draw_mine(Vector2(w * 0.47, 130.0), 0.92)
	_draw_raider(Vector2(w * 0.73, 117.0), 0.78)
	# Coin-values card.
	var card: Rect2 = Rect2(16.0, 382.0, w - 32.0, 126.0)
	draw_style_box(_round_box(Color(SEA_DEEP, 0.62), Color(0.90,0.97,0.99,0.18), 1, 20), card)
	if coin_sheet:
		var coin_left: float = 24.0
		var coin_width: float = w - 48.0
		var slot: float = coin_width / 7.0
		for i in range(COIN_SPRITES.size()):
			var sp: Vector3 = COIN_SPRITES[i]
			var src: Rect2 = Rect2(sp.x - sp.z * 0.5, sp.y - sp.z * 0.5, sp.z, sp.z)
			var cx: float = coin_left + slot * (float(i) + 0.5)
			draw_texture_rect_region(coin_sheet, Rect2(cx - 18.0, 432.0, 36.0, 36.0), src)
