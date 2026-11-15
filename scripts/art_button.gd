extends Button
## Transparent painted-art hotspot. No pointer tooltip or opaque focus overlay.
static var keyboard_navigation := false
var capsule := true

func _ready() -> void:
 for state in ["normal","hover","pressed","focus"]:
  add_theme_stylebox_override(state,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)

func _input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed:
  keyboard_navigation=true
  queue_redraw()
 elif event is InputEventMouseMotion or event is InputEventMouseButton:
  if keyboard_navigation:
   keyboard_navigation=false
   queue_redraw()

func _has_point(point:Vector2) -> bool:
 if not Rect2(Vector2.ZERO,size).has_point(point):return false
 if not capsule:return true
 var radius=size.y*.5
 var center=Vector2(clampf(point.x,radius,size.x-radius),radius)
 return point.distance_squared_to(center)<=radius*radius

func _get_tooltip(_point:Vector2) -> String:
 return ""

func _draw() -> void:
 if has_focus() and keyboard_navigation:
  # A thin inset ivory ring stays entirely inside the painted button.
  var ring=StyleBoxFlat.new()
  ring.bg_color=Color.TRANSPARENT
  ring.border_color=Color("fff5d5")
  ring.set_border_width_all(2)
  ring.set_corner_radius_all(int(size.y/2-7))
  draw_style_box(ring,Rect2(Vector2(7,7),size-Vector2(14,14)))
