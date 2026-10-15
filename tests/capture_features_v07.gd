extends SceneTree

var output_dir="/tmp/dungeons-fires-v070"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):output_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("run")

func capture(name: String) -> void:
	for i in range(5):await process_frame
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	if image==null or image.get_width()<1000:push_error("No rendered framebuffer: "+name);return
	var path=output_dir.path_join(name+".png")
	if image.save_png(path)!=OK:push_error("Could not save capture: "+path);return
	print("FEATURE_CAPTURE: "+path)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Visual validation requires a real rendering display (Xvfb is supported).")
		quit(1);return
	DirAccess.make_dir_recursive_absolute(output_dir)
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://capture_features_v07.json")
	game.progress.d.settings.sound=false;game.progress.d.tutorial=true
	game.progress.d.cleared=[0,1,2,3,4,5,6,7,8]
	game.start_dungeon(1)
	for enemy in game.enemies:
		if is_instance_valid(enemy):enemy.queue_free();game.actors.remove_child(enemy)
	game.enemies.clear()
	var kinds=["ash_hound","bell_wraith","bone_sentinel","cinder_acolyte","glass_stalker"]
	var positions=[Vector2(520,480),Vector2(650,500),Vector2(780,480),Vector2(910,500),Vector2(1040,480)]
	for i in range(kinds.size()):
		var enemy=game.spawn_mob(kinds[i],positions[i],110,12,i==2)
		enemy.cooldown=20;enemy.size_scale=1.55 if i==2 else 1.38
	game.player.position=Vector2(250,500);game.update_hud()
	await capture("01_novos_mobs")
	game.show_preparation(1);game.show_contracts(1);await capture("02_contratos")
	game.start_dungeon(1);game.cleared_room=true;game.route_step="choose";game.show_route_choice();await capture("03_escolha_de_rota")
	game.choose_hunt_route();await capture("04_bencoes_builds")
	game.progress.d.camp_survivors=["tomas_bellkeeper","nara_channel_guide","elin_glasswright"]
	game.progress.d.camp_projects=["supply_cache","hunter_lodge"]
	game.show_camp_projects();await capture("05_projetos_refugio")
	game.queue_free();await process_frame;quit()
