class_name DFDungeonLayout
extends RefCounted

const BOUNDS=Rect2(70,410,1140,147)
var data: Dictionary={}
var obstacles: Array[Rect2]=[]
var definition: Dictionary={}

func _init() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://data/mine_rooms.json"))

func configure(dungeon: int, room: int) -> void:
	obstacles.clear()
	definition=data.rooms[clampi(room,0,4)].duplicate(true) if dungeon==0 else {"id":"D%d_R%d"%[dungeon,room],"name":"Arena %d"%(room+1),"props":[],"chests":[]}
	for prop in definition.get("props",[]):
		if prop.get("solid",false):obstacles.append(Rect2(prop.x-30,prop.y-18,60,36))

func blocked(pos: Vector2, radius: float = 12) -> bool:
	for rect in obstacles:
		if rect.grow(radius).has_point(pos):return true
	return false

func move(from: Vector2, motion: Vector2, radius: float = 12) -> Vector2:
	var target=from
	var horizontal=Vector2(clampf(from.x+motion.x,BOUNDS.position.x,BOUNDS.end.x),from.y)
	if not blocked(horizontal,radius):target=horizontal
	var vertical=Vector2(target.x,clampf(target.y+motion.y,BOUNDS.position.y,BOUNDS.end.y))
	if not blocked(vertical,radius):target=vertical
	return target

func segment_blocked(from: Vector2, to: Vector2, margin: float = 0) -> bool:
	for r in obstacles:
		if crosses(r.grow(margin),from,to):return true
	return false

func crosses(r: Rect2, from: Vector2, to: Vector2) -> bool:
	if r.has_point(from) or r.has_point(to):return true
	var p=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(from,to,p[i],p[(i+1)%4])!=null:return true
	return false

func direction(from: Vector2, to: Vector2) -> Vector2:
	if not segment_blocked(from,to,12):return (to-from).normalized()
	# Tiny visibility graph: each solid prop contributes four clearance corners.
	var nodes: Array[Vector2]=[from,to]
	for rect in obstacles:
		var expanded=rect.grow(14)
		for point in [expanded.position,Vector2(expanded.end.x,expanded.position.y),expanded.end,Vector2(expanded.position.x,expanded.end.y)]:
			if BOUNDS.has_point(point) and not blocked(point,12):nodes.append(point)
	var distances: Array=[];var previous: Array=[];var visited: Array=[]
	for i in range(nodes.size()):distances.append(INF);previous.append(-1);visited.append(false)
	distances[0]=0.0
	for iteration in range(nodes.size()):
		var current=-1;var best=INF
		for i in range(nodes.size()):
			if not visited[i] and distances[i]<best:current=i;best=distances[i]
		if current<0 or current==1:break
		visited[current]=true
		for j in range(nodes.size()):
			if visited[j] or segment_blocked(nodes[current],nodes[j],12):continue
			var cost: float=distances[current]+nodes[current].distance_to(nodes[j])
			if cost<distances[j]:distances[j]=cost;previous[j]=current
	var next=1
	if previous[next]<0:return Vector2.ZERO
	while previous[next]>0:next=previous[next]
	return (nodes[next]-from).normalized()
