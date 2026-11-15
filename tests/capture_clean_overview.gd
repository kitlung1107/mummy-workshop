extends SceneTree
const Mummy=preload("res://scripts/mummy_renderer.gd")
const Data=preload("res://scripts/content.gd")
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(640,780)
 var back=ColorRect.new();back.color=Color("263e3d");back.size=Vector2(640,780);root.add_child(back)
 DirAccess.make_dir_recursive_absolute("res://review/clean")
 for n in range(243):
  var a:Array=[];var v=n
  for i in range(5):a.push_front(v%3);v=int(v/3)
  var m=Mummy.new();root.add_child(m);m.position=Vector2(30,20);m.configure(a);m.animated=false;m.clock=0
  for i in range(3):await process_frame
  await RenderingServer.frame_post_draw
  assert(m.vapors.is_empty())
  assert(not m.body.has_node("SideSeepage"))
  assert(root.get_texture().get_image().save_png("res://review/clean/"+Data.code(a)+".png")==OK)
  root.remove_child(m);m.queue_free()
 print("CLEAN_OVERVIEW 243/243; no external vapor nodes")
 quit()
