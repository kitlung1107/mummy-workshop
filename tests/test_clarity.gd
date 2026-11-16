extends SceneTree
const Data=preload("res://scripts/content.gd")
const Results=preload("res://scripts/result_pages.gd")
var game:Control
var checks=0
var failures:Array=[]
var phase="before" if OS.get_cmdline_user_args().has("--before") else ("draft" if OS.get_cmdline_user_args().has("--draft") else "after")
var refresh=OS.get_cmdline_user_args().has("--refresh-captures")
var full_matrix=phase=="after" and not refresh
var samples=["AAAAA","AAAAC","AABAC","AACAC","AAABC","AABBC","AACBC","AAACC","AABCC","AACCC","BCCBA","CCCCC","AAAAB"]
func _initialize()->void:
 Input.use_accumulated_input=false
 run.call_deferred()
func check(ok:bool,why:String)->void:
 checks+=1
 if not ok:failures.append(why);push_error(why)
func settle()->void:
 for i in range(3):await process_frame
func shot(name:String)->void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://review/"+phase+"/"+name+".png")
func click(c:Control)->void:
 if not is_instance_valid(c):
  check(false,"missing click target")
  return
 var p=c.get_global_rect().get_center()
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=p;e.global_position=p
  root.push_input(e,true)
 # Keep synthetic press/release atomic against native desktop input.
 await settle()
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/"+phase)
 root.size=Vector2i(1600,900)
 game=load("res://ritual.tscn").instantiate();root.add_child(game);await settle()
 await shot("home")
 game.page="instructions";game.render();await settle();await shot("instructions")
 for q in range(5):
  game.page="quiz";game.question=q;game.render();await settle();await shot("question-%d"%q)
 var material_sizes={};var mapping={};var frame_times=[]
 for n in range(243):
  var a:Array=[];var v=n
  for i in range(5):a.push_front(v%3);v=int(v/3)
  var code=Data.code(a)
  if not full_matrix and not samples.has(code):continue
  var start=Time.get_ticks_usec()
  game.answers=a;game.page="result";game.render();game.skip_ritual();await settle()
  var m=game.find_child("CompositeMummy",true,false);m.animated=false;m.clock=0
  await settle()
  frame_times.append((Time.get_ticks_usec()-start)/1000.0)
  var asset=m.body_art.get_meta("material_asset")
  material_sizes[asset]={"source":str(m.body_art.texture.get_size()),"display":str(m.body_art.size),"position":str(m.body_art.position)}
  check(m.vapors.is_empty() and not m.body.has_node("SideSeepage"),code+" no vapor or outward stream")
  check(m.body.has_node("GoldMask")==m.rules.mask,code+" mask")
  check(m.body.has_node("TornTempleWrap")==m.rules.head_notch,code+" torn wrap")
  check(m.body_art.material.get_shader_parameter("wet")==a[2],code+" wet")
  check(m.body_art.material.get_shader_parameter("organ_stain")==m.rules.organ_stain,code+" organ stain")
  check(m.body_art.material.get_shader_parameter("head_decay")==m.rules.head_odor,code+" head decay")
  check(m.anchors.size()==5,code+" anchors")
  check(m.body.position==Vector2(174 if m.rules.in_coffin else 102,37),code+" body alignment")
  if samples.has(code):await shot(code)
  if full_matrix:
   var natural=m.body_art.texture.get_size()
   var scale_xy=m.body_art.size/natural
   check(absf(scale_xy.x-scale_xy.y)<.001,code+" uniform body scale")
   check(m.body_art.size.y<=660.01 and m.body_art.position.y>=0,code+" body frame")
   for q in range(5):
    await click(game.find_child("Hotspot%d"%q,true,false))
    check(game.dialog_question==q,code+" click hotspot %d"%q)
    var art=game.find_child("ExplanationArtwork",true,false)
    check(art!=null and art.get_meta("source_file")==Results.FILES[q*3+a[q]],code+" mapping %d"%q)
    if art:
     mapping[art.get_meta("source_file")]=true
     if n in [0,121,242]:await shot("explanation-%02d"%(q*3+a[q]+1))
    await click(game.find_child("CloseDetail",true,false))
    check(game.dialog_question==-1,code+" return %d"%q)
    if game.dialog_question!=-1:game.close_detail();await settle()
  if n%27==0:print("CLARITY ",phase," ",n+1,"/243")
 var layouts=[]
 for s in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(844,390),Vector2i(390,844)]:
  root.size=s;await settle();game.page="result";game.answers=[0,0,1,0,0];game.render();game.skip_ritual();await settle()
  var m=game.find_child("CompositeMummy",true,false)
  layouts.append({"viewport":str(s),"body_pixels":str(m.body_art.get_global_rect().size),"texture_memory":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
  await shot("viewport-%dx%d"%[s.x,s.y])
 var report={"phase":phase,"checks":checks,"failures":failures,"combinations":243 if full_matrix else samples.size(),"modal_mouse_openings":1215 if full_matrix else 0,"explanations":mapping.size(),"material_sizes":material_sizes,"layouts":layouts,"render_settle_ms":frame_times,"physical_mobile_tested":false}
 var f=FileAccess.open("res://review/"+phase+("-visual" if refresh else "")+"-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("CLARITY COMPLETE ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
