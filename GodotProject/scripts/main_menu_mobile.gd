extends "res://scripts/main_menu.gd"

const DESIGN_SIZE := Vector2(853.0, 1844.0)

# Button hitboxes measured against main_menu_exact.png.
const PLAY_RECT := Rect2(140, 1096, 548, 126)
const LEADERBOARD_RECT := Rect2(140, 1278, 548, 126)
const COLLECTIBLES_RECT := Rect2(140, 1459, 548, 126)
const SETTINGS_RECT := Rect2(18, 27, 96, 121)

var exact_bg: TextureRect
var menu_popup: Control
var button_map: Dictionary = {}

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	_create_dynamic_button("PlayButton", PLAY_RECT, Callable(self, "_start_game_action"))
	_create_dynamic_button("LeaderboardButton", LEADERBOARD_RECT, Callable(self, "_open_leaderboard_action"))
	_create_dynamic_button("CollectiblesButton", COLLECTIBLES_RECT, Callable(self, "_open_collectibles_action"))
	_create_dynamic_button("SettingsButton", SETTINGS_RECT, Callable(self, "_open_settings_action"))

	_layout_ui()

func _create_dynamic_button(button_name: String, design_rect: Rect2, action: Callable) -> void:
	var btn := Button.new()
	btn.name = button_name
	btn.text = ""
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.modulate = Color(1, 1, 1, 0.01)
	btn.set_meta("design_rect", design_rect)
	add_child(btn)

	var overlay := ColorRect.new()
	overlay.name = "%sOverlay" % button_name
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = true
	add_child(overlay)

	button_map[button_name] = {"button": btn, "overlay": overlay, "action": action, "pressed": false}

	btn.pressed.connect(func(): action.call())
	btn.button_down.connect(func(): _set_button_state(button_name, true, false))
	btn.button_up.connect(func(): _set_button_state(button_name, false, false))
	btn.mouse_entered.connect(func(): _set_button_state(button_name, false, true))
	btn.mouse_exited.connect(func(): _set_button_state(button_name, false, false))

func _set_button_state(button_name: String, is_pressed: bool, is_hover: bool) -> void:
	if not button_map.has(button_name):
		return
	var entry: Dictionary = button_map[button_name]
	entry["pressed"] = is_pressed
	var overlay: ColorRect = entry["overlay"]
	var btn: Button = entry["button"]
	if is_pressed:
		overlay.color = Color(0, 0, 0, 0.18)
		btn.position.y += 2
	elif is_hover:
		overlay.color = Color(1, 1, 1, 0.06)
	else:
		overlay.color = Color(0, 0, 0, 0)
	_layout_ui()

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size

	var scale := max(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var drawn_size := DESIGN_SIZE * scale
	var offset := (size - drawn_size) * 0.5

	for key in button_map.keys():
		var entry: Dictionary = button_map[key]
		var btn: Button = entry["button"]
		var overlay: ColorRect = entry["overlay"]
		var design_rect: Rect2 = btn.get_meta("design_rect")
		var rect := Rect2(offset + design_rect.position * scale, design_rect.size * scale)
		btn.position = rect.position
		btn.size = rect.size
		overlay.position = rect.position
		overlay.size = rect.size
		var pressed: bool = entry.get("pressed", false)
		if pressed:
			btn.position.y += 2
			overlay.position.y += 2

	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.size = size

func _start_game_action() -> void:
	if has_method("_start_from_menu"):
		call("_start_from_menu")
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _open_collectibles_action() -> void:
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null:
		if collectibles.has_method("open_from_menu"):
			collectibles.call("open_from_menu", self)
		elif collectibles.has_method("_open_panel"):
			collectibles.call("_open_panel")

func _open_leaderboard_action() -> void:
	var badge := get_node_or_null("/root/LeaderboardRankBadge")
	if badge != null:
		if badge.has_method("show_leaderboard_popup"):
			badge.call("show_leaderboard_popup", self)
			return
		if badge.has_method("open_leaderboard_page"):
			badge.call("open_leaderboard_page", self)
			return
	_show_popup("LEADERBOARD", "Open the leaderboard from the SUNK screen or connect the leaderboard page handler here.")

func _open_settings_action() -> void:
	_show_popup("SETTINGS", "Settings page coming soon.")

func _show_popup(title_text: String, body_text: String) -> void:
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.queue_free()
	menu_popup = Control.new()
	menu_popup.name = "MenuPopup"
	menu_popup.position = Vector2.ZERO
	menu_popup.size = size
	menu_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_popup.z_index = 50000
	add_child(menu_popup)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_popup.add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(size.x * 0.075, size.y * 0.28)
	panel.size = Vector2(size.x * 0.85, minf(300.0, size.y * 0.40))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2d1b12")
	sb.border_color = Color("b2763b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	menu_popup.add_child(panel)

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(18, 18)
	title.size = Vector2(panel.size.x - 36, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f7d48b"))
	panel.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.position = Vector2(24, 76)
	body.size = Vector2(panel.size.x - 48, 120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color("fff4dc"))
	panel.add_child(body)

	var close := Button.new()
	close.text = "BACK"
	close.position = Vector2((panel.size.x - 150) * 0.5, panel.size.y - 62)
	close.size = Vector2(150, 44)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func(): menu_popup.queue_free())
	panel.add_child(close)
