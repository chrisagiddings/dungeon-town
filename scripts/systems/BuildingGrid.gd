extends Node
class_name BuildingGrid
## Authoritative occupancy map for the town grid.
## Tracks which tiles are reserved and by which building.
## Pure data/logic — no drawing.

# ── State ─────────────────────────────────────────────────────────────────────
## tile → building_id (fast collision lookup)
var _occupied: Dictionary = {}

## Ordered list of placements for rendering and save/load
var _placements: Array[Dictionary] = []

# ── Constants ─────────────────────────────────────────────────────────────────
const GRID_SIZE: int = 20

# ── Public API ────────────────────────────────────────────────────────────────

func can_place(origin: Vector2i, footprint: Vector2i) -> bool:
	## Returns true if the footprint fits on the grid with no occupied tiles.
	if not is_in_bounds(origin, footprint):
		return false
	for tile in get_tiles(origin, footprint):
		if _occupied.has(tile):
			return false
	return true

func reserve(origin: Vector2i, footprint: Vector2i, building_id: String, category: String) -> void:
	## Mark all tiles in the footprint as occupied by building_id.
	for tile in get_tiles(origin, footprint):
		_occupied[tile] = building_id
	_placements.append({
		"id":       building_id,
		"origin":   origin,
		"footprint": footprint,
		"category": category,
	})
	EventBus.building_placed.emit(building_id, origin)
	EventBus.debug_log_message.emit(
		"Building placed: %s at %s" % [building_id, origin]
	)

func release(building_id: String) -> void:
	## Free all tiles held by building_id.
	var keys_to_remove: Array = []
	for tile in _occupied.keys():
		if _occupied[tile] == building_id:
			keys_to_remove.append(tile)
	for tile in keys_to_remove:
		_occupied.erase(tile)
	for i in range(_placements.size() - 1, -1, -1):
		if _placements[i]["id"] == building_id:
			_placements.remove_at(i)

func is_tile_occupied(tile: Vector2i) -> bool:
	return _occupied.has(tile)

func get_occupant(tile: Vector2i) -> String:
	return _occupied.get(tile, "")

func get_placements() -> Array[Dictionary]:
	return _placements

func get_placement_count() -> int:
	return _placements.size()

func get_tiles(origin: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	## Return all tile coordinates covered by a footprint at origin.
	var tiles: Array[Vector2i] = []
	for row in range(footprint.y):
		for col in range(footprint.x):
			tiles.append(origin + Vector2i(col, row))
	return tiles

func is_in_bounds(origin: Vector2i, footprint: Vector2i) -> bool:
	## True if every tile in the footprint is within the valid grid area.
	if origin.x < 0 or origin.y < 0:
		return false
	if origin.x + footprint.x > GRID_SIZE:
		return false
	if origin.y + footprint.y > GRID_SIZE:
		return false
	return true

func clear() -> void:
	_occupied.clear()
	_placements.clear()
