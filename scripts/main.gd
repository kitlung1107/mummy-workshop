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
var completion_records: Array = [] # Local UI history; Web completions also enter the authenticated host queue.
var root_box: VBoxContainer
var scroll: ScrollContainer
var stage: Control
var canvas: Control
var dialog_layer: Control
var dialog_question = -1
var restore_focus: Control
var resize_pending = false
var compact = false
const MISSION_DELAY_MSEC = 500
const DETAIL_CACHE_LIMIT = 5
var mission_ready_at = 0
var screen_generation = 0
var focus_request = 0
var detail_textures: Dictionary = {}
var attempt_id=0
var rebuilding=false
var keyboard_navigation=false
@onready var sound:Node=get_node("/root/GameAudio")

func _ready() -> void:
 var theme_new = Theme.new()
 theme_new.default_font = load("res://assets/chinese.ttf")
 var cjk_fallback=SystemFont.new()
 cjk_fallback.font_names=PackedStringArray(["Noto Sans CJK TC","Microsoft JhengHei","PingFang TC"])
 theme_new.default_font.fallbacks=[load("res://assets/fonts/NotoSansCJKtc-Regular.otf"),cjk_fallback]
 theme_new.default_font_size = 20
 theme = theme_new
 # The game area can resize independently beneath the audio toolbar.
 resized.connect(_resized)
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
 detail_textures.clear()
 attempt_id+=1
 if is_instance_valid(sound):sound.reset_attempt(attempt_id)
 answers=[-1,-1,-1,-1,-1]
 question=0
 submitted=false
 orders=[]
 for i in range(5):
  var order=[0,1,2]
  order.shuffle()
  orders.append(order)
 page="instructions" if show_instructions else "home"
 mission_ready_at=Time.get_ticks_msec()+MISSION_DELAY_MSEC if show_instructions else 0

func detail_texture(path: String) -> Texture2D:
 # Per-result LRU: at most the five chosen explanations, including review mode.
 var texture: Texture2D=detail_textures.get(path)
 if texture:
  detail_textures.erase(path)
 else:
  texture=load(path) as Texture2D
 if texture:
  detail_textures[path]=texture
  while detail_textures.size()>DETAIL_CACHE_LIMIT:
   detail_textures.erase(detail_textures.keys()[0])
 return texture

func request_option_focus(value: int, scroll_position:int=0) -> void:
 focus_request+=1
 _focus_option.call_deferred(screen_generation,focus_request,question,value,scroll_position)

func _focus_option(generation: int, request: int, question_id: int, value: int, scroll_position:int) -> void:
 if not is_inside_tree() or is_queued_for_deletion():return
 if generation!=screen_generation or request!=focus_request:return
 if page!="quiz" or submitted or question!=question_id or answers[question]!=value:return
 var target=find_child("Option%d"%value,true,false) as Control
 if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion():
  var question_scroll=find_child("QuestionScroll",true,false) as ScrollContainer
  if question_scroll and not keyboard_navigation:question_scroll.scroll_vertical=scroll_position
  target.grab_focus()

func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:keyboard_navigation=true
 elif event is InputEventMouseButton or event is InputEventScreenTouch:keyboard_navigation=false
 else:return
 # Touching a card must not pull the scroll position toward keyboard focus.
 # Keyboard Tab/arrow navigation still scrolls focused controls into view.
 for node in find_children("*","ScrollContainer",true,false):node.follow_focus=keyboard_navigation

func _resized() -> void:
 if not resize_pending:
  resize_pending=true
  _deferred_resize.call_deferred()

func _deferred_resize() -> void:
 resize_pending=false
 if not is_inside_tree():return
 if page=="result" and is_instance_valid(canvas) and canvas.is_inside_tree():
  # Preserve the live ritual, audio clock and modal; only layout changes.
  layout_result()
  if dialog_question>=0:ResultPages.layout_detail(self)
  return
 var was_dialog=dialog_question
 rebuilding=true
 render()
 if was_dialog>=0: open_detail(was_dialog)
 rebuilding=false

func layout_result()->void:
 var zoom=minf(size.x/1600.0,size.y/900.0)
 canvas.scale=Vector2.ONE*zoom
 canvas.position=(size-canvas.size*zoom)/2

func clear_screen() -> void:
 screen_generation+=1
 focus_request+=1
 if page!="result":detail_textures.clear()
 dialog_question=-1
 dialog_layer=null
 for child in get_children():
  remove_child(child)
  child.queue_free()

func render() -> void:
 sound.set_scene(page)
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
 root_box.add_child(button("開始作答  →",accept_mission,true))
 root_box.add_child(button("返回首頁",func(): page="home"; render()))

func build_question() -> void:
 QuestionPages.build(self)

func choose(value: int) -> void:
 if page!="quiz" or submitted or value<0 or value>2:return
 if answers[question]==value:return
 sound.choice(question,value)
 answers[question]=value
 render()

func next_question() -> void:
 if page!="quiz" or answers[question]<0:return
 if question<4:
  sound.cue("page-turn")
  question+=1
  render()
 else:submit()

func submit() -> bool:
 if submitted or not Data.valid(answers):return false
 if OS.has_feature("web"):
  var accepted=JavaScriptBridge.eval("window.HistoryMummy && window.HistoryMummy.complete("+JSON.stringify(answers)+")",true)
  if accepted != true:return false
 submitted=true
 completion_records.append(Data.record(answers,Time.get_datetime_string_from_system(true)+"Z"))
 page="result"
 render()
 return true

func open_detail(index: int) -> void:
 var before=dialog_question
 ResultPages.open_detail(self,index)
 if before<0 and dialog_question>=0:
  sound.set_ducked(true)
  if not rebuilding:sound.cue("detail-open")

func close_detail() -> void:
 var before=dialog_question
 ResultPages.close_detail(self)
 if before>=0 and dialog_question<0:
  sound.set_ducked(false)
  if not rebuilding:sound.cue("detail-close")

func start_game()->void:
 new_attempt();sound.cue("ui-tap");render()

func accept_mission()->void:
 if page!="instructions" or Time.get_ticks_msec()<mission_ready_at:return
 sound.cue("mission");page="quiz";render()

func entry_home()->void:
 sound.cue("home-return");page="home";render()

func previous_question()->void:
 if page!="quiz" or question<=0 or submitted:return
 sound.cue("page-turn");question-=1;render()

func _unhandled_key_input(event: InputEvent) -> void:
 if dialog_question>=0 and event.is_action_pressed("ui_cancel"):
  close_detail()
  get_viewport().set_input_as_handled()
