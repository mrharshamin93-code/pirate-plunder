extends Node

const API_URL: String = "https://pirate-plunder.vercel.app/api/leaderboard"
const SAVE_PATH: String = "user://leaderboard.cfg"
const GOLD: Color = Color("f4c64d")
const GOLD_DARK: Color = Color("9b5c16")
const WOOD: Color = Color("3a2115")
const WOOD_LIGHT: Color = Color("5b3520")
const RED: Color = Color("8d1718")
const INK: Color = Color("24160f")

var http: HTTPRequest
var leaderboard_box: VBoxContainer = null
var sunk_root: Control = null
var leaderboard_tab: Button = null
var rank_tab: Button = null
var player_id: String = ""
var rank_rows: Array[Dictionary] = []
var personal_rank: int = 0
var rank_ready: bool = false
var active_tab: String = "leaderboard"
var refresh_queued: bool = false

func _ready() -> void:
	http = HTTPRequest.new()
	http.name = "RankTabRequest"
	add_child(http)
	http.request_completed.connect(_on_request_completed)

	# Do not poll the scene every frame. Bind once when the leaderboard UI appears.
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_try_bind_existing")

func _on_node_added(node: Node) -> void:
	if node is VBoxContainer and node.name == "LeaderboardRows":
		call_deferred("_bind_to_leaderboard", node)

func _try_bind_existing() -> void:
	if is_instance_valid(leaderboard_box) and is_instance_valid(sunk_root):
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var found: VBoxContainer = scene.find_child("LeaderboardRows", true, false) as VBoxContainer
	if found != null:
		_bind_to_leaderboard(found)

func _bind_to_leaderboard(found: VBoxContainer) -> void:
	if found == null or not is_instance_valid(found):
		return
	var found_root: Control = found.get_parent() as Control
	if found_root == null:
		return
	if leaderboard_box == found and sunk_root == found_root and is_instance_valid(leaderboard_tab) and is_instance_valid(rank_tab):
		return

	leaderboard_box = found
	sunk_root = found_root
	_create_tabs()
	_layout_tabs()

	if not sunk_root.visibility_changed.is_connected(_on_sunk_visibility_changed):
		sunk_root.visibility_changed.connect(_on_sunk_visibility_changed)
	if not sunk_root.resized.is_connected(_layout_tabs):
		sunk_root.resized.connect(_layout_tabs)

	# Listen to the existing leaderboard request instead of polling footer text.
	# This fires after loads/submissions and keeps RANK current without per-frame work.
	var board_request: HTTPRequest = sunk_root.get_node_or_null("LeaderboardRequest") as HTTPRequest
	if board_request != null and not board_request.request_completed.is_connected(_on_leaderboard_request_completed):
		board_request.request_completed.connect(_on_leaderboard_request_completed)

	_on_sunk_visibility_changed()

func _on_sunk_visibility_changed() -> void:
	if sunk_root == null or not is_instance_valid(sunk_root):
		return
	if not sunk_root.visible:
		# Always start the next SUNK screen on the normal leaderboard tab.
		active_tab = "leaderboard"
		return

	active_tab = "leaderboard"
	rank_ready = false
	rank_rows.clear()
	personal_rank = 0
	refresh_queued = false
	_apply_tab_styles()
	_layout_tabs()
	_load_player_id()
	_request_rank_window()
	# SunkScreen also refreshes itself on visibility_changed. Deferring avoids
	# both scripts rebuilding the same rows in the same signal dispatch.
	call_deferred("_show_leaderboard")

func _on_leaderboard_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return
	if sunk_root == null or not is_instance_valid(sunk_root) or not sunk_root.visible:
		return
	# A completed leaderboard request may be a successful score submission.
	# Refresh rank data once; if RANK is open, restore it after sunk_screen.gd
	# rebuilds the top-10 rows in its own request callback.
	rank_ready = false
	if active_tab == "rank":
		_build_loading_view()
	call_deferred("_request_rank_window")

func on_score_submitted() -> void:
	# Public hook retained for future direct calls; it is event-driven as well.
	rank_ready = false
	if active_tab == "rank":
		_build_loading_view()
	_request_rank_window()

func is_rank_active() -> bool:
	return active_tab == "rank" and sunk_root != null and is_instance_valid(sunk_root) and sunk_root.visible

func _create_tabs() -> void:
	if sunk_root == null:
		return

	var old_left: Node = sunk_root.get_node_or_null("LeaderboardTab")
	if old_left != null:
		old_left.queue_free()
	var old_right: Node = sunk_root.get_node_or_null("RankTab")
	if old_right != null:
		old_right.queue_free()
	var old_badge: Node = sunk_root.get_node_or_null("PersonalRankBadge")
	if old_badge != null:
		old_badge.queue_free()

	var board_title: Control = sunk_root.get_node_or_null("BoardTitle") as Control
	if board_title != null:
		board_title.visible = false

	leaderboard_tab = Button.new()
	leaderboard_tab.name = "LeaderboardTab"
	leaderboard_tab.text = "LEADERBOARD"
	leaderboard_tab.focus_mode = Control.FOCUS_NONE
	leaderboard_tab.mouse_filter = Control.MOUSE_FILTER_STOP
	leaderboard_tab.z_index = 140
	leaderboard_tab.add_theme_font_size_override("font_size", 14)
	leaderboard_tab.pressed.connect(_show_leaderboard)
	sunk_root.add_child(leaderboard_tab)

	rank_tab = Button.new()
	rank_tab.name = "RankTab"
	rank_tab.text = "RANK"
	rank_tab.focus_mode = Control.FOCUS_NONE
	rank_tab.mouse_filter = Control.MOUSE_FILTER_STOP
	rank_tab.z_index = 140
	rank_tab.add_theme_font_size_override("font_size", 14)
	rank_tab.pressed.connect(_show_rank)
	sunk_root.add_child(rank_tab)

	_apply_tab_styles()
	leaderboard_tab.move_to_front()
	rank_tab.move_to_front()

func _layout_tabs() -> void:
	if sunk_root == null or leaderboard_box == null or not is_instance_valid(leaderboard_tab) or not is_instance_valid(rank_tab):
		return

	var w: float = sunk_root.size.x
	var sx: float = w / 390.0 if w > 0.0 else 1.0
	var left: float = 52.0 * sx
	var total_width: float = w - 104.0 * sx
	var gap: float = 6.0 * sx
	var tab_width: float = (total_width - gap) * 0.5
	var tab_y: float = 365.0
	var tab_h: float = 34.0

	leaderboard_tab.position = Vector2(left, tab_y)
	leaderboard_tab.size = Vector2(tab_width, tab_h)
	rank_tab.position = Vector2(left + tab_width + gap, tab_y)
	rank_tab.size = Vector2(tab_width, tab_h)
	leaderboard_box.position = Vector2(left, 408.0)
	leaderboard_box.size = Vector2(total_width, 276.0)
	leaderboard_tab.move_to_front()
	rank_tab.move_to_front()

func _show_leaderboard() -> void:
	active_tab = "leaderboard"
	_apply_tab_styles()
	if leaderboard_box == null or sunk_root == null:
		return
	_clear_rows()
	if sunk_root.has_method("_build_leaderboard"):
		sunk_root.call("_build_leaderboard")

func _show_rank() -> void:
	active_tab = "rank"
	_apply_tab_styles()
	if rank_ready:
		_build_rank_view()
	else:
		_build_loading_view()
		_request_rank_window()

func _apply_tab_styles() -> void:
	if not is_instance_valid(leaderboard_tab) or not is_instance_valid(rank_tab):
		return
	_style_tab(leaderboard_tab, active_tab == "leaderboard")
	_style_tab(rank_tab, active_tab == "rank")

func _style_tab(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color("fff2b2"))
		button.add_theme_stylebox_override("normal", _button_box(RED, GOLD, 2, 8))
		button.add_theme_stylebox_override("hover", _button_box(Color("a51e1f"), Color("ffd86a"), 2, 8))
		button.add_theme_stylebox_override("pressed", _button_box(Color("671011"), GOLD_DARK, 2, 8))
	else:
		button.add_theme_color_override("font_color", Color("e8c989"))
		button.add_theme_stylebox_override("normal", _button_box(WOOD, GOLD_DARK, 2, 8))
		button.add_theme_stylebox_override("hover", _button_box(WOOD_LIGHT, GOLD, 2, 8))
		button.add_theme_stylebox_override("pressed", _button_box(Color("24150e"), GOLD_DARK, 2, 8))

func _load_player_id() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		player_id = String(cfg.get_value("player", "id", ""))

func _request_rank_window() -> void:
	if player_id.is_empty():
		_load_player_id()
	if player_id.is_empty() or http == null:
		rank_ready = true
		rank_rows.clear()
		personal_rank = 0
		if active_tab == "rank":
			_build_rank_view()
		return
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		refresh_queued = true
		return
	refresh_queued = false
	var err: Error = http.request("%s?playerId=%s" % [API_URL, player_id])
	if err != OK:
		rank_ready = true
		rank_rows.clear()
		personal_rank = 0
		if active_tab == "rank":
			_build_rank_view()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var should_refresh_again: bool = refresh_queued
	refresh_queued = false

	rank_rows.clear()
	personal_rank = 0
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if parsed is Dictionary:
			var data := parsed as Dictionary
			personal_rank = int(data.get("personalRank", 0))
			var raw_rows: Variant = data.get("rankWindow", [])
			if raw_rows is Array:
				for item in raw_rows:
					if item is Dictionary:
						var d := item as Dictionary
						rank_rows.append({
							"name": String(d.get("name", "Pirate")),
							"score": int(d.get("score", 0)),
							"coins": int(d.get("coins", 0)),
							"rank": int(d.get("rank", 0)),
							"is_you": bool(d.get("isYou", false))
						})

	if should_refresh_again:
		rank_ready = false
		_request_rank_window()
		return

	rank_ready = true
	if active_tab == "rank" and sunk_root != null and is_instance_valid(sunk_root) and sunk_root.visible:
		_build_rank_view()

func _build_loading_view() -> void:
	if leaderboard_box == null:
		return
	_clear_rows()
	var label := Label.new()
	label.set_meta("rank_tab_row", true)
	label.text = "LOADING YOUR RANK..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(0, 42)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", INK)
	leaderboard_box.add_child(label)

func _build_rank_view() -> void:
	if leaderboard_box == null:
		return
	_clear_rows()

	if rank_rows.is_empty() or personal_rank <= 0:
		var empty := Label.new()
		empty.set_meta("rank_tab_row", true)
		empty.text = "SUBMIT A SCORE TO SEE YOUR RANK"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 70)
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", INK)
		leaderboard_box.add_child(empty)
		return

	for entry in rank_rows:
		var is_you: bool = bool(entry.get("is_you", false))
		var row := PanelContainer.new()
		row.set_meta("rank_tab_row", true)
		row.custom_minimum_size = Vector2(0, 25)
		if is_you:
			row.add_theme_stylebox_override("panel", _button_box(Color(0.20, 0.13, 0.08, 0.90), GOLD, 2, 5))
		else:
			row.add_theme_stylebox_override("panel", _button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))

		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 7)
		row.add_child(h)

		var rank_label := Label.new()
		rank_label.custom_minimum_size = Vector2(45, 0)
		rank_label.text = "#%d" % int(entry.get("rank", 0))
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank_label.add_theme_font_size_override("font_size", 15)
		rank_label.add_theme_color_override("font_color", Color("fff3c8") if is_you else INK)
		h.add_child(rank_label)

		var nm := Label.new()
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var display_name: String = _display_name(String(entry.get("name", "Pirate")))
		nm.text = display_name
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.add_theme_font_size_override("font_size", 15)
		nm.add_theme_color_override("font_color", Color("fff3c8") if is_you else INK)
		h.add_child(nm)

		var score_label := Label.new()
		score_label.custom_minimum_size = Vector2(82, 0)
		score_label.text = "●  %s" % _comma(int(entry.get("score", 0)))
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_label.add_theme_font_size_override("font_size", 15)
		score_label.add_theme_color_override("font_color", GOLD if is_you else Color("6d3f10"))
		h.add_child(score_label)

		leaderboard_box.add_child(row)

func _clear_rows() -> void:
	if leaderboard_box == null:
		return
	for child in leaderboard_box.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		child.queue_free()

func _display_name(value: String) -> String:
	var clean: String = value.strip_edges()
	if clean.length() <= 12:
		return clean
	return clean.substr(0, 11) + "…"

func _comma(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _button_box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
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
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 2.0
	box.content_margin_bottom = 2.0
	return box
