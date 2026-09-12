extends Button

var navigating: bool = false

func _ready() -> void:
	text = "MAIN MENU"
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 110
	add_theme_font_size_override("font_size", 18)
	add_theme_color_override("font_color", Color("fff2b2"))
	add_theme_stylebox_override("normal", _box(Color("3a2115"), Color("f4c64d")))
	add_theme_stylebox_override("hover", _box(Color("4a2b19"), Color("ffd86a")))
	add_theme_stylebox_override("pressed", _box(Color("24150e"), Color("9b5c16")))
	pressed.connect(_go_to_main_menu)
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if navigating or not visible:
		return
	var released: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		released = not mouse.pressed
		pos = mouse.position
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		released = not touch.pressed
		pos = touch.position
	else:
		return
	if released and get_global_rect().has_point(pos):
		_go_to_main_menu()
		get_viewport().set_input_as_handled()

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	return box

func _go_to_main_menu() -> void:
	if navigating:
		return
	navigating = true
	var sunk_panel := get_parent() as Control
	if sunk_panel == null:
		navigating = false
		return
	var canvas := sunk_panel.get_parent()
	var game := canvas.get_parent()
	if game != null and game.has_method("_prepare_idle_state"):
		game.call("_prepare_idle_state")
	var menu := canvas.get_node_or_null("MainMenu") as Control
	if menu == null:
		navigating = false
		return
	menu.set("starting_game", false)
	var play: Variant = menu.get("play_button")
	if play is Button:
		(play as Button).disabled = false
	if menu.has_method("_set_gameplay_ui_visible"):
		menu.call("_set_gameplay_ui_visible", false)
	sunk_panel.visible = false
	menu.visible = true
	menu.move_to_front()
	navigating = false
