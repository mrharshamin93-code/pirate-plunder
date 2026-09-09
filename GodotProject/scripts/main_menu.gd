extends ColorRect

const GOLD: Color = Color("f4c64d")
const GOLD_DARK: Color = Color("9b5c16")
const WOOD: Color = Color("3a2115")
const WOOD_LIGHT: Color = Color("5b3520")
const RED: Color = Color("8d1718")

var play_button: Button

func _ready() -> void:
	color = Color("052f43")
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
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
	title.text = "PIRATE'S\nPLUNDER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	add_child(title)

	var subtitle: Label = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "COLLECT TREASURE • DODGE THE DEPTHS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("d9f4fb"))
	add_child(subtitle)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "⚔  PLAY"
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.add_theme_font_size_override("font_size", 28)
	play_button.add_theme_color_override("font_color", Color("fff2b2"))
	play_button.add_theme_stylebox_override("normal", _button_box(RED, GOLD, 4, 14))
	play_button.add_theme_stylebox_override("hover", _button_box(Color("a51e1f"), Color("ffd86a"), 4, 14))
	play_button.add_theme_stylebox_override("pressed", _button_box(Color("671011"), GOLD_DARK, 4, 14))
	play_button.pressed.connect(_on_play_pressed)
	add_child(play_button)

	var hint: Label = Label.new()
	hint.name = "Hint"
	hint.text = "STEER WITH THE JOYSTICK • GRAB COINS • SURVIVE"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.78, 0.91, 0.95, 0.72))
	add_child(hint)

	_layout_ui()

func _layout_ui() -> void:
	var w: float = size.x
	var h: float = size.y
	var sx: float = w / 390.0
	var title: Control = get_node_or_null("GameTitle") as Control
	if title:
		title.position = Vector2(28.0 * sx, h * 0.20)
		title.size = Vector2(w - 56.0 * sx, 145.0)
	var subtitle: Control = get_node_or_null("Subtitle") as Control
	if subtitle:
		subtitle.position = Vector2(22.0 * sx, h * 0.39)
		subtitle.size = Vector2(w - 44.0 * sx, 30.0)
	if play_button:
		play_button.position = Vector2(72.0 * sx, h * 0.52)
		play_button.size = Vector2(w - 144.0 * sx, 68.0)
	var hint: Control = get_node_or_null("Hint") as Control
	if hint:
		hint.position = Vector2(26.0 * sx, h * 0.65)
		hint.size = Vector2(w - 52.0 * sx, 28.0)

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

func _button_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
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

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, Vector2(w, h)), Color("052f43"))
	for i in range(9):
		var y: float = 40.0 + float(i) * h / 9.0
		var x: float = 30.0 + float((i * 73) % 320)
		draw_circle(Vector2(x, y), 3.0 + float(i % 3), Color(0.55, 0.92, 1.0, 0.12))
	var plaque: Rect2 = Rect2(30.0, h * 0.17, w - 60.0, 190.0)
	draw_style_box(_button_box(WOOD, GOLD_DARK, 4, 18), plaque)
	for yy in [plaque.position.y + 36.0, plaque.position.y + 94.0, plaque.position.y + 152.0]:
		draw_line(Vector2(42.0, yy), Vector2(w - 42.0, yy), Color(WOOD_LIGHT, 0.42), 2.0)
	for p in [Vector2(46.0, plaque.position.y + 18.0), Vector2(w - 46.0, plaque.position.y + 18.0), Vector2(46.0, plaque.end.y - 18.0), Vector2(w - 46.0, plaque.end.y - 18.0)]:
		draw_circle(p, 5.0, GOLD)
		draw_arc(p, 5.0, 0.0, TAU, 18, GOLD_DARK, 1.3, true)
