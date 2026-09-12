extends Node

const STATS_SAVE := "user://profile_stats.cfg"
const LEADERBOARD_SAVE := "user://leaderboard.cfg"
const MUSIC_SAVE := "user://music.cfg"

const GOLD := Color("f4c64d")
const GOLD_DARK := Color("9b5c16")
const WOOD := Color("3a2115")
const WOOD_LIGHT := Color("5b3520")
const RED := Color("8d1718")
const PARCHMENT := Color("e8c989")
const INK := Color("24160f")
const SEA := Color("0b3340")

var overlay: Control = null
var settings_pressed := false
var run_active := false
var last_game_over := false

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	_migrate_old_coin_total()

func _input(event: InputEvent) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var settings_hit := scene.find_child("SettingsHitbox", true, false) as Control
	if settings_hit == null or not settings_hit.is_visible_in_tree():
		return
	var pos := Vector2.ZERO
	var is_press := false
	var is_release := false
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pos = touch.position
		is_press = touch.pressed
		is_release = not touch.pressed
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = mouse.position
		is_press = mouse.pressed
		is_release = not mouse.pressed
	else:
		return
	var inside := settings_hit.get_global_rect().has_point(pos)
	if is_press and inside:
		settings_pressed = true
		get_viewport().set_input_as_handled()
	elif is_release:
		var should_open := settings_pressed and inside
		settings_pressed = false
		if should_open:
			_open_settings(settings_hit.get_parent() as Control)
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	var game := get_tree().current_scene
	if game == null:
		return
	var started_value: Variant = game.get("game_started")
	var over_value: Variant = game.get("game_over")
	if started_value == null or over_value == null:
		return
	var started := bool(started_value)
	var over := bool(over_value)
	if started and not over:
		run_active = true
	if run_active and over and not last_game_over:
		_record_finished_run(game)
		run_active = false
	last_game_over = over

func _record_finished_run(game: Node) -> void:
	var run_coins := maxi(0, int(game.get("coins_collected")))
	var run_score := maxi(0, int(game.get("score")))
	var cfg := ConfigFile.new()
	cfg.load(STATS_SAVE)
	var total_coins := maxi(0, int(cfg.get_value("stats", "total_coins", 0))) + run_coins
	var runs := maxi(0, int(cfg.get_value("stats", "runs_played", 0))) + 1
	var best_coin_run := maxi(int(cfg.get_value("stats", "best_coin_run", 0)), run_coins)
	var total_score := maxi(0, int(cfg.get_value("stats", "total_score", 0))) + run_score
	cfg.set_value("stats", "total_coins", total_coins)
	cfg.set_value("stats", "runs_played", runs)
	cfg.set_value("stats", "best_coin_run", best_coin_run)
	cfg.set_value("stats", "total_score", total_score)
	cfg.save(STATS_SAVE)

func _migrate_old_coin_total() -> void:
	var stats := ConfigFile.new()
	stats.load(STATS_SAVE)
	if int(stats.get_value("stats", "total_coins", 0)) > 0:
		return
	var old := ConfigFile.new()
	if old.load("user://collectibles.cfg") == OK:
		var old_total := maxi(0, int(old.get_value("progress", "total_coins", 0)))
		if old_total > 0:
			stats.set_value("stats", "total_coins", old_total)
			stats.save(STATS_SAVE)

func _open_settings(menu: Control) -> void:
	if menu == null:
		return
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = Control.new()
	overlay.name = "SettingsProfileOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 3000
	menu.add_child(overlay)
	overlay.move_to_front()
	_build_settings_view()

func _clear_overlay() -> void:
	if overlay == null:
		return
	for child in overlay.get_children():
		child.queue_free()

func _panel(fill: Color, border: Color, width := 3, radius := 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	return s

func _make_button(text_value: String, pos: Vector2, node_size: Vector2, action: Callable, red_style := false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.position = pos
	b.size = node_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 19)
	if red_style:
		b.add_theme_color_override("font_color", Color("fff1bd"))
		b.add_theme_stylebox_override("normal", _panel(RED, GOLD, 3, 10))
		b.add_theme_stylebox_override("hover", _panel(Color("a51e1f"), Color("ffd86a"), 3, 10))
		b.add_theme_stylebox_override("pressed", _panel(Color("671011"), GOLD_DARK, 3, 10))
	else:
		b.add_theme_color_override("font_color", INK)
		b.add_theme_stylebox_override("normal", _panel(PARCHMENT, Color("b78645"), 2, 10))
		b.add_theme_stylebox_override("hover", _panel(Color("f4dfb2"), GOLD, 2, 10))
		b.add_theme_stylebox_override("pressed", _panel(Color("d8bd82"), GOLD_DARK, 2, 10))
	b.pressed.connect(action)
	overlay.add_child(b)
	return b

func _build_shell(title_text: String) -> Panel:
	var bg := ColorRect.new()
	bg.color = Color("071923")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)
	var outer := Panel.new()
	outer.position = Vector2(20, 52)
	outer.size = Vector2(350, 728)
	outer.add_theme_stylebox_override("panel", _panel(WOOD, GOLD_DARK, 3, 16))
	overlay.add_child(outer)
	var title := Label.new()
	title.text = "☠  %s" % title_text
	title.position = Vector2(20, 18)
	title.size = Vector2(310, 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	outer.add_child(title)
	return outer

func _build_settings_view() -> void:
	_clear_overlay()
	var outer := _build_shell("SETTINGS")
	var section := Label.new()
	section.text = "GAMEPLAY MUSIC"
	section.position = Vector2(28, 120)
	section.size = Vector2(294, 32)
	section.add_theme_font_size_override("font_size", 18)
	section.add_theme_color_override("font_color", Color("fff1c4"))
	outer.add_child(section)
	var desc := Label.new()
	desc.text = "Turn the sea-shanty music on or off during gameplay."
	desc.position = Vector2(28, 154)
	desc.size = Vector2(294, 52)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color("d9f4fb"))
	outer.add_child(desc)
	var music_button := _make_button("MUSIC: ON" if _music_enabled() else "MUSIC: OFF", Vector2(72, 230), Vector2(246, 54), Callable(self, "_toggle_music"), true)
	music_button.name = "GameplayMusicToggle"
	var profile_label := Label.new()
	profile_label.text = "PLAYER"
	profile_label.position = Vector2(28, 348)
	profile_label.size = Vector2(294, 32)
	profile_label.add_theme_font_size_override("font_size", 18)
	profile_label.add_theme_color_override("font_color", Color("fff1c4"))
	outer.add_child(profile_label)
	_make_button("PROFILE & STATS", Vector2(72, 392), Vector2(246, 54), Callable(self, "_build_profile_view"), false)
	_make_button("BACK", Vector2(72, 650), Vector2(246, 50), Callable(self, "_close_overlay"), false)

func _music_enabled() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(MUSIC_SAVE) == OK:
		return bool(cfg.get_value("audio", "music_enabled", true))
	return true

func _toggle_music() -> void:
	var enabled := not _music_enabled()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_enabled", enabled)
	cfg.save(MUSIC_SAVE)
	var scene := get_tree().current_scene
	if scene != null:
		var music := scene.get_node_or_null("ProceduralMusic")
		if music != null:
			music.set("music_enabled", enabled)
			if music.has_method("_apply_enabled_state"):
				music.call("_apply_enabled_state")
	_build_settings_view()

func _build_profile_view() -> void:
	_clear_overlay()
	var outer := _build_shell("PROFILE")
	var board := ConfigFile.new()
	board.load(LEADERBOARD_SAVE)
	var player_name := String(board.get_value("player", "name", "Pirate")).strip_edges()
	if player_name.is_empty():
		player_name = "Pirate"
	var high_score := maxi(0, int(board.get_value("player", "personal_best", 0)))
	var stats := ConfigFile.new()
	stats.load(STATS_SAVE)
	var total_coins := maxi(0, int(stats.get_value("stats", "total_coins", 0)))
	var runs := maxi(0, int(stats.get_value("stats", "runs_played", 0)))
	var best_coin_run := maxi(0, int(stats.get_value("stats", "best_coin_run", 0)))
	var total_score := maxi(0, int(stats.get_value("stats", "total_score", 0)))
	var current_ship := "Regular Ship"
	var collectibles := get_node_or_null("/root/BoatCollectibles")
	if collectibles != null and collectibles.has_method("get_selected_name"):
		current_ship = String(collectibles.call("get_selected_name"))
	var name_label := Label.new()
	name_label.text = player_name
	name_label.position = Vector2(30, 86)
	name_label.size = Vector2(290, 44)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("fff1c4"))
	outer.add_child(name_label)
	var parchment := Panel.new()
	parchment.position = Vector2(24, 146)
	parchment.size = Vector2(302, 420)
	parchment.add_theme_stylebox_override("panel", _panel(PARCHMENT, Color("b78645"), 3, 12))
	outer.add_child(parchment)
	_add_stat_row(parchment, "HIGH SCORE", _comma(high_score), 28)
	_add_stat_row(parchment, "TOTAL COINS COLLECTED", _comma(total_coins), 96)
	_add_stat_row(parchment, "RUNS PLAYED", _comma(runs), 164)
	_add_stat_row(parchment, "BEST COINS IN A RUN", _comma(best_coin_run), 232)
	_add_stat_row(parchment, "TOTAL SCORE EARNED", _comma(total_score), 300)
	var ship_title := Label.new()
	ship_title.text = "CURRENT SHIP"
	ship_title.position = Vector2(20, 360)
	ship_title.size = Vector2(262, 22)
	ship_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_title.add_theme_font_size_override("font_size", 12)
	ship_title.add_theme_color_override("font_color", Color("6b3f1c"))
	parchment.add_child(ship_title)
	var ship_value := Label.new()
	ship_value.text = current_ship.to_upper()
	ship_value.position = Vector2(20, 382)
	ship_value.size = Vector2(262, 30)
	ship_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_value.add_theme_font_size_override("font_size", 18)
	ship_value.add_theme_color_override("font_color", RED)
	parchment.add_child(ship_value)
	_make_button("BACK TO SETTINGS", Vector2(72, 650), Vector2(246, 50), Callable(self, "_build_settings_view"), false)

func _add_stat_row(parent: Control, label_text: String, value_text: String, y: float) -> void:
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(20, y)
	label.size = Vector2(150, 24)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("6b3f1c"))
	parent.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.position = Vector2(168, y - 2)
	value.size = Vector2(112, 28)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", RED)
	parent.add_child(value)

func _close_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

func _comma(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
