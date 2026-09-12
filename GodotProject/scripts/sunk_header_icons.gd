extends Node

const ICON: Texture2D = preload("res://assets/sunk-skull-double-outline.svg")
var title: Label
var left: TextureRect
var right: TextureRect

func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	call_deferred("_find_title")

func _node_added(node: Node) -> void:
	if node is Label and node.name == "HeroTitle":
		call_deferred("_attach", node)

func _find_title() -> void:
	var scene := get_tree().current_scene
	if scene != null:
		var found := scene.find_child("HeroTitle", true, false) as Label
		if found != null:
			_attach(found)

func _attach(found: Label) -> void:
	if found == null or not is_instance_valid(found):
		return
	if title == found and is_instance_valid(left) and is_instance_valid(right):
		return
	title = found
	title.text = "SUNK!"
	var parent := title.get_parent() as Control
	if parent == null:
		return
	left = _new_icon("HeaderIconLeft")
	right = _new_icon("HeaderIconRight")
	parent.add_child(left)
	parent.add_child(right)
	if not parent.resized.is_connected(_layout):
		parent.resized.connect(_layout)
	call_deferred("_layout")

func _new_icon(node_name: String) -> TextureRect:
	var view := TextureRect.new()
	view.name = node_name
	view.texture = ICON
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.z_index = 10
	return view

func _layout() -> void:
	if not is_instance_valid(title) or not is_instance_valid(left) or not is_instance_valid(right):
		return
	var parent := title.get_parent() as Control
	if parent == null:
		return
	var sx := parent.size.x / 390.0 if parent.size.x > 0.0 else 1.0
	var icon_size := Vector2(58.0 * sx, 51.0)
	var center_x := title.position.x + title.size.x * 0.5
	var font := title.get_theme_font("font")
	var font_size := title.get_theme_font_size("font_size")
	var text_w := font.get_string_size("SUNK!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var gap := 12.0 * sx
	var y := title.position.y + (title.size.y - icon_size.y) * 0.5
	left.position = Vector2(center_x - text_w * 0.5 - gap - icon_size.x, y)
	left.size = icon_size
	right.position = Vector2(center_x + text_w * 0.5 + gap, y)
	right.size = icon_size
	left.visible = title.visible
	right.visible = title.visible
	left.move_to_front()
	right.move_to_front()
