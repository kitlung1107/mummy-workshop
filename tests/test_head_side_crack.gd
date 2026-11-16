extends SceneTree
const Data=preload("res://scripts/content.gd")
const OUT="res://review/head-crack-b/"
const KEY_CODES=["CAAAC","CAACC","CAAAA","CAACA"]
var checks=0
var failures:Array=[]
var game:Control
var captures:Dictionary={}
var visible_pixels:Dictionary={}
func _initialize()->void:
 Input.use_accumulated_input=false
 run.call_deferred()
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures.append(note);push_error(note)
func settle()->void:
 for i in range(3):await process_frame
func click(id:String)->void:
 var target=game.find_child(id,true,false) as Button
 check(target!=null,"button "+id)
 if target==null:return
 var p=target.get_global_rect().get_center()
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=p;e.global_position=p
  root.push_input(e,true)
 await settle()
func snapshot()->Image:
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func run()->void:
 DirAccess.make_dir_recursive_absolute(OUT)
 root.size=Vector2i(1600,900)
 game=load("res://ritual.tscn").instantiate();root.add_child(game);await settle()
 var preview=OS.get_cmdline_user_args().has("--preview")
 var selected=0;var absent=0;var masked=0
 for n in range(243):
  var values:Array=[];var v=n
  for i in range(5):values.push_front(v%3);v=int(v/3)
  var code=Data.code(values)
  if preview and not KEY_CODES.has(code) and code not in ["CCBBC","CCCCA"]:continue
  game.answers=values;game.page="result";game.finished=false;game.render();game.skip_ritual();await settle()
  var m=game.ritual.renderer;m.animated=false;m.clock=0;await settle()
  var crack=m.body.get_node_or_null("TornTempleWrap") as TextureRect
  check((crack!=null)==(values[0]==2),code+" exact brain-option trigger")
  check(m.body_art.get_meta("material_asset").contains("assets/refined/"),code+" high resolution body retained")
  check(m.body_art.material.get_shader_parameter("organ_stain")== (values[1]==2),code+" organ decay retained")
  check(m.body_art.material.get_shader_parameter("head_decay")== (values[0]==1),code+" head decay retained")
  check(m.body_art.material.get_shader_parameter("wet")==values[2],code+" wet shader retained")
  if crack:
   selected+=1
   var material="papyrus" if values[3]==2 else "linen"
   check(crack.texture.resource_path.ends_with("head-side-crack-"+material+"-b.png"),code+" matching crack material")
   check(is_equal_approx(crack.size.aspect(),crack.texture.get_size().aspect()),code+" crack uniform scaling")
   check(Rect2(Vector2.ZERO,m.body.size).encloses(crack.get_rect()),code+" crack remains attached to head frame")
   check(crack.mouse_filter==Control.MOUSE_FILTER_IGNORE,code+" crack cannot block hotspots")
   var mask=m.body.get_node_or_null("GoldMask") as TextureRect
   if mask:
    masked+=1
    check(crack.get_index()<mask.get_index(),code+" entire mask draws over fracture")
    check(mask.texture.region==Rect2(1206,50,286,264),code+" unchanged complete mask artwork")
   var shown=await snapshot()
   crack.hide();await settle();var hidden=await snapshot()
   var region=Rect2i(crack.get_global_rect()).intersection(Rect2i(Vector2i.ZERO,root.size))
   var different=0
   for y in range(region.position.y,region.end.y):
    for x in range(region.position.x,region.end.x):
     var a=shown.get_pixel(x,y);var b=hidden.get_pixel(x,y)
     if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>.08:different+=1
   visible_pixels[code]=different
   check(different>=75,code+" fracture visible in actual rendered pixels: "+str(different))
   crack.show();await settle()
  else:absent+=1
  if KEY_CODES.has(code) or code in ["CCBBC","CCCCA"]:
   var shot=await snapshot();shot.save_png(OUT+code+".png")
   var crop=Rect2i(m.body.global_position+Vector2(20,-12),Vector2(180,180))
   captures[code]={"texture":ImageTexture.create_from_image(shot),"region":crop}
 if not preview:
  check(selected==81,"81 open-skull combinations")
  check(absent==162,"162 combinations have no crack")
  check(masked==54,"54 open-skull combinations retain complete gold mask")
  await click("ResultHome");check(game.page=="home","result returns home")
  await click("StartGame");check(game.page=="instructions","home starts instructions")
  await click("AcceptMission");check(game.page=="quiz","instructions start quiz")
  for q in range(5):
   await click("Option%d"%(2 if q==0 else 0));await click("NextButton")
  check(game.page=="result" and game.ritual.running,"five questions start coffin reveal")
  await create_timer(4.9).timeout
  check(game.finished and game.hotspots.visible,"natural coffin reveal completes")
  await click("Hotspot0");check(game.dialog_question==0,"brain explanation opens")
  await click("ReturnMummy");check(game.dialog_question==-1,"explanation returns")
  await click("PlayAgain");check(game.page=="instructions" and game.answers==[-1,-1,-1,-1,-1],"replay resets answers")
 game.hide()
 await contact_sheet()
 var report={"checks":checks,"failures":failures,"preview_only":preview,"open_skull":selected,"no_crack":absent,"masked_open_skull":masked,"visible_pixels":visible_pixels,"physical_mobile_tested":false}
 var f=FileAccess.open(OUT+("preview" if preview else "head-crack-report")+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("HEAD SIDE CRACK ",checks," checks; ",failures.size()," failures; ",selected," selected / ",absent," unchanged")
 quit(0 if failures.is_empty() else 1)
func contact_sheet()->void:
 var board=Control.new();root.add_child(board)
 var background=ColorRect.new();background.color=Color("122b2b");background.size=Vector2(1600,900);board.add_child(background)
 var font=load("res://assets/chinese.ttf")
 var title=Label.new();title.text="法魯王｜B：頭側凹裂・遊戲實際畫面";title.position=Vector2(42,24);title.add_theme_font_override("font",font);title.add_theme_font_size_override("font_size",34);board.add_child(title)
 var labels=["亞麻布","紙草","亞麻布＋完整金面具","紙草＋完整金面具"]
 for i in range(4):
  var x=40+(i%2)*780;var y=94+int(i/2)*390
  var art=TextureRect.new();var atlas=AtlasTexture.new();atlas.atlas=captures[KEY_CODES[i]].texture;atlas.region=captures[KEY_CODES[i]].region
  art.texture=atlas;art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.size=Vector2(350,350);art.position=Vector2(x,y);board.add_child(art)
  var label=Label.new();label.text=labels[i]+"\n\n頭側裂縫與乾燥骨邊\n無血腥・非頭頂裂口";label.position=Vector2(x+375,y+90);label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",25);board.add_child(label)
 if FileAccess.file_exists(OUT+"head-crack-report.json") and FileAccess.file_exists("res://review/after-report.json"):
  var head_report=JSON.parse_string(FileAccess.get_file_as_string(OUT+"head-crack-report.json"))
  var matrix_report=JSON.parse_string(FileAccess.get_file_as_string("res://review/after-report.json"))
  if head_report.failures.is_empty() and matrix_report.failures.is_empty() and head_report.open_skull==81 and head_report.no_crack==162 and matrix_report.modal_mouse_openings==1215:
   var footer=Label.new();footer.position=Vector2(42,846);footer.add_theme_font_override("font",font);footer.add_theme_font_size_override("font_size",16)
   footer.text="測試通過：243 組合（81 組裂口／162 組無裂口）・54 組完整面具・1,215 次熱點開啟・15 張解說圖映射。\nGodot 實際遊戲畫面；實體手機與 Web 匯出尚未測試。"
   board.add_child(footer)
 await settle();var shot=await snapshot();shot.save_png(OUT+"head-side-crack-B-contact-sheet.png")
