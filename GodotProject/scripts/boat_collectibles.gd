extends Node

const SAVE_PATH := "user://collectibles.cfg"
const BOATS := ["Plunderer", "Crimson Raider", "Black Pearl", "Royal Fortune", "Ghost Ship", "Inferno", "Sea Serpent", "Golden Galleon"]
const COLORS := [Color("9a6231"), Color("c8322f"), Color("20242b"), Color("f2e5c2"), Color("7fa7a1"), Color("e64a19"), Color("159b91"), Color("d6a51e")]
var selected_index: int = 0
var panel: Panel = null
var menu: Control = null
var trophy_button: Button = null

func _ready() -> void:
	_load_selection()
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

func get_selected_index() -> int:
	return selected_index

func get_selected_name() -> String:
	return BOATS[selected_index]

func get_selected_color() -> Color:
	return COLORS[selected_index]

func _on_node_added(node: Node) -> void:
	if node.name == "PlayButton" or node.name == "GameTitle":
		call_deferred("_find_menu")

func _find_menu() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var play := scene.find_child("PlayButton", true, false) as Button
	if play == null:
		return
	# PlayButton is created directly by main_menu.gd, so its parent IS the full-screen menu root.
	menu = play.get_parent() as Control
	if menu == null:
		return
	if trophy_button != null and is_instance_valid(trophy_button):
		return
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
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.02, 0.10, 0.13, 1.0)
	trophy_button.add_theme_stylebox_override("normal", normal)
	trophy_button.add_theme_stylebox_override("hover", normal)
	trophy_button.add_theme_stylebox_override("pressed", pressed)
	menu.add_child(trophy_button)
	# Use explicit viewport coordinates. Anchoring to the right and then assigning position
	# was placing the control outside the visible menu on some layouts.
	trophy_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	trophy_button.position = Vector2(328, 18)
	trophy_button.size = Vector2(46, 46)
	trophy_button.pressed.connect(_open_panel)
	trophy_button.move_to_front()

func _open_panel() -> void:
	if menu == null or not is_instance_valid(menu):
		return
	if panel != null and is_instance_valid(panel):
		panel.visible = true
		panel.move_to_front()
		return
	panel = Panel.new()
	panel.name = "CollectiblesPanel"
	panel.position = Vector2(18, 150)
	panel.size = Vector2(354, 560)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 20000
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
	title.position = Vector2(20, 16)
	title.size = Vector2(314, 38)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("f6c53d"))
	panel.add_child(title)
	var sub := Label.new()
	sub.name = "SelectedBoat"
	sub.text = "Equipped: %s" % get_selected_name()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(20, 52)
	sub.size = Vector2(314, 26)
	sub.add_theme_color_override("font_color", Color("d9f4fb"))
	panel.add_child(sub)
	for i in range(BOATS.size()):
		var button := Button.new()
		button.name = "Boat%d" % i
		button.text = BOATS[i]
		button.position = Vector2(24 + (i % 2) * 157, 92 + (i / 2) * 92)
		button.size = Vector2(148, 72)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	close.focus_mode = Control.FOCUS_NONE
	close.mouse_filter = Control.MOUSE_FILTER_STOP
	close.position = Vector2(102, 478)
	close.size = Vector2(150, 48)
	close.pressed.connect(_close_panel)
	panel.add_child(close)
	panel.move_to_front()

func _close_panel() -> void:
	if panel != null and is_instance_valid(panel):
		panel.visible = false

func _select_boat(index: int) -> void:
	selected_index = index
	_save_selection()
	if panel == null or not is_instance_valid(panel):
		return
	var label := panel.get_node_or_null("SelectedBoat") as Label
	if label:
		label.text = "Equipped: %s" % get_selected_name()
	for i in range(BOATS.size()):
		var b := panel.get_node_or_null("Boat%d" % i) as Button
		if b:
			var sb := b.get_theme_stylebox("normal") as StyleBoxFlat
			if sb:
				sb.border_color = Color("f6c53d") if i == selected_index else Color("315b66")
