extends Node

func _input(event: InputEvent) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var page: Control = scene.find_child("FreshLeaderboardPage", true, false) as Control
	if page == null or not page.visible:
		return
	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if back == null or not back.visible:
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
	else:
		return

	if pressed and back.get_global_rect().has_point(pos):
		page.visible = false
		get_viewport().set_input_as_handled()
