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
	for region in range(5):
		game.start_dungeon(region*3)
		await capture("05_combat_region_%d"%region)
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
