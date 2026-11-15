extends "res://scripts/main.gd"
const Ritual=preload("res://scripts/ritual_layer.gd")
@export var renderer_script:Script=preload("res://scripts/mummy_renderer.gd")
const PRESENTATION_ORIGIN=Vector2(510,105)
var ritual:Control
var hotspots:Control
var status_label:Label
var review_mode=false
var picker_open=false
var finished=false
var stage_dim:ColorRect
var result_actions:Control

func new_attempt(show_instructions:bool=true)->void:
 finished=false
 super.new_attempt(show_instructions)

func _process(_delta:float)->void:
 if page=="result" and is_instance_valid(ritual) and is_instance_valid(stage_dim):
  var t=ritual.elapsed
  stage_dim.color.a=lerpf(.66,.93,smoothstep(0.0,.65,t))-smoothstep(2.7,4.6,t)*.15

func _ready()->void:
 DisplayServer.window_set_title("木乃伊工房｜整合試玩預覽")
 review_mode=OS.get_cmdline_user_args().has("--preview-tools")
 super._ready()
 if OS.get_cmdline_user_args().has("--ritual-preview"):
  answers=[0,0,0,0,0];page="result";render()

func cartouche(b:Button,font_size:int=32)->void:
 ResultPages.egyptian_button(b,font_size)

func play_again()->void:
 if page!="result" or not finished or dialog_question>=0:return
 new_attempt();render()

func go_home()->void:
 if page!="result" or not finished or dialog_question>=0:return
 new_attempt(false);render()

func render()->void:
 if page!="result":super.render();return
 clear_screen()
 var bg=TextureRect.new();bg.texture=preload("res://assets/questions/workshop-background.png")
 bg.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;bg.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(bg)
 var dim=ColorRect.new();dim.color=Color(.015,.07,.085,.85);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);dim.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(dim);stage_dim=dim
 canvas=Control.new();canvas.name="ResultCanvas";canvas.size=Vector2(1600,900)
 var zoom=minf(size.x/1600.0,size.y/900.0)
 canvas.scale=Vector2.ONE*zoom;canvas.position=(size-canvas.size*zoom)/2;add_child(canvas);stage=canvas
 var title_node=ResultPages.put_label(self,canvas,"木乃伊工房  /  法魯王的揭曉時刻",Rect2(300,20,1000,58),34,CREAM);title_node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status_label=ResultPages.put_label(self,canvas,"五個選擇，藏在同一具木乃伊之中。",Rect2(400,77,800,35),20,GOLD);status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var subject=renderer_script.new();subject.position=PRESENTATION_ORIGIN;canvas.add_child(subject);subject.configure(answers)
 hotspots=Control.new();hotspots.name="FiveHotspots";hotspots.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(hotspots)
 var places=[Vector2(330,180),Vector2(1100,315),Vector2(330,475),Vector2(1100,620),Vector2(330,740)]
 for i in range(5):
  var from=places[i]+Vector2(110,40);var to=PRESENTATION_ORIGIN+subject.anchors[i]
  var wire=Line2D.new();wire.points=PackedVector2Array([from,to]);wire.width=2;wire.default_color=Color("cfa760");hotspots.add_child(wire)
  var dot=Polygon2D.new();dot.polygon=PackedVector2Array([to+Vector2(0,-5),to+Vector2(5,0),to+Vector2(0,5),to+Vector2(-5,0)]);dot.color=GOLD;hotspots.add_child(dot)
  var tag=ResultPages.put_button(self,hotspots,"Hotspot%d"%i,Data.LABELS[i],Rect2(places[i],Vector2(220,80)),func():open_detail(i))
  cartouche(tag)
 ritual=Ritual.new();ritual.name="RitualLayer";ritual.position=PRESENTATION_ORIGIN;canvas.add_child(ritual);ritual.configure(subject);ritual.revealed.connect(_on_revealed)
 result_actions=Control.new();result_actions.name="ResultActions";result_actions.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(result_actions)
 cartouche(ResultPages.put_button(self,result_actions,"PlayAgain","再玩一次",Rect2(1270,715,285,66),play_again),27)
 cartouche(ResultPages.put_button(self,result_actions,"ResultHome","回到首頁",Rect2(1270,795,285,66),go_home),27)
 if review_mode:
  ResultPages.put_button(self,canvas,"ReplayRitual","重播開棺",Rect2(30,610,190,56),replay_ritual)
  ResultPages.put_button(self,canvas,"SkipRitual","跳過動畫",Rect2(30,685,190,56),skip_ritual)
  ResultPages.put_button(self,canvas,"PreviewTools","審閱選項",Rect2(30,770,170,56),func():picker_open=not picker_open;render())
  ResultPages.put_label(self,canvas,"獨立雛形 · 組合 "+Data.code(answers),Rect2(30,838,330,35),18,MUTED)
 ResultPages.put_label(self,canvas,"點選五個部位標籤，查看你的選擇。",Rect2(470,849,680,34),19,MUTED).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 if finished:ritual.skip()
 else:hotspots.visible=false;result_actions.visible=false
 if picker_open and review_mode:build_picker()

func replay_ritual()->void:
 if dialog_question>=0 or picker_open:return
 finished=false;hotspots.visible=false;result_actions.visible=false
 status_label.text="五個選擇，藏在同一具木乃伊之中。"
 ritual.play()

func skip_ritual()->void:
 if dialog_question>=0 or picker_open:return
 ritual.skip()

func _on_revealed()->void:
 finished=true;hotspots.visible=true;result_actions.visible=true
 status_label.text="你的木乃伊，已經甦醒。"

func open_detail(index:int)->void:
 if not finished:return
 super.open_detail(index)

func build_picker()->void:
 var panel=Panel.new();panel.name="ReviewOnlyPicker";panel.position=Vector2(235,165);panel.size=Vector2(1130,575)
 panel.add_theme_stylebox_override("panel",panel_style(Color("103e49"),GOLD,22));canvas.add_child(panel)
 ResultPages.put_label(self,panel,"審閱工具 · 243 組合 · "+Data.code(answers),Rect2(25,15,1000,45),27,CREAM)
 for i in range(5):
  ResultPages.put_button(self,panel,"PreviewChoice%d"%i,Data.LABELS[i]+"  /  "+Data.OPTIONS[i][answers[i]],Rect2(25,80+i*72,1080,60),func():answers[i]=(answers[i]+1)%3;finished=false;render())
 ResultPages.put_button(self,panel,"ClosePreviewTools","播放這個組合",Rect2(25,470,1080,65),func():picker_open=false;finished=false;render(),true)

func _unhandled_key_input(event:InputEvent)->void:
 super._unhandled_key_input(event)
 if review_mode and dialog_question<0 and page=="result":
  if event is InputEventKey and event.pressed and not event.echo:
   if event.keycode==KEY_SPACE:skip_ritual()
   if event.keycode==KEY_R:replay_ritual()
