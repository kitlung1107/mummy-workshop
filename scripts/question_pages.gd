extends RefCounted
## Presentation only: stable identities and game logic remain owned by main/content.
const Data=preload("res://scripts/content.gd")
const BACKGROUND=preload("res://assets/questions/workshop-background.png")
# Load only the current sheet. The other four keep no GPU texture resident.
const SHEETS=["res://assets/questions/visual/question-1.png","res://assets/questions/visual/question-2.png","res://assets/questions/visual/question-3.png","res://assets/questions/visual/question-4.png","res://assets/questions/visual/question-5.png"]
const INK=Color("164d4e")
const GOLD=Color("d5ac53")
const PAPER=Color("fff6df")
const REDRAWN_BRAIN_CARDS=["res://assets/questions/redrawn/brain-hook-v1.png","res://assets/questions/redrawn/brain-oil-v1.png","res://assets/questions/redrawn/brain-mallet-v1.png"]
const COMPLETE_CARD=preload("res://assets/questions/redrawn/papyrus-card-v1.png")

static func build(game:Control)->void:
 var background=TextureRect.new()
 background.texture=BACKGROUND
 background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 background.modulate=Color("343e3c") if game.size.y>=550 else Color("b6b5a5")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(background)
 if game.size.y>=550:_wide(game)
 else:_landscape(game)

static func _style(fill:Color,edge:Color,radius:int=14,width:int=2)->StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=fill;style.border_color=edge
 style.set_border_width_all(width);style.set_corner_radius_all(radius)
 return style

static func _place(node:Control,host:Control,at:Vector2,dimensions:Vector2)->void:
 node.position=at;node.size=dimensions;host.add_child(node)

static func _button(game:Control,caption:String,action:Callable,primary:bool=false)->Button:
 var button=Button.new()
 button.text=caption;button.custom_minimum_size.y=60
 button.add_theme_font_size_override("font_size",24)
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","disabled"]:
  var fill=Color("0b5b60") if primary else PAPER
  if state=="hover":fill=Color("16737a") if primary else Color("fffcef")
  if state=="pressed":fill=Color("06434a") if primary else Color("f0dfb8")
  if state=="disabled":fill=Color("807c6f")
  button.add_theme_stylebox_override(state,_style(fill,GOLD))
 button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("9eeff1"),14,4))
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  button.add_theme_color_override(key,PAPER if primary else INK)
 button.add_theme_color_override("font_disabled_color",Color("c5c1b6"))
 button.pressed.connect(action)
 return button

static func _choose(game:Control,value:int)->void:
 var scroll=game.find_child("QuestionScroll",true,false) as ScrollContainer
 var offset=scroll.scroll_vertical if scroll else 0
 game.choose(value)
 game.request_option_focus(value,offset)

static func _option(game:Control,value:int,width:float,art_height:float,caption_height:float,small:bool=false)->Button:
 var chosen:bool=game.answers[game.question]==value
 var card=Button.new()
 card.mouse_filter=Control.MOUSE_FILTER_PASS
 card.name="Option%d"%value
 card.accessibility_name=Data.OPTIONS[game.question][value]
 card.accessibility_description="已選取" if chosen else "未選取"
 card.set_meta("option_id",value);card.set_meta("question_id",game.question);card.set_meta("atlas_column",value)
 card.custom_minimum_size=Vector2(width,art_height+caption_height)
 card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 card.pressed.connect(func():_choose(game,value))
 card.add_theme_stylebox_override("normal",_style(Color("0b5b60") if chosen else PAPER,Color("8de3df") if chosen else GOLD,16,5 if chosen else 2))
 card.add_theme_stylebox_override("hover",_style(Color("146f73") if chosen else Color("fffbea"),Color("95ddda"),16,3))
 card.add_theme_stylebox_override("pressed",_style(Color("165b60"),Color("b5ffef"),16,5))
 card.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("b5f7f5"),16,3))
 var stack=VBoxContainer.new()
 stack.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stack.offset_left=7;stack.offset_top=7;stack.offset_right=-7;stack.offset_bottom=-7
 stack.add_theme_constant_override("separation",0);card.add_child(stack)
 var picture=TextureRect.new()
 var sheet:Texture2D=load(SHEETS[game.question])
 var atlas=AtlasTexture.new()
 atlas.atlas=sheet
 var cell_width:float=sheet.get_width()/3.0
 atlas.region=Rect2(value*cell_width,0,cell_width,sheet.get_height())
 picture.texture=atlas;picture.name="OptionArtwork"
 picture.set_meta("option_id",value);picture.set_meta("question_id",game.question)
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.custom_minimum_size.y=art_height-7
 picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.add_child(picture)
 var caption=HBoxContainer.new()
 caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 caption.size_flags_vertical=Control.SIZE_EXPAND_FILL
 caption.add_theme_constant_override("separation",10);stack.add_child(caption)
 var copy=game.label(Data.OPTIONS[game.question][value],21 if small else 25,PAPER if chosen else Color("382e21"))
 copy.name="OptionText";copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 copy.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;caption.add_child(copy)
 return card

static func _steps(game:Control,host:Control,small:bool=false)->void:
 var steps=HBoxContainer.new()
 steps.name="QuestionSteps";steps.add_theme_constant_override("separation",6 if small else 18)
 steps.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);host.add_child(steps)
 for i in range(5):
  var panel=PanelContainer.new()
  panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var active:bool=i==game.question
  panel.add_theme_stylebox_override("panel",_style(Color("17595e") if active else Color("173c3e"),GOLD if active else Color("52726a"),12))
  var text=("%02d\n%s" if small else "%02d  %s")%[i+1,Data.LABELS[i]]
  var label=game.label(text,15 if small else 24,Color("ffe4a0") if active else Color("bdd3cd"))
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  panel.add_child(label);steps.add_child(panel)

static func _navigation(game:Control,host:HBoxContainer,small:bool=false)->void:
 var prev=_button(game,"‹ 上一步",func():game.previous_question())
 prev.name="PreviousButton";prev.disabled=game.question==0
 prev.size_flags_horizontal=Control.SIZE_EXPAND_FILL;host.add_child(prev)
 if not small:
  var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;host.add_child(spacer)
 var next=_button(game,"揭曉 ›" if game.question==4 else "下一步 ›",func():game.next_question(),true)
 next.name="NextButton";next.disabled=game.answers[game.question]<0
 next.size_flags_horizontal=Control.SIZE_EXPAND_FILL;host.add_child(next)
 if small:
  for button in [prev,next]:button.add_theme_font_size_override("font_size",20)

static func _wide(game:Control)->void:
 var frame=Control.new()
 frame.name="QuestionArtwork";frame.size=Vector2(1600,900)
 var factor:float=minf(game.size.x/1600.0,game.size.y/900.0)
 frame.scale=Vector2.ONE*factor;frame.position=(game.size-frame.size*factor)/2;game.add_child(frame)
 var steps=Control.new();_place(steps,frame,Vector2(80,24),Vector2(minf(1440,(game.size.x-100-frame.position.x)/factor-80),60));_steps(game,steps)
 var heading=game.label(Data.LABELS[game.question],44,PAPER)
 heading.name="QuestionHeading";_place(heading,frame,Vector2(80,112),Vector2(1440,60))
 var prompt=game.label(Data.QUESTIONS[game.question],27,Color("ebdec0"))
 prompt.name="QuestionPrompt";_place(prompt,frame,Vector2(80,177),Vector2(1440,48))
 for display_index in range(3):
  var value:int=game.orders[game.question][display_index]
  var card=_option(game,value,458,450,112)
  _place(card,frame,Vector2(80+display_index*491,241),Vector2(458,562))
 var navigation=HBoxContainer.new();navigation.add_theme_constant_override("separation",24)
 _place(navigation,frame,Vector2(80,824),Vector2(1440,60));_navigation(game,navigation)

static func _compact(game:Control)->void:
 var scroll=preload("res://scripts/touch_scroll.gd").new();scroll.name="QuestionScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=game.keyboard_navigation
 scroll.offset_bottom=-84;game.add_child(scroll)
 var margin=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["top","bottom","left","right"]:margin.add_theme_constant_override("margin_"+side,16)
 scroll.add_child(margin)
 var stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",16);margin.add_child(stack)
 var steps=Control.new();steps.custom_minimum_size.y=70;stack.add_child(steps);_steps(game,steps,true)
 var heading=game.label(Data.LABELS[game.question],34,PAPER);heading.name="QuestionHeading";stack.add_child(heading)
 var prompt=game.label(Data.QUESTIONS[game.question],22,PAPER);prompt.name="QuestionPrompt";stack.add_child(prompt)
 var art_height:float=minf(380,maxf(240,game.size.x-48))
 var option_host:Container=stack
 var columns=game.size.x>=720
 if columns:
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);stack.add_child(row);option_host=row
  art_height=clampf(game.size.y-320,120,240)
 for value in game.orders[game.question]:
  var card=_option(game,value,220 if columns else 240,art_height,100,true)
  if columns:card.find_child("OptionText",true,false).add_theme_font_size_override("font_size",18)
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option_host.add_child(card)
 var navigation=HBoxContainer.new();navigation.add_theme_constant_override("separation",12)
 game.add_child(navigation)
 navigation.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 navigation.offset_left=16;navigation.offset_right=-16;navigation.offset_top=-72;navigation.offset_bottom=-12
 _navigation(game,navigation,true)

static func _landscape(game:Control)->void:
 var ui=preload("res://scripts/egyptian_ui.gd")
 var w=game.size.x
 var h=game.size.y
 var pad=12.0
 ui.panel(game,Rect2(4,2,w-8,52),true)
 var heading=game.label("%02d / 05  ·  %s"%[game.question+1,Data.LABELS[game.question]],15,Color("edcc82"))
 heading.name="QuestionHeading";_place(heading,game,Vector2(64,6),Vector2(132,40))
 heading.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var prompt=game.label(Data.QUESTIONS[game.question],20,Color("fff1ca"))
 prompt.name="QuestionPrompt";_place(prompt,game,Vector2(216,6),Vector2(w-316,40))
 prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var card_y=61.0
 var card_h=h-card_y-57
 var card_w=(w-pad*2-20)/3
 for i in range(3):
  var value:int=game.orders[game.question][i]
  _complete_landscape_card(game,value,Rect2(pad+i*(card_w+10),card_y,card_w,card_h))
 var nav=HBoxContainer.new();nav.add_theme_constant_override("separation",14)
 _place(nav,game,Vector2(pad,h-50),Vector2(w-24,46));_navigation(game,nav,true)
 for b in nav.get_children():
  b.custom_minimum_size.y=44;ui.button(b,17)

# The second phrase starts here when the full caption cannot fit on one line.
# Keys follow the stable answer IDs, independent of shuffled display order.
const CAPTION_SECOND_PHRASE = [
 ["取出腦部", "並塗香油", "取出腦部"],
 ["心臟留在體內", "胃、腸和心臟", "留在體內"],
 ["約 40 日", "約 40 日", "約 40 日"],
 ["塗樹脂和油", "亞麻布", "用紙草包裹"],
 ["並放入棺木", "但放在棺旁", "但不戴面具"]
]

static func _fit_landscape_caption(label:Label,area:Rect2,second_phrase:String)->void:
 var caption=label.text
 var font=label.get_theme_font("font")
 label.position=area.position
 label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 label.autowrap_mode=TextServer.AUTOWRAP_OFF
 # The CJK font includes leading above and below each line.
 const LINE_SPACING = -5
 label.add_theme_constant_override("line_spacing",LINE_SPACING)
 for point_size in range(16,13,-1):
  if font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x<=area.size.x:
   label.add_theme_font_size_override("font_size",point_size)
   label.size=area.size
   return
 var split_at=caption.find(second_phrase)
 if split_at>0:
  label.text=caption.insert(split_at,"\n")
 var lines=label.text.split("\n")
 # The lower corners contain painted leaves. Keep the second line inside them.
 var inner_width=area.size.x*.89
 if font.get_string_size(lines[-1],HORIZONTAL_ALIGNMENT_LEFT,-1,14).x>inner_width:
  var compact_font=FontVariation.new()
  compact_font.base_font=font
  compact_font.spacing_glyph=-1
  label.add_theme_font_override("font",compact_font)
  font=compact_font
 for point_size in range(16,11,-1):
  label.add_theme_font_size_override("font_size",point_size)
  var first_width=font.get_string_size(lines[0],HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x
  var last_width=font.get_string_size(lines[-1],HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x
  var height=label.get_line_height()*lines.size() + LINE_SPACING*(lines.size()-1)
  if first_width<=area.size.x and last_width<=inner_width and height<=area.size.y:
   break
 label.size=area.size

static func _complete_landscape_card(game:Control,value:int,bounds:Rect2)->void:
 var dimensions=bounds.size
 var chosen:bool=game.answers[game.question]==value
 var card=Button.new();card.name="Option%d"%value
 card.custom_minimum_size=dimensions;card.mouse_filter=Control.MOUSE_FILTER_PASS
 _place(card,game,bounds.position,dimensions)
 card.accessibility_name=Data.OPTIONS[game.question][value]
 card.set_meta("option_id",value);card.set_meta("question_id",game.question)
 card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 card.pressed.connect(func():_choose(game,value))
 for state in ["normal","hover","pressed"]:card.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 card.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("fff0bd"),12,2))
 var texture:Texture2D=load(REDRAWN_BRAIN_CARDS[value]) if game.question==0 else COMPLETE_CARD
 var scale_factor=minf(dimensions.x/texture.get_width(),dimensions.y/texture.get_height())
 var painted_size=texture.get_size()*scale_factor
 var inset=(dimensions-painted_size)*.5
 var background=TextureRect.new();background.name="OptionArtwork" if game.question==0 else "CompleteCardBackground"
 background.texture=texture;background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 background.position=inset;background.size=painted_size;background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 background.set_meta("whole_card",true);background.set_meta("option_id",value);background.set_meta("question_id",game.question)
 card.add_child(background)
 # The three brain options are complete individual paintings: no atlas or nine-patch.
 # Other questions retain their original complete square illustrations inside a new whole frame.
 if game.question>0:
  var picture=TextureRect.new();picture.name="OptionArtwork"
  var sheet:Texture2D=load(SHEETS[game.question]);var atlas=AtlasTexture.new();atlas.atlas=sheet
  atlas.region=Rect2(value*sheet.get_width()/3.0,0,sheet.get_width()/3.0,sheet.get_height())
  picture.texture=atlas;picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  picture.position=inset+painted_size*Vector2(.18,.06);picture.size=painted_size*Vector2(.64,.66)
  picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
  picture.set_meta("option_id",value);picture.set_meta("question_id",game.question);card.add_child(picture)
 var copy=game.label(Data.OPTIONS[game.question][value],16,Color("382e21"));copy.name="OptionText"
 card.add_child(copy)
 var caption_area=Rect2(inset+painted_size*Vector2(.08,.71),painted_size*Vector2(.84,.234))
 _fit_landscape_caption(copy,caption_area,CAPTION_SECOND_PHRASE[game.question][value])
 var selected=StyleBoxFlat.new();selected.bg_color=Color.TRANSPARENT;selected.border_color=Color("ffd36a")
 selected.set_border_width_all(3);selected.set_corner_radius_all(12)
 var ring=Panel.new();ring.name="SelectedYellowBorder";ring.add_theme_stylebox_override("panel",selected)
 ring.position=inset;ring.size=painted_size;ring.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(ring)
 _set_landscape_choice(card,background,chosen)

static func _set_landscape_choice(card:Button,background:TextureRect,chosen:bool)->void:
 card.accessibility_description="已選擇" if chosen else "未選擇"
 background.modulate=Color(1.12,1.06,.74) if chosen else Color.WHITE
 card.get_node("SelectedYellowBorder").visible=chosen

static func update_landscape_selection(game:Control)->void:
 # Keep the painted controls resident while the browser starts the answer cue.
 for value in range(3):
  var card:Button=game.get_node("Option%d"%value)
  var background:TextureRect=card.get_node("OptionArtwork" if game.question==0 else "CompleteCardBackground")
  _set_landscape_choice(card,background,game.answers[game.question]==value)
 var next:=game.find_child("NextButton",true,false) as Button
 next.disabled=false
