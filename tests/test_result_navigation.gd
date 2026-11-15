extends SceneTree
func _initialize()->void:run.call_deferred()
func settle()->void:
 for i in range(3):await process_frame
func click(button:Button)->void:
 var point=button.get_global_rect().get_center()
 for down in [true,false]:
  var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;e.global_position=point;root.push_input(e,true);await process_frame
 await settle()
func run()->void:
 var game=load("res://ritual.tscn").instantiate();root.add_child(game);await settle()
 for size in [Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size=size;await settle();game.answers=[1,2,1,2,0];game.page="result";game.finished=false;game.render();game.skip_ritual();await settle()
  assert(game.find_child("ReviewCombinations",true,false)==null)
  for i in range(5):
   var b=game.find_child("Hotspot%d"%i,true,false);assert(Rect2(Vector2.ZERO,Vector2(size)).encloses(b.get_global_rect()))
  await click(game.find_child("ResultHome",true,false));assert(game.page=="home")
  game.answers=[1,2,1,2,0];game.page="result";game.finished=false;game.render();game.skip_ritual();await settle()
  await click(game.find_child("PlayAgain",true,false));assert(game.answers==[-1,-1,-1,-1,-1]);assert(game.page=="instructions")
 print("RESULT_NAVIGATION PASS: home/replay + five labels within bounds at 1366x768,1600x900,1920x1080; student review controls absent")
 quit()
