extends SceneTree
const Data=preload("res://scripts/content.gd")
var game: Control
var failures: Array=[]
var checks=0
var destination="res://review/questions"
func _initialize() -> void:
 Input.use_accumulated_input=false
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--output-dir="):
   destination=argument.trim_prefix("--output-dir=")
 run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func settle() -> void:
 for i in range(5):await process_frame
func button(id: String) -> Button:
 return game.find_child(id,true,false) as Button
func click(id: String) -> void:
 var control=button(id)
 check(control!=null,"button exists "+id)
 if control==null:return
 for scroll_name in ["QuestionScroll","EntryScroll"]:
  var scroll=game.find_child(scroll_name,true,false) as ScrollContainer
  if scroll:scroll.ensure_control_visible(control);await settle()
 var point=control.get_global_rect().get_center()
 check(Rect2(Vector2.ZERO,Vector2(root.size)).has_point(point),"visible click "+id)
 for down in [true,false]:
  var event=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
  event.position=point;event.global_position=point
  root.push_input(event,true)
 # Keep each synthetic press/release together so native window input cannot
 # interrupt the click while another rendering test owns desktop focus.
 await settle()
func screenshot(name: String) -> void:
 RenderingServer.force_draw(false)
 check(root.get_texture().get_image().save_png(destination+"/"+name+".png")==OK,"capture "+name)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(destination)
 root.size=Vector2i(1600,900)
 game=load("res://ritual.tscn").instantiate()
 root.add_child(game);await settle()
 check(Data.OPTIONS[1][0]=="取出肝、肺、胃、腸，心臟留在體內","correct organ identity preserved")
 check(Data.OPTIONS[1][1]=="取出肝、肺、胃、腸和心臟","remove-heart distractor wording")
 check(Data.OPTIONS[3][1]=="直接包亞麻布","no-filling distractor wording")
 var sizes=[Vector2i(1600,900),Vector2i(1100,820),Vector2i(1366,768),Vector2i(1024,768),Vector2i(768,1024),Vector2i(390,844),Vector2i(844,390)]
 for viewport_size in sizes:
  root.size=viewport_size
  # Native window resize events can arrive after the first layout frames.
  # Let the pending resize finish before pressing a button that render replaces.
  await create_timer(.25).timeout
  game.page="home";game.render();await settle()
  var suffix="%dx%d"%[viewport_size.x,viewport_size.y]
  if viewport_size==sizes[0]:await screenshot("home-"+suffix)
  await click("StartGame")
  check(game.page=="instructions","home to instructions "+suffix)
  if viewport_size==sizes[0]:await screenshot("instructions-"+suffix)
  await click("AcceptMission")
  check(game.page=="quiz" and game.question==0,"instructions to quiz "+suffix)
  var values=[0,1,2,1,0]
  for q in range(5):
   check(game.question==q,"question navigation "+suffix)
   check(button("NextButton").disabled,"unanswered next disabled "+suffix)
   var order: Array=game.orders[q].duplicate()
   for display_i in range(3):
    var value: int=order[display_i]
    var option=button("Option%d"%value)
    var copy=option.find_child("OptionText",true,false) as Label
    check(copy.text==Data.OPTIONS[q][value],"stable shuffled label %s q%d id%d"%[suffix,q,value])
    check(option.get_meta("option_id")==value,"stable option identity")
    var art=option.find_child("OptionArtwork",true,false) as TextureRect
    check(art!=null and art.get_meta("option_id")==value and art.get_meta("question_id")==q,"art identity follows shuffled answer")
    check(art.texture is AtlasTexture and is_equal_approx(art.texture.region.position.x,value*art.texture.atlas.get_width()/3.0),"exact artwork atlas column")
    check(option.tooltip_text.is_empty(),"no option tooltip")
    check(game.completion_records.is_empty(),"no result or score before all five answers")
    check(option.get_global_rect().size.y>=44,"touch target "+suffix)
    check(copy.get_line_count()==copy.get_visible_line_count(),"no option text clipping %s q%d id%d"%[suffix,q,value])
   if viewport_size==sizes[0]:await screenshot("question-%02d-"%[q+1]+suffix)
   if q==3 and viewport_size!=sizes[0]:await screenshot("wrapping-"+suffix)
   await click("Option%d"%values[q])
   check(game.answers[q]==values[q],"actual click records stable id "+suffix)
   check(not button("NextButton").disabled,"selection enables next")
   if q==1:
    if viewport_size==sizes[0]:await screenshot("organs-selected-"+suffix)
    await click("PreviousButton")
    check(game.question==0 and game.answers[1]==1 and game.answers[0]==0,"back preserves selections")
    await click("Option2")
    check(game.answers[0]==2 and game.question==0,"back allows changing prior answer without advancing")
    await click("Option0")
    await click("NextButton")
    check(game.question==1 and game.orders[1]==order,"back preserves shuffled order")
   await click("NextButton")
  check(game.page=="result","five questions reach result "+suffix)
  check(game.completion_records.back().score==40,"mixed shuffled selection scores 40 "+suffix)
  check(game.completion_records.back().correct_by_question==[true,false,false,false,true],"per-question correctness preserved")
  check(Data.visual_rules(game.answers).hollow and Data.visual_rules(game.answers).beer,"original effects preserved")
  game.skip_ritual();await settle()
  if viewport_size==sizes[0]:await screenshot("result-"+suffix)
  game.open_detail(1);await settle()
  check(game.dialog_question==1,"result organ explanation opens")
  game.close_detail();await settle()
  game.completion_records.clear()
 # Exhaust every displayed permutation, using real button input for each stable identity.
 root.size=Vector2i(1100,820)
 var permutations=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
 for permutation in permutations:
  for q in range(5):
   game.new_attempt();game.page="quiz";game.question=q;game.orders[q]=permutation.duplicate();game.render();await settle()
   for value in permutation:
    await click("Option%d"%value)
    check(game.answers[q]==value,"all six permutations preserve clicked id")
    check(Data.correct(game.answers)[q]==(value==0),"all six permutations preserve correctness")
 # Keyboard selection is still operable.
 game.new_attempt();game.page="quiz";game.render();await settle()
 button("Option1").grab_focus()
 for down in [true,false]:
  var key=InputEventKey.new();key.keycode=KEY_ENTER;key.pressed=down
  Input.parse_input_event(key);await process_frame
 await settle()
 check(game.answers[0]==1,"keyboard Enter chooses stable answer")
 check(root.gui_get_focus_owner()==button("Option1"),"selection restores keyboard focus")
 var report={"checks":checks,"failures":failures,"sizes":sizes.map(func(s):return str(s)),"permutations":6,"input":"Godot GUI mouse and keyboard events","scope":"entry flow, five question layouts, navigation, stable shuffled choices, scoring, original effects and result"}
 var file=FileAccess.open(destination+"/question-integration-report.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 game.queue_free()
 await settle()
 quit(0 if failures.is_empty() else 1)
