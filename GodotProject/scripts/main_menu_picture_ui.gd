extends "res://scripts/main_menu_mobile.gd"

var picture_hitboxes: Dictionary = {}
var picture_feedback: Dictionary = {}

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

	# Only the art in main_menu_exact.png is visible. This invisible Button exists
	# solely because the inherited gameplay-start code expects play_button.
	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = ""
	play_button.flat = true
	play_button.focus_mode = Control.FOCUS_NONE
	play_button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.set_meta("design_rect", PLAY_RECT)
	var transparent := StyleBoxEmpty.new()
	play_button.add_theme_stylebox_override("normal", transparent)
	play_button.add_theme_stylebox_override("hover", transparent)
	play_button.add_theme_stylebox_override("pressed", transparent)
	play_button.add_theme_stylebox_override("focus", transparent)
	play_button.add_theme_stylebox_override("disabled", transparent)
	add_child(play_button)
	play_button.pressed.connect(_start_game_action)
	play_button.button_down.connect(func() -> void: _set_picture_feedback("play", true))
	play_button.button_up.connect(func() -> void: _set_picture_feedback("play", false))
	play_button.mouse_exited.connect(func() -> void: _set_picture_feedback("play", false))
	_add_feedback("play", PLAY_RECT)

	# Leaderboard / Collectibles / Settings are plain hit areas, not visible
	# Godot Buttons. The visible controls are the ones painted in the picture.
	_add_picture_hitbox("leaderboard", LEADERBOARD_RECT, Callable(self, "_open_fresh_leaderboard"))
	_add_picture_hitbox("collectibles", COLLECTIBLES_RECT, Callable(self, "_open_collectibles"))
	_add_picture_hitbox("settings", SETTINGS_RECT, Callable(self, "_open_settings"))
	_layout_ui()

func _add_picture_hitbox(key: String, design_rect: Rect2, action: Callable) -> void:
	var hit := Control.new()
	hit.name = "%sHitbox" % key.capitalize()
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_meta("design_rect", design_rect)
	hit.set_meta("action", action)
	add_child(hit)
	picture_hitboxes[key] = hit
	_add_feedback(key, design_rect)
	hit.gui_input.connect(func(event: InputEvent) -> void: _handle_picture_input(key, hit, event))
	hit.mouse_exited.connect(func() -> void: _set_picture_feedback(key, false))

func _add_feedback(key: String, design_rect: Rect2) -> void:
	var feedback := ColorRect.new()
	feedback.name = "%sPressFeedback" % key.capitalize()
	feedback.color = Color(0, 0, 0, 0)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.set_meta("design_rect", design_rect)
	add_child(feedback)
	picture_feedback[key] = feedback

func _handle_picture_input(key: String, hit: Control, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		_set_picture_feedback(key, touch.pressed)
		if not touch.pressed:
			var action: Callable = hit.get_meta("action") as Callable
			action.call()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_set_picture_feedback(key, mouse.pressed)
			if not mouse.pressed:
				var action: Callable = hit.get_meta("action") as Callable
				action.call()

func _set_picture_feedback(key: String, pressed: bool) -> void:
	if not picture_feedback.has(key):
		return
	var feedback: ColorRect = picture_feedback[key] as ColorRect
	# Temporary press feedback only; no permanent overlay artwork is added.
	feedback.color = Color(0, 0, 0, 0.16) if pressed else Color(0, 0, 0, 0)

func _layout_ui() -> void:
	if exact_bg == null:
		return
	exact_bg.position = Vector2.ZERO
	exact_bg.size = size
	var scale_factor: float = maxf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var drawn_size: Vector2 = DESIGN_SIZE * scale_factor
	var offset: Vector2 = (size - drawn_size) * 0.5

	if play_button != null:
		var play_rect: Rect2 = play_button.get_meta("design_rect") as Rect2
		play_button.position = offset + play_rect.position * scale_factor
		play_button.size = play_rect.size * scale_factor

	for key: Variant in picture_hitboxes.keys():
		var hit: Control = picture_hitboxes[String(key)] as Control
		var rect: Rect2 = hit.get_meta("design_rect") as Rect2
		hit.position = offset + rect.position * scale_factor
		hit.size = rect.size * scale_factor

	for key: Variant in picture_feedback.keys():
		var feedback: ColorRect = picture_feedback[String(key)] as ColorRect
		var rect: Rect2 = feedback.get_meta("design_rect") as Rect2
		feedback.position = offset + rect.position * scale_factor
		feedback.size = rect.size * scale_factor
		feedback.move_to_front()

	if play_button != null:
		play_button.move_to_front()
	for key: Variant in picture_hitboxes.keys():
		var hit: Control = picture_hitboxes[String(key)] as Control
		hit.move_to_front()

	if board_page != null and is_instance_valid(board_page):
		board_page.size = size
	if menu_popup != null and is_instance_valid(menu_popup):
		menu_popup.size = size
