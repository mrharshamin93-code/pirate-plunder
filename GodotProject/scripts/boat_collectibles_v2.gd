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
var equip_hitbox: Button
var selected_badge: Label

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

	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/collectibles_exact.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var hero_cover := ColorRect.new()
	hero_cover.color = Color(0.025, 0.10, 0.15, 0.98)
	hero_cover.position = Vector2(85, 203)
	hero_cover.size = Vector2(220, 292)
	hero_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hero_cover)

	name_label = Label.new()
	name_label.position = Vector2(55, 205)
	name_label.size = Vector2(280, 40)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 25)
	name_label.add_theme_color_override("font_color", Color("f6d9a3"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(name_label)

	sub_label = Label.new()
	sub_label.position = Vector2(75, 242)
	sub_label.size = Vector2(240, 24)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_size_override("font_size", 14)
	sub_label.add_theme_color_override("font_color", Color.WHITE)
	sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sub_label)

	hero = TextureRect.new()
	hero.position = Vector2(128, 270)
	hero.size = Vector2(134, 188)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hero)

	selected_badge = Label.new()
	selected_badge.position = Vector2(106, 479)
	selected_badge.size = Vector2(178, 50)
	selected_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_badge.add_theme_font_size_override("font_size", 20)
	selected_badge.add_theme_color_override("font_color", Color("17461f"))
	selected_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(selected_badge)

	_add_hitbox(Rect2(338, 20, 40, 48), _close)
	_add_hitbox(Rect2(62, 355, 42, 64), func(): _cycle(-1))
	_add_hitbox(Rect2(284, 355, 42, 64), func(): _cycle(1))
	equip_hitbox = _add_hitbox(Rect2(104, 476, 182, 58), _equip)

func _add_hitbox(r: Rect2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = ""
	b.flat = true
	b.modulate = Color(1, 1, 1, 0.01)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.position = r.position
	b.size = r.size
	b.pressed.connect(callback)
	overlay.add_child(b)
	b.move_to_front()
	return b

func _cycle(delta: int) -> void:
	preview = wrapi(preview + delta, 0, 8)
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
	if selected_badge:
		selected_badge.text = "EQUIPPED" if preview == selected else "SELECT SHIP"
	if equip_hitbox:
		equip_hitbox.disabled = preview == selected

func _close() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.visible = false
