extends RefCounted
const Data=preload("res://scripts/content.gd")
const ArtButton=preload("res://scripts/art_button.gd")
const Mummy=preload("res://scripts/mummy_renderer.gd")
const BACK=preload("res://assets/questions/workshop-background.png")
const FILES=["01-brain-nasal-correct-v2.png","02-brain-oil-incorrect-v2.png","03-brain-skull-incorrect-v2.png","04-organs-heart-kept-correct-v2.png","05-organs-heart-removed-incorrect-v2.png","06-organs-all-kept-incorrect-v2.png","07-drying-natron-correct-v2.png","08-drying-water-incorrect-v2.png","09-drying-beer-incorrect-v2.png","10-wrapping-linen-correct-v2.png","11-wrapping-direct-linen-incorrect-v2.png","12-wrapping-papyrus-incorrect-v2.png","13-burial-mask-coffin-correct-v3.png","14-burial-beside-coffin-incorrect-v2.png","15-burial-no-mask-incorrect-v3.png"]
# Source-only bounds of obsolete painted controls, covered with adjacent blank
# parchment during rendering. Original illustrations and ornamental borders stay intact.
const PAINTED_RETURN_RECTS=[
 Rect2(0.562200957,0.804463337,0.196770335,0.082890542),
 Rect2(0.562537403,0.804463337,0.196888091,0.082890542),
 Rect2(0.562200957,0.804463337,0.196770335,0.082890542),
 Rect2(0.561938959,0.821466525,0.197486535,0.077577046),
 Rect2(0.561602871,0.821466525,0.197368421,0.076514346),
 Rect2(0.562200957,0.821466525,0.196770335,0.076514346),
 Rect2(0.562200957,0.820403826,0.196172249,0.076514346),
 Rect2(0.561938959,0.820403826,0.196888091,0.075451647),
 Rect2(0.561938959,0.820403826,0.196888091,0.074388948),
 Rect2(0.562200957,0.819341126,0.196172249,0.074388948),
 Rect2(0.562200957,0.818278427,0.196172249,0.075451647),
 Rect2(0.561938959,0.804463337,0.196888091,0.082890542),
 Rect2(0.562275449,0.804463337,0.197005988,0.082890542),
 Rect2(0.562275449,0.803609342,0.197005988,0.082802548),
 Rect2(0.561602871,0.803400638,0.197368421,0.082890542)
]
const NOTES=[
 ["經鼻腔移除易腐敗組織，同時較能保存頭顱外形。","香油不能代替移除腦部；頭部出現紫色臭味提示。","打開頭顱會破壞外形；面具旁仍可見破損包布。"],
 ["肝、肺、胃、腸另作處理，心臟保留以配合來世信仰。","心臟被取出，不符合本題保留心臟的宗教要求。","內臟留在胸腹，保存風險上升；以暗斑及紫色臭味提示。"],
 ["固體天然鹼吸收水分，完成約 40 日的乾燥處理。","清水不能脫水；外層有藍灰濕痕及水滴。","啤酒不能代替天然鹼；外層有琥珀色濕痕。"],
 ["填充維持體形，再以樹脂、油及亞麻布處理。","缺乏填充，胸腹輪廓較凹；仍保留內臟時不會完全塌陷。","紙草的寬片植物紋理，與所需的亞麻布不同。"],
 ["金色面具配合入棺，完成本題法魯王的安葬安排。","全身與面具留在棺旁，空棺仍清楚可見。","已入棺，但頭部沒有本題要求的金色面具。"]]

static func put_label(game:Control,parent:Control,text:String,rect:Rect2,font_size:int,color:Color)->Label:
 var label=game.label(text,font_size,color)
 label.position=rect.position;label.size=rect.size
 parent.add_child(label)
 return label

static func put_button(game:Control,parent:Control,id:String,text:String,rect:Rect2,callback:Callable,primary:bool=false)->Button:
 var button=game.button(text,callback,primary)
 button.name=id;button.position=rect.position;button.size=rect.size
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 parent.add_child(button)
 return button

static func egyptian_button(button:Button,font_size:int=32)->void:
 var parchment=load("res://assets/refined/label-cartouche.svg") as Texture2D
 for state in ["normal","hover","pressed","disabled"]:
  var style=StyleBoxTexture.new()
  style.texture=parchment
  style.content_margin_left=24;style.content_margin_right=24
  style.content_margin_top=8;style.content_margin_bottom=10
  button.add_theme_stylebox_override(state,style)
 var focus=StyleBoxFlat.new()
 focus.bg_color=Color.TRANSPARENT;focus.border_color=Color("fff1bd")
 focus.set_border_width_all(2);focus.set_corner_radius_all(38)
 button.add_theme_stylebox_override("focus",focus)
 button.add_theme_font_size_override("font_size",font_size)
 button.add_theme_color_override("font_color",Color("53331d"))
 button.add_theme_color_override("font_hover_color",Color("26190f"))
 button.add_theme_color_override("font_pressed_color",Color("8a501c"))
 button.add_theme_color_override("font_focus_color",Color("53331d"))
 button.add_theme_color_override("font_shadow_color",Color("fff3ce"))
 button.add_theme_constant_override("shadow_offset_y",1)

static func build(game:Control)->void:
 var back=TextureRect.new()
 back.texture=BACK;back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 back.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.add_child(back)
 var shade=ColorRect.new();shade.color=Color(.015,.12,.14,.66)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.add_child(shade)
 var screen=Control.new();screen.name="ResultCanvas";screen.size=Vector2(1600,900)
 var zoom=minf(game.size.x/1600.0,game.size.y/900.0)
 screen.scale=Vector2.ONE*zoom;screen.position=(game.size-screen.size*zoom)/2
 game.add_child(screen);game.canvas=screen;game.stage=screen
 var title=Panel.new();title.position=Vector2(360,10);title.size=Vector2(880,74)
 title.add_theme_stylebox_override("panel",game.panel_style(Color("07575c"),game.GOLD,30));screen.add_child(title)
 var heading=put_label(game,title,"木乃伊工房｜製作結果",Rect2(20,10,840,58),38,game.CREAM)
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var mummy=Mummy.new();mummy.position=Vector2(510,115);screen.add_child(mummy);mummy.configure(game.answers)
 var label_positions=[Vector2(360,143),Vector2(980,321),Vector2(360,466),Vector2(980,632),Vector2(360,735)]
 for i in range(5):
  var line=Line2D.new();line.width=3;line.default_color=game.GOLD
  var begin=label_positions[i]+Vector2(110,40)
  var end=mummy.position+mummy.anchors[i]
  line.points=PackedVector2Array([begin,end]);screen.add_child(line)
  var arrow=Polygon2D.new();var direction=(end-begin).normalized();var side=direction.orthogonal()*5
  arrow.polygon=PackedVector2Array([end,end-direction*14+side,end-direction*14-side]);arrow.color=game.GOLD;screen.add_child(arrow)
  var button=put_button(game,screen,"Hotspot%d"%i,Data.LABELS[i],Rect2(label_positions[i],Vector2(220,80)),func():game.open_detail(i))
  egyptian_button(button)
  button.accessibility_description=Data.OPTIONS[i][game.answers[i]]
 var score_label=put_label(game,screen,"完成 %d / 5 題  ·  %d 分"%[Data.score(game.answers),Data.score(game.answers)*20],Rect2(38,32,310,48),25,game.CREAM)
 put_label(game,screen,"點選五個部位標籤，查看你的製作結果。",Rect2(515,850,700,38),22,game.CREAM).name="ResultHint"
 var replay=put_button(game,screen,"Replay","再玩一次",Rect2(1260,706,280,72),func():game.new_attempt();game.render(),true)
 egyptian_button(replay,28)
 var home=put_button(game,screen,"ResultHome","回到首頁",Rect2(1260,790,280,72),func():game.page="home";game.render())
 egyptian_button(home,28)
 if OS.get_cmdline_user_args().has("--review"):
  put_button(game,screen,"ReviewCombinations","243 組合試看",Rect2(40,715,300,60),func():game.review_controls=not game.review_controls;game.render())
  put_label(game,screen,"獨立精修預覽  ·  "+Data.code(game.answers),Rect2(40,790,370,40),20,game.CREAM)
 if game.review_controls:build_review(game,screen)

static func build_review(game:Control,parent:Control)->void:
 var bar=Panel.new();bar.name="CombinationPicker";bar.position=Vector2(40,112);bar.size=Vector2(958,478)
 bar.add_theme_stylebox_override("panel",game.panel_style(Color("fff1d1"),game.GOLD,24));parent.add_child(bar)
 put_label(game,bar,"組合試看｜"+Data.code(game.answers)+"  /  243（按各列切換選項）",Rect2(25,18,900,46),26,game.TEAL)
 for i in range(5):
  put_label(game,bar,Data.LABELS[i],Rect2(24,78+i*60,98,48),23,game.TEAL)
  var pick=put_button(game,bar,"Choice%d"%i,"↻  "+Data.OPTIONS[i][game.answers[i]],Rect2(126,76+i*60,805,52),func():game.answers[i]=(game.answers[i]+1)%3;game.render())
  pick.add_theme_font_size_override("font_size",22)
  pick.accessibility_description="按此切換下一個選項，共三個"
 put_button(game,bar,"PreviousCombination","上一組",Rect2(25,390,220,60),func():step(game,-1))
 put_button(game,bar,"NextCombination","下一組",Rect2(265,390,220,60),func():step(game,1))
 put_button(game,bar,"ClosePicker","收起試看選單",Rect2(510,390,420,60),func():game.review_controls=false;game.render(),true)

static func step(game:Control,amount:int)->void:
 var n=0
 for a in game.answers:n=n*3+a
 n=posmod(n+amount,243)
 var next:Array=[]
 for i in range(5):next.push_front(n%3);n=int(n/3)
 game.answers=next;game.render()

static func lock_background(game:Control,locked:bool)->void:
 var hint=game.canvas.find_child("ResultHint",true,false)
 if hint:hint.visible=not locked
 for node in game.canvas.find_children("*","BaseButton",true,false):
  node.focus_mode=Control.FOCUS_NONE if locked else Control.FOCUS_ALL
  node.mouse_filter=Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP

static func open_detail(game:Control,index:int)->void:
 if game.page!="result" or game.dialog_question>=0 or index<0 or index>4:return
 game.dialog_question=index;game.restore_focus=game.get_viewport().gui_get_focus_owner()
 lock_background(game,true)
 var layer=Control.new();layer.name="ExplanationModal";layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 game.add_child(layer);game.dialog_layer=layer
 var dim=ColorRect.new();dim.name="OutsideClose";dim.color=Color(.01,.06,.07,.65);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(dim)
 dim.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
   game.get_viewport().set_input_as_handled();game.close_detail())
 var frame=Control.new();frame.name="DetailPanel";frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(frame)
 var number=index*3+game.answers[index]
 var texture=game.detail_texture("res://assets/explanations/"+FILES[number]) as Texture2D
 var source_size=texture.get_size()
 var obsolete:Rect2=PAINTED_RETURN_RECTS[number]
 var factor=1004.0/(source_size.x*.638)
 frame.size=source_size*Vector2(.638,.836)*factor
 var art=TextureRect.new();art.name="ExplanationArtwork";art.size=frame.size
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.texture=texture
 var material=ShaderMaterial.new();material.shader=preload("res://scripts/explanation_art.gdshader")
 var cover=obsolete.grow_individual(.009,.009,.009,.010)
 material.set_shader_parameter("removed_rect",Vector4(cover.position.x,cover.position.y,cover.size.x,cover.size.y))
 art.material=material
 art.mouse_filter=Control.MOUSE_FILTER_STOP
 art.set_meta("question_id",index);art.set_meta("option_id",game.answers[index]);art.set_meta("source_file",FILES[number])
 art.accessibility_description=Data.OPTIONS[index][game.answers[index]]+"\n"+NOTES[index][game.answers[index]]
 frame.add_child(art)
 var button=ArtButton.new();button.name="CloseDetail"
 button.position=Vector2((.926-.354)*source_size.x,(.155-.087)*source_size.y)*factor-Vector2(28,28)
 button.size=Vector2(56,56);button.accessibility_name="關閉解說"
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 button.pressed.connect(game.close_detail);frame.add_child(button)
 # Only one modal control: Tab and Shift-Tab stay on the visible cross.
 button.focus_neighbor_top=button.get_path();button.focus_neighbor_bottom=button.get_path()
 button.focus_neighbor_left=button.get_path();button.focus_neighbor_right=button.get_path()
 button.focus_next=button.get_path();button.focus_previous=button.get_path()
 button.grab_focus()
 var hint=put_label(game,frame,"點彈窗外空白位置或按 Esc，也可關閉",Rect2(0,frame.size.y+12,frame.size.x,35),22,game.CREAM)
 hint.name="CloseHint";hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 layout_detail(game)

static func layout_detail(game:Control)->void:
 var frame=game.dialog_layer.get_node("DetailPanel") as Control
 var zoom=minf(1.0,minf(maxf(1,game.size.x-32)/frame.size.x,maxf(1,game.size.y-112)/frame.size.y))
 frame.scale=Vector2.ONE*zoom
 frame.position=(game.size-frame.size*zoom)/2

static func close_detail(game:Control)->void:
 if game.dialog_question<0:return
 game.remove_child(game.dialog_layer);game.dialog_layer.queue_free();game.dialog_layer=null;game.dialog_question=-1
 lock_background(game,false)
 if is_instance_valid(game.restore_focus) and game.restore_focus.is_inside_tree() and not game.restore_focus.is_queued_for_deletion():
  game.restore_focus.grab_focus()
 game.restore_focus=null
