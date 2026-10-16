extends SceneTree

var failures: Array = []
var checks: int = 0
var game

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func reset_hero(pos: Vector2) -> void:
	game.player.position = pos
	game.player.hp = game.player.max_hp
	game.player.invuln = 0
	game.player.state = "idle"
	game.player.slowed = 0
	game.world.projectiles.clear()

func advance(actor: DFActor, seconds: float) -> void:
	for i in range(int(ceil(seconds*120))):
		game.player.invuln = maxf(0,game.player.invuln-1.0/120)
		actor.tick(1.0/120)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate(); root.add_child(game); await process_frame
	game.set_physics_process(false)
	game.progress = DFProgress.new(DFContent.new(),"user://mobs_v071_qa.json")
	game.progress.d.settings.sound = false
	game.start_dungeon(1)
	game.room_layout.definition = {}; game.room_layout.obstacles.clear()
	for e in game.enemies:
		e.queue_free(); game.actors.remove_child(e)
	game.enemies.clear()
	reset_hero(Vector2(660,480))
	var stalker: DFActor = game.spawn_mob("glass_stalker",Vector2(600,480),120,12)
	stalker.facing = 1; stalker.cooldown = 10
	stalker.start_action("attack","enemy",1.05)
	advance(stalker,.30)
	var first_hp: float = game.player.hp
	check(first_hp < game.player.max_hp and not stalker.second_swing_done,"stalker first cut lands before the second")
	advance(stalker,.56)
	check(stalker.second_swing_done and game.player.hp < first_hp,"second cut deals independent damage after hero invulnerability")
	var two_cut_hp: float = game.player.hp
	advance(stalker,.17)
	check(game.player.hp == two_cut_hp,"second cut fires only once")
	reset_hero(Vector2(660,480)); stalker.position = Vector2(600,480)
	stalker.start_action("attack","enemy",1.05); advance(stalker,.30)
	game.player.position = Vector2(800,530); first_hp = game.player.hp
	advance(stalker,.56)
	check(game.player.hp == first_hp,"moving away avoids the second cut")
	reset_hero(Vector2(660,480)); stalker.position = Vector2(600,480)
	stalker.start_action("attack","enemy",1.05); advance(stalker,.30)
	stalker.invuln=0; stalker.hurt(1,Vector2.ZERO,game.player.position)
	first_hp=game.player.hp; advance(stalker,.60)
	check(game.player.hp == first_hp and not stalker.second_swing_done,"interrupting stalker cancels the pending cut")
	reset_hero(Vector2(740,480))
	var hound: DFActor = game.spawn_mob("ash_hound",Vector2(600,480),100,12)
	hound.aim=game.player.position; hound.start_action("windup","enemy",.7)
	var committed: Vector2 = hound.leap_direction
	game.player.position=Vector2(540,550)
	hound.start_action("attack","enemy",.48); advance(hound,.47)
	check(hound.leap_direction==committed and hound.position.x>=600 and hound.position.x<=741,"hound commits to original direction and stops at destination")
	check(game.player.hp==game.player.max_hp,"dodging away avoids the committed leap")
	advance(hound,.03)
	check(hound.state=="recover","hound exposes a recovery window")
	reset_hero(Vector2(650,480))
	var acolyte: DFActor=game.spawn_mob("cinder_acolyte",Vector2(900,480),100,12)
	acolyte.aim=game.player.position; game.enemy_strike(acolyte)
	check(game.world.projectiles.back().target==Vector2(650,480),"acolyte projectile retains marked ground target")
	game.player.position=Vector2(710,480)
	game.world.tick(.66)
	check(game.player.hp==game.player.max_hp and game.world.projectiles.is_empty(),"ground fire misses after moving outside blast")
	check(not game.world.effects.is_empty(),"ground fire still explodes when it misses the hero")
	reset_hero(Vector2(650,480)); acolyte.aim=game.player.position; game.enemy_strike(acolyte)
	game.player.position=Vector2(690,480); game.world.tick(.66)
	check(game.player.hp<game.player.max_hp,"ground fire damages inside AoE without direct projectile collision")
	reset_hero(Vector2(650,480)); acolyte.aim=game.player.position; game.enemy_strike(acolyte)
	game.player.invuln=1; game.world.tick(.66)
	check(game.player.hp==game.player.max_hp,"dodge invulnerability avoids ground fire")
	reset_hero(Vector2(650,480))
	var wraith: DFActor=game.spawn_mob("bell_wraith",Vector2(750,480),100,12)
	wraith.cooldown=10; wraith.tick_enemy(.1)
	check(wraith.position.x>750,"wraith really retreats at close range")
	game.world.missile(game.player.position,Vector2.ZERO,10,false,Color.CYAN,false,"spectral",0,true)
	game.player.invuln=1; game.world.tick(.01)
	check(game.player.slowed==0,"invulnerable hero is not slowed by spectral bolt")
	game.player.invuln=0
	game.world.missile(game.player.position,Vector2.ZERO,10,false,Color.CYAN,false,"spectral",0,true)
	game.world.tick(.01)
	check(game.player.slowed>0,"spectral bolt slows after a successful hit")
	var bone: DFActor=game.spawn_mob("bone_sentinel",Vector2(850,480),160,12)
	bone.facing=1; bone.aim=Vector2(920,480); bone.start_action("windup","enemy",1.05)
	bone.hurt(15,Vector2.ZERO,Vector2(920,480)); var front_loss: float=bone.max_hp-bone.hp
	check(bone.state=="windup","front guard protects sentinel attack preparation from interruption")
	bone.hp=bone.max_hp; bone.invuln=0; bone.hurt(15,Vector2.ZERO,Vector2(780,480))
	check(bone.state=="hurt" and bone.max_hp-bone.hp>front_loss,"rear hit breaks sentinel preparation and deals more damage")
	print(JSON.stringify({"suite":"mob_patterns_v071","checks":checks,"failures":failures}))
	game.queue_free(); await process_frame; quit(0 if failures.is_empty() else 1)
