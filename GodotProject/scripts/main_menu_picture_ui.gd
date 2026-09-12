extends "res://scripts/main_menu_mobile.gd"

const MENU_GOLD: Color = Color("f4c64d")
const MENU_GOLD_DARK: Color = Color("9b5c16")
const MENU_PARCHMENT: Color = Color("e8c989")
const MENU_WOOD: Color = Color("3a2115")
const MENU_RED: Color = Color("8d1718")
const MENU_INK: Color = Color("24160f")

var picture_hitboxes: Dictionary = {}
var picture_feedback: Dictionary = {}
var picture_pressed: Dictionary = {}

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = ""
	play_button.flat = true
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.set_meta("design_rect", PLAY_RECT)
	var transparent := StyleBoxEmpty.new()
	play_button.add_theme_stylebox_override("normal", transparent)
	play_button.add_theme_stylebox_override("hover", transparent)
	play_button.add_theme_stylebox_override("pressed", transparent)
	play_button.add_theme_stylebox_override("focus", transparent)
	play_button.add_theme_stylebox_override("disabled", transparent)
	add_child(play_button)
	play_button.pressed.connect(_start_game_action)
	play_button.button_down.connect(func() -> void: _set_picture_feedback("play", true))
	play_button.button_up.connect(func() -> void: _set_picture_feedback("play", false))
	play_button.mouse_exited.connect(func() -> void: _set_picture_feedback("play", false))
	_add_feedback("play", PLAY_RECT)

	_add_picture_hitbox("leaderboard", LEADERBOARD_RECT, Callable(self, "_open_fresh_leaderboard"))
	_add_picture_hitbox("collectibles", COLLECTIBLES_RECT, Callable(self, "_open_collectibles"))
	_add_picture_hitbox("settings", SETTINGS_RECT, Callable(self, "_open_settings"))
	_layout_ui()

func _add_picture_hitbox(key: String, design_rect: Rect2, action: Callable) -> void:
	var hit := Control.new()
	hit.name = "%sHitbox" % key.capitalize()
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_meta("design_rect", design_rect)
	hit.set_meta("action", action)
	add_child(hit)
	picture_hitboxes[key] = hit
	_add_feedback(key, design_rect)
	hit.gui_input.connect(func(event: InputEvent) -> void: _handle_picture_input(key, hit, event))
	hit.mouse_exited.connect(func() -> void: _set_picture_feedback(key, false))

func _add_feedback(key: String, design_rect: Rect2) -> void:
	var feedback := TextureRect.new()
	feedback.name = "%sPressFeedback" % key.capitalize()
	var atlas := AtlasTexture.new()
	atlas.atlas = exact_bg.texture
	atlas.region = design_rect
	feedback.texture = atlas
	feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feedback.stretch_mode = TextureRect.STRETCH_SCALE
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.set_meta("design_rect", design_rect)
	feedback.set_meta("base_position", Vector2.ZERO)
	feedback.set_meta("base_size", Vector2.ZERO)
	add_child(feedback)
	picture_feedback[key] = feedback
	picture_pressed[key] = false

func _handle_picture_input(key: String, hit: Control, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_set_picture_feedback(key, touch.pressed)
		if not touch.pressed:
			var action: Callable = hit.get_meta("action") as Callable
			action.call()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_set_picture_feedback(key, mouse.pressed)
			if not mouse.pressed:
				var action: Callable = hit.get_meta("action") as Callable
				action.call()

func _set_picture_feedback(key: String, pressed: bool) -> void:
	if not picture_feedback.has(key):
		return
	picture_pressed[key] = pressed
	_apply_feedback_state(key)

func _apply_feedback_state(key: String) -> void:
	if not picture_feedback.has(key):
		return
	var feedback: TextureRect = picture_feedback[key] as TextureRect
	var base_position: Vector2 = feedback.get_meta("base_position") as Vector2
	var base_size: Vector2 = feedback.get_meta("base_size") as Vector2
	var pressed: bool = bool(picture_pressed.get(key, false))
	if pressed:
		var press_scale: float = 0.97
		var shrink_offset: Vector2 = base_size * (1.0 - press_scale) * 0.5
		feedback.position = base_position + shrink_offset + Vector2(0.0, 2.0)
		feedback.size = base_size * press_scale
		feedback.modulate = Color(1.06, 1.02, 0.90, 1.0)
	else:
		feedback.position = base_position
		feedback.size = base_size
		feedback.modulate = Color.WHITE

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size
	var scale_factor: float = maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var drawn_size: Vector2 = DESIGN_SIZE * scale_factor
	var offset: Vector2 = (size - drawn_size) * 0.5

	if play_button != null:
		var play_rect: Rect2 = play_button.get_meta("design_rect") as Rect2
		play_button.position = offset + play_rect.position * scale_factor
		play_button.size = play_rect.size * scale_factor

	for key: Variant in picture_hitboxes.keys():
		var hit: Control = picture_hitboxes[String(key)] as Control
		var rect: Rect2 = hit.get_meta("design_rect") as Rect2
		hit.position = offset + rect.position * scale_factor
		hit.size = rect.size * scale_factor

	for key: Variant in picture_feedback.keys():
		var key_string: String = String(key)
		var feedback: TextureRect = picture_feedback[key_string] as TextureRect
		var rect: Rect2 = feedback.get_meta("design_rect") as Rect2
		var base_position: Vector2 = offset + rect.position * scale_factor
		var base_size: Vector2 = rect.size * scale_factor
		feedback.set_meta("base_position", base_position)
		feedback.set_meta("base_size", base_size)
		_apply_feedback_state(key_string)
		feedback.move_to_front()

	if play_button != null:
		play_button.move_to_front()
	for key: Variant in picture_hitboxes.keys():
		var hit: Control = picture_hitboxes[String(key)] as Control
		hit.move_to_front()

	if board_page != null and is_instance_valid(board_page):
		board_page.size = size
		board_page.move_to_front()
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.size = size

func _board_box(fill: Color, border: Color, width: int = 3, radius: int = 8) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box

func _style_board_tab(button: Button, selected: bool) -> void:
	button.disabled = false
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("fff1bd") if selected else MENU_INK)
	if selected:
		button.add_theme_stylebox_override("normal", _board_box(MENU_RED, MENU_GOLD, 3, 8))
		button.add_theme_stylebox_override("hover", _board_box(Color("a51e1f"), Color("ffd86a"), 3, 8))
		button.add_theme_stylebox_override("pressed", _board_box(Color("671011"), MENU_GOLD_DARK, 3, 8))
	else:
		button.add_theme_stylebox_override("normal", _board_box(Color("f4dfb2"), Color("b78645"), 2, 8))
		button.add_theme_stylebox_override("hover", _board_box(Color("f8e8c4"), MENU_GOLD, 2, 8))
		button.add_theme_stylebox_override("pressed", _board_box(Color("d8bd82"), MENU_GOLD_DARK, 2, 8))

func _build_board_page() -> void:
	board_page = Control.new()
	board_page.name = "FreshLeaderboardPage"
	board_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_page.mouse_filter = Control.MOUSE_FILTER_STOP
	board_page.z_index = 50000
	add_child(board_page)

	var background := ColorRect.new()
	background.color = Color("0b3340")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_page.add_child(background)

	var outer := Panel.new()
	outer.position = Vector2(18, 38)
	outer.size = Vector2(354, 754)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_theme_stylebox_override("panel", _board_box(MENU_WOOD, MENU_GOLD_DARK, 3, 16))
	board_page.add_child(outer)

	var title := Label.new()
	title.text = "☠  LEADERBOARD"
	title.position = Vector2(20, 20)
	title.size = Vector2(314, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", MENU_GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	outer.add_child(title)

	var tabs := HBoxContainer.new()
	tabs.position = Vector2(24, 82)
	tabs.size = Vector2(306, 46)
	tabs.add_theme_constant_override("separation", 8)
	outer.add_child(tabs)

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
	parchment.position = Vector2(20, 146)
	parchment.size = Vector2(314, 500)
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parchment.add_theme_stylebox_override("panel", _board_box(MENU_PARCHMENT, Color("b78645"), 3, 12))
	outer.add_child(parchment)

	board_rows = VBoxContainer.new()
	board_rows.position = Vector2(12, 14)
	board_rows.size = Vector2(290, 456)
	board_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_rows.add_theme_constant_override("separation", 4)
	parchment.add_child(board_rows)

	board_status = Label.new()
	board_status.position = Vector2(24, 656)
	board_status.size = Vector2(306, 24)
	board_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_status.add_theme_font_size_override("font_size", 12)
	board_status.add_theme_color_override("font_color", Color("fff1c4"))
	outer.add_child(board_status)

	var back := Button.new()
	back.name = "LeaderboardBackButton"
	back.text = "BACK"
	back.position = Vector2(111, 730)
	back.size = Vector2(168, 48)
	back.focus_mode = Control.FOCUS_NONE
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	back.z_index = 100
	back.add_theme_font_size_override("font_size", 20)
	back.add_theme_color_override("font_color", Color("fff1bd"))
	back.add_theme_stylebox_override("normal", _board_box(MENU_RED, MENU_GOLD, 3, 10))
	back.add_theme_stylebox_override("hover", _board_box(Color("a51e1f"), Color("ffd86a"), 3, 10))
	back.add_theme_stylebox_override("pressed", _board_box(Color("671011"), MENU_GOLD_DARK, 3, 10))
	back.pressed.connect(_close_board_page)
	board_page.add_child(back)
	back.move_to_front()

	board_http = HTTPRequest.new()
	board_http.name = "FreshLeaderboardRequest"
	board_page.add_child(board_http)
	board_http.request_completed.connect(_on_board_loaded)
	_refresh_board_view()

func _close_board_page() -> void:
	if board_page != null and is_instance_valid(board_page):
		board_page.visible = false

func _refresh_board_view() -> void:
	if board_rows == null or board_status == null:
		return
	_clear_board_rows()
	if leaderboard_tab != null:
		_style_board_tab(leaderboard_tab, active_tab == "leaderboard")
	if rank_tab != null:
		_style_board_tab(rank_tab, active_tab == "rank")
	if active_tab == "rank":
		_build_rank_rows()
	else:
		_build_top_rows()

func _add_score_row(rank_value: int, entry: Dictionary, highlight: bool) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 38)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)

	var rank_label := Label.new()
	rank_label.text = "#%d" % rank_value
	rank_label.custom_minimum_size = Vector2(44, 38)
	rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rank_label.add_theme_color_override("font_color", MENU_RED if highlight else MENU_INK)
	row.add_child(rank_label)

	var name_label := Label.new()
	name_label.text = String(entry.get("name", entry.get("playerName", "Pirate")))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", MENU_RED if highlight else MENU_INK)
	row.add_child(name_label)

	var score_label := Label.new()
	score_label.text = _comma(int(entry.get("score", entry.get("bestScore", 0))))
	score_label.custom_minimum_size = Vector2(80, 38)
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label.add_theme_color_override("font_color", MENU_RED if highlight else MENU_INK)
	row.add_child(score_label)

	if highlight:
		for label: Label in [rank_label, name_label, score_label]:
			label.add_theme_color_override("font_color", Color("8d1718"))
	board_rows.add_child(row)
