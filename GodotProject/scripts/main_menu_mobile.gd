extends "res://scripts/main_menu.gd"

const MOCKUP_W := 390.0
const MOCKUP_H := 844.0
const API_URL := "https://pirate-plunder.vercel.app/api/leaderboard"
const LEADERBOARD_SAVE := "user://leaderboard.cfg"

var exact_bg: TextureRect
var leaderboard_button: Button
var trophy_button: Button
var button_visuals: Dictionary = {}
var leaderboard_overlay: Control = null
var leaderboard_rows: VBoxContainer = null
var leaderboard_status: Label = null
var leaderboard_http: HTTPRequest = null

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

	# Remove the baked HOW TO PLAY button visually by covering it with a clean
	# ocean patch taken from the same approved menu artwork.
	var remove_how := TextureRect.new()
	remove_how.name = "HowToPlayRemovalPatch"
	var how_atlas := AtlasTexture.new()
	how_atlas.atlas = exact_bg.texture
	how_atlas.region = Rect2(44, 326, 302, 82)
	remove_how.texture = how_atlas
	remove_how.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	remove_how.stretch_mode = TextureRect.STRETCH_SCALE
	remove_how.position = Vector2(74, 579)
	remove_how.size = Vector2(242, 82)
	remove_how.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(remove_how)
	remove_how.move_to_front()

	play_button.visible = true
	_make_live_button(play_button, Rect2(77, 399, 230, 90))
	play_button.move_to_front()

	leaderboard_button = Button.new()
	leaderboard_button.name = "LeaderboardButton"
	add_child(leaderboard_button)
	_make_live_button(leaderboard_button, Rect2(80, 504, 228, 69))
	leaderboard_button.pressed.connect(_open_leaderboard_page)
	leaderboard_button.move_to_front()

	trophy_button = Button.new()
	trophy_button.name = "CollectiblesButton"
	add_child(trophy_button)
	_make_live_button(trophy_button, Rect2(319, 8, 55, 86))
	trophy_button.pressed.connect(_open_collectibles)
	trophy_button.move_to_front()

	# The red rectangle was baked into the supplied mockup. Cover only those
	# four thin red edges so the actual trophy artwork remains untouched.
	_add_trophy_border_cover(Vector2(315, 4), Vector2(4, 94))
	_add_trophy_border_cover(Vector2(319, 4), Vector2(59, 4))
	_add_trophy_border_cover(Vector2(374, 4), Vector2(4, 94))
	_add_trophy_border_cover(Vector2(319, 94), Vector2(59, 4))

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

func _add_trophy_border_cover(pos: Vector2, sz: Vector2) -> void:
	var cover := ColorRect.new()
	cover.color = Color("123454")
	cover.position = pos
	cover.size = sz
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 5
	cover.set_meta("base_pos", pos)
	cover.set_meta("base_size", sz)
	cover.add_to_group("trophy_border_cover")
	add_child(cover)
	cover.move_to_front()
	if trophy_button:
		var art := button_visuals.get(trophy_button) as TextureRect
		if art: art.move_to_front()
		trophy_button.move_to_front()

func _press_visual(button: Button) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null: return
	art.modulate = Color(0.82, 0.82, 0.82, 1.0)
	art.scale = Vector2(0.965, 0.965)

func _release_visual(button: Button) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null: return
	art.modulate = Color.WHITE
	art.scale = Vector2.ONE

func _hover_visual(button: Button, hovering: bool) -> void:
	var art := button_visuals.get(button) as TextureRect
	if art == null or button.button_pressed: return
	art.modulate = Color(1.06, 1.06, 1.06, 1.0) if hovering else Color.WHITE

func _layout_exact() -> void:
	if exact_bg == null: return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size
	var sx := size.x / MOCKUP_W
	var sy := size.y / MOCKUP_H
	for button in [play_button, leaderboard_button, trophy_button]:
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
	for node in get_tree().get_nodes_in_group("trophy_border_cover"):
		if node is ColorRect and node.get_parent() == self:
			var c := node as ColorRect
			var bp: Vector2 = c.get_meta("base_pos")
			var bs: Vector2 = c.get_meta("base_size")
			c.position = Vector2(bp.x * sx, bp.y * sy)
			c.size = Vector2(bs.x * sx, bs.y * sy)
	if leaderboard_overlay != null and is_instance_valid(leaderboard_overlay):
		leaderboard_overlay.size = size

func _open_collectibles() -> void:
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("open_from_menu"):
		collectibles.call("open_from_menu", self)

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
	back.pressed.connect(func(): leaderboard_overlay.visible = false)
	frame.add_child(back)

	leaderboard_http = HTTPRequest.new()
	leaderboard_http.name = "MenuLeaderboardRequest"
	leaderboard_overlay.add_child(leaderboard_http)
	leaderboard_http.request_completed.connect(_on_leaderboard_loaded)

	leaderboard_overlay.move_to_front()
	_request_leaderboard()

func _request_leaderboard() -> void:
	if leaderboard_rows == null: return
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
	var player_id := ""
	var cfg := ConfigFile.new()
	if cfg.load(LEADERBOARD_SAVE) == OK:
		player_id = String(cfg.get_value("player", "id", ""))
	var url := API_URL
	if not player_id.is_empty():
		url += "?playerId=%s" % player_id.uri_encode()
	var err := leaderboard_http.request(url)
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
		rows = parsed
	elif parsed is Dictionary:
		var data := parsed as Dictionary
		for key in ["leaderboard", "top10", "top", "scores", "entries"]:
			var candidate: Variant = data.get(key, null)
			if candidate is Array:
				rows = candidate
				break
	if rows.is_empty():
		leaderboard_status.text = "No scores yet"
		return
	var limit := mini(10, rows.size())
	for i in range(limit):
		var raw: Variant = rows[i]
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 38)
		row.add_theme_constant_override("separation", 6)
		var rank := Label.new()
		rank.text = "#%d" % (i + 1)
		rank.custom_minimum_size = Vector2(42, 0)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.add_theme_font_size_override("font_size", 15)
		rank.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(rank)
		var name := Label.new()
		name.text = String(entry.get("name", entry.get("playerName", "Pirate")))
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name.add_theme_font_size_override("font_size", 15)
		name.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(name)
		var score := Label.new()
		score.text = _comma(int(entry.get("score", entry.get("bestScore", 0))))
		score.custom_minimum_size = Vector2(82, 0)
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score.add_theme_font_size_override("font_size", 15)
		score.add_theme_color_override("font_color", Color("24160f"))
		row.add_child(score)
		leaderboard_rows.add_child(row)
	leaderboard_status.text = "Global top 10"

func _clear_leaderboard_rows() -> void:
	if leaderboard_rows == null: return
	for child in leaderboard_rows.get_children():
		child.queue_free()
