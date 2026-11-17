extends SceneTree
func _initialize():run.call_deferred()
func settle():
 for i in range(8):await process_frame
func run():
 var app=load("res://game_shell.tscn").instantiate();root.add_child(app);root.size=Vector2i(844,390);await settle()
 var game=app.game;game.answers=[0,0,0,0,0];game.page="result";game.finished=true;game.render();await settle()
 var before={}
 for id in ["Hotspot0","Hotspot1","Hotspot2","Hotspot3","Hotspot4","PlayAgain","ResultHome"]:before[id]=game.find_child(id,true,false).get_global_rect()
 var failures=[]
 for sz in [Vector2i(1366,900),Vector2i(844,390),Vector2i(1024,768),Vector2i(844,390)]:
  root.size=sz;await settle()
  if sz.x==844:
   for id in before:
    if game.find_child(id,true,false).get_global_rect()!=before[id]:failures.append(id+" resize drift")
 var f=FileAccess.open("res://review/revision/resize-drift.json",FileAccess.WRITE);f.store_string(JSON.stringify({"failures":failures}))
 print("RESIZE_DRIFT ",failures);quit(0 if failures.is_empty() else 1)
