extends Node
## SaveSystem — serializes and deserializes complete game state to JSON.
##
## Slots: 1–5 (user://save_slot_N.json) + slot 0 (autosave.json)
## Autosave: fires on every day_started event.
##
## State saved: GameState, EconomyState, BuildingGrid, RoadGrid, UpgradeManager

const SAVE_VERSION:    int    = 1
const AUTOSAVE_SLOT:   int    = 0
const MAX_SLOTS:       int    = 5
const SAVE_DIR:        String = "user://"

var _is_loading: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	EventBus.debug_log_message.emit("SaveSystem: ready")

# ── Public API ────────────────────────────────────────────────────────────────

func save(slot: int) -> bool:
	## Save to slot (0 = autosave, 1–5 = manual). Returns true on success.
	var data := _collect_state()
	data["slot"] = slot
	var json  := JSON.stringify(data, "\t")
	var path  := _slot_path(slot)
	var file  := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot write to %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(json)
	file.close()
	EventBus.game_saved.emit(slot)
	EventBus.debug_log_message.emit(
		"Game saved — slot %s" % ("autosave" if slot == 0 else str(slot))
	)
	return true

func load_slot(slot: int) -> bool:
	## Load from slot. Returns true on success.
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		EventBus.debug_log_message.emit("No save in slot %d" % slot)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: cannot read %s" % path)
		return false
	var text   := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("SaveSystem: corrupt save in slot %d" % slot)
		return false
	_is_loading = true
	_restore_state(parsed as Dictionary)
	_is_loading = false
	EventBus.game_loaded.emit(slot)
	EventBus.debug_log_message.emit(
		"Game loaded — slot %s" % ("autosave" if slot == 0 else str(slot))
	)
	return true

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func get_save_info(slot: int) -> Dictionary:
	## Returns {day, gold, timestamp} for display, or {} if no save exists.
	if not has_save(slot):
		return {}
	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {}
	var d := parsed as Dictionary
	return {
		"day":       d.get("game_day", 0),
		"gold":      d.get("gold", 0),
		"timestamp": d.get("timestamp", ""),
		"buildings": (d.get("buildings", []) as Array).size(),
	}

func delete_save(slot: int) -> void:
	var path := _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# ── Serialization ─────────────────────────────────────────────────────────────

func _collect_state() -> Dictionary:
	var buildings: Array = []
	var grid: BuildingGrid = _find("BuildingGrid")
	if grid:
		for p in grid.get_placements():
			var origin:    Vector2i = p["origin"]
			var footprint: Vector2i = p["footprint"]
			buildings.append({
				"instance_id": p["instance_id"],
				"data_id":     p["data_id"],
				"origin":      [origin.x, origin.y],
				"footprint":   [footprint.x, footprint.y],
				"category":    p["category"],
			})

	var roads: Array = []
	var road_grid: RoadGrid = _find("RoadGrid")
	if road_grid:
		for tile in road_grid.get_road_tiles():
			roads.append([tile.x, tile.y])

	var constructions: Dictionary = {}
	var manager: UpgradeManager = _find("UpgradeManager")
	if manager:
		for iid in manager.get_all_constructions():
			var c: Dictionary = manager.get_all_constructions()[iid]
			var entry: Dictionary = {
				"kind":         c["kind"],
				"complete_day": c["complete_day"],
				"total_days":   c["total_days"],
			}
			if c["kind"] == "upgrade":
				var origin:    Vector2i = c["origin"]
				var footprint: Vector2i = c["footprint"]
				entry["target_data_id"] = c["target_data_id"]
				entry["origin"]         = [origin.x, origin.y]
				entry["footprint"]      = [footprint.x, footprint.y]
				entry["category"]       = c["category"]
			constructions[iid] = entry

	return {
		"version":          SAVE_VERSION,
		"timestamp":        _timestamp(),
		"game_day":         GameState.current_day,
		"game_hour":        GameState.current_hour,
		"sim_speed":        GameState.sim_speed,
		"gold":             EconomyState.gold,
		"total_income":     EconomyState.total_income,
		"total_expenses":   EconomyState.total_expenses,
		"buildings":        buildings,
		"instance_counter": grid.get_instance_counter() if grid else 0,
		"roads":            roads,
		"constructions":    constructions,
	}

# ── Deserialization ───────────────────────────────────────────────────────────

func _restore_state(data: Dictionary) -> void:
	# ── Time & economy ────────────────────────────────────────────────────────
	GameState.current_day   = int(data.get("game_day",   1))
	GameState.current_hour  = float(data.get("game_hour", 6.0))
	GameState.sim_speed     = float(data.get("sim_speed", 1.0))

	EconomyState.gold           = int(data.get("gold",           EconomyState.STARTING_GOLD))
	EconomyState.total_income   = int(data.get("total_income",   0))
	EconomyState.total_expenses = int(data.get("total_expenses", 0))
	EconomyState.transaction_log.clear()

	# ── Buildings ─────────────────────────────────────────────────────────────
	var grid: BuildingGrid = _find("BuildingGrid")
	if grid:
		grid.clear()
		grid.set_instance_counter(int(data.get("instance_counter", 0)))
		for b in data.get("buildings", []):
			var origin_arr:    Array = b["origin"]
			var footprint_arr: Array = b["footprint"]
			grid.restore_placement(
				b["instance_id"],
				Vector2i(int(origin_arr[0]),    int(origin_arr[1])),
				Vector2i(int(footprint_arr[0]), int(footprint_arr[1])),
				b["data_id"],
				b["category"]
			)

	# ── Roads ─────────────────────────────────────────────────────────────────
	var road_grid: RoadGrid = _find("RoadGrid")
	if road_grid:
		road_grid.clear_roads()
		for tile_arr in data.get("roads", []):
			road_grid.place_road(Vector2i(int(tile_arr[0]), int(tile_arr[1])))

	# ── Constructions ─────────────────────────────────────────────────────────
	var manager: UpgradeManager = _find("UpgradeManager")
	if manager:
		# Clear active constructions by completing them silently
		for iid in manager.get_construction_ids().duplicate():
			manager._constructions.erase(iid)
		var saved_constructions: Dictionary = data.get("constructions", {})
		for iid in saved_constructions.keys():
			var c: Dictionary = saved_constructions[iid]
			var entry: Dictionary = {
				"kind":         c["kind"],
				"complete_day": int(c["complete_day"]),
				"total_days":   int(c["total_days"]),
			}
			if c["kind"] == "upgrade":
				var o: Array = c["origin"]
				var f: Array = c["footprint"]
				entry["target_data_id"] = c["target_data_id"]
				entry["origin"]         = Vector2i(int(o[0]), int(o[1]))
				entry["footprint"]      = Vector2i(int(f[0]), int(f[1]))
				entry["category"]       = c["category"]
			manager.restore_construction(iid, entry)

	# Sync nav grid passability after restoring buildings
	if road_grid:
		road_grid._sync_building_passability()

# ── Autosave ──────────────────────────────────────────────────────────────────

func _on_day_started(_day: int) -> void:
	if not _is_loading:
		save(AUTOSAVE_SLOT)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _slot_path(slot: int) -> String:
	if slot == AUTOSAVE_SLOT:
		return SAVE_DIR + "autosave.json"
	return SAVE_DIR + "save_slot_%d.json" % slot

func _find(node_name: String) -> Node:
	return get_tree().root.find_child(node_name, true, false)

func _timestamp() -> String:
	return "Day %d" % GameState.current_day
