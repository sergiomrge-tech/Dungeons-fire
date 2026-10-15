extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://combat_bot_save.json")
	game.progress.d.settings.sound=false
	var index=2 if "--garron" in OS.get_cmdline_user_args() else 0
	if index==2:
		game.progress.complete(0,{});game.progress.complete(1,{})
		game.progress.d.heroes.varek.level=5;game.progress.equip("W_sword_1")
	game.start_dungeon(index)
	var ticks=0;var dodges=0;var skills=0
	while game.screen in ["combat","route_choice","boon_draft"] and ticks<18000:
		ticks+=1
		if game.cleared_room:
			if game.screen=="route_choice":game.choose_safe_route()
			elif game.screen=="boon_draft" and not game.boon_offers.is_empty():game.select_route_boon(str(game.boon_offers[0]))
			else:game.next_room()
		var nearest: DFActor=null
		var distance=INF
		for a in game.enemies:
			if a.hp>0 and a.position.distance_to(game.player.position)<distance:
				nearest=a;distance=a.position.distance_to(game.player.position)
		if nearest!=null:
			var diff=nearest.position-game.player.position
			game.controls.axis=game.room_layout.direction(game.player.position,nearest.position) if game.room_layout.segment_blocked(game.player.position,nearest.position,14) else Vector2(signf(diff.x) if absf(diff.x)>63 else 0,signf(diff.y) if absf(diff.y)>18 else 0)
			game.player.facing=1 if diff.x>=0 else -1
			game.attack_held=absf(diff.x)<117 and absf(diff.y)<52
			if nearest.state=="windup" and nearest.timer<.25 and game.player.dodge_cd<=0:
				game.move_axis=Vector2(0,-1 if game.player.position.y>485 else 1);game.player.request_dodge();dodges+=1
			if distance<200 and game.player.skill_cd[0]<=0:game.player.request_skill(0);skills+=1
			if game.player.hp<game.player.max_hp*.6:game.use_potion()
		game._physics_process(1.0/60)
		if ticks%60==0:await process_frame
	var result={"won":game.screen=="result","seconds_simulated":ticks/60.0,"dodges":dodges,"skills":skills,"health":game.player.hp,"gold":game.progress.d.gold,"level":game.progress.hero_stats().level}
	print(JSON.stringify(result))
	game.queue_free();await process_frame
	call_deferred("quit",0 if result.won else 1)
