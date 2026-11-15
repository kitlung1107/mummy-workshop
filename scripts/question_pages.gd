extends RefCounted
## Presentation only: stable option IDs, answers and scoring remain owned by main/content.
const Data = preload("res://scripts/content.gd")
const ART = preload("res://assets/questions/workshop-background.png")
const INK = Color("164d4e")
const GOLD = Color("d5ac53")
const PAPER = Color("fff6df")

static func build(game: Control) -> void:
 var back := ColorRect.new()
 back.color=Color("192c2c")
 back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(back)
 if game.size.x >= 960 and game.size.y >= 540:
  _wide(game)
 else:
  _compact(game)

static func _label(game: Control, text: String, font_size: int, color: Color) -> Label:
 return game.label(text,font_size,color)

static func _style(fill: Color, border: Color, radius: int=12) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color=fill
 style.border_color=border
 style.set_border_width_all(2)
 style.set_corner_radius_all(radius)
 style.content_margin_left=20
 style.content_margin_right=20
 style.content_margin_top=14
 style.content_margin_bottom=14
 return style

static func _button(game: Control, caption: String, action: Callable, primary: bool=false) -> Button:
 var button := Button.new()
 button.text=caption
 button.custom_minimum_size.y=60
 button.add_theme_font_size_override("font_size",26)
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for state in ["normal","hover","pressed","disabled"]:
  var fill := Color("0b5b60") if primary else PAPER
  if state=="hover":fill=Color("16737a") if primary else Color("fffcef")
  if state=="pressed":fill=Color("06434a") if primary else Color("f0dfb8")
  if state=="disabled":fill=Color("d9d1b9")
  button.add_theme_stylebox_override(state,_style(fill,GOLD if primary else Color("b99b61")))
 var focus := _style(Color.TRANSPARENT,Color("f5b532"))
 focus.set_border_width_all(4)
 button.add_theme_stylebox_override("focus",focus)
 for color_name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  button.add_theme_color_override(color_name,PAPER if primary else INK)
 button.add_theme_color_override("font_disabled_color",Color("887f69"))
 button.pressed.connect(action)
 return button

static func _option(game: Control, value: int, small: bool=false) -> Button:
 var chosen: bool=game.answers[game.question]==value
 var row := _button(game,"",func(): game.choose(value),chosen)
 row.name="Option%d"%value
 row.set_meta("option_id",value)
 row.set_meta("question_id",game.question)
 row.custom_minimum_size.y=86 if small else 88
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var margins := MarginContainer.new()
 margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 margins.mouse_filter=Control.MOUSE_FILTER_IGNORE
 for side in ["left","right"]:margins.add_theme_constant_override("margin_"+side,18)
 for side in ["top","bottom"]:margins.add_theme_constant_override("margin_"+side,14)
 row.add_child(margins)
 var contents := HBoxContainer.new()
 contents.add_theme_constant_override("separation",16)
 contents.mouse_filter=Control.MOUSE_FILTER_IGNORE
 margins.add_child(contents)
 var marker := _label(game,"●" if chosen else "○",26,GOLD if chosen else Color("9f885a"))
 marker.custom_minimum_size.x=28
 marker.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 contents.add_child(marker)
 var copy := _label(game,Data.OPTIONS[game.question][value],20 if small else 26,PAPER if chosen else Color("382e21"))
 copy.name="OptionText"
 copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 copy.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 contents.add_child(copy)
 # Long translated choices expand in the scrolling layout instead of clipping.
 if small:
  var usable: float=maxf(140,game.size.x-128)
  var lines: int=int(ceil(copy.get_theme_font("font").get_string_size(copy.text,HORIZONTAL_ALIGNMENT_LEFT,-1,20).x/usable))
  row.custom_minimum_size.y=maxf(86,lines*30+30)
 return row

static func _steps(game: Control, host: Control, small: bool=false) -> void:
 var steps := HBoxContainer.new()
 steps.name="QuestionSteps"
 steps.add_theme_constant_override("separation",8 if small else 24)
 steps.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 host.add_child(steps)
 for i in range(5):
  var active: bool=i==game.question
  var text := ("%02d\n%s" if small else "%02d  %s")%[i+1,Data.LABELS[i]]
  var label := _label(game,text,15 if small else 26,Color("ffe4a0") if active else Color("b6d0c9"))
  label.name="Step%d"%i
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  if active:
   label.add_theme_color_override("font_outline_color",Color("062e32"))
   label.add_theme_constant_override("outline_size",2)
  steps.add_child(label)

static func _navigation(game: Control, host: HBoxContainer, small: bool=false) -> void:
 var prev := _button(game,"← 上一步",func(): game.question-=1;game.render())
 prev.name="PreviousButton"
 prev.disabled=game.question==0
 prev.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 host.add_child(prev)
 if not small:
  var space := Control.new()
  space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  host.add_child(space)
 var next := _button(game,"提交  ✓" if game.question==4 else "下一步 →",func(): game.next_question(),true)
 next.name="NextButton"
 next.disabled=game.answers[game.question]<0
 next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 host.add_child(next)
 if small:
  for button in [prev,next]:button.add_theme_font_size_override("font_size",20)

static func _wide(game: Control) -> void:
 var frame := Control.new()
 frame.name="QuestionArtwork"
 frame.size=Vector2(1600,900)
 var factor: float=minf(game.size.x/1600.0,game.size.y/900.0)
 frame.scale=Vector2.ONE*factor
 frame.position=(game.size-frame.size*factor)/2
 game.add_child(frame)
 var art := TextureRect.new()
 art.texture=ART
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 frame.add_child(art)
 var progress := Control.new()
 progress.position=Vector2(192,16)
 progress.size=Vector2(1216,64)
 frame.add_child(progress)
 _steps(game,progress)
 var panel := Control.new()
 panel.position=Vector2(622,174)
 panel.size=Vector2(875,582)
 frame.add_child(panel)
 var count := _label(game,"第 %d / 5 步"%[game.question+1],19,Color("7f5d28"))
 count.position=Vector2(0,0);count.size=Vector2(875,30);panel.add_child(count)
 var heading := _label(game,Data.LABELS[game.question],52,INK)
 heading.name="QuestionHeading"
 heading.position=Vector2(0,37);heading.size=Vector2(875,68);panel.add_child(heading)
 var prompt := _label(game,Data.QUESTIONS[game.question],31,Color("382e21"))
 prompt.name="QuestionPrompt"
 prompt.position=Vector2(0,111);prompt.size=Vector2(875,58);panel.add_child(prompt)
 for display_index in range(3):
  var value: int=game.orders[game.question][display_index]
  var option := _option(game,value)
  option.position=Vector2(0,180+display_index*101)
  option.size=Vector2(875,88)
  panel.add_child(option)
 var navigation := HBoxContainer.new()
 navigation.position=Vector2(0,512)
 navigation.size=Vector2(875,70)
 navigation.add_theme_constant_override("separation",20)
 panel.add_child(navigation)
 _navigation(game,navigation)

static func _compact(game: Control) -> void:
 var art := TextureRect.new()
 art.texture=ART
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.modulate=Color(0.48,0.48,0.42)
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(art)
 var scroll := ScrollContainer.new()
 scroll.name="QuestionScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 game.add_child(scroll)
 var margins := MarginContainer.new()
 margins.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["top","bottom","left","right"]:margins.add_theme_constant_override("margin_"+side,16)
 scroll.add_child(margins)
 var stack := VBoxContainer.new()
 stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",14)
 margins.add_child(stack)
 var header := PanelContainer.new()
 header.custom_minimum_size.y=76
 header.add_theme_stylebox_override("panel",_style(Color("0b5056"),GOLD))
 stack.add_child(header)
 var step_host := Control.new()
 step_host.custom_minimum_size.y=46
 header.add_child(step_host)
 _steps(game,step_host,true)
 var paper := PanelContainer.new()
 paper.add_theme_stylebox_override("panel",_style(Color("fff3dcee"),GOLD,18))
 stack.add_child(paper)
 var body := VBoxContainer.new()
 body.add_theme_constant_override("separation",14)
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 paper.add_child(body)
 body.add_child(_label(game,"第 %d / 5 步"%[game.question+1],16,Color("7f5d28")))
 var heading := _label(game,Data.LABELS[game.question],34,INK)
 heading.name="QuestionHeading";body.add_child(heading)
 var prompt := _label(game,Data.QUESTIONS[game.question],22,Color("382e21"))
 prompt.name="QuestionPrompt";body.add_child(prompt)
 for value in game.orders[game.question]:body.add_child(_option(game,value,true))
 var navigation := HBoxContainer.new()
 navigation.add_theme_constant_override("separation",12)
 body.add_child(navigation)
 _navigation(game,navigation,true)
