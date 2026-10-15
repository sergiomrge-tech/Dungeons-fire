class_name DFContent
extends RefCounted

var dungeons: Array = []
var items: Dictionary = {}
var regions: Array = []
var boons: Dictionary = {}
var mobs: Dictionary = {}
var regional_rosters: Array = []

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	if not parsed is Dictionary:
		push_error("Invalid catalog")
		return
	dungeons = parsed.dungeons
	regions = parsed.regions
	for item in parsed.items:
		items[item.id] = item
	var boon_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/boons.json"))
	if boon_data is Dictionary:
		for boon in boon_data.get("boons", []): boons[boon.id] = boon
	var mob_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mobs.json"))
	if mob_data is Dictionary:
		for mob in mob_data.get("mobs", []): mobs[mob.id] = mob
		regional_rosters = mob_data.get("regional_rosters", [])

func item(id: String) -> Dictionary:
	return items.get(id, {})

func boon(id: String) -> Dictionary:
	return boons.get(id, {})

func mob(id: String) -> Dictionary:
	return mobs.get(id, {})

func roster(region: int) -> Array:
	if regional_rosters.is_empty(): return ["knight", "archer", "brute"]
	return regional_rosters[clampi(region, 0, regional_rosters.size() - 1)].duplicate()

func unlocked_items(stage: int, hero: String) -> Array:
	var result: Array = []
	for def in items.values():
		if int(def.tier) <= stage and (def.hero == hero or def.hero == "all"):
			result.append(def)
	return result
