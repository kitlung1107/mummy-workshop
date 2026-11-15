extends Control
const Data=preload("res://scripts/content.gd")
const SHEET=preload("res://assets/composite/sprites.png")
const EFFECT=preload("res://scripts/body_effects.gdshader")
var answers:Array=[]
var rules:Dictionary={}
var body:Control
var body_art:TextureRect
var clock:float=0.0
var animated=true
var effects:Control
var anchors:Array[Vector2]=[]

static func sprite(region:Rect2)->AtlasTexture:
 var atlas=AtlasTexture.new()
 atlas.atlas=SHEET
 atlas.region=region
 atlas.filter_clip=true
 return atlas

func art(parent:Control, id:String, region:Rect2, rect:Rect2)->TextureRect:
 var image=TextureRect.new()
 image.name=id
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.texture=sprite(region)
 image.position=rect.position

 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_SCALE
 image.size=rect.size
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
 image.set_deferred("size",rect.size)
 return image

func configure(selected:Array)->void:
 answers=selected.duplicate()
 rules=Data.visual_rules(answers)
 name="CompositeMummy"
 size=Vector2(580,740)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var coffin_rect=Rect2(139,4,278,718) if rules.in_coffin else Rect2(370,55,180,640)
 art(self,"Coffin",Rect2(20,24,346,978),coffin_rect)
 body=Control.new()
 body.name="WholeMummy"
 body.position=Vector2(174,37) if rules.in_coffin else Vector2(102,37)
 body.size=Vector2(208,660)
 body.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(body)
 if not rules.in_coffin:
  var support=Panel.new()
  support.position=Vector2(-10,-12)
  support.size=Vector2(228,690)
  support.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var style=StyleBoxFlat.new()
  style.bg_color=Color("78513b")
  style.border_color=Color("c89b52")
  style.set_border_width_all(5)
  style.set_corner_radius_all(45)
  support.add_theme_stylebox_override("panel",style)
  body.add_child(support)
 body_art=art(body,"Papyrus" if rules.material=="papyrus" else "Linen",Rect2(824 if rules.material=="papyrus" else 440,48,276,936),Rect2(0,0,208,660))
 var material_new=ShaderMaterial.new()
 material_new.shader=EFFECT
 material_new.set_shader_parameter("hollow",rules.hollow)
 material_new.set_shader_parameter("full_belly",rules.belly_full)
 material_new.set_shader_parameter("damaged_head",rules.head_notch)
 material_new.set_shader_parameter("organ_stain",rules.organ_stain)
 material_new.set_shader_parameter("wet",answers[2])
 material_new.set_shader_parameter("uv_origin",Vector2(824.0 if rules.material=="papyrus" else 440.0,48.0)/Vector2(1536.0,1024.0))
 material_new.set_shader_parameter("uv_extent",Vector2(276.0,936.0)/Vector2(1536.0,1024.0))
 body_art.material=material_new
 if rules.mask:
  art(body,"GoldMask",Rect2(1206,50,286,264),Rect2(32,-6,144,134))
 effects=Control.new();effects.name="VisibleEffects";effects.mouse_filter=Control.MOUSE_FILTER_IGNORE;effects.size=size;add_child(effects);effects.draw.connect(_draw_effects)
 anchors=[body.position+Vector2(102,65),body.position+Vector2(112,240),body.position+Vector2(118,355),body.position+Vector2(114,620),coffin_rect.position+Vector2(coffin_rect.size.x*.73,coffin_rect.size.y*.78)]
 if is_instance_valid(effects):effects.queue_redraw()

func _process(delta:float)->void:
 if animated:clock+=delta
 if is_instance_valid(effects):effects.queue_redraw()

func _draw_effects()->void:
 if rules.is_empty():return
 var offset=body.position
 if rules.head_odor:odor(offset+Vector2(171,57),1.0)
 if rules.organ_stain:odor(offset+Vector2(179,250),1.2 if rules.wet else 1.0)
 if rules.wet:
  for i in range(9):
   var p=offset+Vector2(48+(i*41)%127,203+(i*73)%423)
   p.y+=sin(clock*1.7+i)*3.0
   var tint=Color("dfa03f") if rules.beer else Color("64c4e6")
   effects.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-10),p+Vector2(-5,1),p+Vector2(-4,6),p+Vector2(4,6),p+Vector2(5,1)]),tint)
   effects.draw_circle(p+Vector2(-1,2),1.5,Color("e9ffff"))
   if rules.beer:
    for j in range(3):effects.draw_circle(p+Vector2(j*5-5,-10-j%2*4),3.0,Color("fbe5b3"))
 if rules.head_notch:
  var p=offset+(Vector2(176,22) if rules.mask else Vector2(141,30))
  # A visible torn wrapping edge behind the mask, never an exposed wound.
  effects.draw_polyline(PackedVector2Array([p+Vector2(-9,-10),p+Vector2(-4,3),p+Vector2(4,-3),p+Vector2(7,12),p+Vector2(15,7)]),Color("543329"),5.0,true)
  effects.draw_polyline(PackedVector2Array([p+Vector2(-8,-12),p+Vector2(-1,0),p+Vector2(5,-6),p+Vector2(10,8)]),Color("ffe7bd"),2.0,true)

func odor(origin:Vector2,strength:float)->void:
 for strand in range(3):
  var points=PackedVector2Array()
  for j in range(18):
   var t=float(j)/17.0
   points.append(origin+Vector2(strand*13+sin(t*8.0+clock*1.5+strand)*9.0,-t*70*strength))
  effects.draw_polyline(points,Color(.21,.03,.31,.55),9.0,true)
  effects.draw_polyline(points,Color("c75cff"),4.5,true)
  effects.draw_circle(points[-1],3,Color("e1a4ff"))
