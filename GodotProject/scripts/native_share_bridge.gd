extends Node

# Owns the SUNK screen Share button and opens Android's native share sheet.
# The button is created dynamically by sunk_screen.gd, so this autoload waits
# for it, replaces the old clipboard-only callback, and handles the press itself.

var _share_hooked: bool = false

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	if _share_hooked:
		set_process(false)
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var button: Button = root.find_child("Share", true, false) as Button
	if button == null:
		return

	# Remove the old sunk_screen.gd clipboard-only handler so this button has one
	# authoritative action on Android.
	for connection in button.pressed.get_connections():
		var existing: Callable = connection.get("callable", Callable()) as Callable
		if existing.is_valid() and button.pressed.is_connected(existing):
			button.pressed.disconnect(existing)

	var callback := Callable(self, "_on_share_pressed")
	button.pressed.connect(callback)
	_share_hooked = true
	set_process(false)
	print("Pirate's Plunder share: native Share button hooked")

func _on_share_pressed() -> void:
	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)
	if not share_text(message):
		push_error("Pirate's Plunder share: native share unavailable; copied to clipboard")

func share_text(message: String) -> bool:
	if OS.get_name() == "Android" and _share_android(message):
		return true
	DisplayServer.clipboard_set(message)
	return false

func _share_android(message: String) -> bool:
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_error("Pirate's Plunder share: AndroidRuntime unavailable")
		return false

	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		push_error("Pirate's Plunder share: Android Activity unavailable")
		return false

	# Launch the Android Intent from Android's UI thread. This avoids device/build
	# differences where startActivity from Godot's game thread does nothing.
	var launch_share := func() -> void:
		var Intent: Variant = JavaClassWrapper.wrap("android.content.Intent")
		if Intent == null:
			push_error("Pirate's Plunder share: Intent class unavailable")
			return
		var intent: Variant = Intent.Intent()
		if intent == null:
			push_error("Pirate's Plunder share: could not create Intent")
			return
		intent.setAction(Intent.ACTION_SEND)
		intent.putExtra(Intent.EXTRA_TEXT, message)
		intent.setType("text/plain")
		activity.startActivity(intent)
		var exception: Variant = JavaClassWrapper.get_exception()
		if exception != null:
			push_error("Pirate's Plunder share: Android Intent failed: %s" % str(exception))

	var runnable: Variant = android_runtime.createRunnableFromGodotCallable(launch_share)
	if runnable == null:
		push_error("Pirate's Plunder share: could not create Android UI runnable")
		return false
	activity.runOnUiThread(runnable)
	return true

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
