extends Node

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply")

func _on_node_added(node: Node) -> void:
	if node.name == "PlayButton" or node.name == "ExactMenuBG":
		call_deferred("_apply")

func _apply() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var play := scene.find_child("PlayButton", true, false) as Button
	if play == null:
		return
	var menu := play.get_parent() as Control
	if menu == null:
		return
	var bg := menu.get_node_or_null("ExactMenuBG") as TextureRect
	if bg == null or bg.texture == null:
		return

	# Remove the old corner trophy interaction and its live visual.
	var old_trophy := menu.get_node_or_null("CollectiblesButton") as Button
	if old_trophy != null:
		old_trophy.visible = false
		old_trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var old_trophy_art := menu.get_node_or_null("CollectiblesButtonArt") as CanvasItem
	if old_trophy_art != null:
		old_trophy_art.visible = false

	# Hide the old border-cover helpers since we replace the entire trophy area.
	for n in get_tree().get_nodes_in_group("trophy_border_cover"):
		if n is CanvasItem and n.get_parent() == menu:
			(n as CanvasItem).visible = false

	# Cover the baked trophy artwork in the top-right with a nearby sky crop.
	if menu.get_node_or_null("TrophyRemovalPatch") == null:
		var patch := TextureRect.new()
		patch.name = "TrophyRemovalPatch"
		var atlas := AtlasTexture.new()
		atlas.atlas = bg.texture
		atlas.region = Rect2(250, 8, 55, 86)
		patch.texture = atlas
		patch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		patch.stretch_mode = TextureRect.STRETCH_SCALE
		patch.position = Vector2(319, 8)
		patch.size = Vector2(55, 86)
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		patch.z_index = 12000
		menu.add_child(patch)
		patch.move_to_front()

	# The old How To Play artwork is already covered by main_menu_mobile.gd.
	# Put the real Collectibles button in that exact lower button slot.
	if menu.get_node_or_null("CollectiblesMenuButton") == null:
		var b := Button.new()
		b.name = "CollectiblesMenuButton"
		b.text = "🏆  COLLECTIBLES"
		b.position = Vector2(81, 585)
		b.size = Vector2(229, 69)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.z_index = 13000
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color("f7ddb0"))
		b.add_theme_color_override("font_hover_color", Color("fff3cf"))
		b.add_theme_color_override("font_pressed_color", Color("e8c287"))
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("4a2b19")
		normal.border_color = Color("9a6231")
		normal.set_border_width_all(3)
		normal.set_corner_radius_all(10)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("5a3520")
		hover.border_color = Color("d6a04f")
		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("321b10")
		pressed.border_color = Color("7b4a24")
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", pressed)
		b.pressed.connect(func():
			var collectibles := get_node_or_null("/root/BoatCollectibles")
			if collectibles != null and collectibles.has_method("open_from_menu"):
				collectibles.call("open_from_menu", menu)
		)
		menu.add_child(b)
		b.move_to_front()
