extends "res://scripts/main_menu.gd"

const DESIGN_SIZE: Vector2 = Vector2(853.0, 1844.0)
const API_URL: String = "https://pirate-plunder.vercel.app/api/leaderboard"
const LEADERBOARD_SAVE: String = "user://leaderboard.cfg"

# Exact button bounds measured from the uploaded 853x1844 main_menu_exact.png.
const PLAY_RECT: Rect2 = Rect2(168, 900, 495, 145)
const LEADERBOARD_RECT: Rect2 = Rect2(168, 1063, 495, 130)
const COLLECTIBLES_RECT: Rect2 = Rect2(168, 1213, 495, 130)
const SETTINGS_RECT: Rect2 = Rect2(30, 48, 88, 106)

var exact_bg: TextureRect
var menu_popup: Control
var button_map: Dictionary = {}
var leaderboard_overlay: Control = null
var leaderboard_rows: VBoxContainer = null
var leaderboard_status: Label = null
var leaderboard_http: HTTPRequest = null

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	# IMPORTANT: assign the inherited play_button variable so the original
	# MainMenu input/start logic continues to work.
	play_button = _create_dynamic_button("PlayButton", PLAY_RECT, Callable(self, "_start_game_action"))
	_create_dynamic_button("LeaderboardButton", LEADERBOARD_RECT, Callable(self, "_open_leaderboard_action"))
	_create_dynamic_button("CollectiblesButton", COLLECTIBLES_RECT, Callable(self, "_open_collectibles_action"))
	_create_dynamic_button("SettingsButton", SETTINGS_RECT, Callable(self, "_open_settings_action"))

	_layout_ui()

func _transparent_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = Color(0, 0, 0, 0)
	box.set_border_width_all(0)
	return box

func _create_dynamic_button(button_name: String, design_rect: Rect2, action: Callable) -> Button:
	var btn := Button.new()
	btn.name = button_name
	btn.text = ""
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.set_meta("design_rect", design_rect)
	var transparent := _transparent_box()
	btn.add_theme_stylebox_override("normal", transparent)
	btn.add_theme_stylebox_override("hover", transparent)
	btn.add_theme_stylebox_override("pressed", transparent)
	btn.add_theme_stylebox_override("focus", transparent)
	add_child(btn)

	var overlay := ColorRect.new()
	overlay.name = "%sOverlay" % button_name
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	button_map[button_name] = {
		"button": btn,
		"overlay": overlay,
		"pressed": false,
		"hover": false
	}

	btn.pressed.connect(func() -> void: action.call())
	btn.button_down.connect(func() -> void: _set_button_state(button_name, true, false))
	btn.button_up.connect(func() -> void: _set_button_state(button_name, false, false))
	btn.mouse_entered.connect(func() -> void: _set_button_state(button_name, false, true))
	btn.mouse_exited.connect(func() -> void: _set_button_state(button_name, false, false))
	btn.move_to_front()
	return btn

func _set_button_state(button_name: String, is_pressed: bool, is_hover: bool) -> void:
	if not button_map.has(button_name):
		return
	var entry: Dictionary = button_map[button_name]
	entry["pressed"] = is_pressed
	entry["hover"] = is_hover
	button_map[button_name] = entry
	var overlay: ColorRect = entry["overlay"] as ColorRect
	if is_pressed:
		overlay.color = Color(0, 0, 0, 0.20)
	elif is_hover:
		overlay.color = Color(1, 1, 1, 0.07)
	else:
		overlay.color = Color(0, 0, 0, 0)
	_layout_ui()

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size

	# Same math as STRETCH_KEEP_ASPECT_COVERED so the interactive regions stay
	# locked to the visible artwork on every phone aspect ratio.
	var scale_factor: float = maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var drawn_size: Vector2 = DESIGN_SIZE * scale_factor
	var offset: Vector2 = (size - drawn_size) * 0.5

	for key: Variant in button_map.keys():
		var entry: Dictionary = button_map[String(key)]
		var btn: Button = entry["button"] as Button
		var overlay: ColorRect = entry["overlay"] as ColorRect
		var design_rect: Rect2 = btn.get_meta("design_rect") as Rect2
		var rect_pos: Vector2 = offset + design_rect.position * scale_factor
		var rect_size: Vector2 = design_rect.size * scale_factor
		var pressed: bool = bool(entry.get("pressed", false))
		if pressed:
			rect_pos.y += 2.0
		btn.position = rect_pos
		btn.size = rect_size
		overlay.position = rect_pos
		overlay.size = rect_size
		overlay.move_to_front()
		btn.move_to_front()

	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.size = size
	if leaderboard_overlay != null and is_instance_valid(leaderboard_overlay):
		leaderboard_overlay.size = size

func _start_game_action() -> void:
	_start_from_menu()

func _open_collectibles_action() -> void:
	var collectibles: Node = get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("open_from_menu"):
		collectibles.call("open_from_menu", self)

func _open_leaderboard_action() -> void:
	_open_leaderboard_page()

func _open_settings_action() -> void:
	_show_popup("SETTINGS", "Settings page coming soon.")

func _open_leaderboard_page() -> void:
	if leaderboard_overlay != null and is_instance_valid(leaderboard_overlay):
		leaderboard_overlay.visible = true
		leaderboard_overlay.move_to_front()
		_request_leaderboard()
		return

	leaderboard_overlay = Control.new()
	leaderboard_overlay.name = "MainMenuLeaderboard"
	leaderboard_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_overlay.z_index = 50000
	add_child(leaderboard_overlay)

	var dim := ColorRect.new()
	dim.color = Color("071923")
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leaderboard_overlay.add_child(dim)

	var frame := Panel.new()
	frame.position = Vector2(18, 55)
	frame.size = Vector2(354, 730)
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("10202a")
	fs.border_color = Color("8b5b2d")
	fs.set_border_width_all(4)
	fs.set_corner_radius_all(18)
	frame.add_theme_stylebox_override("panel", fs)
	leaderboard_overlay.add_child(frame)

	var title := Label.new()
	title.text = "☠  LEADERBOARD"
	title.position = Vector2(20, 24)
	title.size = Vector2(314, 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("f6d18a"))
	frame.add_child(title)

	var sub := Label.new()
	sub.text = "GLOBAL TOP 10"
	sub.position = Vector2(20, 72)
	sub.size = Vector2(314, 26)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color("b9d7df"))
	frame.add_child(sub)

	var parchment := Panel.new()
	parchment.position = Vector2(22, 112)
	parchment.size = Vector2(310, 500)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("e8c989")
	ps.border_color = Color("9b5c16")
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	parchment.add_theme_stylebox_override("panel", ps)
	frame.add_child(parchment)

	leaderboard_rows = VBoxContainer.new()
	leaderboard_rows.position = Vector2(12, 12)
	leaderboard_rows.size = Vector2(286, 450)
	leaderboard_rows.add_theme_constant_override("separation", 4)
	parchment.add_child(leaderboard_rows)

	leaderboard_status = Label.new()
	leaderboard_status.position = Vector2(22, 620)
	leaderboard_status.size = Vector2(310, 28)
	leaderboard_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaderboard_status.add_theme_font_size_override("font_size", 12)
	leaderboard_status.add_theme_color_override("font_color", Color("d9f4fb"))
	frame.add_child(leaderboard_status)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(102, 661)
	back.size = Vector2(150, 48)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: leaderboard_overlay.visible = false)
	frame.add_child(back)

	leaderboard_http = HTTPRequest.new()
	leaderboard_http.name = "MenuLeaderboardRequest"
	leaderboard_overlay.add_child(leaderboard_http)
	leaderboard_http.request_completed.connect(_on_leaderboard_loaded)
	leaderboard_overlay.move_to_front()
	_request_leaderboard()

func _request_leaderboard() -> void:
	if leaderboard_rows == null or leaderboard_status == null:
		return
	_clear_leaderboard_rows()
	leaderboard_status.text = "Loading leaderboard..."
	var loading := Label.new()
	loading.text = "LOADING..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.custom_minimum_size = Vector2(0, 52)
	loading.add_theme_color_override("font_color", Color("24160f"))
	leaderboard_rows.add_child(loading)
	if leaderboard_http == null or leaderboard_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var player_id: String = ""
	var cfg := ConfigFile.new()
	if cfg.load(LEADERBOARD_SAVE) == OK:
		player_id = String(cfg.get_value("player", "id", ""))
	var url: String = API_URL
	if not player_id.is_empty():
		url += "?playerId=%s" % player_id.uri_encode()
	var err: Error = leaderboard_http.request(url)
	if err != OK:
		leaderboard_status.text = "Leaderboard unavailable"

func _on_leaderboard_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_clear_leaderboard_rows()
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		leaderboard_status.text = "Leaderboard unavailable"
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	var rows: Array = []
	if parsed is Array:
		rows = parsed as Array
	elif parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		for key: String in ["leaderboard", "top10", "top", "scores", "entries"]:
			var candidate: Variant = data.get(key, null)
			if candidate is Array:
				rows = candidate as Array
				break
	if rows.is_empty():
		leaderboard_status.text = "No scores yet"
		return
	var limit: int = mini(10, rows.size())
	for i: int in range(limit):
		var raw: Variant = rows[i]
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw as Dictionary
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 38)
		row.add_theme_constant_override("separation", 6)
		var rank := Label.new()
		rank.text = "#%d" % (i + 1)
		rank.custom_minimum_size = Vector2(42, 0)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(rank)
		var nm := Label.new()
		nm.text = String(entry.get("name", entry.get("playerName", "Pirate")))
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(nm)
		var score := Label.new()
		score.text = _comma(int(entry.get("score", entry.get("bestScore", 0))))
		score.custom_minimum_size = Vector2(82, 0)
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(score)
		leaderboard_rows.add_child(row)
	leaderboard_status.text = "Global top 10"

func _clear_leaderboard_rows() -> void:
	if leaderboard_rows == null:
		return
	for child: Node in leaderboard_rows.get_children():
		child.queue_free()

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
	close.pressed.connect(func() -> void: menu_popup.queue_free())
	panel.add_child(close)
