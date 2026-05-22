extends Node
## DataRegistry — central store for all game resource definitions.
## Systems query here rather than loading resources directly at runtime.
## In M0, all entries are stubs. M1 will scan resource folders and load .tres files.

# ── Storage ───────────────────────────────────────────────────────────────────
var buildings:    Dictionary = {}
var adventurers:  Dictionary = {}
var mobs:         Dictionary = {}
var loot_tables:  Dictionary = {}
var quests:       Dictionary = {}

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_register_stubs()
	EventBus.debug_log_message.emit("DataRegistry: ready (M0 stubs loaded)")

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

# ── Stub Data ─────────────────────────────────────────────────────────────────

func _register_stubs() -> void:
	## Placeholder data for M0. Replace with .tres loading in M1.
	pass
