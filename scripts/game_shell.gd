extends Control
var orientation:Control
var game:Control
var toggle:Button
var settings:Control
var pause_overlay:Control
var music_slider:HSlider
var effects_slider:HSlider
var music_label:Label
var effects_label:Label
var header_label:Label
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
 var box=VBoxContainer.new();box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.add_theme_constant_override("separation",0);add_child(box)
 var bar=PanelContainer.new();bar.name="AudioToolbar";bar.custom_minimum_size.y=54;bar.add_theme_stylebox_override("panel",_style(Color("103e49")));box.add_child(bar)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);bar.add_child(row)
 header_label=Label.new();header_label.text="木乃伊工房";header_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header_label.add_theme_color_override("font_color",Color("e7bd73"));row.add_child(header_label)
 toggle=_button("開啟聲音",func():sound.set_enabled(not sound.enabled));toggle.name="AudioToggle";row.add_child(toggle)
 var options=_button("音量",func():settings.show();close_settings.grab_focus());options.name="AudioSettings";row.add_child(options)
 game=preload("res://ritual.tscn").instantiate();game.name="Game";game.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(game)
 _settings_overlay();_pause_overlay();_orientation_overlay()
 sound.settings_changed.connect(_refresh);resized.connect(_layout);_layout();_refresh()
 DisplayServer.window_set_title("木乃伊工房 · 尼羅河的祕密")

func _style(color:Color)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=color;s.content_margin_left=12;s.content_margin_right=12;s.content_margin_top=5;s.content_margin_bottom=5;return s

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
 var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(72,44);b.pressed.connect(action);b.add_theme_color_override("font_color",Color("fff0ce"));b.add_theme_stylebox_override("normal",_style(Color("1c5359")));b.add_theme_stylebox_override("hover",_style(Color("317178")));b.add_theme_stylebox_override("pressed",_style(Color("0b343a")));return b

func _shade()->Control:
 var shade=ColorRect.new();shade.color=Color(0,0,0,.76);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade);return shade

func _settings_overlay()->void:
 settings=_shade();settings.name="AudioSettingsOverlay";settings.hide()
 var panel=PanelContainer.new();panel.name="Panel";panel.add_theme_stylebox_override("panel",_style(Color("153e46")));settings.add_child(panel)
 var panel_layout=VBoxContainer.new();panel.add_child(panel_layout)
 var scroll=preload("res://scripts/touch_scroll.gd").new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel_layout.add_child(scroll)
 var stack=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",10);scroll.add_child(stack)
 var heading=Label.new();heading.text="聲音與音量";heading.add_theme_font_size_override("font_size",24);stack.add_child(heading)
 music_label=Label.new();stack.add_child(music_label)
 music_slider=HSlider.new();music_slider.name="MusicVolume";music_slider.min_value=0;music_slider.max_value=100;music_slider.step=1;music_slider.custom_minimum_size.y=44;music_slider.accessibility_name="背景音樂音量";music_slider.value_changed.connect(func(v):sound.set_music_volume(v/100.0));stack.add_child(music_slider)
 effects_label=Label.new();stack.add_child(effects_label)
 effects_slider=HSlider.new();effects_slider.name="EffectsVolume";effects_slider.max_value=100;effects_slider.step=1;effects_slider.custom_minimum_size.y=44;effects_slider.accessibility_name="音效音量";effects_slider.value_changed.connect(func(v):sound.set_effects_volume(v/100.0));stack.add_child(effects_slider)
 settings_toggle=_button("靜音／開聲",func():sound.set_enabled(not sound.enabled));stack.add_child(settings_toggle)
 var credits=RichTextLabel.new();credits.name="AudioCredits";credits.bbcode_enabled=true;credits.fit_content=true;credits.scroll_active=false;credits.selection_enabled=true;credits.add_theme_font_size_override("normal_font_size",14)
 credits.mouse_filter=Control.MOUSE_FILTER_PASS
 credits.text="[b]音樂與素材致謝[/b]\n首頁：Oud 撥弦｜工房：Darbuka 手鼓｜結果：Ney 吹管。\n\nNey：ney.wav，由 xserra 錄音、Hamza Zeytinoglu 演奏，CC BY 4.0。已節錄、濾波、調音量、加短延遲及重新安排留白；作者未背書本遊戲。\n[url=https://freesound.org/people/xserra/sounds/115398/]原始錄音[/url] · [url=https://creativecommons.org/licenses/by/4.0/]授權全文[/url]\n\n其餘錄音（CC0）：hammondman（Oud）、hollandm（Darbuka）、cmorris035、DrFahrts（木件）、scallep（布）、Jae-Aye（陶盤）、hello_world+123（米粒）、jbeetle（水）。\n翻書聲：保留原創合成原檔。完整來源與修改紀錄見隨附 AUDIO-LICENSES.md。\n\n本版為當代地域音色靈感，不宣稱古埃及音樂的精確還原。"
 credits.text+="\n\n[b]動作與材質錄音（CC0）[/b]\nDannWillis（金屬工具）、Nickh69（金屬托盤）、wolfmagpie（乳液塗抹作香油擬音）、Mafon2（信封紙作紙草擬音）。填充與安葬使用原有米粒、布及木件錄音重新編排；並非人體、古代工具或棺木實錄。完整來源及修改記錄見 AUDIO-LICENSES.md。"
 credits.meta_clicked.connect(func(url):OS.shell_open(str(url)));stack.add_child(credits)
 close_settings=_button("返回遊戲",_close_settings);close_settings.name="CloseAudioSettings";panel_layout.add_child(close_settings)

func _pause_overlay()->void:
 pause_overlay=_shade();pause_overlay.name="AudioPauseOverlay";pause_overlay.hide()
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);pause_overlay.add_child(center)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",16);center.add_child(col)
 var message=Label.new();message.text="遊戲已暫停";message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;col.add_child(message)
 resume_button=_button("繼續遊戲",func():sound.resume_session());col.add_child(resume_button)

func _close_settings()->void:
 settings.hide();toggle.grab_focus()

func _layout()->void:
 if not is_instance_valid(settings):return
 var panel=settings.get_node("Panel") as Control
 panel.size=Vector2(minf(480,size.x-24),minf(570,size.y-24));panel.position=(size-panel.size)/2
 var phone=size.y<600 and size.x>size.y
 header_label.add_theme_font_size_override("font_size",14 if phone else 17)
 var bar=find_child("AudioToolbar",true,false) as Control
 bar.custom_minimum_size.y=36 if phone else 54
 for button in [toggle,find_child("AudioSettings",true,false)]:
  button.custom_minimum_size.y=26 if phone else 44
  button.add_theme_font_size_override("font_size",13 if phone else 17)
 orientation.visible=size.y>size.x

func _refresh()->void:
 toggle.text="靜音" if sound.enabled else "開啟聲音"
 toggle.accessibility_name="關閉所有聲音" if sound.enabled else "開啟所有聲音"
 music_slider.set_value_no_signal(sound.music_volume*100);effects_slider.set_value_no_signal(sound.effects_volume*100)
 music_label.text="音樂  %d%%"%roundi(sound.music_volume*100);effects_label.text="音效  %d%%"%roundi(sound.effects_volume*100)
 var was_paused=pause_overlay.visible
 pause_overlay.visible=sound.suspended
 if sound.suspended:resume_button.grab_focus()
 elif was_paused:
  if settings.visible:close_settings.grab_focus()
  else:toggle.grab_focus()

func _input(event:InputEvent)->void:
 if is_instance_valid(orientation) and orientation.visible:
  get_viewport().set_input_as_handled();return
 if is_instance_valid(pause_overlay) and pause_overlay.visible:
  if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev"):
   resume_button.grab_focus();get_viewport().set_input_as_handled()
  return
 if is_instance_valid(settings) and settings.visible and (event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
  var controls=[music_slider,effects_slider,settings_toggle,close_settings]
  var current=controls.find(get_viewport().gui_get_focus_owner())
  var step=-1 if event.is_action_pressed("ui_focus_prev") else 1
  controls[posmod(current+step,controls.size())].grab_focus();get_viewport().set_input_as_handled();return
 if is_instance_valid(settings) and settings.visible and event.is_action_pressed("ui_cancel"):
  _close_settings();get_viewport().set_input_as_handled()

func _orientation_overlay()->void:
 orientation=ColorRect.new();orientation.name="RotateDevice";orientation.color=Color("103e49")
 orientation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(orientation)
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);orientation.add_child(center)
 var text=Label.new();text.text="請將裝置轉為橫向\n\n橫向遊玩木乃伊工房\n畫面更清晰，選擇更方便。".replace("\n","\n")
 text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text.add_theme_font_size_override("font_size",24);text.add_theme_color_override("font_color",Color("ffe0a0"));center.add_child(text)
