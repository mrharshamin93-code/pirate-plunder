extends Node

# Adds a real Android system share sheet to the existing SUNK screen Share button.
# The sunk screen still copies the text to the clipboard as a fallback.

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_existing")

func _scan_existing() -> void:
	var buttons: Array[Node] = get_tree().get_nodes_in_group("__unused_share_scan_group")
	# The group call above intentionally returns nothing; scan the current scene directly.
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
	var callable: Callable = Callable(self, "_on_share_pressed")
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)

func _on_share_pressed() -> void:
	var current_score: int = _find_current_score()
	var message: String = "I scored %s in Pirate's Plunder! Can you beat it?" % _comma(current_score)

	if OS.get_name() == "Android" and _share_android(message):
		return

	DisplayServer.clipboard_set(message)

func _share_android(message: String) -> bool:
	var android_runtime: Object = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		return false

	var activity: Variant = android_runtime.call("getActivity")
	if activity == null:
		return false

	var intent_class: Variant = JavaClassWrapper.wrap("android.content.Intent")
	if intent_class == null:
		return false

	var intent: Variant = intent_class.Intent()
	intent.setAction(intent_class.ACTION_SEND)
	intent.putExtra(intent_class.EXTRA_TEXT, message)
	intent.setType("text/plain")

	var chooser: Variant = intent_class.createChooser(intent, "Share Pirate's Plunder")
	activity.startActivity(chooser)
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
	var s: String = str(value)
	var out: String = ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
