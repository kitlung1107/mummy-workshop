extends Control
const Data = preload("res://scripts/content.gd")
const EntryPages = preload("res://scripts/entry_pages.gd")
const QuestionPages = preload("res://scripts/question_pages.gd")
const ResultPages = preload("res://scripts/result_pages.gd")
var review_controls=false
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
 var cjk_fallback=SystemFont.new()
 cjk_fallback.font_names=PackedStringArray(["Noto Sans CJK TC","Microsoft JhengHei","PingFang TC"])
 theme_new.default_font.fallbacks=[cjk_fallback]
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
 if page == "result":
  ResultPages.build(self)
  return
 if page in ["home", "instructions"]:
  EntryPages.build(self, page)
  return
 if page == "quiz":
  build_question()
  return
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
  "result": ResultPages.build(self)
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
 QuestionPages.build(self)

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

func open_detail(index: int) -> void:
 ResultPages.open_detail(self,index)

func close_detail() -> void:
 ResultPages.close_detail(self)

func _unhandled_key_input(event: InputEvent) -> void:
 if dialog_question>=0 and event.is_action_pressed("ui_cancel"):
  close_detail()
  get_viewport().set_input_as_handled()
