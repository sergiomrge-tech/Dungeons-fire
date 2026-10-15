class_name DFBossPatterns
extends RefCounted

static func profile(kind: String, phase: int, step: int, origin: Vector2, aim: Vector2, facing: int) -> Dictionary:
	var order=["cleave","slam","rush"] if phase==1 else ["rush","slam","cleave","slam"]
	if kind!="garron":order=["slam","cleave"]
	var move: String=order[step%order.size()]
	return {"move":move,"origin":origin,"aim":aim,"facing":facing,
		"windup":(.95 if move=="cleave" else 1.15) if phase==1 else (.78 if move=="cleave" else .95),
		"recovery":.9 if phase==1 else .65,"attack_time":.65,
		"damage":1.15 if move=="cleave" else (1.45 if move=="slam" else 1.05),
		"range":Vector2(190,51) if move=="cleave" else Vector2(155,69),
		"travel":380.0 if kind=="garron" else 0.0,"phase":phase}

static func contains(p: Dictionary, point: Vector2) -> bool:
	var offset: Vector2=point-p.origin
	match p.move:
		"slam":return pow(offset.x/p.range.x,2)+pow(offset.y/p.range.y,2)<=1
		"rush":return offset.x*p.facing>=-20 and offset.x*p.facing<=p.travel+45 and absf(offset.y)<=36
	return offset.x*p.facing>=-20 and offset.x*p.facing<=p.range.x and absf(offset.y)<=p.range.y

static func draw_zone(canvas: CanvasItem, p: Dictionary, alpha: float, filled: bool = false) -> void:
	var color=Color(1,.48,.20,alpha)
	var origin: Vector2=p.origin
	if p.move=="slam":
		var points=PackedVector2Array()
		for i in range(49):
			var angle=i*TAU/48.0;points.append(origin+Vector2(cos(angle)*p.range.x,sin(angle)*p.range.y))
		if filled:canvas.draw_colored_polygon(points,Color(1,.40,.14,alpha*.35))
		canvas.draw_polyline(points,color,3.5,true)
		canvas.draw_line(origin-Vector2(12,0),origin+Vector2(12,0),color,2,true)
		canvas.draw_line(origin-Vector2(0,10),origin+Vector2(0,10),color,2,true)
	else:
		var reach: float=p.travel+45 if p.move=="rush" else p.range.x
		var depth: float=36 if p.move=="rush" else p.range.y
		var end=origin+Vector2(p.facing*reach,0)
		var rect=Rect2(Vector2(minf(origin.x-p.facing*20,end.x),origin.y-depth),Vector2(reach+20,depth*2))
		canvas.draw_rect(rect,Color(1,.38,.15,alpha*.12),true)
		canvas.draw_rect(rect,color,false,3,true)
		for i in range(3):
			var pos=origin+Vector2(p.facing*(45+i*reach/4.0),0)
			canvas.draw_polyline(PackedVector2Array([pos+Vector2(-p.facing*9,-10),pos+Vector2(p.facing*5,0),pos+Vector2(-p.facing*9,10)]),color,2,true)
