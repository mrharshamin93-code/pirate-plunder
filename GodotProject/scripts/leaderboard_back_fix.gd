extends Node

var back_press_armed: bool = false

func _process(_delta: float) -> void:
	var back: Button = _get_back_button()
	if back != null and back.text != "MAIN MENU":
		back.text = "MAIN MENU"

func _input(event: InputEvent) -> void:
	var page: Control = _get_board_page()
	if page == null or not page.visible:
		back_press_armed = false
		return

	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if back == null or not back.visible:
		back_press_armed = false
		return

	back.text = "MAIN MENU"

	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			if back.get_global_rect().has_point(touch.position):
				back_press_armed = true
				get_viewport().set_input_as_handled()
		else:
			if back_press_armed:
				# Consume the release BEFORE hiding the page so the release cannot
				# fall through to the main-menu Leaderboard hitbox and reopen it.
				get_viewport().set_input_as_handled()
				back_press_armed = false
				page.visible = false
		return

	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			if back.get_global_rect().has_point(mouse.position):
				back_press_armed = true
				get_viewport().set_input_as_handled()
		else:
			if back_press_armed:
				get_viewport().set_input_as_handled()
				back_press_armed = false
				page.visible = false

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
