class_name DFActor
extends Node2D

var game
var kind: String = "varek"
var is_player: bool = false
var boss: bool = false
var hp: float = 100
var max_hp: float = 100
var attack_power: float = 10
var defense: float = 0
var state: String = "idle"
var timer: float = 0
var duration: float = 0
var phase: float = 0
var facing: int = 1
var cooldown: float = 0
var invuln: float = 0
var dodge_cd: float = 0
var skill_cd: Array = [0.0,0.0]
var supreme: float = 0
var mana: float = 100
var slowed: float = 0
var anim_clock: float = 0
var swing_done: bool = false
var attack_kind: String = "basic"
var combo: int = -1
var combo_window: float = 0
var velocity: Vector2 = Vector2.ZERO
var rush_hit: bool = false
var boss_phase: int = 1
var boss_step: int = 0
var boss_profile: Dictionary = {}
var elite: bool = false
var guard_age: float = 0
var stagger_multiplier: float = 1
var hit_flash: float = 0
var recoil_offset: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var aim: Vector2 = Vector2.ZERO
var id: int = 0
var pending_attack: bool = false
var atlas: Texture2D
var size_scale: float = 1.35
var mob_profile: Dictionary = {}
var marked: float = 0
var route_reward: bool = false

func setup(owner_game, actor_kind: String, player: bool, life: float, damage: float, boss_actor: bool = false, mob_data: Dictionary = {}) -> void:
	game = owner_game; kind = actor_kind; is_player = player; boss = boss_actor
	hp = life; max_hp = life; attack_power = damage
	mob_profile = mob_data.duplicate(true)
	atlas = load("res://assets/%s.png" % kind)
	size_scale = 1.85 if boss else (1.35 if is_player else 1.25)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cooldown = .6+float(id%4)*.35

func start_action(name: String, action_type: String, seconds: float) -> void:
	rush_hit=false
	if name!="attack":pending_attack=false
	state = name; attack_kind = action_type; duration = seconds; timer = seconds; swing_done = false
	if game!=null and game.world!=null and game.world.vfx!=null:game.world.vfx.action_started(self,name,action_type,seconds)

func request_attack() -> void:
	if hp<=0: return
	if state in ["idle","run"]:
		combo = (combo+1)%3 if combo_window>0 else 0
		combo_window=1.1
		var seconds=[.34,.38,.52][combo]
		var family=game.db.item(game.progress.d.equipped.weapon).get("family","")
		if family=="hammer":seconds*=1.4
		elif family=="daggers":seconds*=.8
		start_action("attack","basic",seconds)
		game.play_sfx("blade_heavy" if combo==2 else "swing")
	elif state=="attack" and timer < .2:
		pending_attack = true

func request_dodge() -> void:
	if hp<=0 or dodge_cd>0 or not state in ["idle","run","attack"]: return
	start_action("dodge","dodge",.28)
	invuln = .20; dodge_cd = .85*(1.0-game.run_boon_total("dodge_cd_mult"))
	direction = game.move_axis if game.move_axis.length()>.1 else Vector2(facing,0)
	direction = direction.normalized()
	pending_attack = false

func request_skill(slot: int) -> void:
	if hp<=0 or skill_cd[slot]>0 or not state in ["idle","run"]: return
	if kind=="maela" and mana<25:
		game.toast("Mana insuficiente; ela recupera com o tempo.")
		return
	if kind=="maela": mana-=25
	var cooldown_scale = 1.0 - game.run_boon_total("skill_cd_mult")
	skill_cd[slot] = (5.0 if slot==0 else 9.0) * cooldown_scale
	if kind=="varek" and slot==1:
		start_action("guard","guard",.85);guard_age=0;velocity=Vector2.ZERO
		game.play_sfx("shield");return
	start_action("cast","skill%d" % slot,.62)
	game.play_sfx("magic")

func request_supreme() -> void:
	if supreme<100 or hp<=0 or not state in ["idle","run"]: return
	supreme = 0
	start_action("cast","supreme",.85)
	invuln = .65
	game.play_sfx("magic")

func tick(delta: float) -> void:
	anim_clock += delta
	hit_flash=maxf(0,hit_flash-delta)
	recoil_offset=recoil_offset.lerp(Vector2.ZERO,minf(1,delta*18))
	combo_window=maxf(0,combo_window-delta)
	marked=maxf(0,marked-delta)
	if boss and kind=="garron" and boss_phase==1 and hp>0 and hp<=max_hp*.55:
		boss_phase=2;boss_profile={};start_action("roar","roar",1.1);cooldown=1.2
		game.toast("Garron • Fase II: investidas mais rápidas. Ataque após o impacto.",4)
	cooldown = maxf(0,cooldown-delta)
	invuln = maxf(0,invuln-delta)
	dodge_cd = maxf(0,dodge_cd-delta)
	slowed = maxf(0,slowed-delta)
	for i in range(2): skill_cd[i] = maxf(0,skill_cd[i]-delta)
	mana = minf(100,mana+delta*9)
	if state=="death":
		timer = maxf(0,timer-delta); queue_redraw(); return
	if state in ["attack","cast","dodge","hurt","windup","guard","recover","roar"]:
		timer -= delta
		if state=="dodge": position=game.move_actor(position,direction*530*delta)
		if not is_player and mob_profile.get("special", "") == "leap" and state == "attack" and not rush_hit:
			var pounce = (aim-position).normalized()
			position = game.move_actor(position, pounce * 390 * delta)
			if game.player.position.distance_to(position) < 48:
				rush_hit = true
				game.player.hurt(attack_power, Vector2(pounce.x*20,-3), position)
				game.world.fx(position-Vector2(0,22),52,Color("ef8650"),.34)
		if state=="guard":guard_age+=delta
		if is_player and state=="cast" and kind=="varek" and attack_kind=="skill0" and timer>duration*.50:
			position=game.move_actor(position,Vector2(facing*270,0)*delta)
		if boss and state=="attack" and not boss_profile.is_empty() and boss_profile.move=="rush":
			position=game.move_actor(position,Vector2(facing*boss_profile.travel/duration,0)*delta)
			if not rush_hit and game.player!=null and absf(game.player.position.x-position.x)<45 and absf(game.player.position.y-position.y)<36:
				rush_hit=true;game.player.hurt(attack_power*boss_profile.damage,Vector2(facing*18,0),position)
		if state=="windup" and timer<=0:
			start_action("attack","enemy",float(boss_profile.attack_time) if not boss_profile.is_empty() else .55)
		elif state in ["attack","cast"] and not swing_done and timer<duration*.55:
			swing_done = true
			if is_player: game.player_strike(self,attack_kind)
			elif mob_profile.get("special", "") != "leap": game.enemy_strike(self)
		if timer<=0:
			if boss and state=="attack" and not boss_profile.is_empty():
				start_action("recover","recover",boss_profile.recovery);cooldown=maxf(cooldown,timer+.25)
			else:state = "idle"
			if is_player and pending_attack:
				pending_attack = false; request_attack()
	else:
		if is_player: tick_player(delta)
		else: tick_enemy(delta)
	position.x = clampf(position.x,70,1210)
	position.y = clampf(position.y,410,557)
	z_index = int(position.y)
	queue_redraw()

func tick_player(delta: float) -> void:
	var axis: Vector2 = game.move_axis
	state = "run" if axis.length()>.1 else "idle"
	if axis.length()>.1:
		if absf(axis.x)>.1: facing = 1 if axis.x>0 else -1
		velocity=velocity.move_toward(Vector2(axis.x,axis.y*.70)*285*(.70 if slowed>0 else 1.0),delta*2400)
		position=game.move_actor(position,velocity*delta)
		if int(anim_clock*7)%4==0 and game.step_timer<=0:
			game.step_timer=.23; game.play_sfx("step")
	else:
		velocity=velocity.move_toward(Vector2.ZERO,delta*3200)
		position=game.move_actor(position,velocity*delta)
	if game.attack_held: request_attack()

func tick_enemy(delta: float) -> void:
	if game.player==null or game.player.hp<=0: return
	var diff: Vector2 = game.player.position-position
	facing = 1 if diff.x>=0 else -1
	var ranged = bool(mob_profile.get("ranged",kind in ["archer","sereia","severan"]))
	var reach = float(mob_profile.get("reach",115.0 if boss else 77.0))
	if ranged: reach = maxf(reach,220)
	if absf(diff.x)<reach and absf(diff.y)<45 and cooldown<=0 and game.windup_count()<3:
		aim = game.player.position
		if boss and kind in ["garron","brute"]:
			boss_profile=DFBossPatterns.profile(kind,boss_phase,boss_step,position,aim,facing);boss_step+=1
			start_action("windup","enemy",boss_profile.windup)
		else:start_action("windup","enemy",float(mob_profile.get("windup",.70 if not boss else 1.0)))
		cooldown = (1.5 if not boss else 1.7)+float(id%3)*.15
	else:
		var target = diff
		if ranged and absf(diff.x)<180: target.x = -diff.x
		if absf(diff.x)<reach and absf(diff.y)<28: target = Vector2.ZERO
		state = "run" if target.length()>5 else "idle"
		if target.length()>5:
			var speed = (65.0 if boss else float(mob_profile.get("speed",94.0))) * (.55 if slowed>0 else 1.0)
			var nav=game.room_layout.direction(position,position+target)
			position=game.move_actor(position,Vector2(nav.x,nav.y*.8)*speed*delta)

func hurt(amount: float, push: Vector2 = Vector2.ZERO, source: Vector2 = Vector2.INF) -> bool:
	if hp<=0:return false
	if invuln>0:return false
	if is_player and state=="guard" and source!=Vector2.INF and (source.x-position.x)*facing>=-8:
		game.play_sfx("shield");game.world.vfx.parry(self)
		if game.relic_effect()=="guard":game.guard_charge=5.0
		if guard_age<=.20:
			game.toast("Defesa perfeita!" if game.guard_charge<=0 else "Marca do Portão pronta • próximo golpe rompe a postura",1.3)
			return false
		amount*=.2
	var received = maxf(1,amount*100/(100+defense))
	if not is_player and kind=="bone_sentinel" and mob_profile.get("special", "")=="frontal_guard" and state not in ["attack","recover","hurt"] and source!=Vector2.INF and (source.x-position.x)*facing>=-8:
		received *= .48
	if not is_player and marked>0:
		received *= 1.18
	if is_player and game.relic_effect()=="resist":received*=.9
	if is_player and game.progress.d.settings.story_mode: received *= .6
	hp = maxf(0,hp-received)
	hit_flash=.10;recoil_offset=Vector2(push.x*.45,-3)
	game.world.vfx.impact(self,source,received>max_hp*.15)
	game.damage_text(position-Vector2(0,100),int(received),is_player)
	game.play_sfx("impact")
	position=game.move_actor(position,push)
	if hp<=0:
		start_action("death","death",.7)
		if not is_player: game.on_enemy_dead(self)
		else: game.on_player_dead()
	else:
		if not boss:
			start_action("hurt","hurt",.19); invuln=.12
		else:
			phase += received*stagger_multiplier
			stagger_multiplier=1
			if phase>max_hp*.20:
				phase=0; start_action("hurt","hurt",.85);boss_profile={}
				game.toast("Postura quebrada • contra-ataque!",1.0)
		if is_player: invuln=.4; game.shake_timer=.13
	return true

func snapshot() -> Dictionary:
	return {"id":id,"kind":kind,"boss":boss,"hp":hp,"max_hp":max_hp,"attack":attack_power,"x":position.x,"y":position.y,"facing":facing,"boss_phase":boss_phase,"boss_step":boss_step,"elite":elite,"route_reward":route_reward,"marked":marked,"slowed":slowed}

func _draw() -> void:
	if atlas==null: return
	var fade = clampf(timer/.7,0,1) if state=="death" else 1.0
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.30))
	draw_circle(Vector2.ZERO,23*size_scale,Color(0,0,0,.30*fade))
	draw_set_transform(Vector2.ZERO)
	if state=="run" and int(anim_clock*12.0)%4 < 2:
		var dust: Color = Color(.85,.81,.72,.22)
		draw_circle(Vector2(-facing*18,-3),5.0*size_scale,dust)
		draw_circle(Vector2(-facing*30,-6),3.0*size_scale,Color(.91,.85,.73,.13))
	if is_player and game.guard_charge>0:
		draw_arc(Vector2(0,-56),62,0,TAU,36,Color(1,.77,.29,.55),2,true)
	if elite:
		draw_arc(Vector2.ZERO,33,0,TAU,32,Color(.9,.63,1,.6),2)
	if marked>0 and hp>0:
		draw_arc(Vector2(0,-46),30,anim_clock*2,anim_clock*2+PI*1.6,28,Color(.77,.58,1,.72),2.4,true)
	if state=="windup" and boss_profile.is_empty():
		var warn = Color(1,.36,.17,.45+sin(anim_clock*14)*.15)
		draw_arc(Vector2.ZERO,60 if boss else 43,0,TAU,32,warn,4)
		draw_line(Vector2.ZERO,(aim-position).normalized()*95,warn,4)
	var aura_colors={"ash_hound":Color("ff9d48"),"bell_wraith":Color("7bdcff"),"bone_sentinel":Color("d4e4f4"),"cinder_acolyte":Color("ff784b"),"glass_stalker":Color("c384ff")}
	if aura_colors.has(kind) and hp>0:
		var aura: Color=aura_colors[kind];aura.a=.12+.06*sin(anim_clock*5)
		draw_circle(Vector2(0,-54),15+sin(anim_clock*4)*2,aura)
	var frame = visual_frame()
	var tint = Color(1.55,1.35,1.10) if hit_flash>0 else Color.WHITE
	if invuln>0 and state=="hurt" and hit_flash<=0: tint=Color(1,.6,.55)
	tint.a = fade
	var pose=pose_transform()
	if state=="death":pose.rotation=(1.0-fade)*PI/2
	draw_set_transform(pose.offset+recoil_offset,pose.rotation*facing,Vector2(facing*pose.scale.x,pose.scale.y))
	if state=="dodge":
		for ghost_index in range(3,0,-1):
			var ghost_color: Color = Color(.79,.90,1.0,(4-ghost_index)*.085*fade)
			draw_texture_rect_region(atlas,Rect2(-48*size_scale-ghost_index*direction.x*18,-90*size_scale-ghost_index*direction.y*10,96*size_scale,96*size_scale),Rect2(2*192,0,192,192),ghost_color)
	draw_texture_rect_region(atlas, Rect2(-48*size_scale,-90*size_scale,96*size_scale,96*size_scale), Rect2(frame*192,0,192,192), tint)
	draw_set_transform(Vector2.ZERO)
	if not is_player and hp>0 and game.screen=="combat":
		var w = 85 if boss else 54
		var bar_y=-96*size_scale
		draw_rect(Rect2(-w/2.0-1,bar_y-1,w+2,7),Color("304660"))
		draw_rect(Rect2(-w/2.0,bar_y,w,5),Color("e8eaf0"))
		draw_rect(Rect2(-w/2.0,bar_y,w*hp/max_hp,5),Color("ce5b70"))
		if kind in ["ash_hound","bell_wraith","bone_sentinel","cinder_acolyte","glass_stalker"] or elite:
			var name=str(mob_profile.get("name",kind.capitalize()))
			var text_width=game.world.font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
			draw_string_outline(game.world.font,Vector2(-text_width/2,bar_y-8),name,HORIZONTAL_ALIGNMENT_LEFT,-1,11,3,Color("241e18"))
			draw_string(game.world.font,Vector2(-text_width/2,bar_y-8),name,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3e3c0"))

func pose_transform() -> Dictionary:
	var offset=Vector2(0,sin(anim_clock*3)*.7)
	var rotation=0.0
	var scale=Vector2.ONE
	var t=clampf(1-timer/maxf(duration,.001),0,1)
	if state=="run":
		offset.y=-absf(sin(anim_clock*12))*2
		rotation=sin(anim_clock*12)*.012
	elif state=="attack":
		var winding=sin(clampf(t/.42,0,1)*PI/2)
		var release=sin(clampf((t-.38)/.20,0,1)*PI/2)
		var settle=1-pow(clampf((t-.58)/.42,0,1),.65)
		var weight=1.0 if combo<2 else 1.45
		offset.x=facing*((-3*winding+12*release)*settle)*weight
		rotation=(-.055*winding+.13*release)*settle*weight
		if combo==1:rotation*=-.7;offset.y=-sin(t*PI)*2.5
		scale=Vector2(1+.018*release*settle,1-.012*release*settle)
	elif state=="cast":
		if kind=="varek":offset=Vector2(facing*sin(t*PI)*8,-sin(t*PI)*2);rotation=sin(t*PI)*.08
		else:offset.y=-sin(t*PI)*4;rotation=-.035*sin(t*PI)
	elif state=="guard":rotation=-.035;offset.x=-facing*2
	elif state=="dodge":rotation=.22;offset.y=7
	elif state=="hurt":rotation=-.10*minf(1,timer/.12)
	return {"offset":offset,"rotation":rotation,"scale":scale}

func visual_frame() -> int:
	# Eight authored poses per character/weapon; timing follows actual hit windows.
	match state:
		"run": return [1, 2, 3, 2][int(anim_clock * 10) % 4]
		"windup": return 4
		"attack":
			var t = 1.0 - timer / maxf(duration, .01)
			return 4 if t < .42 else (5 if t < .72 else 6)
		"cast": return (4 if timer>duration*.55 else 5) if kind=="varek" else 7
		"roar": return 7
		"guard": return 4
		"recover","hurt": return 6
		"dodge": return [1, 2, 3][clampi(int((1.0-timer/maxf(duration,.01))*3),0,2)]
	return 0
