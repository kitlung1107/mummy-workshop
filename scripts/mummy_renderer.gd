extends Control
const Data=preload("res://scripts/content.gd")
const SHEET=preload("res://assets/composite/sprites.png")
const EFFECT=preload("res://scripts/refined_material.gdshader")
var answers:Array=[]
var rules:Dictionary={}
var body:Control
var body_art:TextureRect
var clock:float=0.0
var animated=true
var effects:Control
var anchors:Array[Vector2]=[]
var vapors:Array[ShaderMaterial]=[]

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
 var material_name="papyrus" if rules.material=="papyrus" else "linen"
 var state=["dry","water","beer"][answers[2]]
 var asset_path="res://assets/refined/"+material_name+"-"+state+".png"
 if rules.hollow:
  asset_path="res://assets/refined/linen-unfilled-"+state+"-v3.png"
 elif answers[2]>0:
  asset_path="res://assets/refined/"+material_name+"-filled-"+state+"-v3.png"
 body_art.texture=load(asset_path)
 body_art.set_meta("material_asset",asset_path)
 var material_new=ShaderMaterial.new()
 material_new.shader=EFFECT
 material_new.set_shader_parameter("hollow",rules.hollow)
 material_new.set_shader_parameter("full_belly",rules.belly_full)
 material_new.set_shader_parameter("damaged_head",rules.head_notch)
 material_new.set_shader_parameter("organ_stain",rules.organ_stain)
 material_new.set_shader_parameter("head_decay",rules.head_odor)
 material_new.set_shader_parameter("papyrus",rules.material=="papyrus")
 material_new.set_shader_parameter("wet",answers[2])
 body_art.material=material_new
 if rules.head_notch:
  var torn=TextureRect.new();torn.name="TornTempleWrap"
  torn.texture=load("res://assets/refined/torn-wrap.png")
  torn.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  torn.stretch_mode=TextureRect.STRETCH_SCALE
  torn.position=Vector2(153,-9) if rules.mask else Vector2(134,-6)
  torn.size=Vector2(57,77) if rules.mask else Vector2(46,64)
  torn.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if rules.material=="papyrus":torn.modulate=Color("d8b271")
  body.add_child(torn)
 if rules.mask:
  art(body,"GoldMask",Rect2(1206,50,286,264),Rect2(32,-6,144,134))
 effects=Control.new();effects.name="Atmosphere";effects.mouse_filter=Control.MOUSE_FILTER_IGNORE;effects.size=size;body.add_child(effects)
 # User review: no external odor waves, haze or plumes.
 anchors=[body.position+Vector2(102,65),body.position+Vector2(112,240),body.position+Vector2(118,355),body.position+Vector2(114,620),coffin_rect.position+Vector2(coffin_rect.size.x*.12,coffin_rect.size.y*.78)]
 if is_instance_valid(effects):effects.queue_redraw()

func add_vapor(rect:Rect2,strength:float)->void:
 var cloud=ColorRect.new()
 cloud.name="SeamVapor%d"%vapors.size()
 cloud.position=rect.position;cloud.size=rect.size
 cloud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var mat=ShaderMaterial.new();mat.shader=load("res://scripts/atmosphere.gdshader")
 mat.set_shader_parameter("strength",strength)
 cloud.material=mat;effects.add_child(cloud);vapors.append(mat)

func _process(delta:float)->void:
 if animated:clock+=delta
 if is_instance_valid(body_art):body_art.material.set_shader_parameter("phase",clock)
 for i in range(vapors.size()):vapors[i].set_shader_parameter("phase",clock+float(i)*4.7)
