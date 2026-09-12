extends Node

const SKULL_TEXTURE: Texture2D = preload("res://assets/sunk-skull.svg")

var sunk_root: Control = null
var hero_title: Label = null
var left_skull: TextureRect = null
var right_skull: TextureRect = null

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_try_bind_existing")

func _on_node_added(node: Node) -> void:
	if node is Label and node.name == "HeroTitle":
		call_deferred("_bind_hero", node)

func _try_bind_existing() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var found: Label = scene.find_child("HeroTitle", true, false) as Label
	if found != null:
		_bind_hero(found)

func _bind_hero(found: Label) -> void:
	if found == null or not is_instance_valid(found):
		return
	var root: Control = found.get_parent() as Control
	if root == null:
		return

	hero_title = found
	sunk_root = root
	hero_title.text = "SUNK!"

	var old_left: Node = sunk_root.get_node_or_null("SunkSkullLeft")
	if old_left != null:
		old_left.queue_free()
	var old_right: Node = sunk_root.get_node_or_null("SunkSkullRight")
	if old_right != null:
		old_right.queue_free()

	left_skull = _make_skull("SunkSkullLeft")
	right_skull = _make_skull("SunkSkullRight")
	sunk_root.add_child(left_skull)
	sunk_root.add_child(right_skull)
	left_skull.move_to_front()
	right_skull.move_to_front()

	if not sunk_root.resized.is_connected(_layout_skulls):
		sunk_root.resized.connect(_layout_skulls)
	if not sunk_root.visibility_changed.is_connected(_on_visibility_changed):
		sunk_root.visibility_changed.connect(_on_visibility_changed)
	call_deferred("_layout_skulls")

func _make_skull(node_name: String) -> TextureRect:
	var skull := TextureRect.new()
	skull.name = node_name
	skull.texture = SKULL_TEXTURE
	skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skull.z_index = 20
	return skull

func _on_visibility_changed() -> void:
	if sunk_root != null and sunk_root.visible:
		call_deferred("_layout_skulls")

func _layout_skulls() -> void:
	if sunk_root == null or hero_title == null:
		return
	if not is_instance_valid(sunk_root) or not is_instance_valid(hero_title):
		return
	if not is_instance_valid(left_skull) or not is_instance_valid(right_skull):
		return

	var sx: float = sunk_root.size.x / 390.0 if sunk_root.size.x > 0.0 else 1.0
	var icon_w: float = 48.0 * sx
	var icon_h: float = 41.0 * sx
	var gap: float = 9.0 * sx
	var font: Font = hero_title.get_theme_font("font")
	var font_size: int = hero_title.get_theme_font_size("font_size")
	var text_width: float = font.get_string_size(hero_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var center_x: float = hero_title.position.x + hero_title.size.x * 0.5
	var y: float = hero_title.position.y + (hero_title.size.y - icon_h) * 0.5

	left_skull.position = Vector2(center_x - text_width * 0.5 - gap - icon_w, y)
	left_skull.size = Vector2(icon_w, icon_h)
	right_skull.position = Vector2(center_x + text_width * 0.5 + gap, y)
	right_skull.size = Vector2(icon_w, icon_h)
	left_skull.visible = hero_title.visible
	right_skull.visible = hero_title.visible
	left_skull.move_to_front()
	right_skull.move_to_front()
