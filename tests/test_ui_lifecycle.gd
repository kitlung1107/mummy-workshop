extends SceneTree
const Results=preload("res://scripts/result_pages.gd")
var game:Control
var checks=0
var failures:Array=[]
var captures=false
var resize_count=0
func _initialize()->void:run.call_deferred()
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures.append(note);push_error(note)
func settle()->void:
 for i in range(3):await process_frame
func click_at(point:Vector2)->void:
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
  event.position=point;event.global_position=point;event.pressed=down
  root.push_input(event,true)
func click(id:String)->void:
 var node=game.find_child(id,true,false) as Control
 check(node!=null,"click target "+id)
 if node:click_at(node.get_global_rect().get_center())
func key(code:Key)->void:
 for down in [true,false]:
  var event=InputEventKey.new();event.keycode=code;event.pressed=down
  root.push_input(event,true)
func shot(id:String)->void:
 if not captures:return
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://review/ui-lifecycle/"+id+".png")==OK,"capture "+id)
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/ui-lifecycle")
 captures=DisplayServer.get_name()!="headless"
 root.size=Vector2i(1600,900)
 var app=load("res://game_shell.tscn").instantiate();root.add_child(app);await settle()
 game=app.game
 var sound=root.get_node("GameAudio")
 sound.set_enabled(true)
 check(game.position.y>=54,"actual audio shell reserves toolbar above game")
 # Same screen point: the second click is the accidental overlapping mission click.
 var start=game.find_child("StartGame",true,false).get_global_rect().get_center()
 click_at(start)
 var entered=Time.get_ticks_msec()
 check(game.page=="instructions","first click enters instructions")
 var entry_cues=sound.stats.effect_starts
 await create_timer(.110).timeout
 click_at(start)
 check(game.page=="instructions","110 ms double click cannot skip instructions")
 click("AcceptMission")
 check(game.page=="instructions","direct mission click also blocked inside 500 ms")
 check(sound.stats.effect_starts==entry_cues,"blocked mission produces no audio cue")
 var deadline=game.mission_ready_at
 root.size=Vector2i(1366,768);await settle()
 check(game.mission_ready_at==deadline,"resize does not reset mission deadline")
 # SceneTree timers advance by frame delta; the production gate uses wall time.
 while Time.get_ticks_msec()<entered+510:await process_frame
 click("AcceptMission");await settle()
 check(game.page=="quiz","mission mouse works after 500 ms")
 check(sound.stats.last_effect=="mission","accepted mission retains audio cue")
 # Portrait blocks interaction; landscape keyboard shares the mission gate.
 root.size=Vector2i(390,844);game.new_attempt();game.render();await settle()
 game.find_child("AcceptMission",true,false).grab_focus();key(KEY_ENTER)
 check(game.page=="instructions","compact keyboard is blocked before deadline")
 while Time.get_ticks_msec()<game.mission_ready_at+10:await process_frame
 key(KEY_ENTER);await settle()
 check(game.page=="instructions" and app.orientation.visible,"portrait remains blocked after deadline")
 root.size=Vector2i(844,390);await settle()
 game.find_child("AcceptMission",true,false).grab_focus();key(KEY_ENTER);await settle()
 check(game.page=="quiz" and not app.orientation.visible,"landscape keyboard accepts after rotation and deadline")
 root.size=Vector2i(1600,900);await settle()
 for i in range(61):
  game.find_child("Option%d"%(i%3),true,false).pressed.emit()
 game.find_child("Option2",true,false).pressed.emit()
 await settle()
 check(game.answers[0]==2,"same-frame reselection keeps last answer")
 check(root.gui_get_focus_owner()==game.find_child("Option2",true,false),"latest live option owns focus")
 key(KEY_TAB);await settle()
 var focused=root.gui_get_focus_owner()
 check(focused!=null and focused.is_inside_tree(),"Tab navigation remains on live controls")
 game.find_child("Option1",true,false).grab_focus();key(KEY_ENTER);await settle()
 check(game.answers[0]==1,"keyboard Enter still chooses answer")
 game.find_child("Option0",true,false).pressed.emit();game.next_question();await settle()
 check(game.question==1 and root.gui_get_focus_owner()==null,"old question cannot steal new page focus")
 game.find_child("Option1",true,false).pressed.emit();root.size=Vector2i(1366,768);await settle()
 check(game.answers[1]==1,"resize with queued focus preserves answer")
 var reveal_starts=sound.stats.reveal_starts
 var reveal_audio_starts=sound.stats.reveal_audio_starts
 var reveal_completions=sound.stats.reveal_completions
 game.answers=[2,1,0,1,2];game.question=4;game.submit();await settle()
 var ritual=game.ritual
 var notices=[0]
 ritual.revealed.connect(func():notices[0]+=1)
 var choices=game.answers.duplicate()
 var start_time=Time.get_ticks_msec()
 var previous=ritual.elapsed
 var sizes=[Vector2i(1600,900),Vector2i(1366,768),Vector2i(1920,1080),Vector2i(768,1024),Vector2i(844,390),Vector2i(390,844)]
 while not game.finished and Time.get_ticks_msec()-start_time<6500:
  root.size=sizes[resize_count%sizes.size()];resize_count+=1
  await create_timer(.08).timeout
  check(game.ritual==ritual,"resize preserves ritual instance")
  check(ritual.elapsed>=previous,"resize never rewinds reveal")
  check(game.answers==choices,"resize preserves answers")
  check(sound.stats.reveal_starts==reveal_starts+1 and sound.stats.reveal_audio_starts==reveal_audio_starts+1,"resize preserves single audio timeline")
  check(absf(ritual.elapsed-sound.reveal_elapsed)<.1,"audio and visual reveal clocks agree")
  previous=ritual.elapsed
 check(game.finished and notices[0]==1,"continuous resize reveals exactly once")
 check(game.completion_records.size()==1,"resize records completion once")
 check(sound.stats.reveal_completions==reveal_completions+1,"audio completion emitted once")
 for viewport_size in sizes:
  root.size=viewport_size;await settle()
 check(notices[0]==1,"post-reveal resize emits no extra completion")
 var toolbar=app.find_child("AudioToolbar",true,false)
 toolbar.custom_minimum_size.y=96;await settle()
 check((game.canvas.position+game.canvas.size*game.canvas.scale/2).distance_to(game.size/2)<1,"container-only resize updates game layout")
 check(game.ritual==ritual and notices[0]==1,"container-only resize preserves completed reveal")
 toolbar.custom_minimum_size.y=54;await settle()
 # Actual modal interactions are available in landscape; portrait rotation is
 # covered above and by test_option_redraw_review's progress/modal checks.
 var modal_sizes=[Vector2i(1600,900),Vector2i(1366,768),Vector2i(1920,1080),Vector2i(844,390)]
 for viewport_size in modal_sizes:
  root.size=viewport_size;await settle()
  for n in range(15):
   var q=int(n/3);game.answers[q]=n%3
   var hotspot=game.find_child("Hotspot%d"%q,true,false)
   hotspot.grab_focus();click("Hotspot%d"%q);await settle()
   check(game.dialog_question==q,"explanation opens %d at %s"%[n,viewport_size])
   var frame=game.dialog_layer.get_node("DetailPanel") as Control
   var art=frame.get_node("ExplanationArtwork") as Control
   check(frame.get_global_rect().get_center().distance_to(game.get_global_rect().get_center())<1,"panel centered in game area %d at %s"%[n,viewport_size])
   check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(art.get_global_rect()),"panel fits viewport")
   check(art.get_meta("option_id")==n%3 and art.get_meta("question_id")==q,"exact explanation mapping")
   check(game.find_child("ReturnMummy",true,false)==null,"no obsolete return control")
   var painted:Rect2=Results.PAINTED_RETURN_RECTS[n]
   var patch:Vector4=art.material.get_shader_parameter("removed_rect")
   var covered=Rect2(patch.x,patch.y,patch.z,patch.w)
   check(covered.encloses(painted.grow(.003)),"painted return and shadow covered with parchment")
   check(not game.find_child("ResultHint",true,false).visible,"background hint hidden")
   check(sound.ducked,"modal retains audio ducking")
   var hint=frame.get_node("CloseHint") as Control
   check(not hint.get_global_rect().intersects(art.get_global_rect()),"close hint does not overlap art")
   check(hint.visible==(game.size.y>=550),"close hint is hidden in compact landscape")
   check(not hint.visible or Rect2(Vector2.ZERO,Vector2(root.size)).encloses(hint.get_global_rect()),"visible close hint stays on screen")
   check(game.detail_textures.size()<=game.DETAIL_CACHE_LIMIT,"texture cache bounded")
   if viewport_size==sizes[0]:await shot("dialog-%02d"%(n+1))
   elif n==14:await shot("dialog-15-%dx%d"%[viewport_size.x,viewport_size.y])
   match n%4:
    0:click("CloseDetail")
    1:key(KEY_ESCAPE)
    2:click_at(game.global_position+Vector2(4,4))
    3:
     key(KEY_TAB);await settle()
     check(root.gui_get_focus_owner()==frame.get_node("CloseDetail"),"modal Tab stays on cross")
     key(KEY_ENTER)
   await settle()
   check(game.dialog_question==-1,"cross/Esc/outside/keyboard closes")
   check(not sound.ducked,"all closing methods restore music level")
   check(root.gui_get_focus_owner()==hotspot,"closing restores live hotspot focus")
   check(game.find_child("ResultHint",true,false).visible,"background hint restored")
 # Reopen after queue_free has completed; texture identity must still be retained.
 game.open_detail(0);await settle()
 var cached_id=game.find_child("ExplanationArtwork",true,false).texture.get_instance_id()
 var layer=game.dialog_layer
 root.size=Vector2i(1600,900);await settle()
 check(game.dialog_layer==layer,"resize keeps modal instance and focus")
 game.close_detail();await settle();game.open_detail(0);await settle()
 check(game.find_child("ExplanationArtwork",true,false).texture.get_instance_id()==cached_id,"reopening reuses texture instance")
 game.close_detail();await settle()
 game.detail_textures.clear()
 var first_path="res://assets/explanations/"+Results.FILES[0]
 for n in range(5):game.detail_texture("res://assets/explanations/"+Results.FILES[n])
 game.detail_texture(first_path)
 game.detail_texture("res://assets/explanations/"+Results.FILES[5])
 check(game.detail_textures.size()==5 and game.detail_textures.has(first_path),"LRU retains recently reopened texture")
 check(not game.detail_textures.has("res://assets/explanations/"+Results.FILES[1]),"LRU evicts oldest unused texture")
 game.go_home();await settle()
 check(game.detail_textures.is_empty(),"home clears result cache")
 game.answers=[0,0,0,0,0];game.page="result";game.finished=true;game.render()
 game.open_detail(0);game.close_detail();game.play_again();await settle()
 check(game.detail_textures.is_empty(),"new attempt clears result cache")
 game.page="quiz";game.render();game.find_child("Option2",true,false).pressed.emit()
 game.get_parent().remove_child(game);game.queue_free();await settle()
 app.queue_free();await settle()
 var report={"checks":checks,"failures":failures,"resize_events":resize_count,"explanations":15,"viewport_sizes":modal_sizes.map(func(s):return str(s)),"rotation_sizes":sizes.map(func(s):return str(s)),"modal_cases":15*modal_sizes.size(),"cache_limit":5,"gpu_captures":captures,"audio_shell":true,"audio_stats":sound.stats,"engine":Engine.get_version_info().string}
 FileAccess.open("res://review/ui-lifecycle/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 # Let the audio mixer release active WAV playbacks before test shutdown.
 sound.set_enabled(false)
 for player in sound.music_players+sound.effect_players+[sound.reveal_player]:player.stop()
 await create_timer(.2).timeout
 quit(0 if failures.is_empty() else 1)
