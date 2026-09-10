extends Node

# Hooks the SUNK screen Share button and opens Android's native share target picker.
# Uses Godot's AndroidRuntime + JavaClassWrapper APIs (Godot 4.4+).
# Clipboard remains a fallback on desktop/unsupported Android exports.

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_existing")

func _scan_existing() -> void:
	var root: Node = get_tree().current_scene
	if root != null:
		_scan_node(root)

func _scan_node(node: Node) -> void:
	_try_hook_share(node)
	for child in node.get_children():
		_scan_node(child)

func _on_node_added(node: Node) -> void:
	call_deferred("_try_hook_share", node)

func _try_hook_share(node: Node) -> void:
	if not (node is Button):
		return
	var button: Button = node as Button
	if button.name != "Share":
		return
	var callable := Callable(self, "_on_share_pressed")
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)

func _on_share_pressed() -> void:
	var current_score: int = _find_current_score()
	var message := "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)
	share_text(message)

func share_text(message: String) -> bool:
	if OS.get_name() == "Android" and _share_android(message):
		return true
	DisplayServer.clipboard_set(message)
	return false

func _share_android(message: String) -> bool:
	# AndroidRuntime and JavaClassWrapper are built into Godot Android exports in 4.4+.
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	var java_wrapper: Object = Engine.get_singleton("JavaClassWrapper")
	if android_runtime == null or java_wrapper == null:
		return false

	var activity: Variant = android_runtime.call("getActivity")
	if activity == null:
		return false

	var Intent: Variant = java_wrapper.call("wrap", "android.content.Intent")
	if Intent == null:
		return false

	var intent: Variant = Intent.Intent()
	if intent == null:
		return false

	# Match Godot's documented Android ACTION_SEND implementation directly.
	intent.setAction(Intent.ACTION_SEND)
	intent.putExtra(Intent.EXTRA_TEXT, message)
	intent.setType("text/plain")

	# Do not wrap this in another Runnable/closure. Godot's official example starts
	# the Activity directly, which is also more reliable on older Android devices.
	activity.startActivity(intent)
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
