extends Node

const SAVE := "user://collectibles.cfg"
const NAMES := ["Plunderer","Crimson Raider","Black Pearl","Royal Fortune","Ghost Ship","Inferno","Sea Serpent","Golden Galleon"]
const SUBS := ["Default Ship","Raider Variant","Shadow Variant","Royal Variant","Spectral Variant","Infernal Variant","Serpent Variant","Legendary Variant"]
const FILES := ["plunderer","crimson_raider","black_pearl","royal_fortune","ghost_ship","inferno","sea_serpent","golden_galleon"]
const COLORS := [Color("9a6231"),Color("c8322f"),Color("20242b"),Color("f2e5c2"),Color("7fa7a1"),Color("e64a19"),Color("159b91"),Color("d6a51e")]
# Exact safe crop windows for the eight 160x160 ship SVGs. We only remove empty
# horizontal canvas; the full 0..160 height is retained so no mast, flag, bow or stern can be cut off.
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
	if c.load(SAVE)==OK: selected=clampi(int(c.get_value("boats","selected",0)),0,7)
	preview=selected
	for i in range(FILES.size()): textures.append(_read_ship(i))
	get_tree().node_added.connect(func(n):
		if n.name=="PlayButton": call_deferred("_attach"))
	call_deferred("_attach")

func get_selected_index()->int: return selected
func get_selected_name()->String: return NAMES[selected]
func get_selected_color()->Color: return COLORS[selected]

func _read_ship(index:int)->Texture2D:
	# Use Godot's SVG renderer directly. AtlasTexture then gives every ship a deterministic
	# portrait crop. This avoids alpha scanning and stray antialias pixels entirely.
	var source=load("res://assets/ships/%s.svg" % FILES[index]) as Texture2D
	if source==null: return null
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
	var b=Button.new(); b.name="CollectiblesButton"; b.text="🏆"; b.position=Vector2(328,18); b.size=Vector2(46,46); b.z_index=10000
	b.add_theme_font_size_override("font_size",25); b.pressed.connect(_open); menu.add_child(b); b.move_to_front()

func _open():
	preview=selected
	if panel:
		panel.visible=true; panel.move_to_front(); _refresh(); return
	_build()

func _build():
	panel=Panel.new(); panel.position=Vector2(12,78); panel.size=Vector2(366,730); panel.z_index=20000
	var bg=StyleBoxFlat.new(); bg.bg_color=Color("081b25"); bg.border_color=Color("8b5b2d"); bg.set_border_width_all(4); bg.set_corner_radius_all(18); panel.add_theme_stylebox_override("panel",bg); menu.add_child(panel)
	var heading=_label("COLLECTIBLES",Vector2(18,10),Vector2(330,44),27,Color("f6d18a")); panel.add_child(heading)
	var tab=Button.new(); tab.text="SHIPS"; tab.disabled=true; tab.position=Vector2(20,58); tab.size=Vector2(326,40); tab.add_theme_font_size_override("font_size",18); tab.add_theme_color_override("font_disabled_color",Color.WHITE); panel.add_child(tab)
	name_label=_label("",Vector2(25,103),Vector2(316,34),23,Color("f6d18a")); panel.add_child(name_label)
	sub_label=_label("",Vector2(25,137),Vector2(316,24),13,Color("d9f4fb")); panel.add_child(sub_label)
	var frame=Panel.new(); frame.position=Vector2(55,165); frame.size=Vector2(256,205); var fs=StyleBoxFlat.new(); fs.bg_color=Color("102a35"); fs.border_color=Color("28718e"); fs.set_border_width_all(2); fs.set_corner_radius_all(18); frame.add_theme_stylebox_override("panel",fs); panel.add_child(frame)
	hero=TextureRect.new(); hero.position=Vector2(38,6); hero.size=Vector2(180,193); hero.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; hero.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; hero.mouse_filter=Control.MOUSE_FILTER_IGNORE; frame.add_child(hero)
	for d in [["<",12,-1],[">",316,1]]:
		var a=Button.new(); a.text=d[0]; a.position=Vector2(d[1],230); a.size=Vector2(38,64); a.pressed.connect(_cycle.bind(d[2])); panel.add_child(a)
	equip=Button.new(); equip.position=Vector2(96,378); equip.size=Vector2(174,44); equip.pressed.connect(_equip); panel.add_child(equip)
	var board=Panel.new(); board.position=Vector2(16,432); board.size=Vector2(334,224); board.clip_contents=true; var bs=StyleBoxFlat.new(); bs.bg_color=Color("ead4a1"); bs.set_corner_radius_all(10); board.add_theme_stylebox_override("panel",bs); panel.add_child(board)
	for i in range(8):
		var card=Button.new(); card.name="ShipCard%d"%i; card.position=Vector2(8+(i%4)*81,7+int(i/4)*105); card.size=Vector2(74,100); card.clip_contents=true; card.pressed.connect(_choose.bind(i)); board.add_child(card)
		var t=TextureRect.new(); t.texture=textures[i]; t.position=Vector2(8,2); t.size=Vector2(58,74); t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; t.mouse_filter=Control.MOUSE_FILTER_IGNORE; card.add_child(t)
		var l=_label(NAMES[i],Vector2(3,77),Vector2(68,19),8,Color("2b1a0c")); l.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS; card.add_child(l)
	var back=Button.new(); back.text="BACK"; back.position=Vector2(108,670); back.size=Vector2(150,42); back.pressed.connect(func():panel.visible=false); panel.add_child(back)
	_refresh()

func _label(text:String,pos:Vector2,size:Vector2,font_size:int,color:Color)->Label:
	var l=Label.new(); l.text=text; l.position=pos; l.size=size; l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",color); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; return l
func _cycle(d:int): preview=wrapi(preview+d,0,8); _refresh()
func _choose(i:int): preview=i; _refresh()
func _equip():
	selected=preview; var c=ConfigFile.new(); c.set_value("boats","selected",selected); c.save(SAVE); _refresh()
func _refresh():
	name_label.text=NAMES[preview].to_upper(); sub_label.text=SUBS[preview]; hero.texture=textures[preview]; equip.text="EQUIPPED" if preview==selected else "SELECT SHIP"; equip.disabled=preview==selected
	for i in range(8):
		var card=panel.find_child("ShipCard%d"%i,true,false) as Button
		var s=StyleBoxFlat.new(); s.bg_color=Color(1,1,1,0.04); s.set_corner_radius_all(7)
		if i==selected:s.border_color=Color("54e66a");s.set_border_width_all(3)
		elif i==preview:s.border_color=Color("f6c53d");s.set_border_width_all(3)
		card.add_theme_stylebox_override("normal",s); card.add_theme_stylebox_override("hover",s); card.add_theme_stylebox_override("pressed",s)
