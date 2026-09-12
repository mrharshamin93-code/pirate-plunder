extends Node

# This deliberately handles the tap before Godot's Control GUI dispatch.
# The leaderboard is an overlay inside MainMenu, so hiding that overlay is
# all that is required to return immediately to the existing main menu.

func _ready() -> void:
	set_process_input(true)

func _input(event: InputEvent) -> void:
	var page: Control = _get_board_page()
	if page == null or not page.visible:
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

	if not pressed:
		return

	# First use the real visible MAIN MENU button rect.
	var back: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	var hit: bool = false
	if back != null and is_instance_valid(back):
		hit = back.get_global_rect().grow(18.0).has_point(pos)

	# Resolution-independent fallback. The MAIN MENU button occupies the lower
	# centre of the leaderboard screen. This catches the tap even if a platform
	# reports pointer coordinates in a different stretched-canvas space.
	if not hit:
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		if viewport_size.x > 0.0 and viewport_size.y > 0.0:
			var nx: float = pos.x / viewport_size.x
			var ny: float = pos.y / viewport_size.y
			hit = nx >= 0.18 and nx <= 0.82 and ny >= 0.82 and ny <= 0.98

	if hit:
		# Consume the press before it can reach the Leaderboard hitbox underneath.
		get_viewport().set_input_as_handled()
		_go_to_main_menu(page)

func _go_to_main_menu(page: Control) -> void:
	if page == null or not is_instance_valid(page):
		return

	# FreshLeaderboardPage is created directly under the actual MainMenu node.
	# This mirrors the working Collectibles BACK behavior: close only the overlay.
	var menu: Control = page.get_parent() as Control
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.visible = false

	if menu != null and is_instance_valid(menu):
		menu.visible = true
		menu.mouse_filter = Control.MOUSE_FILTER_STOP

func _get_board_page() -> Control:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("FreshLeaderboardPage", true, false) as Control
