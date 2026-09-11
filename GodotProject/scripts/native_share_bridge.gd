extends Node

# Robust native Android sharing for the dynamically-created SUNK screen button.
# This bridge owns the touch itself, bypasses the old clipboard-only callback,
# and follows Godot 4.4's documented AndroidRuntime + JavaClassWrapper Intent flow.

var _share_button: Button = null
var _last_share_msec: int = 0

func _ready() -> void:
	set_process(true)
	set_process_input(true)

func _process(_delta: float) -> void:
	if is_instance_valid(_share_button):
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

	# Remove every previous Share callback. The old sunk_screen.gd callback only
	# copied text to the clipboard, which made the button look broken on Android.
	for connection in _share_button.pressed.get_connections():
		var existing: Callable = connection.get("callable", Callable())
		if existing.is_valid() and _share_button.pressed.is_connected(existing):
			_share_button.pressed.disconnect(existing)

	_share_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_share_button.focus_mode = Control.FOCUS_NONE
	_share_button.z_index = 1000
	_share_button.move_to_front()
	_share_button.text = "↗"
	_share_button.add_theme_font_size_override("font_size", 22)

	# Put Share directly beside PLAY AGAIN as a compact square button.
	# This preserves the working native-share logic while keeping it out of the UI above.
	var parent_control: Control = _share_button.get_parent() as Control
	if parent_control != null:
		var play_again: Button = parent_control.get_node_or_null("PlayAgain") as Button
		if play_again != null:
			var square_size: float = minf(48.0, play_again.size.y)
			var gap: float = 6.0
			_share_button.position = Vector2(
				play_again.position.x + play_again.size.x + gap,
				play_again.position.y + (play_again.size.y - square_size) * 0.5
			)
			_share_button.size = Vector2(square_size, square_size)
		else:
			var w: float = parent_control.size.x
			_share_button.position = Vector2(maxf(8.0, w - 56.0), 741.0)
			_share_button.size = Vector2(48.0, 48.0)

	print("Pirate's Plunder share: direct Android Share control ready")

func _input(event: InputEvent) -> void:
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

	if not pressed:
		return
	if not _share_button.get_global_rect().has_point(pos):
		return

	# Debounce in case a device produces duplicate touch events.
	var now: int = Time.get_ticks_msec()
	if now - _last_share_msec < 700:
		get_viewport().set_input_as_handled()
		return
	_last_share_msec = now
	get_viewport().set_input_as_handled()
	_on_share_pressed()

func _on_share_pressed() -> void:
	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)
	_set_footer("Opening Android share...")

	if OS.get_name() == "Android":
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
	# This is intentionally the same direct Intent flow shown in Godot's official
	# AndroidRuntime / JavaClassWrapper documentation for sending text.
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
		var detail := str(exception)
		push_error("Pirate's Plunder share: Android Intent failed: %s" % detail)
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
