extends Node

# Native Android sharing for the dynamically-created SUNK screen Share button.
# Keep the sharing logic independent from the icon asset so a failed SVG import
# can never prevent the Share handler itself from loading.

var _share_button: Button = null
var _last_share_msec: int = 0

func _ready() -> void:
	set_process(true)
	set_process_input(true)
	print("Pirate's Plunder share bridge loaded")

func _process(_delta: float) -> void:
	if is_instance_valid(_share_button):
		_keep_share_button_beside_play_again()
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var button: Button = root.find_child("Share", true, false) as Button
	if button == null:
		return
	_share_button = button
	_configure_share_button()

func _configure_share_button() -> void:
	if not is_instance_valid(_share_button):
		return

	# Remove old callbacks so there is one owner for Share.
	for connection in _share_button.pressed.get_connections():
		var existing: Callable = connection.get("callable", Callable())
		if existing.is_valid() and _share_button.pressed.is_connected(existing):
			_share_button.pressed.disconnect(existing)

	# Normal GUI click path.
	if not _share_button.pressed.is_connected(_on_share_pressed):
		_share_button.pressed.connect(_on_share_pressed)

	_share_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_share_button.focus_mode = Control.FOCUS_NONE
	_share_button.z_index = 1000
	_share_button.move_to_front()

	# Load the image at runtime instead of preloading it. If the SVG import has a
	# problem on any machine/build, Share still works and falls back to text.
	var icon_texture: Resource = load("res://assets/share-icon.svg")
	if icon_texture is Texture2D:
		_share_button.text = ""
		_share_button.icon = icon_texture as Texture2D
		_share_button.expand_icon = true
	else:
		_share_button.icon = null
		_share_button.text = "SHARE"
		_share_button.add_theme_font_size_override("font_size", 11)

	_keep_share_button_beside_play_again()
	print("Pirate's Plunder share button configured")

func _keep_share_button_beside_play_again() -> void:
	if not is_instance_valid(_share_button):
		return
	var parent_control: Control = _share_button.get_parent() as Control
	if parent_control == null:
		return
	var play_again: Button = parent_control.get_node_or_null("PlayAgain") as Button
	if play_again == null:
		return

	var square_size: float = minf(48.0, play_again.size.y)
	var gap: float = 6.0
	_share_button.position = Vector2(
		play_again.position.x + play_again.size.x + gap,
		play_again.position.y + (play_again.size.y - square_size) * 0.5
	)
	_share_button.size = Vector2(square_size, square_size)
	_share_button.move_to_front()

func _input(event: InputEvent) -> void:
	# Direct fallback for both desktop mouse input and Android touch input.
	if not is_instance_valid(_share_button) or not _share_button.visible:
		return

	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		pressed = touch.pressed
		pos = touch.position
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pressed = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
		pos = mouse.position
	else:
		return

	if not pressed:
		return

	# Check both the actual Share control rect and a rect derived from PLAY AGAIN.
	# The second check avoids coordinate/layout races during the SUNK screen setup.
	var hit: bool = _share_button.get_global_rect().has_point(pos)
	if not hit:
		var parent_control: Control = _share_button.get_parent() as Control
		if parent_control != null:
			var play_again: Button = parent_control.get_node_or_null("PlayAgain") as Button
			if play_again != null:
				var play_rect: Rect2 = play_again.get_global_rect()
				var square_size: float = minf(48.0, play_rect.size.y)
				var fallback_rect := Rect2(
					Vector2(play_rect.end.x + 6.0, play_rect.position.y + (play_rect.size.y - square_size) * 0.5),
					Vector2(square_size, square_size)
				)
				hit = fallback_rect.has_point(pos)

	if not hit:
		return

	get_viewport().set_input_as_handled()
	_on_share_pressed()

func _on_share_pressed() -> void:
	# Prevent the Button signal and direct input fallback from firing twice.
	var now: int = Time.get_ticks_msec()
	if now - _last_share_msec < 500:
		return
	_last_share_msec = now

	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)
	print("Pirate's Plunder share activated: %s" % message)

	if OS.get_name() == "Android":
		_set_footer("Opening Android share...")
		var result: String = _share_android(message)
		if result == "ok":
			_set_footer("Choose an app to share your score")
			return
		DisplayServer.clipboard_set(message)
		_set_footer("%s — score copied instead" % result)
		return

	DisplayServer.clipboard_set(message)
	_set_footer("Score copied — ready to share!")

func _share_android(message: String) -> String:
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_error("Pirate's Plunder share: AndroidRuntime unavailable")
		return "AndroidRuntime unavailable"

	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		push_error("Pirate's Plunder share: Android Activity unavailable")
		return "Android Activity unavailable"

	var Intent: Variant = JavaClassWrapper.wrap("android.content.Intent")
	if Intent == null:
		push_error("Pirate's Plunder share: Intent class unavailable")
		return "Intent unavailable"

	var intent: Variant = Intent.Intent()
	if intent == null:
		push_error("Pirate's Plunder share: could not create Intent")
		return "Could not create share Intent"

	intent.setAction(Intent.ACTION_SEND)
	intent.putExtra(Intent.EXTRA_TEXT, message)
	intent.setType("text/plain")
	activity.startActivity(intent)

	var exception: Variant = JavaClassWrapper.get_exception()
	if exception != null:
		push_error("Pirate's Plunder share: Android Intent failed: %s" % str(exception))
		return "Android share failed"

	return "ok"

func _set_footer(text: String) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var footer: Label = root.find_child("Footer", true, false) as Label
	if footer != null:
		footer.text = text

func _find_current_score() -> int:
	var root: Node = get_tree().current_scene
	if root == null:
		return 0
	var value: Variant = root.get("score")
	if value is int:
		return value as int
	if value is float:
		return int(value as float)
	return 0

func _comma(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
