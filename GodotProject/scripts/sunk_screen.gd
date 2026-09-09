extends ColorRect

const GOLD: Color = Color("f4c64d")
const GOLD_DARK: Color = Color("9b5c16")
const PARCHMENT: Color = Color("e8c989")
const PARCHMENT_DARK: Color = Color("b78645")
const WOOD: Color = Color("3a2115")
const WOOD_LIGHT: Color = Color("5b3520")
const RED: Color = Color("8d1718")
const INK: Color = Color("24160f")
const SEA: Color = Color("073d54")

var name_entry: LineEdit
var submit_button: Button
var share_button: Button
var leaderboard_box: VBoxContainer
var footer_label: Label
var leaderboard: Array[Dictionary] = [
	{"name":"CaptainKidd", "score":12480},
	{"name":"SeaDog92", "score":9750},
	{"name":"TreasureTina", "score":8620},
	{"name":"BlueBeard", "score":7300},
	{"name":"MarauderMike", "score":6910},
	{"name":"SaltySam", "score":6420},
	{"name":"OceanOracle", "score":5880},
	{"name":"StormChaser", "score":3960},
	{"name":"AnchorAway", "score":3210}
]

func _ready() -> void:
	color = Color(0, 0, 0, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	$Title.visible = false
	$LeaderboardTitle.visible = false
	$ComingSoon.visible = false
	_style_existing_score()
	_style_play_again()
	_build_ui()
	visibility_changed.connect(_on_visibility_changed)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_ui")
		queue_redraw()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_from_game()

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
	b.offset_top = 730.0
	b.offset_right = 328.0
	b.offset_bottom = 790.0
	b.text = "⚔  PLAY AGAIN"
	b.add_theme_font_size_override("font_size", 25)
	b.add_theme_color_override("font_color", Color("fff2b2"))
	b.add_theme_stylebox_override("normal", _button_box(RED, GOLD, 4, 12))
	b.add_theme_stylebox_override("hover", _button_box(Color("a51e1f"), Color("ffd86a"), 4, 12))
	b.add_theme_stylebox_override("pressed", _button_box(Color("671011"), GOLD_DARK, 4, 12))

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
	name_entry.max_length = 18
	name_entry.add_theme_font_size_override("font_size", 18)
	name_entry.add_theme_color_override("font_color", INK)
	name_entry.add_theme_color_override("font_placeholder_color", Color(0.25,0.18,0.12,0.55))
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
	share_button.text = "⇧\nSHARE"
	share_button.add_theme_font_size_override("font_size", 13)
	share_button.add_theme_color_override("font_color", Color("fff0b5"))
	share_button.add_theme_stylebox_override("normal", _button_box(WOOD, GOLD, 3, 8))
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
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color("fff1cc"))
	add_child(footer_label)

	_layout_ui()

func _layout_ui() -> void:
	var w: float = size.x
	var sx: float = w / 390.0
	var hero: Control = get_node_or_null("HeroTitle") as Control
	if hero:
		hero.position = Vector2(30.0*sx, 46.0)
		hero.size = Vector2(w-60.0*sx, 64.0)
	var subtitle: Control = get_node_or_null("Subtitle") as Control
	if subtitle:
		subtitle.position = Vector2(32.0*sx, 112.0)
		subtitle.size = Vector2(w-64.0*sx, 30.0)
	var score_title: Control = get_node_or_null("ScoreTitle") as Control
	if score_title:
		score_title.position = Vector2(55.0*sx, 188.0)
		score_title.size = Vector2(w-110.0*sx, 35.0)
	if name_entry:
		name_entry.position = Vector2(45.0*sx, 302.0)
		name_entry.size = Vector2(215.0*sx, 48.0)
	if submit_button:
		submit_button.position = Vector2(266.0*sx, 302.0)
		submit_button.size = Vector2(82.0*sx, 48.0)
	if share_button:
		share_button.position = Vector2(w-72.0*sx, 25.0)
		share_button.size = Vector2(58.0*sx, 62.0)
	var board_title: Control = get_node_or_null("BoardTitle") as Control
	if board_title:
		board_title.position = Vector2(62.0*sx, 376.0)
		board_title.size = Vector2(w-124.0*sx, 40.0)
	if leaderboard_box:
		leaderboard_box.position = Vector2(52.0*sx, 420.0)
		leaderboard_box.size = Vector2(w-104.0*sx, 285.0)
	if footer_label:
		footer_label.position = Vector2(40.0*sx, 798.0)
		footer_label.size = Vector2(w-80.0*sx, 24.0)

func _refresh_from_game() -> void:
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	$Score.text = _comma(current_score)
	_build_leaderboard(current_score, "You")
	footer_label.text = "Your score: %s" % _comma(current_score)
	queue_redraw()

func _submit_score() -> void:
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	var player_name: String = name_entry.text.strip_edges()
	if player_name.is_empty():
		player_name = "You"
	_build_leaderboard(current_score, player_name)
	footer_label.text = "Score submitted locally as %s" % player_name

func _share_score() -> void:
	var game: Node = get_parent().get_parent()
	var current_score: int = int(game.get("score"))
	DisplayServer.clipboard_set("I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score))
	footer_label.text = "Score copied — ready to share!"

func _build_leaderboard(current_score: int, player_name: String) -> void:
	for child in leaderboard_box.get_children():
		child.queue_free()
	var rows: Array[Dictionary] = []
	for entry in leaderboard:
		rows.append(entry.duplicate())
	rows.append({"name":player_name, "score":current_score, "you":true})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))
	var limit: int = mini(10, rows.size())
	for i in range(limit):
		var entry: Dictionary = rows[i]
		var row: PanelContainer = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 27)
		if bool(entry.get("you", false)):
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
		rank.add_theme_color_override("font_color", INK if not bool(entry.get("you", false)) else Color("fff3c8"))
		h.add_child(rank)
		var nm: Label = Label.new()
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.text = String(entry["name"])
		nm.add_theme_font_size_override("font_size", 15)
		nm.add_theme_color_override("font_color", INK if not bool(entry.get("you", false)) else Color("fff3c8"))
		h.add_child(nm)
		var sc: Label = Label.new()
		sc.custom_minimum_size = Vector2(72, 0)
		sc.text = "●  %s" % _comma(int(entry["score"]))
		sc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sc.add_theme_font_size_override("font_size", 15)
		sc.add_theme_color_override("font_color", Color("6d3f10") if not bool(entry.get("you", false)) else GOLD)
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
	# Deep-water backdrop.
	draw_rect(Rect2(Vector2.ZERO, Vector2(w,h)), Color("052f43"))
	for i in range(7):
		var y: float = float(i) * h / 7.0
		draw_circle(Vector2(35.0 + float(i%3)*155.0, y + 70.0), 5.0 + float(i%2)*3.0, Color(0.55,0.92,1.0,0.22))
	# Hero wood sign.
	var hero_rect: Rect2 = Rect2(28.0, 35.0, w-56.0, 115.0)
	draw_style_box(_button_box(WOOD, GOLD_DARK, 4, 15), hero_rect)
	for yy in [66.0, 95.0, 124.0]:
		draw_line(Vector2(38.0,yy), Vector2(w-38.0,yy), Color(WOOD_LIGHT,0.45), 2.0)
	# Parchment body.
	var paper: Rect2 = Rect2(30.0, 164.0, w-60.0, 555.0)
	draw_style_box(_button_box(PARCHMENT, PARCHMENT_DARK, 3, 18), paper)
	# Dark score plaque.
	var score_plaque: Rect2 = Rect2(70.0, 228.0, w-140.0, 62.0)
	draw_style_box(_button_box(WOOD, GOLD_DARK, 2, 7), score_plaque)
	# Small decorative gold coins and divider marks.
	for p in [Vector2(45,182),Vector2(w-45,182),Vector2(50,704),Vector2(w-50,704)]:
		draw_circle(p, 6.0, GOLD)
		draw_arc(p, 6.0, 0.0, TAU, 18, GOLD_DARK, 1.5, true)
