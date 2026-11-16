extends SceneTree
const OUT="res://review/head-crack-b/quality/"
var checks=0
var failures:Array=[]
func _initialize()->void:run.call_deferred()
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures.append(note);push_error(note)
func settle()->void:
 for i in range(4):await process_frame
func run()->void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var game=load("res://ritual.tscn").instantiate();root.add_child(game);await settle()
 var sources={}
 for material in ["linen","papyrus"]:
  var path="res://assets/refined/head-side-crack-"+material+"-b.png"
  var original=Image.load_from_file(ProjectSettings.globalize_path(path))
  var imported:Texture2D=load(path)
  sources[material]={"original":str(original.get_size()),"imported":str(imported.get_size())}
  check(original.get_size()==Vector2i(1122,1402),material+" retains generated original pixels")
  check(imported.get_height()==256,material+" bounded runtime texture")
  check(imported.get_image().has_mipmaps(),material+" mipmaps available for minification")
 var cases=[[2,0,0,0,2],[2,0,0,2,2],[2,0,0,0,0],[2,0,0,2,0],[2,2,1,1,2],[2,2,2,2,0]]
 var samples=[]
 for viewport_size in [Vector2i(1600,900),Vector2i(1920,1080),Vector2i(3840,2160),Vector2i(390,844)]:
  root.size=viewport_size;await create_timer(.25).timeout
  for values in cases:
   game.answers=values;game.page="result";game.finished=false;game.render();game.skip_ritual();await settle()
   var mummy=game.ritual.renderer;mummy.animated=false;mummy.clock=0;await settle()
   var crack=mummy.body.get_node("TornTempleWrap") as TextureRect
   var scale=crack.get_global_transform_with_canvas().get_scale().abs()
   var display=crack.size*scale
   var density=Vector2(crack.texture.get_size())/display
   var body_display=mummy.body_art.size*mummy.body_art.get_global_transform_with_canvas().get_scale().abs()
   var body_density=Vector2(mummy.body_art.texture.get_size())/body_display
   check(density.x>=1 and density.y>=1,"no crack upscale at "+str(viewport_size))
   check(density.x>=body_density.x and density.y>=body_density.y,"crack sampling at least matches torso")
   check(is_equal_approx(display.aspect(),crack.texture.get_size().aspect()),"no display distortion")
   var code=game.Data.code(values)
   samples.append({"code":code,"requested_viewport":str(viewport_size),"actual_viewport":str(root.size),"display_pixels":str(display),"texture_pixels_per_screen_pixel":str(density),"body_display_pixels":str(body_display),"body_density":str(body_density)})
   await RenderingServer.frame_post_draw
   var screenshot=root.get_texture().get_image()
   check(screenshot.get_size()==root.size,"native-size capture")
   check(screenshot.save_png(OUT+"%dx%d-%s.png"%[root.size.x,root.size.y,code])==OK,"save full-size capture")
   # A 1:1 crop aids inspection without enlarging or sharpening rendered pixels.
   var head_rect=Rect2i(mummy.body.global_position+Vector2(20,-12)*scale,Vector2(180,180)*scale)
   screenshot.get_region(head_rect).save_png(OUT+"native-head-%dx%d-%s.png"%[root.size.x,root.size.y,code])
 var report={"checks":checks,"failures":failures,"source_textures":sources,"samples":samples,"scope":"Actual framebuffer captures at desktop, Full HD, 4K and phone-size window; no resizing or sharpening of captures.","physical_mobile_tested":false}
 var f=FileAccess.open(OUT+"quality-report.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
 print("HEAD CRACK QUALITY ",checks," checks; ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)
