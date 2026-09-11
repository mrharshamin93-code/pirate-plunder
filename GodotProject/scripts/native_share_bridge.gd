extends Node

# Native Android share bridge for the SUNK screen.
# The Share button itself owns the normal pressed signal on every platform.
# Android also keeps a direct touch fallback in case a device swallows the GUI signal.

const SHARE_ICON: Texture2D = preload("res://assets/share-icon.svg")

var _share_button: Button = null
var _last_share_msec: int = 0

func _ready() -> void:
	set_process(true)
	set_process_input(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(_share_button):
		var root: Node = get_tree().current_scene
		if root == null:
			return
		var button: Button = root.find_child("Share", true, false) as Button
		if button == null:
			return
		_share_button = button
		_configure_share_button()
	else:
		_keep_share_button_beside_play_again()

func _configure_share_button() -> void:
	if not is_instance_valid(_share_button):
		return

	# Remove every previous callback, including the old clipboard-only handler.
	for connection in _share_button.pressed.get_connections():
		var existing: Callable = connection.get("callable", Callable())
		if existing.is_valid() and _share_button.pressed.is_connected(existing):
			_share_button.pressed.disconnect(existing)

	# Use one real Button signal on Windows and Android.
	_share_button.pressed.connect(_on_share_pressed)
	_share_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_share_button.focus_mode = Control.FOCUS_NONE
	_share_button.z_index = 1000
	_share_button.move_to_front()
	_share_button.text = ""
	_share_button.icon = null

	# Use a child TextureRect for the three-node image. IGNORE ensures the image
	# never consumes mouse/touch events intended for the Button.
	var old_icon: Node = _share_button.get_node_or_null("ShareIcon")
	if old_icon != null:
		old_icon.queue_free()
	var icon_rect := TextureRect.new()
	icon_rect.name = "ShareIcon"
	icon_rect.texture = SHARE_ICON
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 9.0
	icon_rect.offset_top = 9.0
	icon_rect.offset_right = -9.0
	icon_rect.offset_bottom = -9.0
	_share_button.add_child(icon_rect)

	_keep_share_button_beside_play_again()
	print("Pirate's Plunder share: button signal connected")

func _keep_share_button_beside_play_again() -> void:
	if not is_instance_valid(_share_button):
		return
	var parent_control: Control = _share_button.get_parent() as Control
	if parent_control == null:
		return
	var play_again: Button = parent_control.get_node_or_null("PlayAgain") as Button
	if play_again != null:
		var square_size: float = minf(48.0, play_again.size.y)
		var gap: float = 6.0
		_share_button.position = Vector2(
			play_again.position.x + play_again.size.x + gap,
			play_again.position.y + (play_again.size.y - square_size) * 0.5
		)
		_share_button.size = Vector2(square_size, square_size)

func _input(event: InputEvent) -> void:
	# Android-only fallback. Normal desktop clicks use Button.pressed directly.
	if OS.get_name() != "Android":
		return
	if not is_instance_valid(_share_button) or not _share_button.visible:
		return
	if not (event is InputEventScreenTouch):
		return
	var touch := event as InputEventScreenTouch
	if not touch.pressed:
		return
	if not _share_button.get_global_rect().has_point(touch.position):
		return
	get_viewport().set_input_as_handled()
	_on_share_pressed()

func _on_share_pressed() -> void:
	# Prevent the Android touch fallback and Button.pressed from opening twice.
	var now: int = Time.get_ticks_msec()
	if now - _last_share_msec < 700:
		return
	_last_share_msec = now

	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)

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
	print("Pirate's Plunder share text copied: %s" % message)

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
