extends RefCounted
## Presentation only: stable identities and game logic remain owned by main/content.
const Data=preload("res://scripts/content.gd")
const BACKGROUND=preload("res://assets/questions/workshop-background.png")
const SHEETS=[preload("res://assets/questions/visual/question-1.png"),preload("res://assets/questions/visual/question-2.png"),preload("res://assets/questions/visual/question-3.png"),preload("res://assets/questions/visual/question-4.png"),preload("res://assets/questions/visual/question-5.png")]
const INK=Color("164d4e")
const GOLD=Color("d5ac53")
const PAPER=Color("fff6df")

static func build(game:Control)->void:
 var background=TextureRect.new()
 background.texture=BACKGROUND
 background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 background.modulate=Color("343e3c")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(background)
 if game.size.x>=960 and game.size.y>=540:_wide(game)
 else:_compact(game)

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
 game.choose(value)
 var replacement=game.find_child("Option%d"%value,true,false)
 if replacement:replacement.grab_focus.call_deferred()

static func _option(game:Control,value:int,width:float,art_height:float,caption_height:float,small:bool=false)->Button:
 var chosen:bool=game.answers[game.question]==value
 var card=Button.new()
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
 var sheet:Texture2D=SHEETS[game.question]
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
 var marker=game.label("●" if chosen else "○",24,Color("a7f3e5") if chosen else Color("a17e3b"))
 marker.custom_minimum_size.x=34;marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 marker.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;caption.add_child(marker)
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
 var prev=_button(game,"‹ 上一步",func():game.question-=1;game.render())
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
 var steps=Control.new();_place(steps,frame,Vector2(80,24),Vector2(1440,60));_steps(game,steps)
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
 var scroll=ScrollContainer.new();scroll.name="QuestionScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;game.add_child(scroll)
 var margin=MarginContainer.new();margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["top","bottom","left","right"]:margin.add_theme_constant_override("margin_"+side,16)
 scroll.add_child(margin)
 var stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",16);margin.add_child(stack)
 var steps=Control.new();steps.custom_minimum_size.y=70;stack.add_child(steps);_steps(game,steps,true)
 var heading=game.label(Data.LABELS[game.question],34,PAPER);heading.name="QuestionHeading";stack.add_child(heading)
 var prompt=game.label(Data.QUESTIONS[game.question],22,PAPER);prompt.name="QuestionPrompt";stack.add_child(prompt)
 var art_height:float=minf(380,maxf(240,game.size.x-48))
 for value in game.orders[game.question]:
  var card=_option(game,value,240,art_height,100,true)
  card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_child(card)
 var navigation=HBoxContainer.new();navigation.add_theme_constant_override("separation",12)
 stack.add_child(navigation);_navigation(game,navigation,true)
