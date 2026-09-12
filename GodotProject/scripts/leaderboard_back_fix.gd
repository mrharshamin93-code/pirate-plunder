extends Node

func _process(_delta: float) -> void:
	var back: Button = _get_back_button()
	if back != null and back.text != "MAIN MENU":
		back.text = "MAIN MENU"

func _input(event: InputEvent) -> void:
	var page: Control = _get_board_page()
	if page == null or not page.visible:
		return

	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if back == null or not back.visible:
		return

	var activate: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		activate = touch.pressed
		pos = touch.position
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		activate = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		pos = mouse.position
	else:
		return

	if activate and back.get_global_rect().has_point(pos):
		get_viewport().set_input_as_handled()
		get_tree().call_deferred("reload_current_scene")

func _get_board_page() -> Control:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("FreshLeaderboardPage", true, false) as Control

func _get_back_button() -> Button:
	var page: Control = _get_board_page()
	if page == null:
		return null
	return page.find_child("LeaderboardBackButton", true, false) as Button
