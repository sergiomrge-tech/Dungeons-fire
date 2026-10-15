extends SceneTree

var checks=0
var failures=[]
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false)
	game.progress=DFProgress.new(DFContent.new(),"user://first_region_v05.json");game.progress.d.settings.sound=false
	game.start_dungeon(0)
	var hero=game.player
	hero.request_attack();check(hero.combo==0,"combo begins with first strike")
	hero.timer=.10;hero.request_attack();check(hero.pending_attack,"late input buffered")
	hero.tick(.11);check(hero.combo==1 and hero.state=="attack","buffer chains second strike")
	hero.timer=.08;hero.request_attack();hero.tick(.09);check(hero.combo==2,"third strike reached")
	hero.state="idle";hero.combo_window=0;hero.request_attack();check(hero.combo==0,"combo resets after inactivity")
	game.room=1;game.spawn_room()
	check(game.room_layout.obstacles.size()==2,"rails contain two real obstacles")
	var original=Vector2(450,515)
	var result=game.move_actor(original,Vector2(250,0))
	check(result.x<500 and not game.room_layout.blocked(result),"dash cannot tunnel through cart")
	check(game.room_layout.segment_blocked(Vector2(450,515),Vector2(630,515)),"cart blocks attacks and missiles")
	var route=original
	for i in range(600):route=game.move_actor(route,game.room_layout.direction(route,Vector2(700,515))*2)
	check(route.distance_to(Vector2(700,515))<15,"navigation goes around cart without trapping")
	game.room=2;game.spawn_room();hero.position=Vector2(650,520)
	check(game.enemies.any(func(e):return e.elite),"storeroom elite has distinct durable encounter")
	var gold=game.loot.gold;game.interact_chest()
	check(game.loot.gold==gold+30 and game.room_events.has("MINE_CHEST_02"),"chest grants resources once")
	game.interact_chest();check(game.loot.gold==gold+30,"double touch does not duplicate chest")
	game.show_pause();game.resume_run();hero=game.player
	check(game.room_events.has("MINE_CHEST_02") and game.loot.gold==gold+30,"chest remains opened after resume")
	check(game.world.chest_nodes.MINE_CHEST_02.cell==1,"opened chest visual follows save")
	game.room=3;hero.hp=50;game.spawn_room()
	check(game.enemies.is_empty() and hero.hp>50,"rest room is safe and heals")
	var hp=hero.hp;game.save_run();game.resume_run();hero=game.player
	check(is_equal_approx(hero.hp,hp),"resume does not repeat rest heal")
	game.room=0;game.spawn_room();hero.state="idle";hero.invuln=0;hero.skill_cd[1]=0;hero.request_skill(1)
	var front=hero.position+Vector2(60,0);hero.facing=1;hp=hero.hp
	check(not hero.hurt(20,Vector2.ZERO,front) and hero.hp==hp,"perfect frontal guard blocks damage")
	hero.guard_age=.4;hero.hurt(20,Vector2.ZERO,front)
	check(hero.hp<hp and hero.hp>hp-5,"late frontal guard reduces damage")
	hero.state="guard";hero.guard_age=0;hero.invuln=0;hp=hero.hp
	hero.hurt(20,Vector2.ZERO,hero.position-Vector2(60,0))
	check(hero.hp<hp-10,"rear attack bypasses frontal guard")
	game.progress.d.inventory.append("R_0");game.progress.d.equipped.relic="R_0"
	hero.state="dodge";hero.invuln=.2;game.guard_charge=0;hero.hurt(20,Vector2.ZERO,front)
	check(game.guard_charge==0,"dodge never charges guard relic")
	hero.state="guard";hero.guard_age=0;hero.invuln=0;hero.hurt(20,Vector2.ZERO,front)
	check(game.guard_charge>0,"actual guarded hit charges relic")
	hero.state="idle";hero.position=game.enemies[0].position-Vector2(70,0);hero.facing=1
	game.player_strike(hero,"basic");check(game.guard_charge==0,"successful relic strike consumes charge")
	game.start_dungeon(2);game.room=4;game.spawn_room();hero=game.player
	var boss=game.enemies[0];hero.position=boss.position-Vector2(90,0);boss.cooldown=0;boss.tick(.017)
	check(boss.state=="windup" and boss.boss_profile.move=="cleave","Garron begins telegraphed cleave")
	check(DFBossPatterns.contains(boss.boss_profile,hero.position),"warning geometry contains target")
	check(not DFBossPatterns.contains(boss.boss_profile,hero.position+Vector2(0,120)),"safe depth lies outside warning")
	var fixed_aim: Vector2=boss.boss_profile.origin;hero.position.y+=80;boss.tick(.1)
	check(boss.boss_profile.origin==fixed_aim,"telegraph does not track escaping player")
	for i in range(130):boss.tick(1.0/60)
	check(boss.state=="recover" or boss.state=="idle","boss exposes recovery after attack")
	boss.hp=boss.max_hp*.54;boss.tick(.017)
	check(boss.boss_phase==2 and boss.state=="roar","55 percent health triggers announced phase II")
	game.save_run();game.resume_run();boss=game.enemies[0]
	check(boss.boss_phase==2 and boss.state=="idle","phase survives resume with safe restart")
	var seen=[]
	for i in range(8):
		var p=DFBossPatterns.profile("garron",2,i,Vector2(800,480),Vector2(700,480),-1)
		if not seen.has(p.move):seen.append(p.move)
	check(seen.size()==3,"Garron has three distinct attack patterns")
	var progress=DFProgress.new(DFContent.new(),"user://recipes_v05.json")
	check(not progress.recipe_unlocked("R_0"),"boss recipe starts locked")
	progress.complete(0,{});progress.complete(1,{});progress.complete(2,{})
	check(progress.recipe_unlocked("R_0") and progress.d.cores.CORE_0==1,"Garron grants unique material and recipe")
	progress.d.hub.forge=2;progress.d.gold=1000
	check(progress.buy_item("R_0") and progress.d.cores.CORE_0==0,"craft consumes unique boss material")
	progress.d.erase("recipes");progress.save()
	var restored=DFProgress.new(DFContent.new(),progress.path);restored.load_save()
	check(restored.recipe_unlocked("R_0"),"old saves migrate without losing recipe progress")
	print(JSON.stringify({"suite":"first_region_v05","checks":checks,"failures":failures}))
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
