extends Node

const SAVE := "user://collectibles.cfg"
const LEADERBOARD_SAVE := "user://leaderboard.cfg"
const NAMES := ["Regular Ship","Crimson Raider","Black Pearl","Royal Fortune","Ghost Ship","Inferno","Sea Serpent","Golden Galleon"]
const SUBS := ["Default Ship","Raider Variant","Shadow Variant","Royal Variant","Spectral Variant","Infernal Variant","Serpent Variant","Legendary Variant"]
const FILES := ["plunderer","crimson_raider","black_pearl","royal_fortune","ghost_ship","inferno","sea_serpent","golden_galleon"]
const COLORS := [Color("9a6231"),Color("c8322f"),Color("20242b"),Color("f2e5c2"),Color("7fa7a1"),Color("e64a19"),Color("159b91"),Color("d6a51e")]
const SCORE_UNLOCKS := [0,500,1000,2000,3500,5000,7500,10000]
const COIN_UNLOCKS := [0,25,75,150,300,500,750,1000]
const CROP_RECTS := [Rect2(40,0,84,160),Rect2(42,0,82,160),Rect2(43,0,78,160),Rect2(43,0,80,160),Rect2(41,0,84,160),Rect2(0,0,160,160),Rect2(0,0,160,200),Rect2(40,0,82,160)]
var selected:=0
var preview:=0
var active_tab:="ships"
var lifetime_coins:int=0
var last_run_coins:int=0
var textures:Array[Texture2D]=[]
var menu:Control
var overlay:Control
var hero:TextureRect
var name_label:Label
var sub_label:Label
var equip_button:Button
var left_button:Button
var right_button:Button
var ships_tab:Button
var mines_tab:Button
var mines_panel:Control
func _ready()->void:
 var cfg:=ConfigFile.new()
 if cfg.load(SAVE)==OK:
  selected=clampi(int(cfg.get_value("boats","selected",0)),0,7)
  lifetime_coins=maxi(0,int(cfg.get_value("progress","total_coins",0)))
 preview=selected;textures.resize(FILES.size())
 if not _is_unlocked(selected):
  selected=0;preview=0;_save_collectibles()
func _process(_delta:float)->void:
 var scene:Node=get_tree().current_scene
 if scene==null:return
 var current_value:Variant=scene.get("coins_collected")
 if current_value==null:return
 var current:int=maxi(0,int(current_value))
 if current<last_run_coins:
  last_run_coins=current
  return
 if current>last_run_coins:
  lifetime_coins+=current-last_run_coins
  last_run_coins=current
  _save_collectibles()
func _save_collectibles()->void:
 var cfg:=ConfigFile.new();cfg.set_value("boats","selected",selected);cfg.set_value("progress","total_coins",lifetime_coins);cfg.save(SAVE)
func _personal_best()->int:
 var cfg:=ConfigFile.new()
 if cfg.load(LEADERBOARD_SAVE)==OK:return maxi(0,int(cfg.get_value("player","personal_best",0)))
 return 0
func _is_unlocked(index:int)->bool:
 if index<=0:return true
 if index>=NAMES.size():return false
 return _personal_best()>=int(SCORE_UNLOCKS[index]) or lifetime_coins>=int(COIN_UNLOCKS[index])
func get_selected_index()->int:return selected
func get_selected_name()->String:return NAMES[selected]
func get_selected_color()->Color:return COLORS[selected]
func get_total_coins()->int:return lifetime_coins
func _ship_texture(index:int)->Texture2D:
 if index<0 or index>=FILES.size():return null
 if textures[index]==null:textures[index]=_read_ship(index)
 return textures[index]
func _read_ship(index:int)->Texture2D:
 var source:=load("res://assets/ships/%s.svg"%FILES[index]) as Texture2D
 if source==null:return null
 if index==5 or index==6:return source
 var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=CROP_RECTS[index];return atlas
func open_from_menu(menu_control:Control)->void:
 menu=menu_control;preview=selected;active_tab="ships"
 if overlay!=null and is_instance_valid(overlay):overlay.visible=true;overlay.move_to_front();_refresh();_refresh_tabs();return
 _build_overlay();_refresh();_refresh_tabs()
func _box(fill:Color,border:Color,r:int=8)->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=fill;s.border_color=border;s.set_border_width_all(2);s.set_corner_radius_all(r);return s
func _build_overlay()->void:
 overlay=Control.new();overlay.name="ExactCollectibles";overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.z_index=2500;menu.add_child(overlay);overlay.move_to_front()
 var bg:=TextureRect.new();bg.texture=load("res://assets/ui/collectibles_exact.jpg");bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_SCALE;bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(bg)
 var tab_cover:=Panel.new();tab_cover.position=Vector2(32,120);tab_cover.size=Vector2(326,58);tab_cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;tab_cover.add_theme_stylebox_override("panel",_box(Color("071925"),Color("6f4725")));overlay.add_child(tab_cover)
 ships_tab=Button.new();ships_tab.text="SHIPS";ships_tab.position=Vector2(40,126);ships_tab.size=Vector2(151,46);ships_tab.focus_mode=Control.FOCUS_NONE;ships_tab.add_theme_font_size_override("font_size",18);ships_tab.pressed.connect(func()->void:_set_tab("ships"));overlay.add_child(ships_tab)
 mines_tab=Button.new();mines_tab.text="MINES";mines_tab.position=Vector2(199,126);mines_tab.size=Vector2(151,46);mines_tab.focus_mode=Control.FOCUS_NONE;mines_tab.add_theme_font_size_override("font_size",18);mines_tab.pressed.connect(func()->void:_set_tab("mines"));overlay.add_child(mines_tab)
 var showcase:=Panel.new();showcase.position=Vector2(22,190);showcase.size=Vector2(346,350);showcase.mouse_filter=Control.MOUSE_FILTER_IGNORE;showcase.add_theme_stylebox_override("panel",_box(Color("071925"),Color("2a5668")));overlay.add_child(showcase)
 name_label=Label.new();name_label.position=Vector2(48,204);name_label.size=Vector2(294,38);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",25);name_label.add_theme_color_override("font_color",Color("f6d9a3"));name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(name_label)
 sub_label=Label.new();sub_label.position=Vector2(40,240);sub_label.size=Vector2(310,40);sub_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sub_label.add_theme_font_size_override("font_size",14);sub_label.add_theme_color_override("font_color",Color.WHITE);sub_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;sub_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(sub_label)
 hero=TextureRect.new();hero.position=Vector2(118,280);hero.size=Vector2(154,180);hero.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;hero.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;hero.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(hero)
 left_button=Button.new();left_button.text="‹";left_button.position=Vector2(52,342);left_button.size=Vector2(50,74);left_button.focus_mode=Control.FOCUS_NONE;left_button.add_theme_font_size_override("font_size",38);left_button.add_theme_color_override("font_color",Color("ffc35b"));left_button.add_theme_stylebox_override("normal",_transparent_box());left_button.add_theme_stylebox_override("hover",_transparent_box());left_button.add_theme_stylebox_override("pressed",_transparent_box());left_button.pressed.connect(func():_cycle(-1));overlay.add_child(left_button)
 right_button=Button.new();right_button.text="›";right_button.position=Vector2(260,342);right_button.size=Vector2(50,74);right_button.focus_mode=Control.FOCUS_NONE;right_button.add_theme_font_size_override("font_size",38);right_button.add_theme_color_override("font_color",Color("ffc35b"));right_button.add_theme_stylebox_override("normal",_transparent_box());right_button.add_theme_stylebox_override("hover",_transparent_box());right_button.add_theme_stylebox_override("pressed",_transparent_box());right_button.pressed.connect(func():_cycle(1));overlay.add_child(right_button)
 equip_button=Button.new();equip_button.position=Vector2(108,472);equip_button.size=Vector2(174,52);equip_button.focus_mode=Control.FOCUS_NONE;equip_button.add_theme_font_size_override("font_size",20)
 for state in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:equip_button.add_theme_color_override(state,Color("111111"))
 var es:=_box(Color("ead9a4"),Color("8a6a34"));equip_button.add_theme_stylebox_override("normal",es);equip_button.add_theme_stylebox_override("hover",es);equip_button.add_theme_stylebox_override("pressed",es);equip_button.add_theme_stylebox_override("disabled",es);equip_button.pressed.connect(_equip);overlay.add_child(equip_button)
 mines_panel=Control.new();mines_panel.position=Vector2(22,190);mines_panel.size=Vector2(346,350);mines_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(mines_panel)
 var mt:=Label.new();mt.text="MINES";mt.position=Vector2(40,82);mt.size=Vector2(266,42);mt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mt.add_theme_font_size_override("font_size",28);mt.add_theme_color_override("font_color",Color("f6d9a3"));mines_panel.add_child(mt)
 var mx:=Label.new();mx.text="Mine collectibles coming soon";mx.position=Vector2(38,145);mx.size=Vector2(270,34);mx.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mx.add_theme_font_size_override("font_size",15);mx.add_theme_color_override("font_color",Color("d9f4fb"));mines_panel.add_child(mx)
 var bottom:=Panel.new();bottom.position=Vector2(0,540);bottom.size=Vector2(390,304);bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE;bottom.add_theme_stylebox_override("panel",_box(Color("071925"),Color("6f4725"),0));overlay.add_child(bottom)
 var footer:=Panel.new();footer.position=Vector2(22,552);footer.size=Vector2(346,82);footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;footer.add_theme_stylebox_override("panel",_box(Color("071925"),Color("6f4725"),10));overlay.add_child(footer)
 var back:=Button.new();back.text="BACK";back.position=Vector2(72,568);back.size=Vector2(246,50);back.focus_mode=Control.FOCUS_NONE;back.pressed.connect(_close);overlay.add_child(back)
 var close_hit:=Button.new();close_hit.text="";close_hit.flat=true;close_hit.modulate=Color(1,1,1,0.01);close_hit.position=Vector2(338,18);close_hit.size=Vector2(42,54);close_hit.focus_mode=Control.FOCUS_NONE;close_hit.pressed.connect(_close);overlay.add_child(close_hit)
func _tab_box(fill:Color,border:Color)->StyleBoxFlat:return _box(fill,border)
func _refresh_tabs()->void:
 var ships_active:bool=active_tab=="ships"
 if ships_tab:ships_tab.add_theme_color_override("font_color",Color("fff1bd") if ships_active else Color("24160f"));ships_tab.add_theme_stylebox_override("normal",_tab_box(Color("8d1718") if ships_active else Color("e8c989"),Color("f4c64d") if ships_active else Color("9b5c16")))
 if mines_tab:mines_tab.add_theme_color_override("font_color",Color("fff1bd") if not ships_active else Color("24160f"));mines_tab.add_theme_stylebox_override("normal",_tab_box(Color("8d1718") if not ships_active else Color("e8c989"),Color("f4c64d") if not ships_active else Color("9b5c16")))
 for c:Control in [name_label,sub_label,hero,equip_button,left_button,right_button]:
  if c!=null:c.visible=ships_active
 if mines_panel!=null:mines_panel.visible=not ships_active
func _set_tab(tab_name:String)->void:active_tab=tab_name;_refresh_tabs()
func _transparent_box()->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=Color(0,0,0,0);return s
func _cycle(delta:int)->void:preview=wrapi(preview+delta,0,NAMES.size());_refresh()
func _equip()->void:
 if not _is_unlocked(preview):return
 selected=preview;_save_collectibles();_refresh()
func _refresh()->void:
 var unlocked:bool=_is_unlocked(preview)
 if name_label:name_label.text=NAMES[preview].to_upper()
 if sub_label:
  if unlocked:
   sub_label.text=SUBS[preview]
  else:
   sub_label.text="LOCKED — Reach score %s OR collect %s total coins"%[_comma(int(SCORE_UNLOCKS[preview])),_comma(int(COIN_UNLOCKS[preview]))]
 if hero:
  hero.texture=_ship_texture(preview);hero.modulate=Color.WHITE if unlocked else Color(0.38,0.38,0.38,1.0)
 if equip_button:
  if not unlocked:equip_button.text="LOCKED"
  elif preview==selected:equip_button.text="EQUIPPED"
  else:equip_button.text="SELECT SHIP"
  equip_button.disabled=not unlocked or preview==selected
 _refresh_tabs()
func _comma(value:int)->String:
 var s:=str(value);var out:=""
 while s.length()>3:out=","+s.substr(s.length()-3,3)+out;s=s.substr(0,s.length()-3)
 return s+out
func _close()->void:
 if overlay!=null and is_instance_valid(overlay):overlay.visible=false
