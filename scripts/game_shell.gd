extends Control
var orientation:Control
var game:Control
const WorkshopSkin = preload("res://scripts/workshop_settings_skin.gd")
var settings_entry:Button
var museum_button:Button
var sound_switch:TextureRect
var settings:Control
var pause_overlay:Control
var volume_slider:HSlider
var volume_label:Label
var volume_group:VBoxContainer
var close_settings:Button
var resume_button:Button
var settings_toggle:Button
@onready var sound:Node=get_node("/root/GameAudio")

func _ready()->void:
 if OS.has_feature("web"):
  _sync_web_viewport()
  get_window().size_changed.connect(_sync_web_viewport)
 var ui_theme=Theme.new();ui_theme.default_font=load("res://assets/chinese.ttf");ui_theme.default_font_size=17;theme=ui_theme
 var fallback=SystemFont.new();fallback.font_names=PackedStringArray(["Microsoft JhengHei","Noto Sans CJK TC"]);ui_theme.default_font.fallbacks=[load("res://assets/fonts/NotoSansCJKtc-Regular.otf"),fallback]
 game=preload("res://ritual.tscn").instantiate()
 game.name="Game"
 add_child(game)
 game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 settings_entry=_button("設定",_open_settings)
 WorkshopSkin.button(settings_entry,WorkshopSkin.JADE,WorkshopSkin.GEAR,16)
 settings_entry.tooltip_text="工房設定"
 settings_entry.name="AudioSettings"
 settings_entry.accessibility_name="遊戲設定"
 settings_entry.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 add_child(settings_entry)
 _settings_overlay();_pause_overlay();_orientation_overlay()
 sound.settings_changed.connect(_refresh);resized.connect(_layout);_layout();_refresh()
 DisplayServer.window_set_title("木乃伊工房 · 尼羅河的祕密")

func _sync_web_viewport()->void:
 # Godot's framebuffer includes devicePixelRatio. Layout and hit targets use
 # CSS pixels, while canvas_items retains a sharp high-density framebuffer.
 var logical=Vector2i(int(JavaScriptBridge.eval("window.innerWidth")),int(JavaScriptBridge.eval("window.innerHeight")))
 if logical.x<=0 or logical.y<=0:return
 var window=get_window()
 window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
 if window.content_scale_size!=logical:window.content_scale_size=logical

func _button(text:String,action:Callable)->Button:
 var b=Button.new()
 b.text=text
 b.custom_minimum_size=Vector2(80,44)
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.pressed.connect(action)
 WorkshopSkin.button(b,WorkshopSkin.JADE,null,18)
 return b

func _open_settings()->void:
 settings.show()
 settings_toggle.grab_focus()

func _return_to_museum()->void:
 _close_settings()
 if OS.has_feature("web"):
  JavaScriptBridge.eval("window.HistoryMummy?.returnToView()")

func _shade()->Control:
 var shade=ColorRect.new();shade.color=Color(.10,.06,.025,.60);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade);return shade

func _settings_overlay()->void:
 settings=_shade()
 settings.name="AudioSettingsOverlay"
 settings.hide()
 var panel=PanelContainer.new()
 panel.name="Panel"
 panel.add_theme_stylebox_override("panel",WorkshopSkin.surface(WorkshopSkin.TABLET,Vector2(34,32),Vector2(26,17)))
 settings.add_child(panel)
 var layout=VBoxContainer.new()
 layout.add_theme_constant_override("separation",5)
 panel.add_child(layout)

 var title_row=HBoxContainer.new()
 title_row.alignment=BoxContainer.ALIGNMENT_CENTER
 title_row.add_theme_constant_override("separation",12)
 layout.add_child(title_row)
 title_row.add_child(WorkshopSkin.picture(WorkshopSkin.WING,Vector2(58,28)))
 var title=Label.new()
 title.text="工房設定"
 title.add_theme_font_size_override("font_size",26)
 title.add_theme_color_override("font_color",Color("ffdfa0"))
 title_row.add_child(title)
 var wing=WorkshopSkin.picture(WorkshopSkin.WING,Vector2(58,28))
 wing.flip_h=true
 title_row.add_child(wing)

 var scroll=preload("res://scripts/touch_scroll.gd").new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 layout.add_child(scroll)
 var stack=VBoxContainer.new()
 stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stack.add_theme_constant_override("separation",6)
 scroll.add_child(stack)
 settings_toggle=_button("",func():sound.set_enabled(not sound.enabled))
 settings_toggle.name="AudioToggle"
 settings_toggle.alignment=HORIZONTAL_ALIGNMENT_LEFT
 settings_toggle.custom_minimum_size.y=48
 WorkshopSkin.button(settings_toggle,WorkshopSkin.DARK,WorkshopSkin.MUTE,18)
 for state in ["normal","hover","pressed","disabled"]:
  settings_toggle.get_theme_stylebox(state).set_content_margin(SIDE_LEFT,16)
 stack.add_child(settings_toggle)
 sound_switch=WorkshopSkin.picture(WorkshopSkin.SWITCH_OFF,Vector2(48,24))
 settings_toggle.add_child(sound_switch)
 sound_switch.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
 sound_switch.offset_left=-64
 sound_switch.offset_right=-16
 sound_switch.offset_top=-12
 sound_switch.offset_bottom=12

 _add_volume_control(stack)

 var actions=HBoxContainer.new()
 actions.add_theme_constant_override("separation",10)
 layout.add_child(actions)
 museum_button=_button("返回探索館",_return_to_museum)
 museum_button.name="ReturnToMuseum"
 museum_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 museum_button.visible=OS.has_feature("web")
 WorkshopSkin.button(museum_button,WorkshopSkin.STONE,WorkshopSkin.TEMPLE,17)
 actions.add_child(museum_button)
 close_settings=_button("返回遊戲",_close_settings)
 close_settings.name="CloseAudioSettings"
 close_settings.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 WorkshopSkin.button(close_settings,WorkshopSkin.JADE,WorkshopSkin.PLAY,17)
 actions.add_child(close_settings)

func _add_volume_control(parent:VBoxContainer)->void:
 volume_group=VBoxContainer.new()
 volume_group.add_theme_constant_override("separation",0)
 parent.add_child(volume_group)
 var row=HBoxContainer.new()
 row.add_theme_constant_override("separation",7)
 volume_group.add_child(row)
 row.add_child(WorkshopSkin.picture(WorkshopSkin.VOLUME,Vector2(20,20)))
 var label=Label.new()
 label.text="音量"
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 label.add_theme_color_override("font_color",Color("f1dfb5"))
 row.add_child(label)
 volume_label=Label.new()
 volume_label.add_theme_color_override("font_color",Color("e7c880"))
 row.add_child(volume_label)
 volume_slider=HSlider.new()
 volume_slider.name="Volume"
 volume_slider.accessibility_name="音量"
 WorkshopSkin.slider(volume_slider)
 volume_slider.value_changed.connect(func(value):sound.set_volume(value/100.0))
 volume_group.add_child(volume_slider)

func _pause_overlay()->void:
 pause_overlay=_shade();pause_overlay.name="AudioPauseOverlay";pause_overlay.hide()
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);pause_overlay.add_child(center)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",16);center.add_child(col)
 var message=Label.new();message.text="遊戲已暫停";message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;col.add_child(message)
 resume_button=_button("繼續遊戲",func():sound.resume_session());col.add_child(resume_button)

func _close_settings()->void:
 settings.hide();settings_entry.grab_focus()

func _layout()->void:
 if not is_instance_valid(settings):return
 var panel=settings.get_node("Panel") as Control
 panel.size=Vector2(minf(420,size.x-20),minf(262,size.y-12))
 panel.position=(size-panel.size)/2
 var inset=6 if size.y<550 else 12
 settings_entry.offset_top=inset
 settings_entry.offset_right=-inset
 settings_entry.offset_left=-inset-82
 settings_entry.offset_bottom=inset+44
 orientation.visible=size.y>size.x

func _refresh()->void:
 settings_toggle.text="聲音已開啟" if sound.enabled else "聲音已關閉"
 settings_toggle.icon=WorkshopSkin.SOUND if sound.enabled else WorkshopSkin.MUTE
 sound_switch.texture=WorkshopSkin.SWITCH_ON if sound.enabled else WorkshopSkin.SWITCH_OFF
 settings_toggle.accessibility_name="關閉所有聲音" if sound.enabled else "開啟所有聲音"
 volume_slider.set_value_no_signal(sound.volume*100)
 volume_slider.editable=sound.enabled
 volume_slider.focus_mode=Control.FOCUS_ALL if sound.enabled else Control.FOCUS_NONE
 volume_group.modulate=Color.WHITE if sound.enabled else Color(1,1,1,.55)
 volume_label.text="%d%%"%roundi(sound.volume*100)
 var was_paused=pause_overlay.visible
 pause_overlay.visible=sound.suspended
 if sound.suspended:resume_button.grab_focus()
 elif was_paused:
  if settings.visible:close_settings.grab_focus()
  else:settings_entry.grab_focus()

func _input(event:InputEvent)->void:
 if is_instance_valid(orientation) and orientation.visible:
  get_viewport().set_input_as_handled();return
 if is_instance_valid(pause_overlay) and pause_overlay.visible:
  if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
   resume_button.grab_focus();get_viewport().set_input_as_handled()
  return
 if is_instance_valid(settings) and settings.visible and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
  var controls=[settings_toggle]
  if volume_slider.editable:controls.append(volume_slider)
  if museum_button.visible:controls.append(museum_button)
  controls.append(close_settings)
  var current=controls.find(get_viewport().gui_get_focus_owner())
  var step=-1 if event.is_action_pressed("ui_focus_prev") else 1
  controls[posmod(current+step,controls.size())].grab_focus();get_viewport().set_input_as_handled();return
 if is_instance_valid(settings) and settings.visible and event.is_action_pressed("ui_cancel"):
  _close_settings();get_viewport().set_input_as_handled()

func _orientation_overlay()->void:
 orientation=ColorRect.new();orientation.name="RotateDevice";orientation.color=Color("44321f")
 orientation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(orientation)
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation.add_child(center)
 var text=Label.new();text.text="請將裝置轉為橫向\n\n橫向遊玩木乃伊工房\n畫面更清晰，選擇更方便。".replace("\n","\n")
 text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.add_theme_font_size_override("font_size",24);text.add_theme_color_override("font_color",Color("ffe0a0"));center.add_child(text)
