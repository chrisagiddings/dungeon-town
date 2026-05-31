extends Node
class_name BuildingGrid
## Authoritative occupancy map for the town grid.
## Each placed building gets a unique instance_id so two buildings of the same
## type can be independently selected and demolished.

# ── State ─────────────────────────────────────────────────────────────────────
## tile → instance_id (fast collision lookup)
var _occupied: Dictionary = {}

## Ordered list of placements for rendering and save/load
var _placements: Array[Dictionary] = []

var _instance_counter: int = 0

# ── Constants ─────────────────────────────────────────────────────────────────
var GRID_SIZE: int = 20

# ── Public API ────────────────────────────────────────────────────────────────

func can_place(origin: Vector2i, footprint: Vector2i) -> bool:
	if not is_in_bounds(origin, footprint):
		return false
	for tile in get_tiles(origin, footprint):
		if _occupied.has(tile):
			return false
	return true

func reserve(origin: Vector2i, footprint: Vector2i, data_id: String, category: String) -> String:
	## Place a building. Returns the unique instance_id assigned to this placement.
	_instance_counter += 1
	var instance_id := "%s_%04d" % [data_id, _instance_counter]
	for tile in get_tiles(origin, footprint):
		_occupied[tile] = instance_id
	_placements.append({
		"instance_id": instance_id,
		"data_id":     data_id,
		"origin":      origin,
		"footprint":   footprint,
		"category":    category,
	})
	EventBus.building_placed.emit(instance_id, origin)
	EventBus.debug_log_message.emit("Building placed: %s at %s" % [instance_id, origin])
	return instance_id

func release(instance_id: String) -> void:
	## Free all tiles held by instance_id and remove the placement record.
	var keys_to_remove: Array = []
	for tile in _occupied.keys():
		if _occupied[tile] == instance_id:
			keys_to_remove.append(tile)
	for tile in keys_to_remove:
		_occupied.erase(tile)
	for i in range(_placements.size() - 1, -1, -1):
		if _placements[i]["instance_id"] == instance_id:
			_placements.remove_at(i)

func is_tile_occupied(tile: Vector2i) -> bool:
	return _occupied.has(tile)

func get_occupant(tile: Vector2i) -> String:
	## Returns the instance_id of the building occupying this tile, or "".
	return _occupied.get(tile, "")

func get_placement_for_instance(instance_id: String) -> Dictionary:
	## Returns the full placement dict for instance_id, or {}.
	for p in _placements:
		if p["instance_id"] == instance_id:
			return p
	return {}

func get_data_id_for_instance(instance_id: String) -> String:
	## Returns the BuildingData id (e.g. "lodging_t1") for an instance_id.
	return get_placement_for_instance(instance_id).get("data_id", "")

func get_placements() -> Array[Dictionary]:
	return _placements

func get_placement_count() -> int:
	return _placements.size()

func get_tiles(origin: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for row in range(footprint.y):
		for col in range(footprint.x):
			tiles.append(origin + Vector2i(col, row))
	return tiles

func is_in_bounds(origin: Vector2i, footprint: Vector2i) -> bool:
	if origin.x < 0 or origin.y < 0:
		return false
	if origin.x + footprint.x > GRID_SIZE:
		return false
	if origin.y + footprint.y > GRID_SIZE:
		return false
	return true

func update_grid_size() -> void:
	GRID_SIZE = GameState.grid_size


func clear() -> void:
	_occupied.clear()
	_placements.clear()
	_instance_counter = 0

func get_instance_counter() -> int:
	return _instance_counter

func set_instance_counter(n: int) -> void:
	_instance_counter = n

func restore_placement(instance_id: String, origin: Vector2i, footprint: Vector2i,
		data_id: String, category: String) -> void:
	## Restores a saved placement with its original instance_id (no new ID generated).
	for tile in get_tiles(origin, footprint):
		_occupied[tile] = instance_id
	_placements.append({
		"instance_id": instance_id,
		"data_id":     data_id,
		"origin":      origin,
		"footprint":   footprint,
		"category":    category,
	})
