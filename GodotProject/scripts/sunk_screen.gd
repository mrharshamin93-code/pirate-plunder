extends ColorRect

const GOLD: Color = Color("f4c64d")
const GOLD_DARK: Color = Color("9b5c16")
const PARCHMENT: Color = Color("e8c989")
const PARCHMENT_DARK: Color = Color("b78645")
const WOOD: Color = Color("3a2115")
const WOOD_LIGHT: Color = Color("5b3520")
const RED: Color = Color("8d1718")
const INK: Color = Color("24160f")
const API_URL: String = "https://pirate-plunder.vercel.app/api/leaderboard"
const SAVE_PATH: String = "user://leaderboard.cfg"
const PLAY_STORE_URL: String = "https://play.google.com/store/apps/details?id=com.harshamin.piratesplunder"

var name_entry: LineEdit
var submit_button: Button
var share_button: Button
var leaderboard_box: VBoxContainer
var footer_label: Label
var http: HTTPRequest
var leaderboard: Array[Dictionary] = []
var player_id: String = ""
var pending_action: String = ""
var submitted_name: String = ""
var submitted_score: int = -1
var restart_in_progress: bool = false
var leaderboard_ready: bool = false
var cached_personal_best: int = 0
var local_personal_best: int = 0
var last_share_msec: int = 0

func _ready() -> void:
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	$Title.visible = false
	$LeaderboardTitle.visible = false
	$ComingSoon.visible = false
	_style_existing_score()
	_style_play_again()
	_build_ui()
	_setup_http()
	_load_identity()
	visibility_changed.connect(_on_visibility_changed)
	_load_leaderboard(true)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible or restart_in_progress:
		return
	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pressed = touch.pressed
		pos = touch.position
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		pos = mouse.position
	if not pressed:
		return
	if share_button != null and is_instance_valid(share_button) and share_button.visible and share_button.get_global_rect().has_point(pos):
		_share_score()
		get_viewport().set_input_as_handled()
		return
	var play_button: Button = $PlayAgain
	if play_button.get_global_rect().has_point(pos):
		_restart_game()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_ui")
		queue_redraw()

func _on_visibility_changed() -> void:
	if visible:
		restart_in_progress = false
		_refresh_from_game()
	elif is_node_ready():
		call_deferred("_refresh_leaderboard_cache")

func _refresh_leaderboard_cache() -> void:
	if http != null and http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_load_leaderboard(true)

func _setup_http() -> void:
	http = HTTPRequest.new()
	http.name = "LeaderboardRequest"
	add_child(http)
	http.request_completed.connect(_on_request_completed)

func _load_identity() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		player_id = String(cfg.get_value("player", "id", ""))
		var saved_name: String = String(cfg.get_value("player", "name", ""))
		local_personal_best = int(cfg.get_value("player", "personal_best", 0))
		cached_personal_best = local_personal_best
		if not saved_name.is_empty():
			name_entry.text = saved_name
	if player_id.is_empty():
		player_id = _make_uuid_v4()
		_save_identity()

func _save_identity() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("player", "id", player_id)
	cfg.set_value("player", "name", name_entry.text.strip_edges())
	cfg.set_value("player", "personal_best", local_personal_best)
	cfg.save(SAVE_PATH)

func _make_uuid_v4() -> String:
	var bytes: PackedByteArray = PackedByteArray()
	for _i in range(16):
		bytes.append(randi_range(0, 255))
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]]

func _style_existing_score() -> void:
	var score_label: Label = $Score
	score_label.offset_left = 72.0
	score_label.offset_top = 235.0
	score_label.offset_right = 318.0
	score_label.offset_bottom = 286.0
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 36)
	score_label.add_theme_color_override("font_color", Color("ffe36f"))
	score_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	score_label.add_theme_constant_override("shadow_offset_x", 2)
	score_label.add_theme_constant_override("shadow_offset_y", 2)

func _style_play_again() -> void:
	var b: Button = $PlayAgain
	b.offset_left = 62.0
	b.offset_top = 738.0
	b.offset_right = 328.0
	b.offset_bottom = 792.0
	b.text = "⚔  PLAY AGAIN"
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.focus_mode = Control.FOCUS_NONE
	b.z_index = 100
	b.add_theme_font_size_override("font_size", 25)
	b.add_theme_color_override("font_color", Color("fff2b2"))
	b.add_theme_stylebox_override("normal", _button_box(RED, GOLD, 4, 12))
	b.add_theme_stylebox_override("hover", _button_box(Color("a51e1f"), Color("ffd86a"), 4, 12))
	b.add_theme_stylebox_override("pressed", _button_box(Color("671011"), GOLD_DARK, 4, 12))
	if not b.pressed.is_connected(_restart_game):
		b.pressed.connect(_restart_game)
	b.move_to_front()

func _restart_game() -> void:
	if restart_in_progress:
		return
	restart_in_progress = true
	var game: Node = get_parent().get_parent()
	if game != null and game.has_method("_start_game"):
		game.call_deferred("_start_game")

func _build_ui() -> void:
	var sunk: Label = Label.new()
	sunk.name = "HeroTitle"
	sunk.text = "☠  SUNK!  ☠"
	sunk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sunk.add_theme_font_size_override("font_size", 46)
	sunk.add_theme_color_override("font_color", GOLD)
	sunk.add_theme_color_override("font_shadow_color", Color(0,0,0,0.85))
	sunk.add_theme_constant_override("shadow_offset_x", 3)
	sunk.add_theme_constant_override("shadow_offset_y", 4)
	add_child(sunk)
	var subtitle: Label = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "YOUR TREASURE SANK TO THE DEPTHS!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("fff1c4"))
	add_child(subtitle)
	var score_title: Label = Label.new()
	score_title.name = "ScoreTitle"
	score_title.text = "—  YOUR SCORE  —"
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_title.add_theme_font_size_override("font_size", 22)
	score_title.add_theme_color_override("font_color", INK)
	add_child(score_title)
	name_entry = LineEdit.new()
	name_entry.name = "NameEntry"
	name_entry.placeholder_text = "Enter your name..."
	name_entry.max_length = 20
	name_entry.add_theme_font_size_override("font_size", 18)
	name_entry.add_theme_color_override("font_color", INK)
	name_entry.add_theme_stylebox_override("normal", _button_box(Color("f4dfb2"), PARCHMENT_DARK, 2, 8))
	add_child(name_entry)
	submit_button = Button.new()
	submit_button.name = "Submit"
	submit_button.text = "SUBMIT"
	submit_button.add_theme_font_size_override("font_size", 18)
	submit_button.add_theme_color_override("font_color", Color("fff1bd"))
	submit_button.add_theme_stylebox_override("normal", _button_box(RED, GOLD, 3, 8))
	submit_button.add_theme_stylebox_override("pressed", _button_box(Color("651011"), GOLD_DARK, 3, 8))
	submit_button.pressed.connect(_submit_score)
	add_child(submit_button)
	share_button = Button.new()
	share_button.name = "Share"
	share_button.text = ""
	share_button.mouse_filter = Control.MOUSE_FILTER_STOP
	share_button.focus_mode = Control.FOCUS_NONE
	share_button.z_index = 200
	share_button.icon = load("res://assets/share-icon.svg") as Texture2D
	share_button.expand_icon = true
	share_button.add_theme_color_override("font_color", Color("fff0b5"))
	share_button.add_theme_stylebox_override("normal", _button_box(Color("3a2115"), GOLD_DARK, 2, 7))
	share_button.add_theme_stylebox_override("hover", _button_box(Color("4a2b19"), GOLD, 2, 7))
	share_button.add_theme_stylebox_override("pressed", _button_box(Color("24150e"), GOLD_DARK, 2, 7))
	share_button.pressed.connect(_share_score)
	add_child(share_button)
	var board_title: Label = Label.new()
	board_title.name = "BoardTitle"
	board_title.text = "☠  LEADERBOARD"
	board_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board_title.add_theme_font_size_override("font_size", 24)
	board_title.add_theme_color_override("font_color", INK)
	add_child(board_title)
	leaderboard_box = VBoxContainer.new()
	leaderboard_box.name = "LeaderboardRows"
	leaderboard_box.add_theme_constant_override("separation", 1)
	add_child(leaderboard_box)
	footer_label = Label.new()
	footer_label.name = "Footer"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 12)
	footer_label.add_theme_color_override("font_color", Color("ffffff"))
	add_child(footer_label)
	$PlayAgain.move_to_front()
	share_button.move_to_front()
	_layout_ui()

func _layout_ui() -> void:
	var w: float = size.x
	var sx: float = w / 390.0
	var hero: Control = get_node_or_null("HeroTitle") as Control
	if hero:
		hero.position = Vector2(30.0*sx, 46.0); hero.size = Vector2(w-60.0*sx, 64.0)
	var subtitle: Control = get_node_or_null("Subtitle") as Control
	if subtitle:
		subtitle.position = Vector2(32.0*sx, 112.0); subtitle.size = Vector2(w-64.0*sx, 30.0)
	var score_title: Control = get_node_or_null("ScoreTitle") as Control
	if score_title:
		score_title.position = Vector2(55.0*sx, 188.0); score_title.size = Vector2(w-110.0*sx, 35.0)
	if name_entry:
		name_entry.position = Vector2(45.0*sx, 302.0); name_entry.size = Vector2(215.0*sx, 48.0)
	if submit_button:
		submit_button.position = Vector2(266.0*sx, 302.0); submit_button.size = Vector2(82.0*sx, 48.0)
	var board_title: Control = get_node_or_null("BoardTitle") as Control
	if board_title:
		board_title.position = Vector2(62.0*sx, 376.0); board_title.size = Vector2(w-124.0*sx, 40.0)
	if leaderboard_box:
		leaderboard_box.position = Vector2(52.0*sx, 416.0); leaderboard_box.size = Vector2(w-104.0*sx, 260.0)
	if footer_label:
		footer_label.position = Vector2(42.0*sx, 708.0); footer_label.size = Vector2(w-84.0*sx, 22.0)
	if share_button:
		var play_button: Button = $PlayAgain
		var square_size: float = minf(48.0, play_button.size.y)
		share_button.position = Vector2(play_button.position.x + play_button.size.x + 6.0, play_button.position.y + (play_button.size.y - square_size) * 0.5)
		share_button.size = Vector2(square_size, square_size)
		share_button.move_to_front()

func _refresh_from_game() -> void:
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	$Score.text = _comma(current_score)
	if current_score > local_personal_best:
		local_personal_best = current_score
		cached_personal_best = maxi(cached_personal_best, local_personal_best)
		_save_identity()
	if leaderboard_ready:
		_build_leaderboard()
		footer_label.text = "Global top 10 • Personal best: %s" % _comma(cached_personal_best)
	else:
		footer_label.text = "Loading global leaderboard... • Personal best: %s" % _comma(cached_personal_best)
		if http.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			_load_leaderboard(false)
	queue_redraw()

func _load_leaderboard(background_fetch: bool = false) -> void:
	if http == null or http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	pending_action = "preload" if background_fetch else "load"
	var err: Error = http.request("%s?playerId=%s" % [API_URL, player_id])
	if err != OK:
		pending_action = ""
		if visible and not leaderboard_ready:
			footer_label.text = "Leaderboard unavailable • Personal best: %s" % _comma(cached_personal_best)

func _submit_score() -> void:
	var player_name: String = name_entry.text.strip_edges().substr(0, 20)
	if player_name.is_empty():
		footer_label.text = "Enter a name first"
		return
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	var coins: int = int(game.get("coins_collected"))
	submitted_name = player_name
	submitted_score = current_score
	_save_identity()
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http.cancel_request()
	submit_button.disabled = true
	footer_label.text = "Submitting score..."
	pending_action = "submit"
	var body: String = JSON.stringify({"name":player_name,"score":current_score,"coins":coins,"playerId":player_id})
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
	var err: Error = http.request("%s?playerId=%s" % [API_URL, player_id], headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		submit_button.disabled = false
		footer_label.text = "Could not submit score • Personal best: %s" % _comma(cached_personal_best)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	submit_button.disabled = false
	var action: String = pending_action
	pending_action = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if visible and not leaderboard_ready:
			footer_label.text = "Leaderboard unavailable — Personal best: %s" % _comma(cached_personal_best)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (parsed is Dictionary):
		if visible and not leaderboard_ready:
			footer_label.text = "Leaderboard unavailable — Personal best: %s" % _comma(cached_personal_best)
		return
	var data: Dictionary = parsed as Dictionary
	var raw_board: Variant = data.get("leaderboard", [])
	leaderboard.clear()
	if raw_board is Array:
		for item in raw_board:
			if item is Dictionary:
				var d: Dictionary = item as Dictionary
				leaderboard.append({"name":String(d.get("name", "Pirate")), "score":int(d.get("score", 0)), "coins":int(d.get("coins", 0))})
	var server_personal_best: int = int(data.get("personalBest", 0))
	if server_personal_best > local_personal_best:
		local_personal_best = server_personal_best
		_save_identity()
	cached_personal_best = maxi(local_personal_best, server_personal_best)
	leaderboard_ready = true
	_build_leaderboard()
	if visible:
		if action == "submit":
			footer_label.text = "Score submitted! Personal best: %s" % _comma(cached_personal_best)
		else:
			footer_label.text = "Global top 10 • Personal best: %s" % _comma(cached_personal_best)

func _share_score() -> void:
	var now: int = Time.get_ticks_msec()
	if now - last_share_msec < 500:
		return
	last_share_msec = now
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	var message: String = "I scored %s in Pirate's Plunder! Can you beat my high score?\n\nDownload Pirate's Plunder: %s" % [_comma(current_score), PLAY_STORE_URL]
	if OS.get_name() == "Android":
		footer_label.text = "Opening share..."
		var result: String = _share_android(message)
		if result == "ok":
			footer_label.text = "Choose an app to share your score"
		else:
			DisplayServer.clipboard_set(message)
			footer_label.text = "%s — score copied instead" % result
		return
	DisplayServer.clipboard_set(message)
	footer_label.text = "Score + download link copied!"
	print("Pirate's Plunder share: %s" % message)

func _share_android(message: String) -> String:
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_error("Pirate's Plunder share: AndroidRuntime unavailable")
		return "AndroidRuntime unavailable"
	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		push_error("Pirate's Plunder share: Android Activity unavailable")
		return "Android Activity unavailable"
	var Intent: Variant = JavaClassWrapper.wrap("android.content.Intent")
	if Intent == null:
		push_error("Pirate's Plunder share: Intent unavailable")
		return "Intent unavailable"
	var intent: Variant = Intent.Intent()
	if intent == null:
		push_error("Pirate's Plunder share: could not create Intent")
		return "Could not create share Intent"
	intent.setAction(Intent.ACTION_SEND)
	intent.putExtra(Intent.EXTRA_TEXT, message)
	intent.setType("text/plain")
	activity.startActivity(intent)
	var exception: Variant = JavaClassWrapper.get_exception()
	if exception != null:
		push_error("Pirate's Plunder share failed: %s" % str(exception))
		return "Android share failed"
	return "ok"

func _clear_leaderboard() -> void:
	for child in leaderboard_box.get_children():
		child.queue_free()

func _display_name(value: String) -> String:
	var clean: String = value.strip_edges()
	if clean.length() <= 12:
		return clean
	return clean.substr(0, 11) + "…"

func _build_leaderboard() -> void:
	_clear_leaderboard()
	var limit: int = mini(10, leaderboard.size())
	for i in range(limit):
		var entry: Dictionary = leaderboard[i]
		var is_you: bool = submitted_score >= 0 and String(entry.get("name", "")) == submitted_name and int(entry.get("score", -1)) == submitted_score
		var row: PanelContainer = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 25)
		if is_you:
			row.add_theme_stylebox_override("panel", _button_box(Color(0.20,0.13,0.08,0.82), GOLD_DARK, 1, 4))
		else:
			row.add_theme_stylebox_override("panel", _button_box(Color(0,0,0,0), Color(0,0,0,0), 0, 0))
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", 7)
		row.add_child(h)
		var rank: Label = Label.new()
		rank.custom_minimum_size = Vector2(32, 0)
		rank.text = str(i + 1)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.add_theme_font_size_override("font_size", 15)
		rank.add_theme_color_override("font_color", Color("fff3c8") if is_you else INK)
		h.add_child(rank)
		var nm: Label = Label.new()
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.text = _display_name(String(entry.get("name", "Pirate")))
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.add_theme_font_size_override("font_size", 15)
		nm.add_theme_color_override("font_color", Color("fff3c8") if is_you else INK)
		h.add_child(nm)
		var sc: Label = Label.new()
		sc.custom_minimum_size = Vector2(82, 0)
		sc.text = "●  %s" % _comma(int(entry.get("score", 0)))
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.add_theme_font_size_override("font_size", 15)
		sc.add_theme_color_override("font_color", GOLD if is_you else Color("6d3f10"))
		h.add_child(sc)
		leaderboard_box.add_child(row)

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
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	return box

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(w,h)), Color("052f43"))
	for i in range(7):
		var y: float = float(i) * h / 7.0
		draw_circle(Vector2(35.0 + float(i%3)*155.0, y + 70.0), 5.0 + float(i%2)*3.0, Color(0.55,0.92,1.0,0.22))
	var hero_rect: Rect2 = Rect2(28.0, 35.0, w-56.0, 115.0)
	draw_style_box(_button_box(WOOD, GOLD_DARK, 4, 15), hero_rect)
	for yy in [66.0, 95.0, 124.0]:
		draw_line(Vector2(38.0,yy), Vector2(w-38.0,yy), Color(WOOD_LIGHT,0.45), 2.0)
	var paper: Rect2 = Rect2(30.0, 164.0, w-60.0, 536.0)
	draw_style_box(_button_box(PARCHMENT, PARCHMENT_DARK, 3, 18), paper)
	var score_plaque: Rect2 = Rect2(70.0, 228.0, w-140.0, 62.0)
	draw_style_box(_button_box(WOOD, GOLD_DARK, 2, 7), score_plaque)
	for p in [Vector2(45,182),Vector2(w-45,182),Vector2(50,686),Vector2(w-50,686)]:
		draw_circle(p, 6.0, GOLD)
		draw_arc(p, 6.0, 0.0, TAU, 18, GOLD_DARK, 1.5, true)
