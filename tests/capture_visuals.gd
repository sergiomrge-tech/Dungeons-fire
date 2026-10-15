extends SceneTree

var output_dir: String = "/tmp/dungeons-fires-visuals"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):output_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("run")

func capture(name: String) -> void:
	for i in range(4):await process_frame
	await RenderingServer.frame_post_draw
	var screenshot=root.get_texture().get_image()
	assert(screenshot!=null and screenshot.get_width()>0)
	assert(screenshot.save_png(output_dir.path_join(name+".png"))==OK)
	print("FRAMEBUFFER_CAPTURE: "+name)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Visual validation requires a real rendering display (Xvfb is supported).")
		quit(1);return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://visual_review_save.json")
	game.progress.d.settings.sound=false;game.progress.d.tutorial=true
	game.show_menu();await capture("01_menu")
	game.show_hub();await capture("02_hub")
	game.show_heroes();await capture("03_heroes")
	game.show_map(0);await capture("04_map")
	game.show_map(1);await capture("04_map_region_1")
	game.show_map(2);await capture("04_map_region_2")
	for region in range(5):
		game.start_dungeon(region*3)
		await capture("05_combat_region_%d"%region)
	game.start_dungeon(0)
	for room in range(5):
		game.room=room;game.spawn_room();game.combat_ui()
		if room==2:game.player.position=Vector2(580,510);game.interact_button.visible=true
		if room==3:game.cleared_room=true;game.combat_ui();game.world.refresh_gate()
		await capture("13_mine_room_%d"%room)
	game.start_dungeon(2);game.room=4;game.spawn_room();game.combat_ui()
	var boss=game.enemies[0];game.player.position=Vector2(795,480);boss.cooldown=0;boss.tick(.017);game.world.tick(.017)
	await capture("14_garron_warning")
	boss.hp=boss.max_hp*.5;boss.tick(.017);boss.state="idle";boss.cooldown=0;boss.tick(.017);game.world.tick(.017);game.update_hud()
	await capture("15_garron_phase_II")
	game.progress.d.inventory.append("R_0");game.progress.d.equipped.relic="R_0";game.guard_charge=5;game.player.state="guard";game.player.queue_redraw()
	await capture("16_varek_guard_relic")
	game.progress.d.run={};game.progress.d.cleared=[0,1,2]
	game.progress.switch_hero("maela");game.start_dungeon(3)
	game.player.request_skill(0);await capture("06_mage")
	game.progress.d.run={};game.progress.d.cleared=[0,1,2,3,4,5]
	game.progress.switch_hero("neris");game.start_dungeon(6)
	game.player.request_attack();await capture("07_ranger")
	game.progress.d.cleared=[0,1,2,3,4,5]
	game.progress.d.hub.forge=2
	game.progress.d.hub.sanctuary=2
	game.show_hub();await capture("08_hub_recovered")
	game.show_journal();await capture("09_journal")
	game.previous_screen="hub";game.show_inventory();await capture("10_inventory")
	game.show_forge();await capture("11_forge")
	game.show_buildings();await capture("12_camp_upgrades")
	game.queue_free();await process_frame
	quit()
