extends SceneTree
var checks=0
var failures=[]
var app:Control
var game:Control
func _initialize():run.call_deferred()
func settle():
 for i in range(5):await process_frame
func check(ok,note):
 checks+=1
 if not ok:failures.append(note);push_error(note)
func click(node:Control):
 var point=node.get_global_rect().get_center()
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;e.global_position=point;root.push_input(e,true)
 await settle()
func shot(name:String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://review/option-redraw/"+name+".png")
func contained(node:Control,note:String):
 var r=node.get_global_rect()
 check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(r),note+" contained")
 check(r.position.y>=app.game.position.y-1,note+" below toolbar")
func no_circle_marker(node:Node)->bool:
 if node is Label and (node.text=="○" or node.text=="●"):return false
 for child in node.get_children():
  if not no_circle_marker(child):return false
 return true
func run():
 DirAccess.make_dir_recursive_absolute("res://review/option-redraw")
 app=load("res://game_shell.tscn").instantiate();root.add_child(app);await settle();game=app.game
 for sz in [Vector2i(844,390),Vector2i(1024,768),Vector2i(1366,900),Vector2i(1920,1080)]:
  root.size=sz;await settle()
  game.new_attempt(false);game.render();await settle();await shot(str(sz.x)+"-home")
  await click(game.find_child("StartGame",true,false));check(game.page=="instructions","start mission "+str(sz))
  for id in ["AcceptMission","BackHome"]:contained(game.find_child(id,true,false),id)
  await shot(str(sz.x)+"-mission");await create_timer(.52).timeout
  if sz.x==844:
   var artwork=game.find_child("RedrawnMissionArtwork",true,false)
   check(artwork!=null and artwork.texture.get_size()==Vector2(1954,805),"new HD mission painting")
   check(artwork.stretch_mode==TextureRect.STRETCH_SCALE,"whole painting displayed without cropping")
  await click(game.find_child("AcceptMission",true,false));check(game.page=="quiz","accept mission")
  for q in range(5):
   for value in range(3):
    var option=game.find_child("Option%d"%value,true,false)
    contained(option,"option "+str(q)+str(value))
    await click(option);check(game.answers[q]==value,"option dispatch")
    var current=game.find_child("Option%d"%value,true,false)
    check(no_circle_marker(current),"caption has no circle marker")
    if sz.x==844:
     var ring=current.find_child("SelectedYellowBorder",true,false)
     check(ring!=null and ring.get_theme_stylebox("panel").border_color==Color("ffd36a"),"selected yellow border")
     var heading=game.find_child("QuestionHeading",true,false)
     var prompt=game.find_child("QuestionPrompt",true,false)
     check(heading.position.x>=60 and heading.get_rect().end.x<prompt.position.x,"step clears ornament and prompt")
     var art=current.find_child("OptionArtwork",true,false)
     var label=current.find_child("OptionText",true,false)
     check(label.get_line_count()==label.get_visible_line_count(),"all caption lines visible")
     check(current.get_global_rect().encloses(label.get_global_rect()),"caption inside full card")
     var full=art if q==0 else current.find_child("CompleteCardBackground",true,false)
     check(not full.texture is AtlasTexture,"whole card is not an atlas crop")
     check(full.stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED,"whole card has no cover crop")
     check(current.get_global_rect().encloses(full.get_global_rect()),"all frame edges inside button")
     check(full.texture.get_width()>=1300 and full.texture.get_height()>=1100,"high resolution source")
     if q==0:
      var expected=["brain-hook-v1.png","brain-oil-v1.png","brain-mallet-v1.png"]
      check(art.texture.resource_path.ends_with(expected[value]),"redrawn subject follows shuffled answer identity")
   contained(game.find_child("NextButton",true,false),"next")
   if q==0 or sz.x==844:await shot(str(sz.x)+"-q"+str(q+1))
   await click(game.find_child("NextButton",true,false))
  check(game.page=="result","five question flow")
  game.skip_ritual();await settle()
  for value in range(3):
   game.answers=[value,value,value,value,value];game.finished=true;game.render();await settle()
   if value==0:await shot(str(sz.x)+"-result")
   var wires=[]
   for child in game.hotspots.get_children():
    if child.has_meta("result_wire"):wires.append(child)
   check(wires.size()==5,"five wires")
   check(absf(game.subject.position.x+290*game.subject.scale.x-game.canvas.size.x/2)<1,"mummy centered")
   for q in range(5):
    var hotspot=game.find_child("Hotspot%d"%q,true,false)
    contained(hotspot,"hotspot")
    check(hotspot.get_global_rect().size.y>=44,"hotspot touch size")
    var expected=game.subject.position+game.subject.anchors[q]*game.subject.scale
    check(wires[q].visible and wires[q].end.distance_to(expected)<.01,"wire "+str(q)+" correct anchor")
    await click(hotspot);check(game.dialog_question==q,"open detail through pointer")
    var frame=game.find_child("DetailPanel",true,false)
    var art=game.find_child("ExplanationArtwork",true,false)
    var close=game.find_child("CloseDetail",true,false)
    check(art.get_meta("option_id")==value and art.get_meta("question_id")==q,"correct explanation")
    check(not frame.get_node("DetailBackdrop").visible and not frame.get_node("ReadableExplanation").visible,"no duplicate blue panel")
    check(frame.get_global_rect().get_center().distance_to(game.get_global_rect().get_center())<1,"modal centered")
    check(close.text.is_empty() and close.get_theme_stylebox("normal") is StyleBoxEmpty,"one painted cross, no black block")
    contained(close,"close")
    check(close.get_global_rect().size.x>=43.9 and close.get_global_rect().size.y>=43.9,"44px close target")
    if sz.x==844 or q==0:await shot(str(sz.x)+"-detail-"+str(q*3+value+1))
    if q==0:
     var answers=game.answers.duplicate()
     root.size=Vector2i(sz.y,sz.x);await settle()
     check(app.orientation.visible,"portrait prompt")
     check(game.answers==answers and game.dialog_question==q,"rotation preserves progress/modal")
     if value==0:await shot(str(sz.x)+"-portrait")
     root.size=sz;await settle()
    await click(game.find_child("CloseDetail",true,false));check(game.dialog_question==-1,"close detail through pointer")
  await click(game.find_child("PlayAgain",true,false));check(game.page=="instructions","replay")
  await click(game.find_child("BackHome",true,false));check(game.page=="home","back home")
 var f=FileAccess.open("res://review/option-redraw/report.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"checks":checks,"failures":failures,"physical_devices":false,"sizes":[[844,390],[1024,768],[1366,900],[1920,1080]],"explanation_variants":15}));f.close()
 print("REVISION ",checks," checks; failures: ",failures)
 quit(0 if failures.is_empty() else 1)
