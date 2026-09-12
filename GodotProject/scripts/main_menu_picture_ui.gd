extends "res://scripts/main_menu_mobile.gd"

var picture_hitboxes: Dictionary = {}
var picture_feedback: Dictionary = {}
var picture_pressed: Dictionary = {}

func _build_ui() -> void:
	exact_bg = TextureRect.new()
	exact_bg.name = "ExactMenuBG"
	exact_bg.texture = load("res://assets/ui/main_menu_exact.png")
	exact_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exact_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	exact_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exact_bg)

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
	var feedback := TextureRect.new()
	feedback.name = "%sPressFeedback" % key.capitalize()
	var atlas := AtlasTexture.new()
	atlas.atlas = exact_bg.texture
	atlas.region = design_rect
	feedback.texture = atlas
	feedback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feedback.stretch_mode = TextureRect.STRETCH_SCALE
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.set_meta("design_rect", design_rect)
	feedback.set_meta("base_position", Vector2.ZERO)
	feedback.set_meta("base_size", Vector2.ZERO)
	add_child(feedback)
	picture_feedback[key] = feedback
	picture_pressed[key] = false

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
	picture_pressed[key] = pressed
	_apply_feedback_state(key)

func _apply_feedback_state(key: String) -> void:
	if not picture_feedback.has(key):
		return
	var feedback: TextureRect = picture_feedback[key] as TextureRect
	var base_position: Vector2 = feedback.get_meta("base_position") as Vector2
	var base_size: Vector2 = feedback.get_meta("base_size") as Vector2
	var pressed: bool = bool(picture_pressed.get(key, false))
	if pressed:
		var press_scale: float = 0.965
		var shrink_offset: Vector2 = base_size * (1.0 - press_scale) * 0.5
		feedback.position = base_position + shrink_offset + Vector2(0.0, 2.0)
		feedback.size = base_size * press_scale
		feedback.modulate = Color(0.78, 0.78, 0.78, 1.0)
	else:
		feedback.position = base_position
		feedback.size = base_size
		feedback.modulate = Color.WHITE

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
		var key_string: String = String(key)
		var feedback: TextureRect = picture_feedback[key_string] as TextureRect
		var rect: Rect2 = feedback.get_meta("design_rect") as Rect2
		var base_position: Vector2 = offset + rect.position * scale_factor
		var base_size: Vector2 = rect.size * scale_factor
		feedback.set_meta("base_position", base_position)
		feedback.set_meta("base_size", base_size)
		_apply_feedback_state(key_string)
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
