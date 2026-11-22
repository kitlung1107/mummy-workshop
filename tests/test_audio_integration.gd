extends SceneTree
var checks=0
var failures:Array=[]
var samples:Array=[]
func check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _initialize()->void:run.call_deferred()
func settle(seconds:float=.16)->void:await create_timer(seconds).timeout
func peak(buffer:PackedVector2Array)->float:
 var value=0.0
 for frame in buffer:value=maxf(value,maxf(absf(frame.x),absf(frame.y)))
 return value
func capture_peak(capture:AudioEffectCapture)->float:
 var count=capture.get_frames_available()
 samples.append(count)
 return peak(capture.get_buffer(count)) if count>0 else -1.0
func run()->void:
 var app=load("res://game_shell.tscn").instantiate();root.add_child(app)
 await process_frame;await process_frame
 var game=app.game;var sound=root.get_node("GameAudio")
 DirAccess.make_dir_recursive_absolute("res://review")
 check(game.page=="home","game starts on home")
 check(FileAccess.get_sha256("res://assets/audio/metal-tray.wav")=="b3313e90344b41d7782222d66dcf54b3503e121c64fe9fd988425c1242705501","approved v5 tray installed")
 check(is_equal_approx(sound.streams["metal-tray"].get_length(),.42),"short metallic v5 tray duration")
 # Run repeatably after other game tests that may have saved audio preferences.
 sound.set_enabled(false)
 sound.set_volume(.4)
 check(not app.volume_slider.editable,"volume is disabled while muted")
 check(sound.streams.size()==22,"all approved audio streams preloaded")
 for id in ["loop-home","loop-workshop","loop-result"]:
  var stream=sound.streams[id]
  check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_begin==0,"loop configured "+id)
  check(stream.format==AudioStreamWAV.FORMAT_16_BITS,"lossless PCM import "+id)
 check(is_equal_approx(sound.streams["coffin-4600"].get_length(),4.6),"reveal PCM exactly 4.6 seconds")
 check(FileAccess.get_sha256("res://assets/audio/page-turn.wav")=="5af53d60a6e08dddff9f0062db3112b575337ee002dc8ac4e21ffbe6c47d8758","approved page turn unchanged")
 var capture=AudioEffectCapture.new();capture.buffer_length=2;AudioServer.add_bus_effect(0,capture)
 app.settings_toggle.pressed.emit();await settle(.9)
 check(sound.enabled and app.volume_slider.editable and sound.stats.music_starts>=1,"explicit gesture enables sound and volume")
 check(app.settings.find_children("*","HSlider",true,false).size()==1,"settings has one audio slider")
 app.volume_slider.value=67
 var music_bus:=AudioServer.get_bus_index(sound.MUSIC_BUS)
 var effects_bus:=AudioServer.get_bus_index(sound.SFX_BUS)
 for bus in [music_bus,effects_bus]:
  check(is_equal_approx(AudioServer.get_bus_volume_db(bus),linear_to_db(.67*.8)),"shared slider applies mixer gain to bus "+str(bus))
 app.settings_toggle.pressed.emit()
 check(not app.volume_slider.editable and is_equal_approx(app.volume_slider.value,67),"muting locks and preserves the slider")
 check(AudioServer.is_bus_mute(music_bus) and AudioServer.is_bus_mute(effects_bus),"toggle mutes both buses")
 var restored=sound.get_script().new()
 restored._load_preferences()
 check(not restored.enabled and is_equal_approx(restored.volume,.67),"muted level survives preference reload")
 app.settings_toggle.pressed.emit()
 restored._load_preferences()
 check(restored.enabled and is_equal_approx(restored.volume,.67),"unmuting retains and saves the same level")
 restored.free()
 check(not AudioServer.is_bus_mute(music_bus) and not AudioServer.is_bus_mute(effects_bus),"unmuting restores both buses")
 app.volume_slider.value=40
 var audible=capture_peak(capture);check(audible>0.00001,"actual mixer produces nonzero PCM")
 var home_position=sound.music_players[sound.music_slot].get_playback_position()
 game.start_game();await settle(.2)
 check(game.page=="instructions" and sound.stats.last_effect=="ui-tap","start gives one neutral cue")
 var blocked_cues=sound.stats.effect_starts
 game.accept_mission()
 check(game.page=="instructions" and sound.stats.effect_starts==blocked_cues,"early mission blocked before audio cue")
 for i in range(12):game.render()
 await settle(.2)
 check(sound.stats.music_starts==1,"home to instructions and rerenders keep same music")
 check(sound.music_players[sound.music_slot].get_playback_position()>home_position,"home loop position advances instead of restarting")
 while Time.get_ticks_msec()<game.mission_ready_at:await process_frame
 game.accept_mission();await settle(.2)
 app.settings_entry.pressed.emit()
 app.volume_slider.value=31
 check(game.page=="quiz" and is_equal_approx(sound.volume,.31),"in-game settings adjusts the same volume")
 for bus in [music_bus,effects_bus]:
  check(is_equal_approx(AudioServer.get_bus_volume_db(bus),linear_to_db(.31*.8)),"in-game slider applies to bus "+str(bus))
 app.volume_slider.value=40
 app.close_settings.pressed.emit()
 check(game.page=="quiz" and sound.current_music=="loop-workshop","mission switches to workshop")
 check(sound.stats.music_starts==2,"one workshop transition")
 await settle();game.choose(1);await settle()
 var cues=sound.stats.effect_starts;game.choose(1);game.choose(1)
 check(sound.stats.effect_starts==cues,"same selected answer makes no new cue")
 game.next_question();await settle()
 check(sound.stats.last_effect=="page-turn","next uses preserved page-turn")
 game.previous_question();await settle()
 check(game.question==0 and game.answers[0]==1,"previous keeps answer")
 check(sound.stats.music_starts==2,"previous and choice rebuild do not restart music")
 var expected=[["nasal-metal","anoint-oil","tool"],["metal-tray","metal-tray","metal-tray"],["mineral","liquid","liquid"],["fill-linen","cloth","fill-papyrus"],["coffin-placement","bed-placement","coffin-placement"]]
 for q in range(5):
  game.question=q
  for v in range(3):
   game.answers[q]=-1;game.render();await settle();game.choose(v)
   check(sound.stats.last_effect==expected[q][v],"all option mappings q=%d v=%d"%[q,v])
 check(sound.stats.music_starts==2,"all fifteen choices keep continuous workshop music")
 check(sound.streams["coffin-placement"].get_length()>sound.streams["bed-placement"].get_length()+1,"coffin placement is distinctly longer")
 check(sound.streams["fill-linen"].get_length()>1.8 and sound.streams["fill-papyrus"].get_length()>2.1,"fill then wrapping recipes retain full sequence")
 # Isolate the effects bus for the PCM probe only.
 AudioServer.set_bus_mute(AudioServer.get_bus_index(sound.MUSIC_BUS),true);await settle(.2)
 for id in ["nasal-metal","anoint-oil","metal-tray","fill-linen","fill-papyrus","bed-placement","coffin-placement"]:
  capture.clear_buffer();sound.cue(id);await settle(.3)
  check(capture_peak(capture)>0.00001,"new cue produces actual PCM with music muted: "+id)
 AudioServer.set_bus_mute(AudioServer.get_bus_index(sound.MUSIC_BUS),false);await settle()
 game.answers=[-1,-1,-1,-1,-1]
 for q in range(5):
  game.question=q;game.render();game.choose(q%3);await settle()
  check(sound.stats.last_effect==["nasal-metal","metal-tray","liquid","fill-linen","bed-placement"][q],"material cue mapping "+str(q))
  if q<4:game.next_question();await settle()
 var records=game.completion_records.size()
 game.next_question();game.submit();game.next_question()
 check(game.page=="result" and game.completion_records.size()==records+1,"one submission and original records")
 check(sound.revealing and sound.stats.reveal_starts==1 and sound.stats.reveal_audio_starts==1,"one reveal timeline and one sound")
 check(not game.canvas.has_node("ReplayRitual") and not game.canvas.has_node("SkipRitual"),"no student replay or skip controls")
 await settle(1.1)
 var prior=sound.reveal_elapsed;var starts=sound.stats.reveal_audio_starts
 var ritual_id=game.ritual.get_instance_id()
 game._deferred_resize();await process_frame
 check(game.ritual.get_instance_id()==ritual_id,"resize preserves live ritual node")
 check(sound.reveal_elapsed>=prior and sound.reveal_elapsed<prior+.2,"resize preserves presentation clock")
 check(sound.stats.reveal_audio_starts==starts,"resize does not replay coffin audio")
 check(absf(game.ritual.elapsed-sound.reveal_elapsed)<.08,"visual and sound presentation clocks agree")
 var drift=absf(sound.reveal_player.get_playback_position()-sound.reveal_elapsed)
 check(drift<.18,"actual player stays within 180ms of reveal clock")
 sound.suspend_session();var paused=sound.reveal_elapsed;await settle(.25)
 check(sound.reveal_elapsed==paused and sound.reveal_player.stream_paused,"background freezes sound and presentation")
 check(app.resume_button.has_focus(),"pause overlay holds keyboard focus")
 sound.resume_session();await settle(4.6-sound.reveal_elapsed+.25)
 check(game.finished and game.hotspots.visible and game.result_actions.visible,"natural reveal completes and unlocks UI")
 check(sound.stats.reveal_completions==1 and sound.current_music=="loop-result","result music once after ceremony")
 var music_starts=sound.stats.music_starts
 await settle();game.open_detail(0);await settle()
 check(game.dialog_question==0 and sound.ducked,"detail opens and ducks music")
 cues=sound.stats.effect_starts;game.open_detail(1)
 check(sound.stats.effect_starts==cues and game.dialog_question==0,"one modal only and no duplicate cue")
 var modal_id=game.dialog_layer.get_instance_id()
 var texture_id=game.find_child("ExplanationArtwork",true,false).texture.get_instance_id()
 game._deferred_resize();await settle()
 check(game.dialog_layer.get_instance_id()==modal_id,"modal resize keeps same dialog")
 check(game.find_child("ExplanationArtwork",true,false).texture.get_instance_id()==texture_id,"modal resize keeps cached texture")
 check(game.dialog_question==0 and sound.stats.effect_starts==cues,"modal resize restores without replay")
 game.close_detail();await settle();game.close_detail()
 check(game.dialog_question==-1 and not sound.ducked,"close restores music")
 check(sound.stats.music_starts==music_starts,"detail open close never restarts result loop")
 capture.clear_buffer();sound.set_enabled(false);await settle(.2);capture.clear_buffer();await settle(.2)
 check(capture_peak(capture)==0,"master mute produces silent PCM")
 sound.set_enabled(true);sound.set_volume(0);await settle(.2);capture.clear_buffer();await settle(.2)
 check(capture_peak(capture)==0,"zero master volume produces silence")
 sound.set_volume(.4);await settle(.3)
 check(capture_peak(capture)>0,"volume restoration resumes existing loop")
 var count=game.completion_records.size();game.play_again();await settle()
 check(game.page=="instructions" and game.answers==[-1,-1,-1,-1,-1],"play again resets only attempt")
 check(game.detail_textures.is_empty(),"play again clears explanation cache with audio intact")
 check(game.completion_records.size()==count and sound.current_music=="loop-home","replay keeps records and returns home music")
 music_starts=sound.stats.music_starts;game.entry_home();await settle()
 check(game.page=="home" and sound.stats.music_starts==music_starts,"return home shares entry loop without restart")
 var formats=[]
 for dimensions in [Vector2i(1440,810),Vector2i(768,1024),Vector2i(390,844),Vector2i(844,390)]:
  root.size=dimensions;await process_frame;await process_frame;await settle(.1)
  app._layout()
  check(app.settings_toggle.size.x>=72 and app.settings_toggle.size.y>=44,"usable sound touch target "+str(dimensions))
  check(game.position==Vector2.ZERO and game.size.is_equal_approx(app.size),"game fills shell "+str(dimensions))
  check(Rect2(Vector2.ZERO,app.size).encloses(app.settings_entry.get_global_rect()),"settings entry fits viewport "+str(dimensions))
  app.settings_entry.pressed.emit();await process_frame
  var panel=app.settings.get_node("Panel")
  check(panel.position.x>=0 and panel.position.y>=0 and panel.get_rect().end.x<=app.size.x+.1 and panel.get_rect().end.y<=app.size.y+.1,"settings fit viewport "+str(dimensions))
  check(app.close_settings.get_global_rect().end.y<=app.size.y and app.close_settings.size.y>=44,"return button remains visible without scrolling "+str(dimensions))
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://review/audio-settings-%dx%d.png"%[dimensions.x,dimensions.y])
  app.settings.hide();formats.append(str(dimensions))
 if DisplayServer.get_name()!="headless":
  root.size=Vector2i(1440,810);game.page="quiz";game.render();await settle(.2);await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://review/audio-quiz.png")
 var report={"checks":checks,"failures":failures,"mixer_sample_counts":samples,"audible_peak":audible,"reveal_drift_seconds":drift,"audio_stats":sound.stats,"sizes":formats,"engine":Engine.get_version_info().string}
 FileAccess.open("res://review/audio-integration.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print(JSON.stringify(report))
 sound.set_enabled(false)
 for player in sound.music_players+sound.effect_players+[sound.reveal_player]:player.stop()
 AudioServer.remove_bus_effect(0,0)
 await settle(.2)
 quit(0 if failures.is_empty() else 1)
