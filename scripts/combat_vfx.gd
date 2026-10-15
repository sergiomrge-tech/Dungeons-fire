class_name DFCombatVFX
extends Node2D
# Native animated ribbons and pooled lighting; no full-screen flash or bloom dependency.
const MAX_EFFECTS=36
const MAX_LIGHTS=6
const MAX_PARTICLES=240
const PALETTES={"varek":Color("ffab43"),"maela":Color("9b91ff"),"neris":Color("63edb1")}
var game
var effects: Array=[]
var particles: Array=[]
var particle_cursor: int=0
var lights: Array[PointLight2D]=[]
var ground: Node2D
var glow: Node2D
var debris: Node2D
var serial: int=0
var light_texture: GradientTexture2D

func _ready() -> void:
	for i in range(MAX_PARTICLES):particles.append({"active":false})
	var additive=CanvasItemMaterial.new();additive.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;additive.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ground=Node2D.new();ground.z_index=4;ground.material=additive;add_child(ground);ground.draw.connect(draw_ground)
	debris=Node2D.new();debris.z_index=938;add_child(debris);debris.draw.connect(draw_debris)
	glow=Node2D.new();glow.z_index=945;glow.material=additive;add_child(glow);glow.draw.connect(draw_glow)
	var gradient=Gradient.new();gradient.offsets=PackedFloat32Array([0,.18,.48,1]);gradient.colors=PackedColorArray([Color.WHITE,Color(1,1,1,.72),Color(1,1,1,.20),Color(1,1,1,0)])
	light_texture=GradientTexture2D.new();light_texture.width=128;light_texture.height=128;light_texture.fill=GradientTexture2D.FILL_RADIAL;light_texture.fill_from=Vector2(.5,.5);light_texture.fill_to=Vector2(1,.5);light_texture.gradient=gradient
	for i in range(MAX_LIGHTS):
		var lamp=PointLight2D.new();lamp.texture=light_texture;lamp.enabled=false;lamp.shadow_enabled=false;lamp.range_z_max=900;lamp.range_layer_min=0;lamp.range_layer_max=0
		add_child(lamp);lights.append(lamp)

func reset() -> void:
	effects.clear()
	for particle in particles:particle.active=false
	for lamp in lights:lamp.enabled=false
	redraw()

func color_for(actor) -> Color:
	return PALETTES.get(actor.kind,Color("fa7150"))

func emit(kind: String, pos: Vector2, color: Color, radius: float, life: float, facing: int = 1, variant: int = 0, light: float = .25, follow = null) -> Dictionary:
	serial+=1
	var effect={"kind":kind,"pos":pos,"color":color,"radius":radius,"life":life,"age":0.0,"facing":facing,"variant":variant,"light":light,"seed":serial,"follow":weakref(follow) if follow!=null else null,"offset":pos-follow.position if follow!=null else Vector2.ZERO,"emit_time":0.0}
	if effects.size()>=MAX_EFFECTS:effects.pop_front()
	effects.append(effect);burst_for(effect);redraw();return effect

func particle_style(color: Color) -> String:
	return "shard" if color.b>color.r*1.3 else ("leaf" if color.g>color.r*1.3 else "ember")

func spawn_particles(style: String, pos: Vector2, color: Color, count: int, force: float, facing: int = 0) -> void:
	for i in range(count):
		var particle: Dictionary=particles[particle_cursor%MAX_PARTICLES];particle_cursor+=1
		var seed=float(particle_cursor)*2.399963
		var angle=seed if facing==0 else (0.0 if facing>0 else PI)+sin(seed)*1.0
		var speed=force*(.45+.55*absf(sin(seed*1.73)))
		var velocity=Vector2(cos(angle)*speed,sin(angle)*speed*.7-40)
		var gravity=240.0
		var life=.3+fposmod(seed,.35)
		var size=2.0+fposmod(seed,3.0)
		if style=="ember":velocity.y=-45-speed*.25;gravity=-22;life=.65;size=2.2
		elif style=="smoke":velocity*=.12;velocity.y=-24;gravity=-8;life=.7;size=14+fposmod(seed,18)
		elif style=="leaf":gravity=35;life=.58;size=4.5
		elif style=="shard":life=.48;size=4+fposmod(seed,4)
		particle.merge({"active":true,"style":style,"pos":pos,"velocity":velocity,"gravity":gravity,"life":life,"age":0.0,"color":color,"size":size,"angle":seed,"spin":sin(seed)*8},true)

func burst_for(e: Dictionary) -> void:
	var style=particle_style(e.color)
	match e.kind:
		"impact":
			spawn_particles("spark",e.pos,e.color,9,220,e.facing)
			spawn_particles(style,e.pos,e.color,5,120)
		"parry":spawn_particles("spark",e.pos,e.color,19,270,e.facing)
		"slash":spawn_particles(style,e.pos+Vector2(e.facing*e.radius*.6,0),e.color,6,125,e.facing)
		"muzzle":spawn_particles(style,e.pos,e.color,5,100,e.facing)
		"charge":spawn_particles(style,e.pos,e.color,7,55)
		"pillar":spawn_particles(style,e.pos-Vector2(0,35),e.color,8,140)
		"nova":
			spawn_particles(style,e.pos-Vector2(0,22),e.color,28,300)
			spawn_particles("spark",e.pos-Vector2(0,20),e.color,14,360)
			if style=="ember":spawn_particles("smoke",e.pos,Color("a88665"),5,160)
		"slam":
			spawn_particles("stone",e.pos,Color("aa8969"),14,260)
			spawn_particles("spark",e.pos,e.color,16,310)
			spawn_particles("smoke",e.pos,Color("987659"),7,240)

func action_started(a, state: String, action: String, seconds: float) -> void:
	if not a.is_player:
		if state=="roar":emit("nova",a.position,Color("ff7040"),160,.7,a.facing,3,.32)
		return
	var color=color_for(a)
	if state=="guard":emit("shield",a.position-Vector2(0,52),color,56,seconds,a.facing,0,.14,a)
	elif state=="cast":
		emit("charge",a.position-Vector2(0,65),color,66 if action!="supreme" else 100,seconds*.45,a.facing,1 if action=="supreme" else 0,.27,a)
	elif state=="dodge":emit("dash",a.position-Vector2(0,45),color,65,.25,a.facing,1,.08)

func strike(a, action: String, reach: float, ranged: bool) -> void:
	var color=color_for(a)
	if ranged:
		emit("muzzle",a.position+Vector2(a.facing*36,-65),color,50,.22,a.facing,0,.20);return
	if action=="supreme":
		var variant=0 if a.kind=="varek" else (1 if a.kind=="maela" else 2)
		emit("nova",a.position,color,minf(reach,330),.85,a.facing,variant,.52)
		for i in range(3):emit("pillar",a.position+Vector2((i-1)*100,-10),color,75,.58+i*.06,a.facing,variant,.22)
	elif action=="skill1":
		emit("nova",a.position,color,reach,.62,a.facing,1 if a.kind=="maela" else 2,.40)
		if a.kind=="neris":
			emit("slash",a.position-Vector2(48,62),color,125,.35,-1,1,.15)
			emit("slash",a.position+Vector2(48,-62),color,125,.35,1,0,.15)
	else:
		var heavy=action=="skill0" or a.combo==2
		var family=game.db.item(game.progress.d.equipped.weapon).get("family","")
		if family=="hammer":
			emit("slam",a.position+Vector2(a.facing*65,0),color,100 if not heavy else 135,.46,a.facing,0,.36)
		else:emit("slash",a.position+Vector2(a.facing*36,-61),color,minf(reach,190),.25 if not heavy else .38,a.facing,maxi(a.combo,0),.18 if not heavy else .36)
		if action=="skill0":emit("dash",a.position-Vector2(a.facing*40,42),color,180,.42,a.facing,0,.30)

func impact(a, source: Vector2, strong: bool = false) -> void:
	var color=Color("ff8869") if a.is_player else (color_for(game.player) if game.player!=null else Color("ffe3a0"))
	var facing=1 if source==Vector2.INF or source.x<=a.position.x else -1
	emit("impact",a.position-Vector2(0,63*a.size_scale/1.35),color,55 if not strong else 82,.25 if not strong else .34,facing,0,.28 if not strong else .40)

func parry(a) -> void:
	emit("parry",a.position+Vector2(a.facing*31,-53),Color("ffe1a2"),92,.4,a.facing,0,.42)

func boss_strike(a) -> void:
	var move: String=a.boss_profile.get("move","cleave")
	if move=="slam":emit("slam",a.position,Color("ff8640"),float(a.boss_profile.range.x),.55,a.facing,3,.40)
	elif move=="rush":emit("dash",a.position-Vector2(0,45),Color("ff6f42"),150,.35,a.facing,0,.25)
	else:emit("slash",a.position+Vector2(a.facing*28,-70),Color("ff7846"),150,.36,a.facing,2,.30)

func tick(delta: float) -> void:
	for effect in effects:
		effect.age+=delta
		if effect.follow!=null:
			var actor=effect.follow.get_ref()
			if actor==null or actor.hp<=0:effect.age=effect.life
			else:
				effect.pos=actor.position+effect.offset
				effect.facing=actor.facing
				if (effect.kind=="shield" and actor.state!="guard") or (effect.kind=="charge" and actor.state!="cast"):effect.age=effect.life
		if effect.kind=="dash":
			effect.emit_time+=delta
			if effect.emit_time>=.045:
				effect.emit_time=0;spawn_particles(particle_style(effect.color),effect.pos+Vector2(effect.facing*effect.radius*effect.age/effect.life*.9,0),effect.color,2,75,-effect.facing)
	for particle in particles:
		if not particle.active:continue
		particle.age+=delta
		if particle.age>=particle.life:particle.active=false;continue
		particle.velocity.y+=particle.gravity*delta
		particle.velocity*=exp(-delta*1.8)
		particle.pos+=particle.velocity*delta;particle.angle+=particle.spin*delta
	effects=effects.filter(func(e):return e.age<e.life)
	update_lights();redraw()

func update_lights() -> void:
	var sources: Array=[]
	for e in effects:
		var fade=pow(1.0-e.age/e.life,1.5)
		if e.light*fade>.02:sources.append({"pos":e.pos,"color":e.color,"radius":maxf(85,e.radius*1.4),"energy":e.light*fade})
	for p in game.world.projectiles:
		if p.style=="ember":sources.append({"pos":p.pos-Vector2(0,65),"color":p.color,"radius":95.0,"energy":.18})
		elif p.style=="fireball":sources.append({"pos":p.pos-Vector2(0,65),"color":p.color,"radius":72.0,"energy":.14})
		elif p.style=="spectral":sources.append({"pos":p.pos-Vector2(0,65),"color":p.color,"radius":58.0,"energy":.12})
	sources.sort_custom(func(a,b):return a.energy>b.energy)
	for i in range(lights.size()):
		var lamp=lights[i];lamp.enabled=i<sources.size() and game.screen=="combat"
		if not lamp.enabled:continue
		var source: Dictionary=sources[i]
		lamp.position=source.pos;lamp.color=source.color;lamp.energy=minf(source.energy,.55);lamp.texture_scale=source.radius*2/128

func redraw() -> void:
	if ground!=null:ground.queue_redraw();glow.queue_redraw();debris.queue_redraw()

func alpha(color: Color, value: float) -> Color:
	return Color(color.r,color.g,color.b,clampf(value,0,1))

func halo(canvas: Node2D, pos: Vector2, radius: float, color: Color, opacity: float, scale: Vector2 = Vector2.ONE) -> void:
	canvas.draw_set_transform(pos,0,scale)
	canvas.draw_texture_rect(light_texture,Rect2(-radius,-radius,radius*2,radius*2),false,alpha(color,opacity))
	canvas.draw_set_transform(Vector2.ZERO)

func ribbon(canvas: Node2D, points: PackedVector2Array, width: float, color: Color, opacity: float) -> void:
	if points.size()<2:return
	canvas.draw_polyline(points,alpha(color,opacity*.10),width*3.5,true)
	canvas.draw_polyline(points,alpha(color,opacity*.35),width*1.8,true)
	canvas.draw_polyline(points,alpha(color,opacity),width,true)
	canvas.draw_polyline(points,alpha(Color("fff5dd"),opacity*.9),maxf(1,width*.18),true)

func sweep_points(e: Dictionary, t: float, scale: float = 1) -> PackedVector2Array:
	var points=PackedVector2Array()
	var rising=e.variant==1
	var start=-1.55 if not rising else 1.5
	var end=1.05 if not rising else -1.15
	var head=lerpf(start,end,clampf(t*2.6,0,1))
	var tail=lerpf(start,head,clampf(t*.8,0,.8))
	for i in range(25):
		var angle=lerpf(tail,head,float(i)/24)
		points.append(e.pos+Vector2(e.facing*cos(angle)*e.radius*scale,sin(angle)*e.radius*.64*scale))
	return points

func draw_ground() -> void:
	if game.screen!="combat":return
	for e in effects:
		var t: float=e.age/e.life;var fade=1-t
		if e.kind in ["nova","slam"]:
			var radius: float=e.radius*(.23+.77*sin(minf(t*1.5,1)*PI/2))
			halo(ground,e.pos,radius*1.2,e.color,fade*.38,Vector2(1,.36))
			ground.draw_set_transform(e.pos,0,Vector2(1,.38))
			for ring in range(2):
				var r=radius*(1-ring*.13)
				ground.draw_arc(Vector2.ZERO,r,0,TAU,64,alpha(e.color,fade*(.8-ring*.3)),maxf(1,5*fade),true)
			if e.kind=="nova" and e.variant==1:
				for i in range(8):
					var dir=Vector2.RIGHT.rotated(i*TAU/8+t*.35)
					ground.draw_line(dir*radius*.68,dir*radius*.9,alpha(e.color,fade),3,true)
			ground.draw_set_transform(Vector2.ZERO)
		elif e.kind=="charge":halo(ground,e.pos+Vector2(0,65),e.radius,e.color,sin(t*PI)*.32,Vector2(1,.36))

func draw_glow() -> void:
	if game.screen!="combat":return
	for e in effects:
		var t: float=e.age/e.life;var fade=pow(1-t,1.4);var color: Color=e.color
		match e.kind:
			"slash":
				ribbon(glow,sweep_points(e,t),12 if e.variant<2 else 21,color,fade*.85)
				if e.variant==2:ribbon(glow,sweep_points(e,minf(1,t+.12),.85),5,Color("ffe7a6"),fade*.55)
			"charge":
				var strength=sin(t*PI*.85)
				halo(glow,e.pos,e.radius*(.75-t*.22),color,strength*.5)
				for i in range(7):
					var angle=i*TAU/7+t*3.5
					var pos: Vector2=e.pos+Vector2(cos(angle),sin(angle)*.7)*e.radius*(1-t*.65)
					glow.draw_line(pos,pos+Vector2(cos(angle),sin(angle))*(-12-8*t),alpha(color,strength*.8),2.5,true)
				halo(glow,e.pos,17+t*8,Color("ffefdb"),strength*.6)
			"shield":
				var opacity=minf(1,(1-t)*6)*(.65+sin(t*7)*.10)
				var center: Vector2=e.pos+Vector2(e.facing*36,0)
				halo(glow,center,55,color,opacity*.27,Vector2(.7,1))
				var shield=PackedVector2Array([center+Vector2(-20,-39),center+Vector2(20,-39),center+Vector2(24,-14),center+Vector2(16,24),center+Vector2(0,41),center+Vector2(-16,24),center+Vector2(-24,-14),center+Vector2(-20,-39)])
				ribbon(glow,shield,2.8,color,opacity*.85)
				glow.draw_line(center-Vector2(0,23),center+Vector2(0,22),alpha(color,opacity*.6),2,true)
			"impact","parry","muzzle":
				halo(glow,e.pos,e.radius*(.9+t*.5),color,fade*.6)
				for i in range(7 if e.kind!="parry" else 11):
					var angle=i*2.39996+e.seed*.71
					var dir=Vector2(cos(angle),sin(angle)*.75)
					var distance=e.radius*(.10+t*.8)*(1-float(i%3)*.15)
					glow.draw_line(e.pos+dir*distance,e.pos+dir*(distance+e.radius*.33*fade),alpha(color,fade),maxf(1,4*fade),true)
				glow.draw_line(e.pos-Vector2(16*fade,0),e.pos+Vector2(16*fade,0),alpha(Color("fff3d8"),fade),3,true)
				glow.draw_line(e.pos-Vector2(0,23*fade),e.pos+Vector2(0,23*fade),alpha(Color("fff3d8"),fade),3,true)
			"dash":
				for i in range(5):
					var y=(i-2)*13.0
					var tip: Vector2=e.pos+Vector2(e.facing*e.radius*t*.9,y)
					var points=PackedVector2Array([tip-Vector2(e.facing*e.radius*.75,5),tip-Vector2(e.facing*e.radius*.25,-sin(t*6+i)*6),tip])
					ribbon(glow,points,2+float(i%2)*2,color,fade*.55)
			"nova","slam":
				halo(glow,e.pos-Vector2(0,25),e.radius*.7,color,fade*.38,Vector2(1,.65))
				for i in range(14):
					var angle=i*TAU/14+e.seed*.37
					var dir=Vector2(cos(angle),sin(angle)*.35)
					var pos: Vector2=e.pos+dir*e.radius*(.25+t*.65)-Vector2(0,sin(t*PI)*float(20+i%3*19))
					var tail: Vector2=pos-dir*(12+24*fade)+Vector2(0,13*fade)
					ribbon(glow,PackedVector2Array([tail,pos]),2+float(i%3),color,fade*.75)
			"pillar":
				var height: float=e.radius*(.3+sin(t*PI)*1.55)
				halo(glow,e.pos-Vector2(0,height*.45),e.radius*.75,color,fade*.35,Vector2(.7,1.5))
				for layer in range(3):
					var w=e.radius*(.29-layer*.075)*fade
					var top: Vector2=e.pos-Vector2(0,height)
					var flame=PackedVector2Array([e.pos+Vector2(-w,0),e.pos+Vector2(-w*.65,-height*.45),top+Vector2(-w*.6,height*.15),top+Vector2(w*.25,0),e.pos+Vector2(w*.45,-height*.45),e.pos+Vector2(w,0)])
					if e.variant==1:flame=PackedVector2Array([e.pos+Vector2(-w,0),top+Vector2(-w*.4,height*.35),top,e.pos+Vector2(w,0)])
					elif e.variant==2:flame=PackedVector2Array([e.pos+Vector2(-w*2,0),top+Vector2(-height*.3,height*.4),top+Vector2(height*.2,0),e.pos+Vector2(w,0)])
					glow.draw_colored_polygon(flame,alpha(color.lerp(Color("fff1ce"),layer*.32),fade*(.3+layer*.13)))
	for p in particles:
		if not p.active or p.style in ["smoke","stone","leaf"]:continue
		var t: float=p.age/p.life;var opacity=pow(1-t,1.2)
		if p.style=="spark":
			var tail: Vector2=p.pos-p.velocity.normalized()*(7+p.velocity.length()*.025)*(1-t)
			glow.draw_line(tail,p.pos,alpha(p.color,opacity),maxf(1,p.size*(1-t)*.6),true)
			glow.draw_circle(p.pos,1.1,alpha(Color("fff0cf"),opacity))
		elif p.style=="shard":
			glow.draw_set_transform(p.pos,p.angle,Vector2.ONE)
			glow.draw_colored_polygon(PackedVector2Array([Vector2(0,-p.size*1.6),Vector2(p.size*.5,0),Vector2(0,p.size*1.6),Vector2(-p.size*.5,0)]),alpha(p.color,opacity*.8))
			glow.draw_set_transform(Vector2.ZERO)
		else:
			halo(glow,p.pos,p.size*3,p.color,opacity*.35)
			glow.draw_circle(p.pos,p.size*(1-t*.5),alpha(p.color.lerp(Color("fff3c2"),1-t),opacity*.85))
	draw_projectiles()

func draw_projectiles() -> void:
	for p in game.world.projectiles:
		var pos: Vector2=p.pos-Vector2(0,65);var heading: Vector2=p.velocity.normalized()
		for i in range(p.trail.size()-1):
			var opacity=(1-float(i)/maxi(1,p.trail.size()))*.55
			ribbon(glow,PackedVector2Array([p.trail[i],p.trail[i+1]]),5 if p.style=="ember" else 2,p.color,opacity)
		if p.style in ["ember","fireball"]:
			halo(glow,pos,35 if not p.piercing else 49,p.color,.65)
			glow.draw_set_transform(pos,p.velocity.angle(),Vector2.ONE)
			var flame=PackedVector2Array([Vector2(-38,-10),Vector2(-20,-4),Vector2(-29,8),Vector2(8,11),Vector2(19,0),Vector2(5,-9)])
			glow.draw_colored_polygon(flame,alpha(p.color,.85))
			glow.draw_circle(Vector2(6,0),7,Color("fff1d9"));glow.draw_set_transform(Vector2.ZERO)
		elif p.style=="spectral":
			halo(glow,pos,25,p.color,.72,Vector2(1.0,.72))
			glow.draw_circle(pos,8,Color("e8f7ff"))
			glow.draw_arc(pos,13,game.world.clock*4,game.world.clock*4+PI*1.5,18,alpha(p.color,.9),2,true)
		else:
			glow.draw_line(pos-heading*28,pos+heading*13,alpha(p.color,.9),2.5,true)
			var wing=heading.orthogonal()*5
			glow.draw_polyline(PackedVector2Array([pos+heading*5+wing,pos+heading*16,pos+heading*5-wing]),Color("fff2d8"),2,true)

func draw_debris() -> void:
	if game.screen!="combat":return
	for p in particles:
		if not p.active or not p.style in ["smoke","stone","leaf"]:continue
		var t: float=p.age/p.life;var opacity=sin(t*PI)*(1-t)
		if p.style=="smoke":halo(debris,p.pos,p.size*(.6+t*1.2),p.color,opacity*.28,Vector2(1.4,.75))
		else:
			debris.draw_set_transform(p.pos,p.angle,Vector2.ONE)
			var color: Color=p.color; color.a=(1-t)*.8
			debris.draw_colored_polygon(PackedVector2Array([Vector2(-p.size,0),Vector2(0,-p.size*.6),Vector2(p.size,0),Vector2(0,p.size*.6)]),color)
			if p.style=="leaf":debris.draw_line(Vector2(-p.size,0),Vector2(p.size,0),alpha(Color("d0ffe0"),(1-t)*.5),1,true)
			debris.draw_set_transform(Vector2.ZERO)
	for e in effects:
		if not e.kind in ["slam","nova"]:continue
		var t: float=e.age/e.life;var fade=1-t
		for i in range(8):
			var angle=i*TAU/8+e.seed
			var pos: Vector2=e.pos+Vector2(cos(angle),sin(angle)*.35)*e.radius*(.25+t*.72)-Vector2(0,sin(t*PI)*(18+i%3*12))
			var radius=3+float(i%3)*2
			var color=Color(.48,.31,.21,fade*.65) if e.variant!=2 else Color(.25,.62,.45,fade*.6)
			debris.draw_circle(pos,radius,color)

func live_particle_count() -> int:
	var count=0
	for particle in particles:
		if particle.active:count+=1
	return count
