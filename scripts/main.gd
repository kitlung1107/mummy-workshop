extends Control
const Data = preload("res://scripts/content.gd")
const TEAL = Color("103e49")
const CREAM = Color("fff0ce")
const GOLD = Color("e7bd73")
const MUTED = Color("b4cdcb")
var answers: Array = [-1,-1,-1,-1,-1]
var orders: Array = []
var page = "home"
var question = 0
var submitted = false
var completion_records: Array = [] # session memory only; no persistence or backend
var root_box: VBoxContainer
var scroll: ScrollContainer
var stage: Control
var canvas: Control
var dialog_layer: Control
var dialog_question = -1
var restore_focus: Control
var resize_pending = false
var compact = false

func _ready() -> void:
 var theme_new = Theme.new()
 theme_new.default_font = load("res://assets/chinese.ttf")
 theme_new.default_font_size = 20
 theme = theme_new
 get_viewport().size_changed.connect(_resized)
 new_attempt(false)
 render()
 if OS.get_cmdline_user_args().has("--review"):
  answers=[2,2,2,2,2]
  submit()

func panel_style(color: Color, edge: Color = Color.TRANSPARENT, radius: int = 18) -> StyleBoxFlat:
 var st = StyleBoxFlat.new()
 st.bg_color=color
 st.border_color=edge
 st.set_border_width_all(1 if edge.a>0 else 0)
 st.set_corner_radius_all(radius)
 st.content_margin_left=20
 st.content_margin_right=20
 st.content_margin_top=16
 st.content_margin_bottom=16
 return st

func label(text_value: String, font_size: int = 20, color: Color = CREAM) -> Label:
 var node=Label.new()
 node.text=text_value
 node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 node.add_theme_font_size_override("font_size",font_size)
 node.add_theme_color_override("font_color",color)
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return node

func button(text_value: String, action: Callable, primary: bool = false) -> Button:
 var node=Button.new()
 node.text=text_value
 node.custom_minimum_size.y=54
 node.add_theme_font_size_override("font_size",19)
 node.add_theme_color_override("font_color",TEAL if primary else CREAM)
 node.add_theme_color_override("font_focus_color",TEAL if primary else CREAM)
 node.add_theme_color_override("font_hover_color",TEAL)
 node.add_theme_color_override("font_pressed_color",TEAL)
 node.add_theme_color_override("font_disabled_color",Color("719294"))
 node.add_theme_stylebox_override("normal",panel_style(GOLD if primary else Color("174d58"),GOLD if primary else Color("477077"),12))
 node.add_theme_stylebox_override("hover",panel_style(Color("f3d8a0"),GOLD,12))
 node.add_theme_stylebox_override("pressed",panel_style(Color("d4b372"),GOLD,12))
 node.add_theme_stylebox_override("disabled",panel_style(Color("123640"),Color("35555b"),12))
 node.add_theme_stylebox_override("focus",panel_style(Color(0,0,0,0),Color("fff1c9"),12))
 node.pressed.connect(action)
 return node

func gap(height: float) -> Control:
 var c=Control.new(); c.custom_minimum_size.y=height
 return c

func new_attempt(show_instructions: bool = true) -> void:
 answers=[-1,-1,-1,-1,-1]
 question=0
 submitted=false
 orders=[]
 for i in range(5):
  var order=[0,1,2]
  order.shuffle()
  orders.append(order)
 page="instructions" if show_instructions else "home"

func _resized() -> void:
 if not resize_pending:
  resize_pending=true
  _deferred_resize.call_deferred()

func _deferred_resize() -> void:
 resize_pending=false
 var was_dialog=dialog_question
 render()
 if was_dialog>=0: open_detail(was_dialog)

func clear_screen() -> void:
 dialog_question=-1
 dialog_layer=null
 for child in get_children():
  remove_child(child)
  child.queue_free()

func render() -> void:
 clear_screen()
 compact=size.x<640
 var back=ColorRect.new()
 back.color=Color("082e38")
 back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(back)
 back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 scroll=ScrollContainer.new()
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 var margin=MarginContainer.new()
 margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,16 if compact else 40)
 for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
 scroll.add_child(margin)
 root_box=VBoxContainer.new()
 root_box.add_theme_constant_override("separation",14)
 root_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 margin.add_child(root_box)
 var brand=label("NILE  /  尼羅河工房",15,GOLD)
 root_box.add_child(brand)
 match page:
  "home": build_home()
  "instructions": build_instructions()
  "quiz": build_question()
  "result": build_result()
 root_box.add_child(gap(10))
 var footer=label("獨立試玩版  ·  古埃及文化探索",13,MUTED)
 footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 root_box.add_child(footer)

func title(t: String, subtitle: String) -> void:
 root_box.add_child(label(t,30 if compact else 40))
 root_box.add_child(label(subtitle,17,MUTED))

func build_home() -> void:
 title("木乃伊工房", "五個選擇，揭曉你的製作結果。")
 var art=TextureRect.new()
 art.texture=preload("res://assets/entrance.svg")
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size.y=250 if compact else 380
 root_box.add_child(art)
 root_box.add_child(label("走進尼羅河畔的工房，\n用你學過的知識，完成這次挑戰。",22))
 root_box.add_child(button("開始遊戲  →",func(): new_attempt(); render(),true))

func build_instructions() -> void:
 title("先看看玩法", "準備好，就開始你的五個選擇。")
 var card=PanelContainer.new()
 card.add_theme_stylebox_override("panel",panel_style(TEAL,Color("38616b")))
 root_box.add_child(card)
 card.add_child(label(Data.INSTRUCTIONS,21))
 root_box.add_child(button("開始作答  →",func(): page="quiz"; render(),true))
 root_box.add_child(button("返回首頁",func(): page="home"; render()))

func build_question() -> void:
 title("第 %d / 5 步 · %s" % [question+1,Data.LABELS[question]],"提交前可隨時返回修改。")
 var dots=HBoxContainer.new()
 dots.add_theme_constant_override("separation",8)
 root_box.add_child(dots)
 for i in range(5):
  var dot=ColorRect.new()
  dot.custom_minimum_size.y=5
  dot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  dot.color=GOLD if i==question else Color("41656b") if answers[i]>=0 else Color("173f48")
  dots.add_child(dot)
 root_box.add_child(gap(12))
 root_box.add_child(label(Data.QUESTIONS[question],25 if compact else 30))
 root_box.add_child(gap(8))
 for display_i in range(3):
  var value: int=orders[question][display_i]
  var chosen: bool=answers[question]==value
  var row=button("",func(): choose(value),chosen)
  row.add_theme_stylebox_override("hover",panel_style(Color("efd097") if chosen else Color("235966"),GOLD,12))
  row.custom_minimum_size.y=94 if compact else 88
  row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var margin=MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  margin.add_theme_constant_override("margin_left",18)
  margin.add_theme_constant_override("margin_right",18)
  margin.add_theme_constant_override("margin_top",12)
  margin.add_theme_constant_override("margin_bottom",12)
  margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
  row.add_child(margin)
  var text_node=label(("●  " if chosen else "○  ")+Data.OPTIONS[question][value],20,TEAL if chosen else CREAM)
  margin.add_child(text_node)
  root_box.add_child(row)
 root_box.add_child(gap(8))
 var nav=HBoxContainer.new()
 nav.add_theme_constant_override("separation",12)
 root_box.add_child(nav)
 var prev=button("上一步",func(): question-=1; render())
 prev.disabled=question==0
 prev.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 nav.add_child(prev)
 var next=button("完成並揭曉" if question==4 else "下一步  →",next_question,true)
 next.name="NextButton"
 next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 next.disabled=answers[question]<0
 nav.add_child(next)
 root_box.add_child(label("答案會在五題全部完成後揭曉。",16,MUTED))

func choose(value: int) -> void:
 if page!="quiz" or submitted or value<0 or value>2:return
 answers[question]=value
 render()

func next_question() -> void:
 if page!="quiz" or answers[question]<0:return
 if question<4:
  question+=1
  render()
 else:submit()

func submit() -> bool:
 if submitted or not Data.valid(answers):return false
 submitted=true
 completion_records.append(Data.record(answers,Time.get_datetime_string_from_system(true)+"Z"))
 page="result"
 render()
 return true

func build_result() -> void:
 var score: int=Data.score(answers)
 title("你的木乃伊", "答對 %d / 5 題  ·  %d 分" % [score,score*20])
 root_box.add_child(label("點箭嘴標籤，看看每個選擇帶來的結果。",17,MUTED))
 var center=CenterContainer.new()
 root_box.add_child(center)
 var art_width: float=minf(size.x-(32 if compact else 100),600)
 if size.x>=640 and size.y>=600:
  art_width=minf(art_width,maxf(400,(size.y-240)*600.0/760.0))
 stage=Control.new()
 stage.custom_minimum_size=Vector2(art_width,art_width*760.0/600.0)
 center.add_child(stage)
 canvas=Control.new()
 canvas.size=Vector2(600,760)
 canvas.scale=Vector2.ONE*art_width/600.0
 stage.add_child(canvas)
 var texture=TextureRect.new()
 texture.texture=load("res://assets/results/"+Data.code(answers)+".svg")
 texture.size=Vector2(600,760)
 texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 canvas.add_child(texture)
 var positions=[Vector2(12,101),Vector2(450,258),Vector2(12,373),Vector2(450,523),Vector2(12,634)]
 for i in range(5):
  var btn=button(("✓ " if answers[i]==0 else "× ")+Data.LABELS[i],func():open_detail(i))
  btn.name="Hotspot%d"%i
  btn.position=positions[i]
  btn.size=Vector2(138,58)
  # scaled result labels retain >=44px touch height even on small screens
  btn.custom_minimum_size.y=maxf(58,44.0/canvas.scale.y)
  btn.size.y=btn.custom_minimum_size.y
  btn.add_theme_font_size_override("font_size",int(maxf(22,15.0/canvas.scale.y)))
  canvas.add_child(btn)
 var summary=label("  ".join(Data.LABELS.map(func(x):return ("✓ " if answers[Data.LABELS.find(x)]==0 else "× ")+x)),17)
 summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 root_box.add_child(summary)
 root_box.add_child(label(Data.CAVEAT,15,MUTED))
 root_box.add_child(button("再玩一次",func():new_attempt();render(),true))
 root_box.add_child(button("返回首頁",func():page="home";render()))

func open_detail(index: int) -> void:
 if page!="result" or dialog_question>=0 or index<0 or index>4:return
 dialog_question=index
 restore_focus=get_viewport().gui_get_focus_owner()
 dialog_layer=Control.new()
 dialog_layer.name="ExplanationModal"
 dialog_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 dialog_layer.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(dialog_layer)
 # Freeze every background control, including keyboard focus, while the modal is open.
 set_background_access(false)
 var dim=ColorRect.new()
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 dim.color=Color(0.01,0.05,0.07,0.84)
 dialog_layer.add_child(dim)
 dim.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
   get_viewport().set_input_as_handled()
   close_detail())
 var panel=PanelContainer.new()
 panel.name="DetailPanel"
 var width: float=minf(size.x-40,590)
 var height: float=minf(size.y-64,720)
 panel.position=(size-Vector2(width,height))/2
 panel.size=Vector2(width,height)
 panel.mouse_filter=Control.MOUSE_FILTER_STOP
 panel.add_theme_stylebox_override("panel",panel_style(Color("f6ecd6"),GOLD,20))
 dialog_layer.add_child(panel)
 var detail_scroll=ScrollContainer.new()
 detail_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(detail_scroll)
 var box=VBoxContainer.new()
 box.add_theme_constant_override("separation",14)
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 detail_scroll.add_child(box)
 var value: int=answers[index]
 box.add_child(label(("✓ 答對了 · " if value==0 else "× 再了解一下 · ")+Data.LABELS[index],24,TEAL))
 box.add_child(label("你的選擇\n"+Data.OPTIONS[index][value],19,TEAL))
 var art=TextureRect.new()
 art.texture=load("res://assets/details/%d_%d.svg"%[index,value])
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.custom_minimum_size.y=150 if compact else 190
 box.add_child(art)
 box.add_child(label(Data.WHY[index][value],19,TEAL))
 if index==1 and value==2 and answers[2]!=0:
  box.add_child(label("本次脫水也未做好，因此主圖以較明顯的腹部污斑示意。兩題仍分別計分。",17,Color("735333")))
 box.add_child(label("本題正確做法\n"+Data.OPTIONS[index][0],19,TEAL))
 box.add_child(label("局部圖只作教學示意。",14,Color("657872")))
 var close=button("返回完整木乃伊",close_detail,true)
 box.add_child(close)
 close.grab_focus()
 box.add_child(label("亦可點彈窗外空白位置，或按 Esc。",14,Color("657872")))

func set_background_access(enabled: bool) -> void:
 for node in root_box.find_children("*","Button",true,false):
  node.focus_mode=Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
  node.mouse_filter=Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
 scroll.mouse_filter=Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func close_detail() -> void:
 if dialog_question<0:return
 remove_child(dialog_layer)
 dialog_layer.queue_free()
 dialog_layer=null
 dialog_question=-1
 set_background_access(true)
 if is_instance_valid(restore_focus):restore_focus.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
 if dialog_question>=0 and event.is_action_pressed("ui_cancel"):
  close_detail()
  get_viewport().set_input_as_handled()
