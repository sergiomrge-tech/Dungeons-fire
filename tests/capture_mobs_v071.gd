extends SceneTree

var output_dir: String = "/tmp/dungeons-mobs-v071"
var game

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): output_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("run")

func capture(name: String) -> void:
	game.world.queue_redraw(); game.world.overlay.queue_redraw(); game.world.vfx.redraw()
	for e in game.enemies: e.queue_redraw()
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	if image == null or image.get_width() < 1000:
		push_error("Framebuffer unavailable"); quit(1); return
	if image.save_png(output_dir.path_join(name+".png")) != OK:
		push_error("Capture write failed"); quit(1); return
	print("MOB_CAPTURE: "+name)

func clear_enemies() -> void:
	for e in game.enemies:
		game.actors.remove_child(e); e.queue_free()
	game.enemies.clear(); game.world.projectiles.clear(); game.world.effects.clear(); game.world.vfx.reset()

func run() -> void:
	if DisplayServer.get_name()=="headless": push_error("Real display required");quit(1);return
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://capture_mobs_v071.json")
	game.progress.d.settings.sound=false; game.progress.d.tutorial=true; game.start_dungeon(1)
	clear_enemies(); game.player.position=Vector2(300,490)
	var kinds: Array=["ash_hound","bell_wraith","bone_sentinel","cinder_acolyte","glass_stalker"]
	for i in range(kinds.size()):
		var e: DFActor=game.spawn_mob(kinds[i],Vector2(510+i*150,480),110,12)
		e.cooldown=20
	game.toast("Cinco mobs • ataques próprios, marcas de perigo e recuperação",10)
	await capture("01_cinco_mobs")
	clear_enemies(); game.player.position=Vector2(610,495)
	var acolyte: DFActor=game.spawn_mob("cinder_acolyte",Vector2(875,490),110,12)
	acolyte.aim=game.player.position; acolyte.facing=-1; acolyte.start_action("windup","enemy",1.08)
	game.toast("Acólito • a área laranja indica onde a explosão vai atingir",10)
	await capture("02_area_marcada")
	acolyte.start_action("attack","enemy",.55); game.enemy_strike(acolyte)
	game.player.position=Vector2(460,520)
	for i in range(40): game.world.tick(1.0/60)
	game.toast("Esquiva para fora da marca • explosão no destino original",10)
	await capture("03_explosao_evitada")
	clear_enemies(); game.player.position=Vector2(670,490)
	var stalker: DFActor=game.spawn_mob("glass_stalker",Vector2(610,490),110,12)
	stalker.facing=1; stalker.start_action("attack","enemy",1.05)
	for i in range(51):
		game.player.invuln=maxf(0,game.player.invuln-1.0/60); stalker.tick(1.0/60); game.world.tick(1.0/60)
	game.toast("Rastejante • segundo corte independente, com rastro violeta",10)
	game.update_hud(); await capture("04_segundo_corte")
	game.queue_free(); await process_frame; quit()
