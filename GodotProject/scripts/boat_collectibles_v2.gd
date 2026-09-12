extends Node

const SAVE := "user://collectibles.cfg"
const NAMES := ["Plunderer","Crimson Raider","Black Pearl","Royal Fortune","Ghost Ship","Inferno","Sea Serpent","Golden Galleon"]
const SUBS := ["Default Ship","Raider Variant","Shadow Variant","Royal Variant","Spectral Variant","Infernal Variant","Serpent Variant","Legendary Variant"]
const FILES := ["plunderer","crimson_raider","black_pearl","royal_fortune","ghost_ship","inferno","sea_serpent","golden_galleon"]
const COLORS := [Color("9a6231"),Color("c8322f"),Color("20242b"),Color("f2e5c2"),Color("7fa7a1"),Color("e64a19"),Color("159b91"),Color("d6a51e")]
const CROP_RECTS := [
	Rect2(40,0,84,160), Rect2(42,0,82,160), Rect2(43,0,78,160), Rect2(43,0,80,160),
	Rect2(41,0,84,160), Rect2(42,0,84,160), Rect2(42,0,82,160), Rect2(40,0,82,160)
]

var selected := 0
var preview := 0
var textures: Array[Texture2D] = []
var menu: Control
var panel: Panel
var hero: TextureRect
var name_label: Label
var sub_label: Label
var equip: Button

func _ready():
	var c=ConfigFile.new()
	if c.load(SAVE)==OK:
		selected=clampi(int(c.get_value("boats","selected",0)),0,7)
	preview=selected
	# Ship artwork is now loaded only when the user opens Collectibles.
	# This keeps app startup fast so the splash screen can disappear sooner.
	get_tree().node_added.connect(func(n):
		if n.name=="PlayButton": call_deferred("_attach"))
	call_deferred("_attach")

func get_selected_index()->int: return selected
func get_selected_name()->String: return NAMES[selected]
func get_selected_color()->Color: return COLORS[selected]

func _ensure_textures() -> void:
	if textures.size()==FILES.size():
		return
	textures.clear()
	for i in range(FILES.size()):
		textures.append(_read_ship(i))

func _read_ship(index:int)->Texture2D:
	var source=load("res://assets/ships/%s.svg" % FILES[index]) as Texture2D
	if source==null:
		return null
	var atlas=AtlasTexture.new()
	atlas.atlas=source
	atlas.region=CROP_RECTS[index]
	return atlas

func _attach():
	var scene=get_tree().current_scene
	if not scene:return
	var play=scene.find_child("PlayButton",true,false) as Button
	if not play:return
	menu=play.get_parent() as Control
	if menu.get_node_or_null("CollectiblesButton"):return
	var b=Button.new()
	b.name="CollectiblesButton"
	b.text="🏆"
	b.position=Vector2(328,18)
	b.size=Vector2(46,46)
	b.z_index=10000
	b.focus_mode=Control.FOCUS_NONE
	b.mouse_filter=Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size",25)
	b.pressed.connect(_open)
	menu.add_child(b)
	b.move_to_front()

func _open():
	preview=selected
	_ensure_textures()
	if panel:
		panel.visible=true
		panel.move_to_front()
		_refresh()
		return
	_build()

func _build():
	panel=Panel.new()
	panel.position=Vector2(12,120)
	panel.size=Vector2(366,535)
	panel.z_index=20000
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	var bg=StyleBoxFlat.new()
	bg.bg_color=Color("081b25")
	bg.border_color=Color("8b5b2d")
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel",bg)
	menu.add_child(panel)

	var heading=_label("COLLECTIBLES",Vector2(18,10),Vector2(330,44),27,Color("f6d18a"))
	panel.add_child(heading)

	var tab=Button.new()
	tab.text="SHIPS"
	tab.disabled=true
	tab.position=Vector2(20,58)
	tab.size=Vector2(326,40)
	tab.add_theme_font_size_override("font_size",18)
	tab.add_theme_color_override("font_disabled_color",Color.WHITE)
	var tab_style=StyleBoxFlat.new()
	tab_style.bg_color=Color("1266a4")
	tab_style.border_color=Color("4ec9ff")
	tab_style.set_border_width_all(2)
	tab_style.set_corner_radius_all(10)
	tab.add_theme_stylebox_override("disabled",tab_style)
	panel.add_child(tab)

	name_label=_label("",Vector2(25,105),Vector2(316,34),23,Color("f6d18a"))
	panel.add_child(name_label)
	sub_label=_label("",Vector2(25,138),Vector2(316,24),13,Color("d9f4fb"))
	panel.add_child(sub_label)

	var frame=Panel.new()
	frame.position=Vector2(55,168)
	frame.size=Vector2(256,205)
	var fs=StyleBoxFlat.new()
	fs.bg_color=Color("102a35")
	fs.border_color=Color("28718e")
	fs.set_border_width_all(2)
	fs.set_corner_radius_all(18)
	frame.add_theme_stylebox_override("panel",fs)
	panel.add_child(frame)

	hero=TextureRect.new()
	hero.position=Vector2(38,6)
	hero.size=Vector2(180,193)
	hero.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.add_child(hero)

	for d in [["<",12,-1],[">",316,1]]:
		var a=Button.new()
		a.text=d[0]
		a.position=Vector2(d[1],238)
		a.size=Vector2(38,64)
		a.focus_mode=Control.FOCUS_NONE
		a.add_theme_font_size_override("font_size",24)
		a.pressed.connect(_cycle.bind(d[2]))
		panel.add_child(a)

	equip=Button.new()
	equip.position=Vector2(96,390)
	equip.size=Vector2(174,48)
	equip.focus_mode=Control.FOCUS_NONE
	equip.add_theme_font_size_override("font_size",17)
	equip.pressed.connect(_equip)
	panel.add_child(equip)

	var hint=_label("Use the arrows to browse ships",Vector2(45,444),Vector2(276,24),12,Color("9ec6d2"))
	panel.add_child(hint)

	var back=Button.new()
	back.text="BACK"
	back.position=Vector2(108,480)
	back.size=Vector2(150,42)
	back.focus_mode=Control.FOCUS_NONE
	back.pressed.connect(func():panel.visible=false)
	panel.add_child(back)
	_refresh()

func _label(text:String,pos:Vector2,size:Vector2,font_size:int,color:Color)->Label:
	var l=Label.new()
	l.text=text
	l.position=pos
	l.size=size
	l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func _cycle(d:int):
	preview=wrapi(preview+d,0,8)
	_refresh()

func _equip():
	selected=preview
	var c=ConfigFile.new()
	c.set_value("boats","selected",selected)
	c.save(SAVE)
	_refresh()

func _refresh():
	if name_label:name_label.text=NAMES[preview].to_upper()
	if sub_label:sub_label.text=SUBS[preview]
	if hero and preview<textures.size():hero.texture=textures[preview]
	if equip:
		equip.text="EQUIPPED" if preview==selected else "SELECT SHIP"
		equip.disabled=preview==selected
