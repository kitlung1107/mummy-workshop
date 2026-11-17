extends SceneTree
const Data=preload("res://scripts/content.gd")
var checks=0
var failures=[]
func _initialize():run.call_deferred()
func settle():
 for i in range(2):await process_frame
func check(ok,note):
 checks+=1
 if not ok:failures.append(note);push_error(note)
func run():
 DirAccess.make_dir_recursive_absolute("res://review/feedback")
 var app=load("res://game_shell.tscn").instantiate();root.add_child(app);await settle()
 var game=app.game
 var seen={}
 for sz in [Vector2i(844,390),Vector2i(1024,768),Vector2i(1366,900)]:
  root.size=sz;await settle()
  for n in range(243):
   var values=[];var v=n
   for i in range(5):values.push_front(v%3);v=int(v/3)
   game.answers=values;game.page="result";game.finished=true;game.render();await settle()
   var subject=game.subject
   var code=Data.code(values);seen[code]=true
   var wire=game.hotspots.get_child(0)
   var head=subject.position+(subject.body.position+subject.body_point(Vector2(80,18)))*subject.scale
   var nose=subject.position+(subject.body.position+subject.body_point(Vector2(102,65)))*subject.scale
   var head_right=subject.position+(subject.body.position+subject.body_point(Vector2(130,18)))*subject.scale
   check(wire.end.distance_to(head)<.01,code+" forehead anchor "+str(sz))
   check(wire.end.y<nose.y-10,code+" above nose "+str(sz))
   check(wire.end.x<nose.x-5,code+" left of nose "+str(sz))
   var nearest=Geometry2D.get_closest_point_to_segment(nose,wire.start,wire.end)
   check(nearest.distance_to(nose)>12,code+" line clears nose "+str(sz))
   check(wire.end.x<head_right.x,code+" endpoint stays in upper head "+str(sz))
   check(subject.anchors[1]==subject.body.position+subject.body_point(Vector2(112,240)),code+" other anchor unchanged")
   var tag=game.find_child("Hotspot0",true,false)
   var p=tag.get_global_rect().get_center()
   for down in [true,false]:
    var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=p;event.global_position=p;root.push_input(event,true)
   await settle()
   check(game.dialog_question==0,code+" brain label clickable "+str(sz))
   game.close_detail()
   if n%81==0:print("BRAIN ",sz," ",n+1,"/243")
 check(seen.size()==243,"all distinct answer combinations")
 var f=FileAccess.open("res://review/feedback/all-combinations-brain.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"combinations":243,"sizes":[[844,390],[1024,768],[1366,900]],"brain_modal_pointer_checks":729,"failures":failures,"physical_devices":false}))
 print("BRAIN_ALL ",checks," checks; failures: ",failures)
 quit(0 if failures.is_empty() else 1)
