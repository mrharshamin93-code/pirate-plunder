extends Node

const SAVE := "user://collectibles.cfg"
const NAMES := ["Plunderer","Crimson Raider","Black Pearl","Royal Fortune","Ghost Ship","Inferno","Sea Serpent","Golden Galleon"]
const SUBS := ["Default Ship","Raider Variant","Shadow Variant","Royal Variant","Spectral Variant","Infernal Variant","Serpent Variant","Legendary Variant"]
const FILES := ["plunderer","crimson_raider","black_pearl","royal_fortune","ghost_ship","inferno","sea_serpent","golden_galleon"]
const COLORS := [Color("9a6231"),Color("c8322f"),Color("20242b"),Color("f2e5c2"),Color("7fa7a1"),Color("e64a19"),Color("159b91"),Color("d6a51e")]
const CROP_RECTS := [
	Rect2(40,0,84,160), Rect2(42,0,82,160), Rect2(43,0,78,160), Rect2(43,0,80,160),
	Rect2(41,0,84,160), Rect2(0,0,160,160), Rect2(0,0,160,160), Rect2(40,0,82,160)
]

var selected := 0
var preview := 0
var textures: Array[Texture2D] = []
var menu: Control
var overlay: Control
var hero: TextureRect
var name_label: Label
var sub_label: Label
var equip_button: Button
var left_button: Button
var right_button: Button

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		selected = clampi(int(cfg.get_value("boats", "selected", 0)), 0, 7)
	preview = selected
	textures.resize(FILES.size())

func get_selected_index() -> int:
	return selected

func get_selected_name() -> String:
	return NAMES[selected]

func get_selected_color() -> Color:
	return COLORS[selected]

func _ship_texture(index: int) -> Texture2D:
	if index < 0 or index >= FILES.size():
		return null
	if textures[index] == null:
		textures[index] = _read_ship(index)
	return textures[index]

func _read_ship(index: int) -> Texture2D:
	var source := load("res://assets/ships/%s.svg" % FILES[index]) as Texture2D
	if source == null:
		return null
	if index == 5 or index == 6:
		return source
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = CROP_RECTS[index]
	return atlas

func open_from_menu(menu_control: Control) -> void:
	menu = menu_control
	preview = selected
	if overlay != null and is_instance_valid(overlay):
		overlay.visible = true
		overlay.move_to_front()
		_refresh()
		return
	_build_overlay()
	_refresh()

func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "ExactCollectibles"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 30000
	menu.add_child(overlay)
	overlay.move_to_front()

	# Keep the approved artwork as the frame/background.
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/collectibles_exact.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	# Cover the baked-in static showcase so the middle of the screen is genuinely dynamic.
	var showcase_cover := Panel.new()
	showcase_cover.position = Vector2(22, 190)
	showcase_cover.size = Vector2(346, 350)
	showcase_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cover_style := StyleBoxFlat.new()
	cover_style.bg_color = Color("071925")
	cover_style.border_color = Color("2a5668")
	cover_style.set_border_width_all(2)
	cover_style.set_corner_radius_all(8)
	showcase_cover.add_theme_stylebox_override("panel", cover_style)
	overlay.add_child(showcase_cover)

	name_label = Label.new()
	name_label.position = Vector2(48, 204)
	name_label.size = Vector2(294, 38)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color("f6d9a3"))
	name_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.7))
	name_label.add_theme_constant_override("shadow_offset_x", 2)
	name_label.add_theme_constant_override("shadow_offset_y", 2)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_label)

	sub_label = Label.new()
	sub_label.position = Vector2(70, 240)
	sub_label.size = Vector2(250, 24)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 14)
	sub_label.add_theme_color_override("font_color", Color.WHITE)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sub_label)

	# Large live ship preview. This texture is replaced every time an arrow is pressed.
	hero = TextureRect.new()
	hero.position = Vector2(118, 270)
	hero.size = Vector2(154, 190)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hero)

	# Use visible arrow controls over the same locations as the artwork so clicks are unmistakable.
	left_button = Button.new()
	left_button.text = "‹"
	left_button.position = Vector2(52, 342)
	left_button.size = Vector2(50, 74)
	left_button.focus_mode = Control.FOCUS_NONE
	left_button.add_theme_font_size_override("font_size", 38)
	left_button.add_theme_color_override("font_color", Color("ffc35b"))
	left_button.add_theme_stylebox_override("normal", _transparent_box())
	left_button.add_theme_stylebox_override("hover", _transparent_box())
	left_button.add_theme_stylebox_override("pressed", _transparent_box())
	left_button.pressed.connect(func(): _cycle(-1))
	overlay.add_child(left_button)

	right_button = Button.new()
	right_button.text = "›"
	right_button.position = Vector2(260, 342)
	right_button.size = Vector2(50, 74)
	right_button.focus_mode = Control.FOCUS_NONE
	right_button.add_theme_font_size_override("font_size", 38)
	right_button.add_theme_color_override("font_color", Color("ffc35b"))
	right_button.add_theme_stylebox_override("normal", _transparent_box())
	right_button.add_theme_stylebox_override("hover", _transparent_box())
	right_button.add_theme_stylebox_override("pressed", _transparent_box())
	right_button.pressed.connect(func(): _cycle(1))
	overlay.add_child(right_button)

	equip_button = Button.new()
	equip_button.position = Vector2(108, 472)
	equip_button.size = Vector2(174, 52)
	equip_button.focus_mode = Control.FOCUS_NONE
	equip_button.add_theme_font_size_override("font_size", 20)
	equip_button.add_theme_color_override("font_color", Color("17461f"))
	var equip_style := StyleBoxFlat.new()
	equip_style.bg_color = Color("ead9a4")
	equip_style.border_color = Color("8a6a34")
	equip_style.set_border_width_all(2)
	equip_style.set_corner_radius_all(8)
	equip_button.add_theme_stylebox_override("normal", equip_style)
	equip_button.add_theme_stylebox_override("hover", equip_style)
	equip_button.add_theme_stylebox_override("pressed", equip_style)
	equip_button.add_theme_stylebox_override("disabled", equip_style)
	equip_button.pressed.connect(_equip)
	overlay.add_child(equip_button)

	# The artwork's thumbnail strip is intentionally covered so it no longer looks like a frozen selector.
	var bottom_cover := Panel.new()
	bottom_cover.position = Vector2(0, 540)
	bottom_cover.size = Vector2(390, 232)
	bottom_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color("071925")
	bottom_style.border_color = Color("6f4725")
	bottom_style.set_border_width_all(2)
	bottom_cover.add_theme_stylebox_override("panel", bottom_style)
	overlay.add_child(bottom_cover)

	var hint := Label.new()
	hint.text = "Use the arrows to browse ships"
	hint.position = Vector2(55, 585)
	hint.size = Vector2(280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("d9f4fb"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint)

	var back := Button.new()
	back.text = "BACK"
	back.position = Vector2(120, 640)
	back.size = Vector2(150, 46)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_close)
	overlay.add_child(back)

	# Exact close-button area in the upper-right artwork.
	var close_hit := Button.new()
	close_hit.text = ""
	close_hit.flat = true
	close_hit.modulate = Color(1,1,1,0.01)
	close_hit.position = Vector2(338, 18)
	close_hit.size = Vector2(42, 54)
	close_hit.focus_mode = Control.FOCUS_NONE
	close_hit.pressed.connect(_close)
	overlay.add_child(close_hit)

func _transparent_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0,0,0,0)
	s.border_width_left = 0
	s.border_width_right = 0
	s.border_width_top = 0
	s.border_width_bottom = 0
	return s

func _cycle(delta: int) -> void:
	preview = wrapi(preview + delta, 0, NAMES.size())
	_refresh()

func _equip() -> void:
	selected = preview
	var cfg := ConfigFile.new()
	cfg.set_value("boats", "selected", selected)
	cfg.save(SAVE)
	_refresh()

func _refresh() -> void:
	if name_label:
		name_label.text = NAMES[preview].to_upper()
	if sub_label:
		sub_label.text = SUBS[preview]
	if hero:
		hero.texture = _ship_texture(preview)
		hero.modulate = Color.WHITE
	if equip_button:
		equip_button.text = "EQUIPPED" if preview == selected else "SELECT SHIP"
		equip_button.disabled = preview == selected

func _close() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.visible = false
