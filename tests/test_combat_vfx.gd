extends SceneTree
var checks=0
var failures=[]
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text);push_error(text)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false);game.progress=DFProgress.new(DFContent.new(),"user://combat_vfx_v06.json");game.progress.d.settings.sound=false
	game.start_dungeon(0)
	var vfx=game.world.vfx;var hero=game.player
	check(vfx.lights.size()==6 and vfx.lights.all(func(l):return l is PointLight2D and not l.shadow_enabled),"six pooled native lights without expensive shadows")
	hero.position=Vector2(550,480);var target=game.enemies[0];target.position=Vector2(710,480);target.cooldown=100
	var hp=target.hp;hero.request_skill(0)
	check(vfx.effects.any(func(e):return e.kind=="charge"),"skill emits anticipation light before contact")
	hero.tick(.10);game.world.tick(.10)
	check(target.hp==hp,"charge does not deal damage before hit window")
	check(vfx.lights.any(func(l):return l.enabled and l.energy>0),"skill activates actual light on game canvas")
	hero.tick(.20);game.world.tick(.20)
	check(target.hp<hp and hero.swing_done,"real contact triggers damage")
	check(vfx.effects.any(func(e):return e.kind=="slash") and vfx.effects.any(func(e):return e.kind=="impact"),"swing and confirmed hit produce different effects")
	check(vfx.live_particle_count()>0,"confirmed hit emits moving particles")
	var moving=vfx.particles.filter(func(p):return p.active)[0]
	var old_pos: Vector2=moving.pos
	var life=target.hp;hero.tick(.1);game.world.tick(.1)
	check(moving.pos!=old_pos,"particles integrate velocity/gravity over time")
	check(target.hp==life,"effect lifetime cannot duplicate attack damage")
	hero.state="idle";hero.skill_cd[1]=0;hero.invuln=0;hero.request_skill(1)
	check(vfx.effects.any(func(e):return e.kind=="shield"),"guard displays a shield tied to its active state")
	hero.hurt(20,Vector2.ZERO,hero.position+Vector2(50,0))
	check(vfx.effects.any(func(e):return e.kind=="parry"),"valid frontal guard produces impact flare")
	hero.state="idle";vfx.tick(.01)
	check(not vfx.effects.any(func(e):return e.kind=="shield"),"shield disappears on guard cancellation")
	var combo_poses=[]
	for combo in range(3):
		hero.combo=combo;hero.start_action("attack","basic",.5);hero.timer=.23
		combo_poses.append(hero.pose_transform())
	check(combo_poses[0].rotation!=combo_poses[1].rotation and combo_poses[2].offset.x>combo_poses[0].offset.x,"three combo strikes use different weight/direction")
	for state in ["attack","cast","guard","hurt","dodge","run"]:
		hero.state=state
		for t in [.0,.2,.45,.7,1.0]:
			hero.timer=hero.duration*(1-t);var pose=hero.pose_transform()
			check(pose.offset.is_finite() and pose.scale.x>.97 and pose.scale.x<1.04 and pose.scale.y>.97,"bounded pose transformation "+state)
	var colors=[]
	for kind in ["varek","maela","neris"]:
		game.progress.d.hero=kind;game.progress.d.equipped.weapon={"varek":"W_sword_0","maela":"W_staff_0","neris":"W_bow_0"}[kind]
		game.start_dungeon(0);hero=game.player;vfx.reset()
		game.player_strike(hero,"skill1" if kind!="varek" else "supreme")
		check(vfx.effects.any(func(e):return e.kind=="nova"),"distinct hero area effect "+kind)
		colors.append(vfx.color_for(hero))
		if kind!="varek":
			game.player_strike(hero,"basic")
			check(game.world.projectiles[0].style==("ember" if kind=="maela" else "arrow"),"projectile identity "+kind)
	check(colors[0]!=colors[1] and colors[1]!=colors[2],"each hero has a separate readable palette")
	var actor_count=vfx.get_child_count();var health=game.enemies[0].hp
	for i in range(1000):vfx.emit("impact",Vector2(400,430),Color.WHITE,50,.3)
	check(vfx.particles.size()==240 and vfx.live_particle_count()<=240,"fixed particle pool remains bounded during stress")
	check(vfx.effects.size()<=DFCombatVFX.MAX_EFFECTS,"heavy bursts respect hard live-effect cap")
	vfx.tick(.01)
	check(vfx.lights.size()==6 and vfx.get_child_count()==actor_count,"bursts reuse lights rather than growing node count")
	check(game.enemies[0].hp==health,"visual-only bursts never change health")
	vfx.tick(5)
	check(vfx.effects.is_empty() and vfx.live_particle_count()==0,"all visual effects and particles expire")
	game.world.projectiles.clear();vfx.tick(.01)
	check(vfx.lights.all(func(l):return not l.enabled),"no light remains after effects and missiles expire")
	game.world.missile(Vector2(180,550),Vector2(100,0),1,true,Color("63edb1"))
	for i in range(20):game.world.tick(1.0/60)
	check(game.world.projectiles[0].trail.size()==8,"projectile history has fixed length")
	game.save_run();check(game.progress.valid(game.progress.d),"transient light/weak references stay out of save")
	game.show_hub();check(vfx.effects.is_empty() and vfx.lights.all(func(l):return not l.enabled),"hub transition clears all combat lights")
	print(JSON.stringify({"suite":"combat_vfx_v06","checks":checks,"failures":failures}))
	game.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
