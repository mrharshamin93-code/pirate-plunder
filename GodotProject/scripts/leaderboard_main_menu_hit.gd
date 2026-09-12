extends Node

var hit_button: Button = null
var bound_page_id: int = 0

func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var page: Control = scene.find_child("FreshLeaderboardPage", true, false) as Control
	if page == null:
		hit_button = null
		bound_page_id = 0
		return

	var page_id: int = page.get_instance_id()
	if hit_button == null or not is_instance_valid(hit_button) or bound_page_id != page_id:
		_install_hit_button(page)

func _install_hit_button(page: Control) -> void:
	var visible_button: Button = page.find_child("LeaderboardBackButton", true, false) as Button
	if visible_button == null:
		return

	var hit := Button.new()
	hit.name = "LeaderboardMainMenuDirectHit"
	hit.text = ""
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.position = visible_button.position - Vector2(12.0, 10.0)
	hit.size = visible_button.size + Vector2(24.0, 20.0)
	hit.z_index = 1000000

	var empty := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", empty)
	hit.add_theme_stylebox_override("hover", empty)
	hit.add_theme_stylebox_override("pressed", empty)
	hit.add_theme_stylebox_override("focus", empty)
	hit.add_theme_stylebox_override("disabled", empty)

	page.add_child(hit)
	hit.move_to_front()
	hit.button_down.connect(func() -> void: _go_to_main_menu(page))

	hit_button = hit
	bound_page_id = page.get_instance_id()

func _go_to_main_menu(page: Control) -> void:
	# Immediate transition: the leaderboard is only an overlay on the main menu.
	# Hiding it exposes the existing main-menu screen underneath, exactly like
	# the Collectibles page's working BACK button.
	get_viewport().set_input_as_handled()
	if is_instance_valid(page):
		page.visible = false
