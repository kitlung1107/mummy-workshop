extends SceneTree
var failures=[]
func _initialize():run.call_deferred()
func settle():
 for i in range(6):await process_frame
func run():
 var app=load("res://game_shell.tscn").instantiate();root.add_child(app);await settle()
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
 for ratio in [1.26,2.0,3.0]:
  for logical in [Vector2i(844,390),Vector2i(390,844),Vector2i(1024,768),Vector2i(768,1024)]:
   root.size=Vector2i(Vector2(logical)*ratio);root.content_scale_size=logical;await settle()
   if app.size.distance_to(Vector2(logical))>1:failures.append("logical viewport "+str(logical)+str(ratio))
   if app.orientation.visible!=(logical.y>logical.x):failures.append("orientation "+str(logical))
   if logical.x>logical.y:
    app.game.page="quiz";app.game.render();await settle()
    var next=app.game.find_child("NextButton",true,false)
    if not Rect2(Vector2.ZERO,Vector2(logical)).encloses(next.get_global_rect()):failures.append("navigation clipped")
 var f=FileAccess.open("res://review/revision/density-report.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"ratios":[1.26,2,3],"logical_sizes":[[844,390],[390,844],[1024,768],[768,1024]],"failures":failures,"physical_devices":false}))
 print("DENSITY ",failures)
 quit(0 if failures.is_empty() else 1)
