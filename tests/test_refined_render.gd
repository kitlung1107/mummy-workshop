extends SceneTree
const Data=preload("res://scripts/content.gd")
var checks=0
var failures:Array=[]
var game:Control
func _initialize()->void:run.call_deferred()
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures.append(note)
func settle()->void:
 for i in range(3):await process_frame
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/combinations")
 root.size=Vector2i(1600,900)
 game=load("res://ritual.tscn").instantiate();root.add_child(game);await settle()
 for n in range(0 if OS.get_cmdline_user_args().has("--picker-only") else 243):
  var a:Array=[];var v=n
  for i in range(5):a.push_front(v%3);v=int(v/3)
  game.answers=a;game.page="result";game.render();game.skip_ritual();await settle()
  var m=game.find_child("CompositeMummy",true,false);m.animated=false;m.clock=0
  check(m.effects.get_parent()==m.body,"atmosphere attached "+Data.code(a))
  check(m.body_art.size==Vector2(208,660),"body fits "+Data.code(a))
  check(m.get_node("Coffin").get_global_rect().end.y<=850,"coffin not clipped "+Data.code(a))
  await RenderingServer.frame_post_draw
  var image=root.get_texture().get_image()
  check(image.get_region(Rect2i(510,110,580,740)).save_png("res://review/combinations/"+Data.code(a)+".png")==OK,"render "+Data.code(a))
  if n in [0,1,2,40,80,121,161,200,242]:image.save_png("res://review/result-"+Data.code(a)+".png")
 game.answers=[0,0,0,0,0];game.review_mode=true;game.picker_open=true;game.render();await settle()
 for i in range(5):
  for repeat in range(2):
   var picker=game.find_child("PreviewChoice%d"%i,true,false)
   var point=picker.get_global_rect().get_center()
   for down in [true,false]:
    var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;e.global_position=point;root.push_input(e,true);await process_frame
   await settle()
  check(game.answers[i]==2,"review selector actual mouse "+str(i))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://review/combination-picker.png")
 var report={"checks":checks,"failures":failures,"all_final_mummy_captures":243,"review_selector_mouse_tests":5}
 var file=FileAccess.open("res://review/final-render-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
