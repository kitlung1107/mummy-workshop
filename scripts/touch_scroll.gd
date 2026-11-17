extends ScrollContainer
## Handle native ScreenDrag as well as ScrollContainer's mouse wheel/keyboard.
## Godot 4.7 buttons consume native touch; mouse emulation alone cannot scroll
## a gesture that starts on an option card. Cancel the card once dragging starts.
var touch_index=-1
var touch_origin=Vector2.ZERO
var scroll_origin=0
var dragging=false

func _gui_input(event:InputEvent)->void:
 if event is InputEventScreenTouch:
  if event.pressed and touch_index<0:
   touch_index=event.index;touch_origin=event.position;scroll_origin=scroll_vertical;dragging=false
  elif not event.pressed and event.index==touch_index:
   if dragging:accept_event()
   touch_index=-1;dragging=false
 elif event is InputEventScreenDrag and event.index==touch_index:
  var distance=event.position.y-touch_origin.y
  if not dragging and absf(distance)>10:
   dragging=true
   propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
  if dragging:
   scroll_vertical=scroll_origin-roundi(distance)
   accept_event()
