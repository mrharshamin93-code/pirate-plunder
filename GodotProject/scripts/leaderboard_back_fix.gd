extends Node

var wired_button_id: int = 0

func _process(_delta: float) -> void:
	var back: Button = _get_back_button()
	if back == null:
		wired_button_id = 0
		return
	back.text = "MAIN MENU"
	var current_id: int = back.get_instance_id()
	if current_id != wired_button_id:
		wired_button_id = current_id
		if not back.button_down.is_connected(_go_to_main_menu):
			back.button_down.connect(_go_to_main_menu)

func _go_to_main_menu() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var page: Control = scene.find_child("FreshLeaderboardPage", true, false) as Control
	var menu: Control = scene.find_child("MainMenu", true, false) as Control
	if page != null:
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.visible = false
		page.queue_free()
	if menu != null:
		menu.visible = true
		menu.mouse_filter = Control.MOUSE_FILTER_STOP
		menu.move_to_front()
		var leaderboard_hitbox: Control = menu.find_child("LeaderboardHitbox", true, false) as Control
		if leaderboard_hitbox != null:
			leaderboard_hitbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_reenable_leaderboard_hitbox(leaderboard_hitbox)
	get_viewport().set_input_as_handled()

func _reenable_leaderboard_hitbox(hitbox: Control) -> void:
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(hitbox):
		hitbox.mouse_filter = Control.MOUSE_FILTER_STOP

func _get_board_page() -> Control:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("FreshLeaderboardPage", true, false) as Control

func _get_back_button() -> Button:
	var page: Control = _get_board_page()
	if page == null or not page.visible:
		return null
	return page.find_child("LeaderboardBackButton", true, false) as Button
