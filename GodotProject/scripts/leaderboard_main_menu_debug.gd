extends Node

func _ready() -> void:
	set_process_input(true)
	print("[LB RAW] debug input watcher ready")

func _input(event: InputEvent) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var page: Control = scene.find_child("FreshLeaderboardPage", true, false) as Control
	if page == null or not page.visible:
		return

	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if back == null:
		print("[LB RAW] leaderboard visible but MAIN MENU button not found")
		return

	var pos: Vector2 = Vector2.ZERO
	var is_press: bool = false
	var is_release: bool = false

	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		pos = mouse.position
		is_press = mouse.pressed
		is_release = not mouse.pressed
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pos = touch.position
		is_press = touch.pressed
		is_release = not touch.pressed
	else:
		return

	var rect: Rect2 = back.get_global_rect()
	var inside: bool = rect.has_point(pos)
	print("[LB RAW] input pos=", pos, " press=", is_press, " release=", is_release, " inside_main_menu=", inside, " rect=", rect, " page_visible=", page.visible)

	# On this project/platform the press event is consumed by GUI before this
	# autoload sees it, but the release event reliably reaches _input. Treat a
	# release inside the visible MAIN MENU button exactly like a normal click.
	if is_release and inside:
		print("[LB RAW] MAIN MENU raw release detected -> hiding leaderboard now")
		page.hide()
		print("[LB RAW] leaderboard visible after hide=", page.visible)
		get_viewport().set_input_as_handled()
