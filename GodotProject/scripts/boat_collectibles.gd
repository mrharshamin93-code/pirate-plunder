extends Node

const SAVE_PATH := "user://collectibles.cfg"
const BOATS := ["Plunderer", "Crimson Raider", "Black Pearl", "Royal Fortune", "Ghost Ship", "Inferno", "Sea Serpent", "Golden Galleon"]
const COLORS := [Color("9a6231"), Color("c8322f"), Color("20242b"), Color("f2e5c2"), Color("7fa7a1"), Color("e64a19"), Color("159b91"), Color("d6a51e")]
var selected_index: int = 0
var panel: Panel = null
var menu: Control = null

func _ready() -> void:
	_load_selection()
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_find_menu")

func _load_selection() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		selected_index = clampi(int(cfg.get_value("boats", "selected", 0)), 0, BOATS.size()-1)

func _save_selection() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("boats", "selected", selected_index)
	cfg.save(SAVE_PATH)

func get_selected_index() -> int:
	return selected_index

func get_selected_name() -> String:
	return BOATS[selected_index]

func get_selected_color() -> Color:
	return COLORS[selected_index]

func _on_node_added(node: Node) -> void:
	if node.name == "PlayButton":
		call_deferred("_find_menu")

func _find_menu() -> void:
	var scene := get_tree().current_scene
	if scene == null: return
	var play := scene.find_child("PlayButton", true, false) as Button
	if play == null: return
	menu = play.get_parent() as Control
	if menu == null or menu.get_node_or_null("CollectiblesButton") != null: return
	var b := Button.new()
	b.name = "CollectiblesButton"
	b.text = "COLLECTIBLES"
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color("f6c53d"))
	b.position = Vector2(112, 750)
	b.size = Vector2(166, 38)
	b.pressed.connect(_open_panel)
	menu.add_child(b)
	b.move_to_front()

func _open_panel() -> void:
	if panel != null and is_instance_valid(panel):
		panel.visible = true
		return
	panel = Panel.new()
	panel.name = "CollectiblesPanel"
	panel.position = Vector2(18, 160)
	panel.size = Vector2(354, 560)
	panel.z_index = 500
	var box := StyleBoxFlat.new()
	box.bg_color = Color("082e3c")
	box.border_color = Color("f6c53d")
	box.set_border_width_all(3)
	box.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", box)
	menu.add_child(panel)
	var title := Label.new()
	title.text = "BOAT COLLECTIBLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20, 16); title.size = Vector2(314, 38)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("f6c53d"))
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "SelectedBoat"
	sub.text = "Equipped: %s" % get_selected_name()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(20, 52); sub.size = Vector2(314, 26)
	sub.add_theme_color_override("font_color", Color("d9f4fb"))
	panel.add_child(sub)
	for i in range(BOATS.size()):
		var button := Button.new()
		button.name = "Boat%d" % i
		button.text = BOATS[i]
		button.position = Vector2(24 + (i%2)*157, 92 + (i/2)*92)
		button.size = Vector2(148, 72)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("ffffff"))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(COLORS[i], 0.78)
		sb.border_color = Color("f6c53d") if i == selected_index else Color("315b66")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(10)
		button.add_theme_stylebox_override("normal", sb)
		button.pressed.connect(_select_boat.bind(i))
		panel.add_child(button)
	var close := Button.new()
	close.text = "BACK"
	close.position = Vector2(102, 478); close.size = Vector2(150, 48)
	close.pressed.connect(func(): panel.visible = false)
	panel.add_child(close)
	panel.move_to_front()

func _select_boat(index: int) -> void:
	selected_index = index
	_save_selection()
	var label := panel.get_node_or_null("SelectedBoat") as Label
	if label: label.text = "Equipped: %s" % get_selected_name()
	for i in range(BOATS.size()):
		var b := panel.get_node_or_null("Boat%d" % i) as Button
		if b:
			var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
			if sb: sb.border_color = Color("f6c53d") if i == selected_index else Color("315b66")
