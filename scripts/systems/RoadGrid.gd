extends Node
class_name RoadGrid
## Authoritative road data and 2D navigation grid.
## Tracks which tiles have roads, and maintains an AStar2D graph so future
## adventurer pathfinding can prefer roads over bare ground.
##
## Navigation costs:
##   Road tile       → weight 1.0 (fast)
##   Open ground     → weight 3.0 (slow, passable)
##   Building tile   → disconnected (impassable)

var GRID_SIZE: int = 20
const COST_ROAD:    float = 1.0
const COST_GROUND:  float = 3.0

# ── State ─────────────────────────────────────────────────────────────────────
var _roads: Dictionary = {}   # Vector2i → true
var _astar: AStar2D    = AStar2D.new()

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_nav_grid()
	EventBus.building_placed.connect(_on_building_placed)
	EventBus.building_demolished.connect(_on_building_demolished)
	EventBus.debug_log_message.emit("RoadGrid: ready")

# ── Public road API ───────────────────────────────────────────────────────────

func place_road(tile: Vector2i) -> void:
	if not _is_valid_tile(tile) or _roads.has(tile):
		return
	_roads[tile] = true
	_astar.set_point_weight_scale(_tile_id(tile), COST_ROAD)
	EventBus.road_placed.emit(tile)

func remove_road(tile: Vector2i) -> void:
	if not _roads.has(tile):
		return
	_roads.erase(tile)
	_astar.set_point_weight_scale(_tile_id(tile), COST_GROUND)
	EventBus.road_removed.emit(tile)

func has_road(tile: Vector2i) -> bool:
	return _roads.has(tile)

func get_road_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for t in _roads.keys():
		tiles.append(t as Vector2i)
	return tiles

func get_road_count() -> int:
	return _roads.size()

func clear_roads() -> void:
	for tile in _roads.keys().duplicate():
		remove_road(tile as Vector2i)

func update_grid_size() -> void:
	## Rebuilds the navigation grid for the current GameState.grid_size.
	GRID_SIZE = GameState.grid_size
	_roads.clear()
	_astar = AStar2D.new()
	_build_nav_grid()

# ── Navigation API ────────────────────────────────────────────────────────────

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	## Returns an array of tile coordinates from from→to, preferring roads.
	## Returns empty array if no path exists.
	var from_id := _tile_id(from)
	var to_id   := _tile_id(to)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return []
	var raw: PackedVector2Array = _astar.get_point_path(from_id, to_id)
	var result: Array[Vector2i] = []
	for v in raw:
		result.append(Vector2i(int(v.x), int(v.y)))
	return result

func set_tile_passable(tile: Vector2i, passable: bool) -> void:
	## Used when buildings are placed (impassable) or demolished (passable).
	var id := _tile_id(tile)
	if not _astar.has_point(id):
		return
	_astar.set_point_disabled(id, not passable)

# ── EventBus handlers ─────────────────────────────────────────────────────────

func _on_building_placed(_instance_id: String, _origin: Vector2i) -> void:
	# Defer one frame so BuildingGrid is updated before we query it
	call_deferred("_sync_building_passability")

func _on_building_demolished(_instance_id: String) -> void:
	call_deferred("_sync_building_passability")

func _sync_building_passability() -> void:
	var grid: BuildingGrid = get_tree().root.find_child("BuildingGrid", true, false)
	if grid == null:
		return
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile := Vector2i(col, row)
			var passable := not grid.is_tile_occupied(tile)
			set_tile_passable(tile, passable)

# ── Nav grid construction ─────────────────────────────────────────────────────

func _build_nav_grid() -> void:
	# Add all points
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var tile := Vector2i(col, row)
			var id   := _tile_id(tile)
			_astar.add_point(id, Vector2(col, row), COST_GROUND)

	# Connect 4-directional neighbors
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var id := _tile_id(Vector2i(col, row))
			if col + 1 < GRID_SIZE:
				_astar.connect_points(id, _tile_id(Vector2i(col + 1, row)))
			if row + 1 < GRID_SIZE:
				_astar.connect_points(id, _tile_id(Vector2i(col, row + 1)))

func _tile_id(tile: Vector2i) -> int:
	return tile.y * GRID_SIZE + tile.x

func _is_valid_tile(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_SIZE and tile.y < GRID_SIZE
