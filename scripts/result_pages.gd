extends RefCounted
const Data=preload("res://scripts/content.gd")
const ArtButton=preload("res://scripts/art_button.gd")
const Mummy=preload("res://scripts/mummy_renderer.gd")
const BACK=preload("res://assets/questions/workshop-background.png")
const FILES=["01-brain-nasal-correct-v2.png","02-brain-oil-incorrect-v2.png","03-brain-skull-incorrect-v2.png","04-organs-heart-kept-correct-v2.png","05-organs-heart-removed-incorrect-v2.png","06-organs-all-kept-incorrect-v2.png","07-drying-natron-correct-v2.png","08-drying-water-incorrect-v2.png","09-drying-beer-incorrect-v2.png","10-wrapping-linen-correct-v2.png","11-wrapping-direct-linen-incorrect-v2.png","12-wrapping-papyrus-incorrect-v2.png","13-burial-mask-coffin-correct-v3.png","14-burial-beside-coffin-incorrect-v2.png","15-burial-no-mask-incorrect-v3.png"]
const RETURN_RECTS=[
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
 var mummy=Mummy.new();mummy.position=Vector2(0,115);screen.add_child(mummy);mummy.configure(game.answers)
 var label_positions=[Vector2(12,125),Vector2(414,317),Vector2(12,480),Vector2(410,699),Vector2(12,765)]
 for i in range(5):
  var line=Line2D.new();line.width=3;line.default_color=game.GOLD
  var begin=label_positions[i]+Vector2(78,29)
  var end=mummy.position+mummy.anchors[i]
  line.points=PackedVector2Array([begin,end]);screen.add_child(line)
  var arrow=Polygon2D.new();var direction=(end-begin).normalized();var side=direction.orthogonal()*5
  arrow.polygon=PackedVector2Array([end,end-direction*14+side,end-direction*14-side]);arrow.color=game.GOLD;screen.add_child(arrow)
  var button=put_button(game,screen,"Hotspot%d"%i,("✓ " if game.answers[i]==0 else "× ")+Data.LABELS[i],Rect2(label_positions[i],Vector2(154,58)),func():game.open_detail(i))
  button.accessibility_description=Data.OPTIONS[i][game.answers[i]]
 var panel=Panel.new();panel.name="ResultSummary";panel.position=Vector2(604,112);panel.size=Vector2(958,724)
 panel.add_theme_stylebox_override("panel",game.panel_style(Color("fff1d1"),game.GOLD,26));screen.add_child(panel)
 put_label(game,panel,"完成 %d / 5 題  ·  %d 分"%[Data.score(game.answers),Data.score(game.answers)*20],Rect2(30,22,880,55),34,game.TEAL)
 put_label(game,panel,"點選部位標籤或下列步驟，查看這次選擇的圖解。",Rect2(30,80,880,44),23,game.TEAL)
 for i in range(5):
  var y=137+i*87
  var row=put_button(game,panel,"Summary%d"%i,"%s  %s｜%s"%["✓" if game.answers[i]==0 else "×",Data.LABELS[i],Data.OPTIONS[i][game.answers[i]]],Rect2(26,y,906,70),func():game.open_detail(i))
  row.add_theme_font_size_override("font_size",23 if i!=3 else 21)
 put_button(game,panel,"Replay","再玩一次",Rect2(30,596,280,64),func():game.new_attempt();game.render(),true)
 put_button(game,panel,"ReviewCombinations","243 組合試看",Rect2(334,596,285,64),func():game.review_controls=not game.review_controls;game.render())
 put_button(game,panel,"ResultHome","返回首頁",Rect2(643,596,285,64),func():game.page="home";game.render())
 put_label(game,screen,"審閱試玩版 · 美術待確認    組合 "+Data.code(game.answers),Rect2(608,846,900,34),19,game.CREAM)
 if game.review_controls:build_review(game,screen)

static func build_review(game:Control,parent:Control)->void:
 var bar=Panel.new();bar.name="CombinationPicker";bar.position=Vector2(604,112);bar.size=Vector2(958,478)
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
 var frame=Control.new();frame.name="DetailPanel";frame.position=game.canvas.position;frame.scale=game.canvas.scale;frame.size=Vector2(1600,900);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(frame)
 var number=index*3+game.answers[index]
 var texture=load("res://assets/explanations/"+FILES[number]) as Texture2D
 var crop=AtlasTexture.new();crop.atlas=texture;crop.filter_clip=true
 crop.region=Rect2(texture.get_width()*.354,texture.get_height()*.087,texture.get_width()*.638,texture.get_height()*.836)
 var art=TextureRect.new();art.name="ExplanationArtwork";art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.texture=crop
 art.position=Vector2(580,90);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.size=Vector2(1004,743);art.stretch_mode=TextureRect.STRETCH_SCALE
 art.mouse_filter=Control.MOUSE_FILTER_STOP
 art.set_meta("question_id",index);art.set_meta("option_id",game.answers[index]);art.set_meta("source_file",FILES[number])
 art.accessibility_description=Data.OPTIONS[index][game.answers[index]]+"\n"+NOTES[index][game.answers[index]]
 frame.add_child(art)
 art.set_deferred("size",Vector2(1004,743))
 var relative:Rect2=RETURN_RECTS[number]
 var return_rect=Rect2(Vector2(580,90)+(relative.position-Vector2(.354,.087))/Vector2(.638,.836)*Vector2(1004,743),relative.size/Vector2(.638,.836)*Vector2(1004,743))
 for spec in [["CloseDetail",Rect2(1454,126,56,56)],["ReturnMummy",return_rect]]:
  var button=ArtButton.new();button.name=spec[0];button.position=spec[1].position;button.size=spec[1].size
  button.accessibility_name="關閉解說" if spec[0]=="CloseDetail" else "返回木乃伊"
  button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  button.pressed.connect(game.close_detail);frame.add_child(button)
  if spec[0]=="ReturnMummy":button.grab_focus()
 put_label(game,frame,"點彈窗外空白位置或按 Esc，也可關閉",Rect2(700,848,800,35),22,game.CREAM)

static func close_detail(game:Control)->void:
 if game.dialog_question<0:return
 game.remove_child(game.dialog_layer);game.dialog_layer.queue_free();game.dialog_layer=null;game.dialog_question=-1
 lock_background(game,false)
 if is_instance_valid(game.restore_focus):game.restore_focus.grab_focus()
