extends Node

var connected_button_id: int = 0
var reopen_blocked: bool = false

func _process(_delta: float) -> void:
	var page: Control = _get_board_page()
	if page == null or not page.visible:
		return
	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if back == null:
		return
	back.text = "MAIN MENU"
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	back.focus_mode = Control.FOCUS_NONE
	back.z_index = 100000
	back.move_to_front()

	var current_id: int = back.get_instance_id()
	if connected_button_id != current_id:
		connected_button_id = current_id
		if not back.button_down.is_connected(_force_main_menu):
			back.button_down.connect(_force_main_menu)
		if not back.pressed.is_connected(_force_main_menu):
			back.pressed.connect(_force_main_menu)

func _force_main_menu() -> void:
	if reopen_blocked:
		return
	reopen_blocked = true
	var page: Control = _get_board_page()
	if page != null:
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.visible = false

	# Prevent the same touch/mouse release from landing on the menu's
	# Leaderboard hitbox and immediately reopening the page.
	var leaderboard_hitbox: Control = _get_leaderboard_hitbox()
	if leaderboard_hitbox != null:
		leaderboard_hitbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	call_deferred("_restore_menu_input")

func _restore_menu_input() -> void:
	# Wait long enough for the current touch/click release to finish.
	await get_tree().create_timer(0.35).timeout
	var leaderboard_hitbox: Control = _get_leaderboard_hitbox()
	if leaderboard_hitbox != null:
		leaderboard_hitbox.mouse_filter = Control.MOUSE_FILTER_STOP
	reopen_blocked = false

func _get_board_page() -> Control:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("FreshLeaderboardPage", true, false) as Control

func _get_leaderboard_hitbox() -> Control:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("LeaderboardHitbox", true, false) as Control
