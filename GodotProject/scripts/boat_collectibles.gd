extends Node

const SAVE_PATH := "user://collectibles.cfg"
const BOATS := ["Plunderer", "Crimson Raider", "Black Pearl", "Royal Fortune", "Ghost Ship", "Inferno", "Sea Serpent", "Golden Galleon"]
const SUBTITLES := ["Default Ship", "Raider Variant", "Shadow Variant", "Royal Variant", "Spectral Variant", "Infernal Variant", "Serpent Variant", "Legendary Variant"]
const SHIP_SVGS := [
	"res://assets/ships/plunderer.svg", "res://assets/ships/crimson_raider.svg", "res://assets/ships/black_pearl.svg", "res://assets/ships/royal_fortune.svg",
	"res://assets/ships/ghost_ship.svg", "res://assets/ships/inferno.svg", "res://assets/ships/sea_serpent.svg", "res://assets/ships/golden_galleon.svg"
]
const COLORS := [Color("9a6231"), Color("c8322f"), Color("20242b"), Color("f2e5c2"), Color("7fa7a1"), Color("e64a19"), Color("159b91"), Color("d6a51e")]
var selected_index := 0
var preview_index := 0
var panel: Panel
var menu: Control
var trophy_button: Button
var preview_texture: TextureRect
var ship_title: Label
var ship_subtitle: Label
var equip_button: Button

func _ready() -> void:
	_load_selection()
	preview_index = selected_index
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_find_menu")

func _load_selection() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		selected_index = clampi(int(cfg.get_value("boats", "selected", 0)), 0, BOATS.size() - 1)

func _save_selection() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("boats", "selected", selected_index)
	cfg.save(SAVE_PATH)

func get_selected_index() -> int: return selected_index
func get_selected_name() -> String: return BOATS[selected_index]
func get_selected_color() -> Color: return COLORS[selected_index]

func _on_node_added(node: Node) -> void:
	if node.name == "PlayButton" or node.name == "GameTitle": call_deferred("_find_menu")

func _find_menu() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var play := scene.find_child("PlayButton", true, false) as Button
	if play == null: return
	menu = play.get_parent() as Control
	if menu == null or (trophy_button != null and is_instance_valid(trophy_button)): return
	_create_trophy_button()

func _create_trophy_button() -> void:
	trophy_button = Button.new()
	trophy_button.name = "CollectiblesButton"
	trophy_button.text = "🏆"
	trophy_button.tooltip_text = "Boat Collectibles"
	trophy_button.focus_mode = Control.FOCUS_NONE
	trophy_button.mouse_filter = Control.MOUSE_FILTER_STOP
	trophy_button.z_index = 10000
	trophy_button.add_theme_font_size_override("font_size", 25)
	trophy_button.add_theme_color_override("font_color", Color("f6c53d"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.03, 0.16, 0.20, 0.94)
	normal.border_color = Color("f6c53d")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	trophy_button.add_theme_stylebox_override("normal", normal)
	trophy_button.add_theme_stylebox_override("hover", normal)
	menu.add_child(trophy_button)
	trophy_button.position = Vector2(328, 18)
	trophy_button.size = Vector2(46, 46)
	trophy_button.pressed.connect(_open_panel)
	trophy_button.move_to_front()

func _open_panel() -> void:
	if menu == null or not is_instance_valid(menu): return
	preview_index = selected_index
	if panel != null and is_instance_valid(panel):
		panel.visible = true
		panel.move_to_front()
		_refresh_collectibles_ui()
		return
	_build_collectibles_panel()

func _build_collectibles_panel() -> void:
	panel = Panel.new()
	panel.name = "CollectiblesPanel"
	panel.position = Vector2(12, 78)
	panel.size = Vector2(366, 730)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 20000
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color("081b25")
	outer.border_color = Color("8b5b2d")
	outer.set_border_width_all(4)
	outer.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", outer)
	menu.add_child(panel)

	var heading := Label.new()
	heading.text = "COLLECTIBLES"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.position = Vector2(18, 10)
	heading.size = Vector2(330, 44)
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("f6d18a"))
	panel.add_child(heading)

	var ships_tab := Button.new()
	ships_tab.text = "SHIPS"
	ships_tab.disabled = true
	ships_tab.position = Vector2(20, 58)
	ships_tab.size = Vector2(326, 40)
	ships_tab.add_theme_font_size_override("font_size", 18)
	ships_tab.add_theme_color_override("font_disabled_color", Color.WHITE)
	var tab_box := StyleBoxFlat.new()
	tab_box.bg_color = Color("1266a4")
	tab_box.border_color = Color("4ec9ff")
	tab_box.set_border_width_all(2)
	tab_box.set_corner_radius_all(10)
	ships_tab.add_theme_stylebox_override("disabled", tab_box)
	panel.add_child(ships_tab)

	ship_title = Label.new()
	ship_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_title.position = Vector2(25, 103)
	ship_title.size = Vector2(316, 34)
	ship_title.add_theme_font_size_override("font_size", 23)
	ship_title.add_theme_color_override("font_color", Color("f6d18a"))
	panel.add_child(ship_title)
	ship_subtitle = Label.new()
	ship_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_subtitle.position = Vector2(25, 137)
	ship_subtitle.size = Vector2(316, 24)
	ship_subtitle.add_theme_font_size_override("font_size", 13)
	ship_subtitle.add_theme_color_override("font_color", Color("d9f4fb"))
	panel.add_child(ship_subtitle)

	var showcase := Panel.new()
	showcase.position = Vector2(55, 165)
	showcase.size = Vector2(256, 205)
	var showcase_box := StyleBoxFlat.new()
	showcase_box.bg_color = Color("07131c")
	showcase_box.border_color = Color("17445d")
	showcase_box.set_border_width_all(2)
	showcase_box.set_corner_radius_all(18)
	showcase.add_theme_stylebox_override("panel", showcase_box)
	panel.add_child(showcase)
	preview_texture = TextureRect.new()
	preview_texture.position = Vector2(43, 10)
	preview_texture.size = Vector2(170, 185)
	preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	showcase.add_child(preview_texture)

	for data in [["<", 12, -1], [">", 316, 1]]:
		var arrow := Button.new()
		arrow.text = data[0]
		arrow.position = Vector2(data[1], 230)
		arrow.size = Vector2(38, 64)
		arrow.focus_mode = Control.FOCUS_NONE
		arrow.add_theme_font_size_override("font_size", 24)
		arrow.pressed.connect(_cycle_preview.bind(data[2]))
		panel.add_child(arrow)

	equip_button = Button.new()
	equip_button.position = Vector2(96, 378)
	equip_button.size = Vector2(174, 44)
	equip_button.focus_mode = Control.FOCUS_NONE
	equip_button.add_theme_font_size_override("font_size", 17)
	equip_button.pressed.connect(_equip_preview)
	panel.add_child(equip_button)

	var board := Panel.new()
	board.position = Vector2(16, 432)
	board.size = Vector2(334, 224)
	board.clip_contents = true
	var board_style := StyleBoxFlat.new()
	board_style.bg_color = Color("ead4a1")
	board_style.border_color = Color("6a4927")
	board_style.set_border_width_all(2)
	board_style.set_corner_radius_all(10)
	board.add_theme_stylebox_override("panel", board_style)
	panel.add_child(board)

	# Strict 4 x 2 grid. Every ship is contained inside its own 76x101 card.
	for i in range(BOATS.size()):
		var col := i % 4
		var row := int(i / 4)
		var card := Button.new()
		card.name = "ShipCard%d" % i
		card.text = ""
		card.position = Vector2(8 + col * 81, 7 + row * 105)
		card.size = Vector2(74, 100)
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.clip_contents = true
		card.pressed.connect(_select_preview.bind(i))
		board.add_child(card)

		var thumb := TextureRect.new()
		thumb.texture = load(SHIP_SVGS[i]) as Texture2D
		thumb.position = Vector2(10, 3)
		thumb.size = Vector2(54, 70)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(thumb)

		var label := Label.new()
		label.text = BOATS[i]
		label.position = Vector2(3, 74)
		label.size = Vector2(68, 23)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", Color("2b1a0c"))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(label)

	var close := Button.new()
	close.text = "BACK"
	close.position = Vector2(108, 670)
	close.size = Vector2(150, 42)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_panel)
	panel.add_child(close)
	panel.move_to_front()
	_refresh_collectibles_ui()

func _cycle_preview(delta: int) -> void:
	preview_index = wrapi(preview_index + delta, 0, BOATS.size())
	_refresh_collectibles_ui()

func _select_preview(index: int) -> void:
	preview_index = clampi(index, 0, BOATS.size() - 1)
	_refresh_collectibles_ui()

func _equip_preview() -> void:
	selected_index = preview_index
	_save_selection()
	_refresh_collectibles_ui()

func _refresh_collectibles_ui() -> void:
	if panel == null or not is_instance_valid(panel): return
	if ship_title: ship_title.text = BOATS[preview_index].to_upper()
	if ship_subtitle: ship_subtitle.text = SUBTITLES[preview_index]
	if preview_texture: preview_texture.texture = load(SHIP_SVGS[preview_index]) as Texture2D
	if equip_button:
		equip_button.text = "EQUIPPED" if preview_index == selected_index else "SELECT SHIP"
		equip_button.disabled = preview_index == selected_index
	for i in range(BOATS.size()):
		var card := panel.find_child("ShipCard%d" % i, true, false) as Button
		if card:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(1, 1, 1, 0.06)
			if i == selected_index:
				style.border_color = Color("54e66a")
				style.set_border_width_all(3)
			elif i == preview_index:
				style.border_color = Color("f6c53d")
				style.set_border_width_all(3)
			else:
				style.border_color = Color(0,0,0,0)
			style.set_corner_radius_all(7)
			card.add_theme_stylebox_override("normal", style)
			card.add_theme_stylebox_override("hover", style)
			card.add_theme_stylebox_override("pressed", style)

func _close_panel() -> void:
	if panel != null and is_instance_valid(panel): panel.visible = false
