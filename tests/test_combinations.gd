extends SceneTree
const Data=preload("res://scripts/content.gd")
const Results=preload("res://scripts/result_pages.gd")
var game:Control
var checks=0
var failures:Array=[]
var capture=not OS.get_cmdline_user_args().has("--no-captures")
var seen:Dictionary={}
func _initialize()->void:run.call_deferred()
func check(value:bool,why:String)->void:
 checks+=1
 if not value:failures.append(why);push_error(why)
func settle()->void:
 for i in range(3):await process_frame
func click(control:Control)->void:
 var point=control.get_global_rect().get_center()
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  # Dispatch both halves to this viewport without a native mouse move between them.
  root.push_input(event,true)
 await settle()
func shot(path:String,only_mummy:bool=false)->void:
 if not capture:return
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 if only_mummy:image=image.get_region(Rect2i(0,110,580,740))
 check(image.save_png("res://review/"+path+".png")==OK,"capture "+path)
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/combinations")
 DirAccess.make_dir_recursive_absolute("res://review/dialogs")
 root.size=Vector2i(1600,900)
 game=load("res://main.tscn").instantiate();root.add_child(game);await settle()
 check(game.page=="home","home starts")
 check(not game.submit(),"incomplete rejected")
 await click(game.find_child("StartGame",true,false))
 check(game.page=="instructions","home to instructions")
 await create_timer(.51).timeout
 await click(game.find_child("AcceptMission",true,false))
 check(game.page=="quiz","instructions to quiz")
 for i in range(5):
  await click(game.find_child("Option0",true,false))
  await click(game.find_child("NextButton",true,false))
 check(game.page=="result" and game.completion_records.size()==1,"five GUI answers submit exactly once")
 check(not game.submit(),"duplicate submission rejected")
 var baseline=game.completion_records.size()
 for n in range(243):
  var values:Array=[];var v=n
  for i in range(5):values.push_front(v%3);v=int(v/3)
  game.answers=values;game.page="result";game.render();await settle()
  var code=Data.code(values);seen[code]=true
  var mummy=game.find_child("CompositeMummy",true,false)
  mummy.animated=false;mummy.clock=0
  check(mummy!=null and mummy.body_art!=null,code+" complete mummy")
  var r=mummy.rules
  check(r.mask==(values[4]!=2) and r.in_coffin==(values[4]!=1),code+" mask coffin")
  check(mummy.body.has_node("GoldMask")==r.mask,code+" mask node")
  check(mummy.body.position.x==(174 if r.in_coffin else 102),code+" entire body positioned together")
  check(mummy.body_art.name==("Papyrus" if values[3]==2 else "Linen"),code+" material")
  check(r.organ_stain==(values[1]==2),code+" no decay from removing heart")
  check(r.head_odor==(values[0]==1) and r.head_notch==(values[0]==2),code+" head effect")
  check(r.hollow==(values[3]==1) and r.belly_full==(values[1]==2),code+" fill interaction")
  check(mummy.body_art.material.get_shader_parameter("wet")==values[2],code+" moisture")
  check(mummy.body_art.material.get_shader_parameter("organ_stain")==r.organ_stain,code+" stain connected")
  await shot("combinations/"+code,true)
  if n in [0,1,2,40,80,121,161,200,242]:await shot("result-"+code)
  for i in range(5):
   var hotspot=game.find_child("Hotspot%d"%i,true,false)
   # Real mouse hit tests across all 1215 possible explanation openings.
   await click(hotspot)
   check(game.dialog_question==i,code+" open modal "+str(i))
   var art=game.find_child("ExplanationArtwork",true,false)
   if art==null:
    check(false,code+" missing artwork");continue
   check(art.get_meta("option_id")==values[i] and art.get_meta("question_id")==i,code+" exact option mapping")
   check(art.get_meta("source_file")==Results.FILES[i*3+values[i]],code+" exact v2 file")
   check(hotspot.focus_mode==Control.FOCUS_NONE,code+" focus locked")
   game.open_detail((i+1)%5);check(game.dialog_question==i,code+" one modal only")
   if n in [0,121,242]:await shot("dialogs/%02d"%(i*3+values[i]+1))
   if n%3==0:await click(game.find_child("CloseDetail",true,false))
   elif n%3==1:await click(game.find_child("CloseDetail",true,false))
   else:
    var event=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true;root.push_input(event,true);await settle()
    event=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=false;root.push_input(event,true)
   check(game.dialog_question==-1,code+" close modal")
  if n%27==0:print("COMBINATIONS ",n+1,"/243")
 check(seen.size()==243,"all unique codes")
 check(game.completion_records.size()==baseline,"preview does not create learner records")
 game.open_detail(0);await settle()
 var outside=game.find_child("OutsideClose",true,false)
 var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=Vector2(40,860);Input.parse_input_event(event);await settle()
 check(game.dialog_question==-1,"outside click closes")
 game.review_controls=true;game.render();await settle()
 check(game.find_child("Choice4",true,false)!=null,"all five review selectors")
 Results.step(game,1);check(game.answers==[0,0,0,0,0],"243 wraps to first")
 Results.step(game,-1);check(game.answers==[2,2,2,2,2],"first wraps to 243")
 game.review_controls=false;game.render();await settle()
 # Desktop fitting and modal persistence on resize. Mobile/tablet out of this scope.
 for viewport_size in [Vector2i(1366,768),Vector2i(1920,1080)]:
  root.size=viewport_size;await settle();game.open_detail(4);await settle()
  check(game.find_child("ExplanationArtwork",true,false).get_global_rect().end.x<=root.size.x,"desktop popup fits")
  game.close_detail()
 var report={"checks":checks,"failures":failures,"combinations":243,"real_mouse_modal_openings":1215,"new_explanation_images":15,"renderer":"Godot OpenGL" if capture else "headless logic","captures":capture,"mobile_tablet_tested":false}
 var file=FileAccess.open("res://review/combinations-test-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
