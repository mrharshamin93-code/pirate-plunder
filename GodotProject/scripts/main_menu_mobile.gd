extends "res://scripts/main_menu.gd"

const DESIGN_SIZE: Vector2 = Vector2(853.0, 1844.0)

# Exact button bounds measured from main_menu_exact.png (853 x 1844).
const PLAY_RECT: Rect2 = Rect2(168, 900, 495, 145)
const LEADERBOARD_RECT: Rect2 = Rect2(168, 1063, 495, 130)
const COLLECTIBLES_RECT: Rect2 = Rect2(168, 1213, 495, 130)
const SETTINGS_RECT: Rect2 = Rect2(30, 48, 88, 106)

var exact_bg: TextureRect
var menu_popup: Control
var button_map: Dictionary = {}

var sunk_panel: Control = null
var sunk_original_z: int = 100
var sunk_visibility_state: Dictionary = {}
var menu_board_backdrop: ColorRect = null
var menu_board_frame: Panel = null
var menu_board_title: Label = null
var menu_board_back: Button = null

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	# Keep the actual Godot controls completely invisible. The artwork already
	# contains the button faces; these nodes are touch targets only.
	play_button = _create_dynamic_button("PlayButton", PLAY_RECT, Callable(self, "_start_game_action"))
	_create_dynamic_button("LeaderboardButton", LEADERBOARD_RECT, Callable(self, "_open_leaderboard_action"))
	_create_dynamic_button("CollectiblesButton", COLLECTIBLES_RECT, Callable(self, "_open_collectibles_action"))
	_create_dynamic_button("SettingsButton", SETTINGS_RECT, Callable(self, "_open_settings_action"))

	_layout_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_ui")

func _transparent_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.border_color = Color(0, 0, 0, 0)
	box.set_border_width_all(0)
	return box

func _create_dynamic_button(button_name: String, design_rect: Rect2, action: Callable) -> Button:
	var btn: Button = Button.new()
	btn.name = button_name
	btn.text = ""
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.self_modulate = Color(1, 1, 1, 0)
	btn.set_meta("design_rect", design_rect)
	var transparent: StyleBoxFlat = _transparent_box()
	btn.add_theme_stylebox_override("normal", transparent)
	btn.add_theme_stylebox_override("hover", transparent)
	btn.add_theme_stylebox_override("pressed", transparent)
	btn.add_theme_stylebox_override("focus", transparent)
	btn.add_theme_stylebox_override("disabled", transparent)
	add_child(btn)

	# The feedback layer is separate from the invisible button, so there can be
	# no extra Godot button drawn over the Collectibles artwork.
	var overlay: ColorRect = ColorRect.new()
	overlay.name = "%sFeedback" % button_name
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
		overlay.color = Color(0, 0, 0, 0.18)
	elif is_hover:
		overlay.color = Color(1, 1, 1, 0.055)
	else:
		overlay.color = Color(0, 0, 0, 0)
	_layout_ui()

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size

	# Match STRETCH_KEEP_ASPECT_COVERED exactly so the hit regions follow the
	# artwork even when a phone is taller or wider than the source image.
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
	if sunk_panel != null and is_instance_valid(sunk_panel) and sunk_panel.visible:
		_layout_menu_leaderboard()

func _start_game_action() -> void:
	_start_from_menu()

func _open_collectibles_action() -> void:
	var collectibles: Node = get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("open_from_menu"):
		collectibles.call("open_from_menu", self)

func _open_leaderboard_action() -> void:
	_open_sunk_leaderboard()

func _open_settings_action() -> void:
	_show_popup("SETTINGS", "Settings page coming soon.")

# Reuse the exact leaderboard/ranking UI already used by the SUNK screen.
# Showing SunkPanel also lets LeaderboardRankBadge run its normal visibility
# hooks, so both LEADERBOARD and RANK use the same data and behavior as a run.
func _open_sunk_leaderboard() -> void:
	var canvas: Node = get_parent()
	if canvas == null:
		return
	sunk_panel = canvas.get_node_or_null("SunkPanel") as Control
	if sunk_panel == null:
		return

	if sunk_panel.visible and sunk_panel.has_meta("main_menu_leaderboard_mode"):
		return

	sunk_visibility_state.clear()
	for child: Node in sunk_panel.get_children():
		if child is CanvasItem:
			sunk_visibility_state[child] = (child as CanvasItem).visible

	sunk_original_z = sunk_panel.z_index
	sunk_panel.set_meta("main_menu_leaderboard_mode", true)
	sunk_panel.z_index = 60000
	sunk_panel.visible = true

	# LeaderboardRankBadge creates/refreshes the LEADERBOARD and RANK tabs when
	# SunkPanel becomes visible. Configure the menu view one frame later so those
	# live controls are present and can simply be reused here.
	call_deferred("_configure_sunk_leaderboard_only")

func _configure_sunk_leaderboard_only() -> void:
	if sunk_panel == null or not is_instance_valid(sunk_panel):
		return

	var keep_visible: Dictionary = {
		"LeaderboardRows": true,
		"LeaderboardTab": true,
		"RankTab": true
	}
	for child: Node in sunk_panel.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = keep_visible.has(child.name)

	# Cover the rest of the SUNK artwork, then place a simple frame behind the
	# existing leaderboard container. The rows and both tabs themselves are the
	# actual SUNK-screen controls, not a duplicate implementation.
	menu_board_backdrop = sunk_panel.get_node_or_null("MenuLeaderboardBackdrop") as ColorRect
	if menu_board_backdrop == null:
		menu_board_backdrop = ColorRect.new()
		menu_board_backdrop.name = "MenuLeaderboardBackdrop"
		menu_board_backdrop.color = Color("071923")
		menu_board_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		menu_board_backdrop.z_index = -20
		sunk_panel.add_child(menu_board_backdrop)

	menu_board_frame = sunk_panel.get_node_or_null("MenuLeaderboardFrame") as Panel
	if menu_board_frame == null:
		menu_board_frame = Panel.new()
		menu_board_frame.name = "MenuLeaderboardFrame"
		menu_board_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_board_frame.z_index = -10
		var frame_style: StyleBoxFlat = StyleBoxFlat.new()
		frame_style.bg_color = Color("e8c989")
		frame_style.border_color = Color("9b5c16")
		frame_style.set_border_width_all(3)
		frame_style.set_corner_radius_all(14)
		menu_board_frame.add_theme_stylebox_override("panel", frame_style)
		sunk_panel.add_child(menu_board_frame)

	menu_board_title = sunk_panel.get_node_or_null("MenuLeaderboardTitle") as Label
	if menu_board_title == null:
		menu_board_title = Label.new()
		menu_board_title.name = "MenuLeaderboardTitle"
		menu_board_title.text = "LEADERBOARD"
		menu_board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		menu_board_title.add_theme_font_size_override("font_size", 28)
		menu_board_title.add_theme_color_override("font_color", Color("f6d18a"))
		menu_board_title.z_index = 160
		sunk_panel.add_child(menu_board_title)

	menu_board_back = sunk_panel.get_node_or_null("MenuLeaderboardBack") as Button
	if menu_board_back == null:
		menu_board_back = Button.new()
		menu_board_back.name = "MenuLeaderboardBack"
		menu_board_back.text = "BACK"
		menu_board_back.focus_mode = Control.FOCUS_NONE
		menu_board_back.z_index = 160
		menu_board_back.pressed.connect(_close_sunk_leaderboard)
		sunk_panel.add_child(menu_board_back)

	menu_board_backdrop.visible = true
	menu_board_frame.visible = true
	menu_board_title.visible = true
	menu_board_back.visible = true
	_layout_menu_leaderboard()

func _layout_menu_leaderboard() -> void:
	if sunk_panel == null or not is_instance_valid(sunk_panel):
		return
	var w: float = sunk_panel.size.x
	var sx: float = w / 390.0 if w > 0.0 else 1.0
	if menu_board_backdrop != null:
		menu_board_backdrop.position = Vector2.ZERO
		menu_board_backdrop.size = sunk_panel.size
	if menu_board_frame != null:
		menu_board_frame.position = Vector2(38.0 * sx, 344.0)
		menu_board_frame.size = Vector2(w - 76.0 * sx, 370.0)
	if menu_board_title != null:
		menu_board_title.position = Vector2(48.0 * sx, 286.0)
		menu_board_title.size = Vector2(w - 96.0 * sx, 48.0)
	if menu_board_back != null:
		menu_board_back.position = Vector2(120.0 * sx, 730.0)
		menu_board_back.size = Vector2(150.0 * sx, 48.0)

func _close_sunk_leaderboard() -> void:
	if sunk_panel == null or not is_instance_valid(sunk_panel):
		return

	if menu_board_backdrop != null:
		menu_board_backdrop.visible = false
	if menu_board_frame != null:
		menu_board_frame.visible = false
	if menu_board_title != null:
		menu_board_title.visible = false
	if menu_board_back != null:
		menu_board_back.visible = false

	for key: Variant in sunk_visibility_state.keys():
		var node: Node = key as Node
		if node != null and is_instance_valid(node) and node is CanvasItem:
			(node as CanvasItem).visible = bool(sunk_visibility_state[key])

	sunk_visibility_state.clear()
	sunk_panel.remove_meta("main_menu_leaderboard_mode")
	sunk_panel.z_index = sunk_original_z
	sunk_panel.visible = false

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

	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.58)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_popup.add_child(shade)

	var panel: Panel = Panel.new()
	panel.position = Vector2(size.x * 0.075, size.y * 0.28)
	panel.size = Vector2(size.x * 0.85, minf(300.0, size.y * 0.40))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("2d1b12")
	sb.border_color = Color("b2763b")
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	menu_popup.add_child(panel)

	var title: Label = Label.new()
	title.text = title_text
	title.position = Vector2(18, 18)
	title.size = Vector2(panel.size.x - 36, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f7d48b"))
	panel.add_child(title)

	var body: Label = Label.new()
	body.text = body_text
	body.position = Vector2(24, 76)
	body.size = Vector2(panel.size.x - 48, 120)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_color_override("font_color", Color("fff4dc"))
	panel.add_child(body)

	var close: Button = Button.new()
	close.text = "BACK"
	close.position = Vector2((panel.size.x - 150) * 0.5, panel.size.y - 62)
	close.size = Vector2(150, 44)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func() -> void: menu_popup.queue_free())
	panel.add_child(close)
