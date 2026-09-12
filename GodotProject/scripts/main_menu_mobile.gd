extends "res://scripts/main_menu.gd"

const DESIGN_SIZE: Vector2 = Vector2(853.0, 1844.0)
const API_URL: String = "https://pirate-plunder.vercel.app/api/leaderboard"
const SAVE_PATH: String = "user://leaderboard.cfg"

const PLAY_RECT: Rect2 = Rect2(168, 900, 495, 145)
const LEADERBOARD_RECT: Rect2 = Rect2(168, 1063, 495, 130)
const SETTINGS_RECT: Rect2 = Rect2(30, 48, 88, 106)
const COLLECTIBLES_ART_RECT: Rect2 = Rect2(168, 1213, 495, 130)
const CLEAN_OCEAN_SOURCE: Rect2 = Rect2(168, 760, 495, 130)

var exact_bg: TextureRect
var collectibles_cover: TextureRect
var menu_popup: Control
var button_map: Dictionary = {}

var board_page: Control = null
var board_rows: VBoxContainer = null
var board_status: Label = null
var board_http: HTTPRequest = null
var leaderboard_tab: Button = null
var rank_tab: Button = null
var active_tab: String = "leaderboard"
var latest_top: Array = []
var latest_rank_window: Array = []
var latest_personal_rank: int = 0

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	# Remove the baked Collectibles button from the image itself.
	collectibles_cover = TextureRect.new()
	collectibles_cover.name = "CollectiblesRemovalPatch"
	var patch_atlas := AtlasTexture.new()
	patch_atlas.atlas = exact_bg.texture
	patch_atlas.region = CLEAN_OCEAN_SOURCE
	collectibles_cover.texture = patch_atlas
	collectibles_cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	collectibles_cover.stretch_mode = TextureRect.STRETCH_SCALE
	collectibles_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(collectibles_cover)

	play_button = _create_button("PlayButton", PLAY_RECT, Callable(self, "_start_game_action"))
	_create_button("LeaderboardButton", LEADERBOARD_RECT, Callable(self, "_open_fresh_leaderboard"))
	_create_button("SettingsButton", SETTINGS_RECT, Callable(self, "_open_settings"))
	_layout_ui()

func _transparent_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = Color(0, 0, 0, 0)
	box.set_border_width_all(0)
	return box

func _create_button(button_name: String, design_rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_meta("design_rect", design_rect)
	var transparent: StyleBoxFlat = _transparent_box()
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("focus", transparent)
	add_child(button)

	var overlay := ColorRect.new()
	overlay.name = "%sFeedback" % button_name
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	button_map[button_name] = {"button": button, "overlay": overlay, "pressed": false}
	button.pressed.connect(func() -> void: action.call())
	button.button_down.connect(func() -> void: _set_pressed(button_name, true))
	button.button_up.connect(func() -> void: _set_pressed(button_name, false))
	button.mouse_exited.connect(func() -> void: _set_pressed(button_name, false))
	return button

func _set_pressed(button_name: String, pressed: bool) -> void:
	if not button_map.has(button_name):
		return
	var entry: Dictionary = button_map[button_name]
	entry["pressed"] = pressed
	button_map[button_name] = entry
	var overlay: ColorRect = entry["overlay"] as ColorRect
	overlay.color = Color(0, 0, 0, 0.18) if pressed else Color(0, 0, 0, 0)
	_layout_ui()

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size
	var scale_factor: float = maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var drawn_size: Vector2 = DESIGN_SIZE * scale_factor
	var offset: Vector2 = (size - drawn_size) * 0.5

	if collectibles_cover != null:
		collectibles_cover.position = offset + COLLECTIBLES_ART_RECT.position * scale_factor
		collectibles_cover.size = COLLECTIBLES_ART_RECT.size * scale_factor

	for key: Variant in button_map.keys():
		var entry: Dictionary = button_map[String(key)]
		var button: Button = entry["button"] as Button
		var overlay: ColorRect = entry["overlay"] as ColorRect
		var design_rect: Rect2 = button.get_meta("design_rect") as Rect2
		var rect_pos: Vector2 = offset + design_rect.position * scale_factor
		var rect_size: Vector2 = design_rect.size * scale_factor
		if bool(entry.get("pressed", false)):
			rect_pos.y += 2.0
		button.position = rect_pos
		button.size = rect_size
		overlay.position = rect_pos
		overlay.size = rect_size
		overlay.move_to_front()
		button.move_to_front()

	if board_page != null and is_instance_valid(board_page):
		board_page.size = size
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.size = size

func _start_game_action() -> void:
	_start_from_menu()

func _open_settings() -> void:
	_show_popup("SETTINGS", "Settings page coming soon.")

func _open_fresh_leaderboard() -> void:
	active_tab = "leaderboard"
	if board_page != null and is_instance_valid(board_page):
		board_page.visible = true
		board_page.move_to_front()
		_request_board_data()
		return
	_build_board_page()
	_request_board_data()

func _build_board_page() -> void:
	board_page = Control.new()
	board_page.name = "FreshLeaderboardPage"
	board_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_page.mouse_filter = Control.MOUSE_FILTER_STOP
	board_page.z_index = 50000
	add_child(board_page)

	var background := ColorRect.new()
	background.color = Color("071923")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_page.add_child(background)

	var title := Label.new()
	title.text = "☠  PIRATE LEADERBOARD"
	title.position = Vector2(24, 48)
	title.size = Vector2(342, 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("f6d18a"))
	board_page.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.position = Vector2(44, 122)
	tabs.size = Vector2(302, 44)
	tabs.add_theme_constant_override("separation", 8)
	board_page.add_child(tabs)

	leaderboard_tab = Button.new()
	leaderboard_tab.text = "LEADERBOARD"
	leaderboard_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_tab.focus_mode = Control.FOCUS_NONE
	leaderboard_tab.pressed.connect(func() -> void:
		active_tab = "leaderboard"
		_refresh_board_view()
	)
	tabs.add_child(leaderboard_tab)

	rank_tab = Button.new()
	rank_tab.text = "RANK"
	rank_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_tab.focus_mode = Control.FOCUS_NONE
	rank_tab.pressed.connect(func() -> void:
		active_tab = "rank"
		_refresh_board_view()
	)
	tabs.add_child(rank_tab)

	var parchment := Panel.new()
	parchment.position = Vector2(28, 184)
	parchment.size = Vector2(334, 520)
	var parchment_style := StyleBoxFlat.new()
	parchment_style.bg_color = Color("e8c989")
	parchment_style.border_color = Color("9b5c16")
	parchment_style.set_border_width_all(3)
	parchment_style.set_corner_radius_all(14)
	parchment.add_theme_stylebox_override("panel", parchment_style)
	board_page.add_child(parchment)

	board_rows = VBoxContainer.new()
	board_rows.position = Vector2(14, 14)
	board_rows.size = Vector2(306, 470)
	board_rows.add_theme_constant_override("separation", 4)
	parchment.add_child(board_rows)

	board_status = Label.new()
	board_status.position = Vector2(36, 716)
	board_status.size = Vector2(318, 28)
	board_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_status.add_theme_font_size_override("font_size", 12)
	board_status.add_theme_color_override("font_color", Color("d9f4fb"))
	board_page.add_child(board_status)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(120, 762)
	back.size = Vector2(150, 48)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: board_page.visible = false)
	board_page.add_child(back)

	board_http = HTTPRequest.new()
	board_http.name = "FreshLeaderboardRequest"
	board_page.add_child(board_http)
	board_http.request_completed.connect(_on_board_loaded)

func _request_board_data() -> void:
	if board_rows == null or board_status == null:
		return
	_clear_board_rows()
	board_status.text = "Loading leaderboard..."
	var loading := Label.new()
	loading.text = "LOADING..."
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.custom_minimum_size = Vector2(0, 48)
	loading.add_theme_color_override("font_color", Color("24160f"))
	board_rows.add_child(loading)
	if board_http == null or board_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var player_id: String = ""
	var local_best: int = 0
	var player_name: String = ""
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		player_id = String(cfg.get_value("player", "id", ""))
		local_best = int(cfg.get_value("player", "personal_best", 0))
		player_name = String(cfg.get_value("player", "name", "")).strip_edges()
	var url: String = API_URL
	if not player_id.is_empty():
		url += "?playerId=%s" % player_id.uri_encode()
		if local_best > 0:
			url += "&localBest=%d" % local_best
		if not player_name.is_empty():
			url += "&playerName=%s" % player_name.uri_encode()
	var err: Error = board_http.request(url)
	if err != OK:
		board_status.text = "Leaderboard unavailable"

func _on_board_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	latest_top.clear()
	latest_rank_window.clear()
	latest_personal_rank = 0
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		board_status.text = "Leaderboard unavailable"
		_clear_board_rows()
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed is Array:
		latest_top = parsed as Array
	elif parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		for key: String in ["leaderboard", "top10", "top", "scores", "entries"]:
			var candidate: Variant = data.get(key, null)
			if candidate is Array:
				latest_top = candidate as Array
				break
		var rank_candidate: Variant = data.get("rankWindow", [])
		if rank_candidate is Array:
			latest_rank_window = rank_candidate as Array
		latest_personal_rank = int(data.get("personalRank", 0))
	_refresh_board_view()

func _refresh_board_view() -> void:
	if board_rows == null or board_status == null:
		return
	_clear_board_rows()
	if leaderboard_tab != null:
		leaderboard_tab.disabled = active_tab == "leaderboard"
	if rank_tab != null:
		rank_tab.disabled = active_tab == "rank"
	if active_tab == "rank":
		_build_rank_rows()
	else:
		_build_top_rows()

func _build_top_rows() -> void:
	if latest_top.is_empty():
		board_status.text = "No scores yet"
		return
	var count: int = mini(10, latest_top.size())
	for i: int in range(count):
		var raw: Variant = latest_top[i]
		if raw is Dictionary:
			_add_score_row(i + 1, raw as Dictionary, false)
	board_status.text = "Global top 10"

func _build_rank_rows() -> void:
	if latest_rank_window.is_empty() or latest_personal_rank <= 0:
		var empty := Label.new()
		empty.text = "PLAY A RUN TO ESTABLISH YOUR RANK"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 70)
		empty.add_theme_color_override("font_color", Color("24160f"))
		board_rows.add_child(empty)
		board_status.text = "Your rank"
		return
	for raw: Variant in latest_rank_window:
		if raw is Dictionary:
			var entry: Dictionary = raw as Dictionary
			_add_score_row(int(entry.get("rank", 0)), entry, bool(entry.get("isYou", false)))
	board_status.text = "Your rank: #%d" % latest_personal_rank

func _add_score_row(rank_value: int, entry: Dictionary, highlight: bool) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 38)
	if highlight:
		var hi := StyleBoxFlat.new()
		hi.bg_color = Color("5b3520")
		hi.border_color = Color("f4c64d")
		hi.set_border_width_all(2)
		hi.set_corner_radius_all(6)
		row.add_theme_stylebox_override("panel", hi)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	row.add_child(h)
	var rank_label := Label.new()
	rank_label.text = "#%d" % rank_value
	rank_label.custom_minimum_size = Vector2(44, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.add_theme_color_override("font_color", Color("fff3c8") if highlight else Color("24160f"))
	h.add_child(rank_label)
	var name_label := Label.new()
	name_label.text = String(entry.get("name", entry.get("playerName", "Pirate")))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_color_override("font_color", Color("fff3c8") if highlight else Color("24160f"))
	h.add_child(name_label)
	var score_label := Label.new()
	score_label.text = _comma(int(entry.get("score", entry.get("bestScore", 0))))
	score_label.custom_minimum_size = Vector2(80, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_color_override("font_color", Color("fff3c8") if highlight else Color("24160f"))
	h.add_child(score_label)
	board_rows.add_child(row)

func _clear_board_rows() -> void:
	if board_rows == null:
		return
	for child: Node in board_rows.get_children():
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
