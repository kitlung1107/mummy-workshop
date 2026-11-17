extends SceneTree
var checks=0
var failures:Array=[]
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(1600,900) # These assertions describe the desktop artwork layout.
 var scene=load("res://ritual.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.answers=[0,0,0,0,0];scene.page="result";scene.render()
 check(not scene.canvas.has_node("ReplayRitual") and not scene.canvas.has_node("SkipRitual"),"formal scene has no animation controls")
 check(not scene.result_actions.visible,"result navigation hidden during ceremony")
 scene.ritual.set_process(false)
 for n in range(243):
  var code=n;var choices:Array=[]
  for i in range(5):choices.push_front(code%3);code=int(code/3)
  scene.answers=choices;scene.finished=false;scene.render()
  scene.ritual.set_process(false)
  var subject=scene.ritual.renderer
  check(subject.answers==choices,"answer identity "+str(n))
  check(subject.size==Vector2(580,740),"renderer canvas "+str(n))
  check(subject.anchors.size()==5,"anchors "+str(n))
  check(subject.body.position==(Vector2(102,37) if choices[4]==1 else Vector2(174,37)),"body alignment "+str(n))
  scene.skip_ritual();scene.skip_ritual()
  check(scene.finished and not scene.ritual.running and scene.hotspots.visible,"skip finish "+str(n))
  check(not scene.ritual.lid.visible and subject.modulate==Color.WHITE,"clear layers "+str(n))
  await process_frame
 scene.review_mode=true
 scene.answers=[0,0,0,0,0];scene.finished=false;scene.render()
 var notices=[0]
 scene.ritual.revealed.connect(func():notices[0]+=1)
 for i in range(100):
  scene.canvas.get_node("ReplayRitual").pressed.emit()
  scene.canvas.get_node("ReplayRitual").pressed.emit()
  scene.canvas.get_node("SkipRitual").pressed.emit()
  scene.canvas.get_node("SkipRitual").pressed.emit()
 check(notices[0]==100,"exactly one signal per replay with repeated clicks")
 check(scene.completion_records.size()==0,"preview controls do not record completion")
 scene.review_mode=false
 for option in range(3):
  scene.answers=[option,option,option,option,option];scene.finished=true;scene.render()
  for i in range(5):
   scene.canvas.get_node("FiveHotspots/Hotspot%d"%i).pressed.emit()
   scene.canvas.get_node("FiveHotspots/Hotspot%d"%i).pressed.emit()
   check(scene.dialog_question==i,"open detail once")
   check(scene.dialog_layer.get_node("DetailPanel/ExplanationArtwork").get_meta("option_id")==option,"correct explanation art")
   scene.close_detail();scene.close_detail()
   check(scene.dialog_question==-1,"close detail idempotent")
   await process_frame
 scene.finished=false;scene.render();scene.replay_ritual()
 await create_timer(4.9).timeout
 check(scene.finished and not scene.ritual.running,"natural 4.6 second completion")
 scene.new_attempt();scene.page="quiz";scene.answers=[2,1,0,1,2];scene.question=4
 scene.next_question();scene.next_question();scene.submit()
 check(scene.completion_records.size()==1,"five-question submit records only once")
 check(scene.completion_records[0].score==20,"original scoring preserved")
 check(scene.ritual.renderer.answers==[2,1,0,1,2],"quiz choices survive reveal")
 check(scene.ritual.running and not scene.finished,"new attempt plays ceremony")
 check(not scene.canvas.has_node("PreviewTools"),"student screen excludes review picker")
 scene.skip_ritual()
 for i in range(5):
  var tag=scene.canvas.get_node("FiveHotspots/Hotspot%d"%i)
  check(tag.text==scene.Data.LABELS[i],"plain label without trailing symbol")
  check(tag.get_theme_font_size("font_size")==32,"larger label type")
  check(tag.size.x>=220 and tag.size.y>=74,"larger label target")
 check(scene.result_actions.visible,"result navigation visible after reveal")
 scene.canvas.get_node("ResultActions/ResultHome").pressed.emit()
 check(scene.page=="home","home button returns to home")
 check(scene.completion_records.size()==1,"home does not add completion records")
 scene.answers=[0,0,0,0,0];scene.page="result";scene.finished=true;scene.render()
 scene.canvas.get_node("ResultActions/PlayAgain").pressed.emit()
 check(scene.page=="instructions" and scene.answers==[-1,-1,-1,-1,-1],"play again starts a fresh attempt")
 check(scene.completion_records.size()==1,"play again does not add completion records")
 scene.page="result"
 # Capture actual GPU-rendered frames when not headless.
 if DisplayServer.get_name()!="headless":
  DirAccess.make_dir_recursive_absolute("res://review/ritual")
  scene.answers=[0,0,0,0,0];scene.finished=false;scene.render();scene.ritual.set_process(false)
  for shot in [["01-sealed",0.1],["02-opening",2.2],["03-revealed",4.6]]:
   scene.ritual.elapsed=shot[1];scene.ritual._pose()
   if shot[1]>=4.6:scene.ritual._finish()
   await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://review/ritual/"+shot[0]+".png")
  scene.answers=[2,2,2,2,1];scene.finished=true;scene.render()
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://review/ritual/04-beside-coffin.png")
  scene.open_detail(2)
  await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://review/ritual/05-explanation.png")
 var report={"checks":checks,"failures":failures,"engine":Engine.get_version_info().string,"all_combinations":243,"repeated_click_cycles":100,"explanations":15}
 FileAccess.open("res://review/ritual-test-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
