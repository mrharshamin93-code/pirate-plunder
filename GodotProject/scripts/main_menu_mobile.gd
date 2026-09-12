extends "res://scripts/main_menu.gd"

const MOCKUP_W := 390.0
const MOCKUP_H := 844.0

var exact_bg: TextureRect
var leaderboard_button: Button
var how_to_play_button: Button
var trophy_button: Button
var button_visuals: Dictionary = {}

func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false

	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.jpg")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_SCALE
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)
	exact_bg.move_to_front()

	play_button.visible = true
	_make_live_button(play_button, Rect2(77, 399, 230, 90))
	play_button.move_to_front()

	leaderboard_button = Button.new()
	leaderboard_button.name = "LeaderboardButton"
	add_child(leaderboard_button)
	_make_live_button(leaderboard_button, Rect2(80, 504, 228, 69))
	leaderboard_button.pressed.connect(_show_leaderboard_info)
	leaderboard_button.move_to_front()

	how_to_play_button = Button.new()
	how_to_play_button.name = "HowToPlayButton"
	add_child(how_to_play_button)
	_make_live_button(how_to_play_button, Rect2(81, 585, 229, 69))
	how_to_play_button.pressed.connect(_show_how_to_play)
	how_to_play_button.move_to_front()

	trophy_button = Button.new()
	trophy_button.name = "CollectiblesButton"
	add_child(trophy_button)
	_make_live_button(trophy_button, Rect2(319, 8, 55, 86))
	trophy_button.pressed.connect(_open_collectibles)
	trophy_button.move_to_front()

	_layout_exact()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_exact")

func _layout_ui() -> void:
	if exact_bg != null:
		_layout_exact()

func _make_live_button(button: Button, base_rect: Rect2) -> void:
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.modulate = Color(1, 1, 1, 0.01)
	button.set_meta("exact_rect", base_rect)

	# Put a real visual layer over the baked-in button artwork. It uses the exact
	# crop from the approved mockup, but can now animate independently when tapped.
	var art := TextureRect.new()
	art.name = "%sArt" % button.name
	var atlas := AtlasTexture.new()
	atlas.atlas = exact_bg.texture
	atlas.region = base_rect
	art.texture = atlas
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_meta("exact_rect", base_rect)
	add_child(art)
	button_visuals[button] = art

	button.button_down.connect(_press_visual.bind(button))
	button.button_up.connect(_release_visual.bind(button))
	button.mouse_entered.connect(_hover_visual.bind(button, true))
	button.mouse_exited.connect(_hover_visual.bind(button, false))

func _press_visual(button: Button) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null:
		return
	art.modulate = Color(0.82, 0.82, 0.82, 1.0)
	art.scale = Vector2(0.965, 0.965)

func _release_visual(button: Button) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null:
		return
	art.modulate = Color.WHITE
	art.scale = Vector2.ONE

func _hover_visual(button: Button, hovering: bool) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null or button.button_pressed:
		return
	art.modulate = Color(1.06, 1.06, 1.06, 1.0) if hovering else Color.WHITE

func _layout_exact() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size
	var sx := size.x / MOCKUP_W
	var sy := size.y / MOCKUP_H
	for button in [play_button, leaderboard_button, how_to_play_button, trophy_button]:
		if button != null and button.has_meta("exact_rect"):
			var r: Rect2 = button.get_meta("exact_rect")
			button.position = Vector2(r.position.x * sx, r.position.y * sy)
			button.size = Vector2(r.size.x * sx, r.size.y * sy)
			var art := button_visuals.get(button) as TextureRect
			if art != null:
				art.position = button.position
				art.size = button.size
				art.pivot_offset = art.size * 0.5
				art.move_to_front()
				button.move_to_front()

func _open_collectibles() -> void:
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("open_from_menu"):
		collectibles.call("open_from_menu", self)

func _show_leaderboard_info() -> void:
	_show_simple_popup("LEADERBOARD", "Your leaderboard and rank are shown after each run on the SUNK screen.")

func _show_how_to_play() -> void:
	_show_simple_popup("HOW TO PLAY", "Steer the ship with the thumbstick. Collect treasure, avoid the homing mines, and escape the whirlpool pull. Every coin increases the danger. Survive as long as you can and chase a new high score.")

func _show_simple_popup(title_text: String, body_text: String) -> void:
	var old := get_node_or_null("ExactInfoPopup")
	if old != null:
		old.queue_free()
	var popup := Control.new()
	popup.name = "ExactInfoPopup"
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 40000
	add_child(popup)
	popup.move_to_front()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.add_child(dim)

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-165, -160)
	panel.size = Vector2(330, 320)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("10202a")
	sb.border_color = Color("9d672e")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	popup.add_child(panel)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(20, 20)
	title.size = Vector2(290, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("f6d18a"))
	panel.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.position = Vector2(28, 76)
	body.size = Vector2(274, 155)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color("eef7fa"))
	panel.add_child(body)

	var close := Button.new()
	close.text = "BACK"
	close.position = Vector2(90, 250)
	close.size = Vector2(150, 44)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): popup.queue_free())
	panel.add_child(close)
