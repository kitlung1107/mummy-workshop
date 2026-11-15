extends Control
## Presentation-only adapter. Renderer geometry and answer rules are untouched.
signal revealed
const DURATION=4.6
@export var lid_texture:Texture2D
var renderer:Control
var elapsed:float=0.0
var running=false
var emitted=false
var lid:Control
var veil:ColorRect
var sparkle:Control
var lid_home:Vector2
var lid_extent:Vector2
var phase="sealed"

func configure(subject:Control)->void:
 renderer=subject
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 size=Vector2(580,740)
 var coffin=renderer.get_node("Coffin") as Control
 lid_home=coffin.position
 lid_extent=coffin.size
 veil=ColorRect.new();veil.size=size;veil.color=Color("03171c");veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(veil)
 lid=Control.new();lid.name="CoffinLid";lid.position=lid_home;lid.size=lid_extent;lid.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(lid)
 lid.draw.connect(_draw_lid)
 sparkle=Control.new();sparkle.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(sparkle);sparkle.draw.connect(_draw_light)
 play()

func play()->void:
 # Restart is synchronous: one clock, no accumulated tweens or delayed callbacks.
 elapsed=0.0;running=true;emitted=false;phase="sealed"
 renderer.modulate=Color(0.22,0.25,0.25,1)
 _pose()

func skip()->void:
 if not running:return
 elapsed=DURATION
 _pose()
 _finish()

func _process(delta:float)->void:
 if not running:return
 elapsed=minf(elapsed+delta,DURATION)
 _pose()
 if elapsed>=DURATION:_finish()

func _finish()->void:
 running=false;phase="revealed"
 renderer.modulate=Color.WHITE
 veil.visible=false;lid.visible=false
 sparkle.queue_redraw()
 if not emitted:emitted=true;revealed.emit()

func _pose()->void:
 var open=smoothstep(0.8,3.65,elapsed)
 var light=smoothstep(1.0,3.5,elapsed)
 phase="sealed" if elapsed<0.8 else ("opening" if elapsed<3.65 else "settling")
 lid.visible=elapsed<4.25;veil.visible=elapsed<DURATION
 lid.position=lid_home+Vector2(300*open,-55*open)
 lid.rotation=-0.075*open
 lid.modulate.a=1.0-smoothstep(3.25,4.25,elapsed)
 veil.color=Color(0,0,0,0)
 renderer.modulate=Color.WHITE*lerpf(.22,1.0,light);renderer.modulate.a=smoothstep(.55,1.4,elapsed)
 lid.queue_redraw();sparkle.queue_redraw()

func _draw_lid()->void:
 if lid_texture:
  lid.draw_texture_rect(lid_texture,Rect2(Vector2.ZERO,lid_extent),false)
  return
 var w=lid_extent.x;var h=lid_extent.y
 var outline=PackedVector2Array()
 # Front-facing anthropoid silhouette, sized from the existing coffin layer.
 for i in range(25):
  var a=PI+PI*float(i)/24.0
  outline.append(Vector2(w*.5+cos(a)*w*.40,h*.145+sin(a)*h*.135))
 outline.append_array(PackedVector2Array([Vector2(w*.91,h*.31),Vector2(w*.94,h*.48),Vector2(w*.80,h*.97),Vector2(w*.68,h),Vector2(w*.32,h),Vector2(w*.20,h*.97),Vector2(w*.06,h*.48),Vector2(w*.09,h*.31)]))
 lid.draw_colored_polygon(outline,Color("b48235"))
 lid.draw_polyline(outline+PackedVector2Array([outline[0]]),Color("f9d888"),5,true)
 var inner=PackedVector2Array()
 for p in outline:inner.append(Vector2(w*.5,h*.5)+(p-Vector2(w*.5,h*.5))*Vector2(.86,.96))
 lid.draw_colored_polygon(inner,Color("115962"))
 lid.draw_polyline(inner+PackedVector2Array([inner[0]]),Color("dfb65f"),3,true)
 # Existing gold mask art remains a decorative lid motif, independent of result mask.
 var mask=preload("res://scripts/mummy_renderer.gd").sprite(Rect2(1206,50,286,264))
 lid.draw_texture_rect(mask,Rect2(w*.17,h*.05,w*.66,h*.24),false)
 for k in range(6):
  var y=h*(.35+k*.095)
  var half=w*(.30-k*.024)
  lid.draw_polyline(PackedVector2Array([Vector2(w*.5-half,y),Vector2(w*.5,y+h*.038),Vector2(w*.5+half,y)]),Color("e8c374"),5,true)
 lid.draw_line(Vector2(w*.5,h*.30),Vector2(w*.5,h*.93),Color("f5d48b"),4,true)
 lid.draw_circle(Vector2(w*.5,h*.33),w*.07,Color("f5d48b"))
 lid.draw_circle(Vector2(w*.5,h*.33),w*.044,Color("115962"))

func _draw_light()->void:
 if elapsed>=DURATION:return
 var energy=sin(clampf((elapsed-.65)/3.95,0.0,1.0)*PI)
 var center=lid_home+lid_extent*Vector2(.5,.5)
 for i in range(8):
  var a=-2.8+i*.39
  var tip=center+Vector2(cos(a)*420,sin(a)*600)
  sparkle.draw_colored_polygon(PackedVector2Array([center+Vector2(-9,0),tip,tip+Vector2(70,15),center+Vector2(9,0)]),Color(1,.81,.35,energy*.055))
 for i in range(60):
  var x=fmod(float(i*97),510.0)+35.0
  var y=fposmod(float(i*137)-elapsed*(24+i%17),720.0)
  var p=Vector2(x+sin(elapsed+i)*10,y)
  sparkle.draw_circle(p,1.0+float(i%3)*.65,Color(1,.87,.59,energy*(.2+float(i%4)*.16)))
