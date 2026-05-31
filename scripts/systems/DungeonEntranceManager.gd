extends Node
class_name DungeonEntranceManager
## Manages dungeon entrance placement — random on new game, restored on load.
##
## Placement rules:
##   Margin = max(footprint) + 2 tiles from every grid edge
##   Entrance tiles reserved in BuildingGrid (id = "dungeon_entrance", fixed)
##   RoadGrid passability synced automatically via BuildingGrid reservation

const DATA_ID: String = "dungeon_entrance"

var _grid:      BuildingGrid = null
var _road_grid: RoadGrid     = null

func _ready() -> void:
	await get_tree().process_frame
	_grid      = get_tree().root.find_child("BuildingGrid", true, false) as BuildingGrid
	_road_grid = get_tree().root.find_child("RoadGrid",     true, false) as RoadGrid

	if _grid == null:
		push_error("DungeonEntranceManager: BuildingGrid not found")
		return

	EventBus.game_loaded.connect(_on_game_loaded)

	# Place on new game (origin == -1,-1 means not yet placed)
	if GameState.dungeon_entrance_origin == Vector2i(-1, -1):
		_place_randomly()
	else:
		_reserve_current()

# ── Public API ────────────────────────────────────────────────────────────────

func get_origin() -> Vector2i:
	return GameState.dungeon_entrance_origin

func get_size() -> Vector2i:
	return GameState.dungeon_entrance_size

# ── Internal ──────────────────────────────────────────────────────────────────

func _pick_entrance_size() -> Vector2i:
	## Randomly select an entrance size valid for the current map size.
	var options: Array = GameState.MAP_ENTRANCE_SIZES.get(
		GameState.map_size,
		GameState.MAP_ENTRANCE_SIZES[GameState.MapSize.MEDIUM]
	)
	return options[randi() % options.size()]

func _place_randomly() -> void:
	# Choose entrance size for the current map
	GameState.dungeon_entrance_size = _pick_entrance_size()

	var size:   Vector2i = GameState.dungeon_entrance_size
	var margin: int      = max(size.x, size.y) + 2
	var gs:     int      = GameState.grid_size

	var max_x: int = gs - size.x - margin
	var max_y: int = gs - size.y - margin
	if max_x <= margin or max_y <= margin:
		push_error("DungeonEntranceManager: grid too small for entrance with margin")
		return

	var ox: int = margin + randi() % (max_x - margin + 1)
	var oy: int = margin + randi() % (max_y - margin + 1)
	GameState.dungeon_entrance_origin = Vector2i(ox, oy)
	_reserve_current()
	EventBus.debug_log_message.emit(
		"Dungeon entrance placed at %s (%s)" % [
			GameState.dungeon_entrance_origin, GameState.dungeon_entrance_size
		]
	)

func _reserve_current() -> void:
	var origin:    Vector2i = GameState.dungeon_entrance_origin
	var footprint: Vector2i = GameState.dungeon_entrance_size

	# Only reserve if not already occupied (handles load case)
	if not _grid.is_tile_occupied(origin):
		_grid.restore_placement(
			DATA_ID + "_0000",
			origin, footprint,
			DATA_ID, "special"
		)

	EventBus.dungeon_entrance_placed.emit(origin, footprint)

	# Sync passability — entrance tiles must be impassable
	if _road_grid:
		_road_grid._sync_building_passability()

func _on_game_loaded(_slot: int) -> void:
	# On load, GameState already has the restored origin.
	# Re-reserve the tiles since BuildingGrid was cleared and reloaded.
	# (SaveSystem restores entrance via buildings array, but belt-and-suspenders.)
	if GameState.dungeon_entrance_origin != Vector2i(-1, -1):
		EventBus.dungeon_entrance_placed.emit(
			GameState.dungeon_entrance_origin,
			GameState.dungeon_entrance_size
		)
