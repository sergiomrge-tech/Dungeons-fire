extends Node
# Included only in an isolated x86_64 QA export, never in the delivered APK.
var game
var report={"checks":{},"stage":"starting","platform":OS.get_name()}
var frames=[]
var measuring=false
func write_report() -> void:
	var f=FileAccess.open("user://android_qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report));f.flush();f.close()
func touch(id: int, pos: Vector2, pressed: bool) -> void:
	var e=InputEventScreenTouch.new();e.index=id;e.position=pos;e.pressed=pressed;Input.parse_input_event(e)
func _process(delta: float) -> void:
	if measuring:frames.append(delta)
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and report.get("stage")=="checkpoint":call_deferred("record_pause")
func record_pause() -> void:
	report.checks.pause_clears_controls=not game.controls.active and game.controls.axis==Vector2.ZERO and not game.attack_held
	report.checks.pause_screen=game.screen=="pause"
	report.stage="paused";write_report()
func _ready() -> void:
	game=get_parent();await get_tree().create_timer(2).timeout
	if FileAccess.file_exists("user://android_checkpoint.json"):
		game.resume_run()
		report.checks.resume_room=game.room==2
		report.checks.resume_health=is_equal_approx(game.player.hp,73.0)
		report.checks.resume_potions=game.potions==1
		report.checks.resume_chest=game.room_events.has("MINE_CHEST_02") and game.world.chest_nodes.MINE_CHEST_02.cell==1
		report.checks.resume_loot=game.loot.gold==30 and game.loot.ore==4
		report.checks.resume_camera=game.camera.zoom.x<=1.3
		report.stage="complete";write_report();game.show_pause();return
	game.progress.d=game.progress.fresh();game.progress.d.settings.sound=false;game.start_dungeon(0)
	var start=game.player.position
	touch(0,Vector2(240,601),true);touch(1,Vector2(1130,611),true);touch(2,Vector2(987,625),true)
	await get_tree().process_frame
	report.checks.three_touch_contacts=game.controls.stick_id==0 and game.controls.touches.size()==2
	report.checks.move_attack_dodge=game.controls.axis.x>.5 and game.attack_held and game.player.dodge_cd>0
	await get_tree().create_timer(.25).timeout
	report.checks.player_moved=game.player.position.x>start.x+20
	for i in range(3):touch(i,Vector2.ZERO,false)
	await get_tree().process_frame
	report.checks.release_all=game.controls.stick_id==-1 and game.controls.touches.is_empty() and not game.attack_held
	game.progress.d.settings.zoom=1.3
	await get_tree().process_frame
	report.checks.zoom_and_bounds=is_equal_approx(game.camera.zoom.x,1.3) and game.camera.position.x>=640/1.3
	measuring=true;await get_tree().create_timer(5).timeout;measuring=false
	var total=0.0;var worst=0.0
	for delta in frames:total+=delta;worst=maxf(worst,delta)
	report.performance={"sample_frames":frames.size(),"average_fps":frames.size()/maxf(total,.001),"worst_frame_ms":worst*1000,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"scope":"API29 x86_64 emulator; not a physical-device benchmark"}
	game.set_physics_process(false);game.room=2;game.spawn_room();game.player.position=Vector2(1040,510);game.interact_chest()
	game.player.hp=73;game.potions=1;game.player.mana=47;game.save_run()
	var checkpoint=FileAccess.open("user://android_checkpoint.json",FileAccess.WRITE);checkpoint.store_string("ready");checkpoint.close()
	report.checks.chest_opened=game.room_events.has("MINE_CHEST_02")
	report.stage="checkpoint";write_report()
