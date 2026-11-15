extends "res://tests/test_combinations.gd"
const ArtButton=preload("res://scripts/art_button.gd")
func audit_tooltips(node:Node)->void:
 if node is Control:
  check(node.get_tooltip(Vector2.ZERO).is_empty(),"no duplicate tooltip: "+str(node.name))
 for child in node.get_children():audit_tooltips(child)
func point_click(point:Vector2)->void:
 for down in [true,false]:
  var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  Input.parse_input_event(event);await process_frame
 await settle()
func hover(control:Control)->void:
 var event=InputEventMouseMotion.new();event.position=control.get_global_rect().get_center();event.global_position=event.position
 Input.parse_input_event(event)
 await create_timer(.65).timeout
 audit_tooltips(game)
 for window in root.get_children():
  if window is Window and window!=root:check(not window.visible,"no hover popup window")
func key(code:Key)->void:
 for down in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.pressed=down;Input.parse_input_event(e);await process_frame
 await settle()
func run()->void:
 DirAccess.make_dir_recursive_absolute("res://review/fix-v3")
 root.size=Vector2i(1600,900)
 game=load("res://main.tscn").instantiate();root.add_child(game);await settle()
 var art=game.find_child("EntryArtwork",true,false).get_child(0)
 await shot("fix-v3/home")
 var edited=root.get_texture().get_image()
 var material=art.material;art.material=null;await settle();await RenderingServer.frame_post_draw
 var original=root.get_texture().get_image()
 var rect=art.get_global_rect();var patch=Rect2(Vector2(894,450),Vector2(128,71))
 var changed_inside=0;var changed_outside=0
 for y in range(900):
  for x in range(1600):
   if edited.get_pixel(x,y)!=original.get_pixel(x,y):
    var local=(Vector2(x+.5,y+.5)-rect.position)/rect.size*Vector2(1453,1083)
    if patch.grow(2).has_point(local):changed_inside+=1
    else:changed_outside+=1
 check(changed_inside>100,"generated cloth patch is visible")
 check(changed_outside==0,"home pixels unchanged outside local cloth patch")
 art.material=material
 await hover(game.find_child("StartGame",true,false))
 await click(game.find_child("StartGame",true,false));await shot("fix-v3/instructions")
 await hover(game.find_child("AcceptMission",true,false));await click(game.find_child("AcceptMission",true,false))
 for i in range(5):
  for option in range(3):
   var row=game.find_child("Option%d"%option,true,false)
   check(not row.accessibility_name.is_empty(),"question accessible name")
   await hover(row)
  if i==4:
   check(game.find_child("QuestionPrompt",true,false).text.contains("法魯王"),"question spelling")
   check(game.theme.default_font.has_char(0x9b6f),"Lu glyph available through explicit fallback")
   await shot("fix-v3/question5")
  await click(game.find_child("Option0",true,false));await click(game.find_child("NextButton",true,false))
 for choice in range(3):
  game.answers=[choice,choice,choice,choice,choice];game.render();await settle()
  for question_id in range(5):
   await hover(game.find_child("Hotspot%d"%question_id,true,false))
   await click(game.find_child("Hotspot%d"%question_id,true,false))
   var back=game.find_child("ReturnMummy",true,false)
   check(back.get_theme_stylebox("focus") is StyleBoxEmpty,"no yellow overlay")
   check(not back.accessibility_name.is_empty() and back.focus_mode==Control.FOCUS_ALL,"return keyboard accessible")
   check(not back._has_point(Vector2(1,1)),"capsule excludes transparent corner")
   await hover(back)
   await point_click(back.get_global_rect().get_center()-Vector2(0,back.get_global_rect().size.y/2+7))
   check(game.dialog_question==question_id,"text above return does not close")
   await shot("fix-v3/dialog-%02d"%(question_id*3+choice+1))
   await click(back);check(game.dialog_question==-1,"painted return click closes")
 game.open_detail(4);await settle()
 await key(KEY_TAB);check(ArtButton.keyboard_navigation,"keyboard focus indicator enabled")
 await key(KEY_ENTER);check(game.dialog_question==-1,"keyboard activation closes")
 game.open_detail(0);await settle();await key(KEY_ESCAPE);check(game.dialog_question==-1,"Escape closes")
 await click(game.find_child("ResultHome",true,false));check(game.page=="home","return home navigation")
 var report={"checks":checks,"failures":failures,"home_changed_inside":changed_inside,"home_changed_outside":changed_outside,"hovered_question_choices":15,"hovered_result_dialogs":15,"keyboard_navigation_tested":true}
 var file=FileAccess.open("res://review/fix-v3/test-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print(JSON.stringify(report));quit(0 if failures.is_empty() else 1)
