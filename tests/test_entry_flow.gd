extends SceneTree
var game: Control
var failures: Array=[]
var checks=0
var captures=not OS.get_cmdline_user_args().has("--no-captures")
func _initialize() -> void:
 run.call_deferred()
func check(ok: bool, description: String) -> void:
 checks+=1
 if not ok: failures.append(description); push_error(description)
func settle() -> void:
 for i in range(4): await process_frame
func find_button(id: String) -> Button:
 return game.find_child(id,true,false) as Button
func click(id: String) -> void:
 var control=find_button(id)
 check(control!=null,"button exists: "+id)
 if control==null:return
 var scroller=game.find_child("EntryScroll",true,false)
 if scroller:
  scroller.ensure_control_visible(control)
  await settle()
 var point=control.get_global_rect().get_center()
 check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"click is visible: "+id)
 for down in [true,false]:
  var event=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT
  event.position=point
  event.global_position=point
  event.pressed=down
  Input.parse_input_event(event)
  await process_frame
 await settle()
func screenshot(name: String) -> void:
 if not captures:return
 await RenderingServer.frame_post_draw
 var error=root.get_texture().get_image().save_png("res://review/"+name+".png")
 check(error==OK,"saved "+name)
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://review")
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await settle()
 var sizes=[Vector2i(1100,820),Vector2i(1366,768),Vector2i(768,1024),Vector2i(390,844),Vector2i(844,390)]
 for viewport_size in sizes:
  root.size=viewport_size
  game.page="home"; game.render()
  await settle()
  var suffix="%dx%d"%[viewport_size.x,viewport_size.y]
  check(game.page=="home","starts at home "+suffix)
  check(find_button("StartGame").size.y>=44,"home touch height "+suffix)
  await screenshot("home-"+suffix)
  await click("StartGame")
  check(game.page=="instructions","home to instructions "+suffix)
  check(find_button("AcceptMission").size.y>=44,"mission touch height "+suffix)
  check(find_button("BackHome").size.y>=44,"back touch height "+suffix)
  await screenshot("instructions-"+suffix)
  await click("BackHome")
  check(game.page=="home","back to home "+suffix)
  await click("StartGame")
  await create_timer(.51).timeout
  await click("AcceptMission")
  check(game.page=="quiz" and game.question==0,"mission to question "+suffix)
  check(game.answers==[-1,-1,-1,-1,-1],"fresh answers "+suffix)
  check(not game.submit(),"incomplete submission blocked "+suffix)
  check(game.find_child("EntryArtwork",true,false)==null,"entry removed in quiz "+suffix)
  check(game.find_child("NextButton",true,false).disabled,"next disabled until selection "+suffix)
  if viewport_size==Vector2i(1100,820):await screenshot("first-question-"+suffix)
  game.choose(0)
  game.next_question()
  check(game.question==1,"quiz advances "+suffix)
  game.choose(1)
  game.question=0;game.render()
  check(game.answers[1]==1,"back preserves choice "+suffix)
  game.page="home"; game.render()
  await settle()
  await click("StartGame")
  check(game.answers==[-1,-1,-1,-1,-1],"restart resets answers "+suffix)
 root.size=Vector2i(1100,820)
 game.page="home";game.render()
 await settle()
 find_button("StartGame").grab_focus()
 for down in [true,false]:
  var key=InputEventKey.new()
  key.keycode=KEY_ENTER;key.pressed=down
  Input.parse_input_event(key)
  await process_frame
 await settle()
 check(game.page=="instructions","keyboard Enter starts game")
 await create_timer(.51).timeout
 await click("AcceptMission")
 for i in range(5):
  game.choose(0);game.next_question()
 check(game.page=="result" and game.completion_records.size()==1,"five questions reach one result")
 check(not game.submit(),"duplicate submission rejected")
 var report={"checks":checks,"failures":failures,"sizes":sizes.map(func(s):return str(s)),"input":"Godot GUI mouse events and keyboard Enter","corrected_asset_sha256":"8CB347A58B946E2ADEA9EC83BFC49830CA0110EDFD3D0E608BCCD803259E3FC8"}
 var file=FileAccess.open("res://review/entry-test-report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if failures.is_empty() else 1)
