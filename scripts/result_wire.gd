extends Control
## The five static result callouts use canvas primitives. Line2D/Polygon2D
## rebuild indexed meshes on WebGL during viewport transforms in Godot 4.7.
var start=Vector2.ZERO
var end=Vector2.ZERO
func configure(from:Vector2,to:Vector2)->void:
 start=from;end=to;mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_meta("result_wire",true);queue_redraw()
func _draw()->void:
 draw_line(start,end,Color("f5ce67"),2,true)
 draw_primitive(PackedVector2Array([end+Vector2(0,-5),end+Vector2(5,0),end+Vector2(0,5),end+Vector2(-5,0)]),PackedColorArray([Color("e7bd73")]),PackedVector2Array())
