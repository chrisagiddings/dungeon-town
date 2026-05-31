extends Node
## DataRegistry — central store for all game resource definitions.
## Scans resource folders at startup and loads all .tres files into typed registries.

# ── Storage ───────────────────────────────────────────────────────────────────
var buildings:    Dictionary = {}
var adventurers:  Dictionary = {}
var mobs:         Dictionary = {}
var loot_tables:  Dictionary = {}
var quests:       Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_folder("res://resources/buildings", buildings, "BuildingData")
	EventBus.debug_log_message.emit(
		"DataRegistry: loaded %d buildings" % buildings.size()
	)

# ── Public API ────────────────────────────────────────────────────────────────

func get_building(id: String) -> Resource:
	return buildings.get(id, null)

func get_adventurer(id: String) -> Resource:
	return adventurers.get(id, null)

func get_mob(id: String) -> Resource:
	return mobs.get(id, null)

func get_loot_table(id: String) -> Resource:
	return loot_tables.get(id, null)

func get_quest(id: String) -> Resource:
	return quests.get(id, null)

func register_building(id: String, data: Resource) -> void:
	buildings[id] = data

func register_adventurer(id: String, data: Resource) -> void:
	adventurers[id] = data

func register_mob(id: String, data: Resource) -> void:
	mobs[id] = data

func register_loot_table(id: String, data: Resource) -> void:
	loot_tables[id] = data

func register_quest(id: String, data: Resource) -> void:
	quests[id] = data

func get_all_building_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in buildings.keys():
		ids.append(str(key))
	return ids

func get_buildings_by_tier(tier: int) -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for data in buildings.values():
		var bd := data as BuildingData
		if bd and bd.tier == tier:
			result.append(bd)
	return result

# ── Resource Loading ──────────────────────────────────────────────────────────

func _load_folder(path: String, registry: Dictionary, _expected_class: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("DataRegistry: cannot open folder: %s" % path)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var full_path := path + "/" + fname
			var res := load(full_path)
			if res == null:
				push_warning("DataRegistry: failed to load %s" % full_path)
			elif not (res is BuildingData):
				push_warning("DataRegistry: %s is not a BuildingData resource" % fname)
			else:
				var data := res as BuildingData
				if data.id.is_empty():
					push_warning("DataRegistry: %s has empty id — skipped" % fname)
				else:
					registry[data.id] = data
		fname = dir.get_next()
	dir.list_dir_end()
