extends Node

# Reliable native sharing for the SUNK screen.
# The SunkPanel builds its Share button dynamically, so this autoload keeps
# looking until that button exists and then connects directly to it.

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
	var callback := Callable(self, "_on_share_pressed")
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	_share_hooked = true
	set_process(false)

func _on_share_pressed() -> void:
	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)
	share_text(message)

func share_text(message: String) -> bool:
	if OS.get_name() == "Android":
		if _share_android(message):
			return true
	DisplayServer.clipboard_set(message)
	return false

func _share_android(message: String) -> bool:
	# This follows Godot's documented AndroidRuntime + JavaClassWrapper Intent
	# pattern directly. Avoid createChooser here because JNI overload resolution
	# has been unreliable on some Android/Godot builds.
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_error("Pirate's Plunder share: AndroidRuntime unavailable")
		return false

	var activity: Variant = android_runtime.getActivity()
	if activity == null:
		push_error("Pirate's Plunder share: Android Activity unavailable")
		return false

	var Intent: Variant = JavaClassWrapper.wrap("android.content.Intent")
	var intent: Variant = Intent.Intent()
	if intent == null:
		push_error("Pirate's Plunder share: could not create Intent")
		return false

	intent.setAction(Intent.ACTION_SEND)
	intent.putExtra(Intent.EXTRA_TEXT, message)
	intent.setType("text/plain")
	activity.startActivity(intent)

	var exception: Variant = JavaClassWrapper.get_exception()
	if exception != null:
		push_error("Pirate's Plunder share: Android Intent failed: %s" % str(exception))
		return false
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
