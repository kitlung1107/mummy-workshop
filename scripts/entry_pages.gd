extends RefCounted
## The painted room and the controls share a viewport, including on short phones.
const HOME=preload("res://assets/entry/home-panorama.jpg")
const INSTRUCTIONS=preload("res://assets/entry/instructions-v3.png")
const MISSION_ART=preload("res://assets/entry/mission-landscape-redrawn-v1.png")
const ROOM=preload("res://assets/questions/workshop-background.png")
const WorkshopSkin=preload("res://scripts/workshop_settings_skin.gd")
const INSTRUCTION_COPY="你是一位古埃及防腐師。\n王室交給你一項重要任務：為法魯王製作木乃伊。"
const OUTCOME_COPY="每個部分選一種做法。\n完成後，看看你製作的木乃伊會變成甚麼模樣！"

static func build(game:Control,page:String)->void:
 if page=="home":
  _home(game)
 elif game.size.x<game.size.y:
  _compact_instructions(game)
 else:
  _mission(game)

static func _home(game:Control)->void:
 var natural:=HOME.get_size()
 var zoom:=maxf(game.size.x/natural.x,game.size.y/natural.y)
 var frame:=Control.new()
 frame.name="EntryArtwork"
 frame.size=natural*zoom
 frame.position=(game.size-frame.size)/2
 game.add_child(frame)
 var art:=TextureRect.new()
 art.texture=HOME
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 frame.add_child(art)
 if game.has_meta("home_pointer"):game.remove_meta("home_pointer")
 var start:=_hotspot(frame,"StartGame","開始遊戲",Rect2(.378,.793,.246,.153),func():game.start_game())
 _remember_pointer(start,game,"home_pointer")

static func _mission(game:Control)->void:
 # Use the workshop's painted wall and writing surface as a single full-bleed
 # background. Place all readable copy, seals and controls in viewport space.
 var source:=AtlasTexture.new()
 var original:=ROOM.get_size()
 source.atlas=ROOM
 source.region=Rect2(0,original.y*.111,original.x,original.y*.889)
 var room:=TextureRect.new()
 room.name="MissionRoom"
 room.texture=source
 room.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 room.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var zoom:=maxf(game.size.x/source.get_width(),game.size.y/source.get_height())
 room.size=source.get_size()*zoom
 room.position=(game.size-room.size)/2
 game.add_child(room)
 var h:=game.size.y
 var w:=game.size.x
 var left:=clampf(room.position.x+room.size.x*.354,w*.28,w*.48)
 var right:=minf(w-20,room.position.x+room.size.x*.971)
 var width:=right-left
 var unit:=clampf(minf(w/1040,h/560),.67,1.65)
 var ink:=Color("55371c")
 var title:Label=game.label("你的任務",roundi(35*unit),ink)
 _place(title,game,Rect2(left,h*.058,width,h*.103))
 var copy:Label=game.label(INSTRUCTION_COPY,roundi(21*unit),ink)
 _place(copy,game,Rect2(left,h*.167,width,h*.154))
 var slot:=width/5
 var diameter:=minf(slot*.83,h*.225)
 var centers=[.410,.525,.640,.755,.870]
 var names=["腦部","內臟","脫水","包裹","安葬"]
 for i in range(5):
  var coin:=TextureRect.new()
  coin.name="MissionSeal%d"%i
  coin.texture=_seal(centers[i])
  coin.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  coin.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  coin.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var pos:=Vector2(left+slot*(i+.5)-diameter/2,h*.33)
  coin.position=pos
  coin.size=Vector2.ONE*diameter
  # Discard the square atlas corners so the seals sit directly on the paper.
  var mask:=ShaderMaterial.new()
  mask.shader=preload("res://scripts/mission_seal.gdshader")
  mask.set_shader_parameter("diameter",diameter)
  coin.material=mask
  game.add_child(coin)
  var caption:Label=game.label("%02d  %s"%[i+1,names[i]],roundi(17*unit),ink)
  _place(caption,game,Rect2(left+slot*i,pos.y+diameter+2,slot,h*.063))
 var outcome:Label=game.label(OUTCOME_COPY,roundi(20*unit),ink)
 _place(outcome,game,Rect2(left,h*.64,width,h*.127))
 var actions:=HBoxContainer.new()
 actions.position=Vector2(left,h*.805)
 actions.size=Vector2(width,maxf(44,h*.126))
 actions.add_theme_constant_override("separation",roundi(10*unit))
 game.add_child(actions)
 for i in range(2):
  var control:=Button.new()
  control.name="BackHome" if i==0 else "AcceptMission"
  control.text="返回首頁" if i==0 else "接受任務"
  control.accessibility_name=control.text
  control.custom_minimum_size.y=44
  control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  control.size_flags_stretch_ratio=1.0 if i==0 else 1.4
  WorkshopSkin.button(control,WorkshopSkin.STONE if i==0 else WorkshopSkin.JADE,null if i==0 else WorkshopSkin.PLAY,roundi(22*unit))
  if i==0:
   _remember_pointer(control,control,"back_pointer")
   control.pressed.connect(func():
    # A rapid second tap on Start may land on the newly reflowed Back control.
    if Time.get_ticks_msec()<game.mission_ready_at and game.has_meta("home_pointer") and control.has_meta("back_pointer"):
     var first:Vector2=game.get_meta("home_pointer")
     if first.distance_to(control.get_meta("back_pointer"))<16:return
    game.entry_home())
  else:control.pressed.connect(func():game.accept_mission())
  actions.add_child(control)

static func _seal(center:float)->AtlasTexture:
 var seal:=AtlasTexture.new()
 seal.atlas=MISSION_ART
 var source:=MISSION_ART.get_size()
 var extent:=source.x*.096
 seal.region=Rect2(source.x*center-extent/2,source.y*.435-extent/2,extent,extent)
 return seal

static func _place(label:Label,game:Control,rect:Rect2)->void:
 label.position=rect.position
 label.size=rect.size
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 game.add_child(label)

static func _remember_pointer(control:Button,owner:Control,key:String)->void:
 control.gui_input.connect(func(event:InputEvent):
  if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
   owner.set_meta(key,control.get_global_transform_with_canvas()*event.position)
  elif event is InputEventKey and event.pressed and owner.has_meta(key):
   owner.remove_meta(key))

static func _hotspot(frame: Control, id: String, caption: String, region: Rect2, action: Callable) -> Button:
 var control := Button.new()
 control.name = id
 control.accessibility_name = caption if not caption.is_empty() else ("開始遊戲" if id=="StartGame" else "接受任務")
 control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 control.position = region.position * frame.size
 control.size = region.size * frame.size
 # Touch targets remain usable on small windows without cropping the artwork.
 if control.size.y < 44:
  control.position.y -= (44-control.size.y)/2
  control.size.y=44
 if control.size.x < 44:
  control.position.x -= (44-control.size.x)/2
  control.size.x=44
 control.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
 for state in ["hover", "pressed", "focus"]:
  var style := StyleBoxFlat.new()
  style.bg_color=Color(1,0.9,0.65,0.13 if state=="hover" else 0.22 if state=="pressed" else 0)
  style.border_color=Color("fff5d5")
  style.set_border_width_all(3 if state=="focus" else 0)
  style.set_corner_radius_all(28)
  control.add_theme_stylebox_override(state,style)
 control.pressed.connect(action)
 frame.add_child(control)
 return control

static func _compact_instructions(game: Control) -> void:
 var backdrop := TextureRect.new()
 # Reuse only the character illustration; baked-in page copy must not sit
 # behind the live, reflowing text on narrow screens.
 var character_art := AtlasTexture.new()
 character_art.atlas=INSTRUCTIONS
 character_art.region=Rect2(0,135,440,780)
 backdrop.texture=character_art
 backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.modulate=Color(0.28,0.32,0.30)
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(backdrop)
 var scroll := preload("res://scripts/touch_scroll.gd").new()
 scroll.name="EntryScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=game.keyboard_navigation
 scroll.offset_bottom=-76
 game.add_child(scroll)
 var margins := MarginContainer.new()
 margins.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for edge in ["left","right","top","bottom"]:
  margins.add_theme_constant_override("margin_"+edge,18)
 scroll.add_child(margins)
 var stack := VBoxContainer.new()
 stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",16)
 margins.add_child(stack)
 var back: Button=game.button("← 返回首頁",func(): game.entry_home())
 back.name="BackHome"
 stack.add_child(back)
 var title: Label=game.label("遊戲玩法",34,Color("ffe0a0"))
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 stack.add_child(title)
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",game.panel_style(Color("fff0ce"),Color("d6ab61"),18))
 stack.add_child(panel)
 var copy: Label=game.label(INSTRUCTION_COPY,23,Color("352619"))
 copy.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(copy)
 stack.add_child(game.label("以下五個部分，由你決定怎樣處理。",21))
 var grid := GridContainer.new()
 grid.columns=2 if game.size.x<720 else 5
 grid.add_theme_constant_override("h_separation",10)
 grid.add_theme_constant_override("v_separation",10)
 stack.add_child(grid)
 var parts=["腦部","內臟","脫水","包裹","安葬"]
 for i in range(5):
  var part := PanelContainer.new()
  part.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  part.add_theme_stylebox_override("panel",game.panel_style(Color("103e49"),Color("d6ab61"),14))
  var text: Label=game.label("%02d  %s" % [i+1,parts[i]],20,Color("ffe4a9"))
  text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  part.add_child(text)
  grid.add_child(part)
 stack.add_child(game.label(OUTCOME_COPY,21))
 var accept: Button=game.button("接受任務",func(): game.accept_mission(),true)
 accept.name="AcceptMission"
 game.add_child(accept)
 accept.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 accept.offset_left=18;accept.offset_right=-18;accept.offset_top=-64;accept.offset_bottom=-10
