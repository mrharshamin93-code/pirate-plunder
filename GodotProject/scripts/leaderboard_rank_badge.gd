extends Node

const API_URL: String = "https://pirate-plunder.vercel.app/api/leaderboard"
const SAVE_PATH: String = "user://leaderboard.cfg"
const GOLD_DARK: Color = Color("9b5c16")
const WOOD: Color = Color("3a2115")

var http: HTTPRequest
var badge: Button = null
var leaderboard_box: Control = null
var sunk_root: Control = null
var player_id: String = ""
var was_visible: bool = false
var last_footer_text: String = ""

func _ready() -> void:
	http = HTTPRequest.new()
	http.name = "RankRequest"
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	set_process(true)

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var found: Control = scene.find_child("LeaderboardRows", true, false) as Control
	if found == null:
		leaderboard_box = null
		sunk_root = null
		badge = null
		was_visible = false
		return
	leaderboard_box = found
	sunk_root = leaderboard_box.get_parent() as Control
	if sunk_root == null:
		return
	if not is_instance_valid(badge) or badge.get_parent() != sunk_root:
		_create_badge()
	_layout_badge()
	var visible_now: bool = sunk_root.visible and sunk_root.is_visible_in_tree()
	badge.visible = visible_now
	if visible_now and not was_visible:
		_load_player_id()
		_request_rank()
	var footer: Label = sunk_root.get_node_or_null("Footer") as Label
	if visible_now and footer != null and footer.text != last_footer_text:
		if footer.text.begins_with("Score submitted!"):
			_request_rank()
		last_footer_text = footer.text
	was_visible = visible_now

func _create_badge() -> void:
	if sunk_root == null:
		return
	badge = Button.new()
	badge.name = "PersonalRankBadge"
	badge.text = "YOUR RANK  —"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.focus_mode = Control.FOCUS_NONE
	badge.z_index = 120
	badge.add_theme_font_size_override("font_size", 13)
	badge.add_theme_color_override("font_color", Color("fff2b2"))
	badge.add_theme_stylebox_override("normal", _button_box(WOOD, GOLD_DARK, 2, 8))
	badge.add_theme_stylebox_override("hover", _button_box(WOOD, GOLD_DARK, 2, 8))
	badge.add_theme_stylebox_override("pressed", _button_box(WOOD, GOLD_DARK, 2, 8))
	sunk_root.add_child(badge)
	badge.move_to_front()

func _layout_badge() -> void:
	if not is_instance_valid(badge) or leaderboard_box == null or sunk_root == null:
		return
	var sx: float = sunk_root.size.x / 390.0 if sunk_root.size.x > 0.0 else 1.0
	var badge_width: float = 148.0 * sx
	badge.position = Vector2((sunk_root.size.x - badge_width) * 0.5, leaderboard_box.position.y + leaderboard_box.size.y + 3.0)
	badge.size = Vector2(badge_width, 24.0)
	badge.move_to_front()

func _load_player_id() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		player_id = String(cfg.get_value("player", "id", ""))

func _request_rank() -> void:
	if player_id.is_empty():
		_load_player_id()
	if player_id.is_empty() or http == null:
		_set_badge_rank(0)
		return
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	badge.text = "YOUR RANK  …"
	var err: Error = http.request("%s?playerId=%s" % [API_URL, player_id])
	if err != OK:
		_set_badge_rank(0)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_set_badge_rank(0)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		_set_badge_rank(0)
		return
	var data := parsed as Dictionary
	_set_badge_rank(int(data.get("personalRank", 0)))

func _set_badge_rank(rank: int) -> void:
	if not is_instance_valid(badge):
		return
	badge.text = "YOUR RANK  #%d" % rank if rank > 0 else "YOUR RANK  —"

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
