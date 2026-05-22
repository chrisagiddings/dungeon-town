extends Node
class_name AdventurerSpawner
## Timer-based adventurer spawn stub.
## In M0, "adventurers" are just IDs tracked in a dictionary.
## M1 will instantiate actual scene nodes and attach AdventurerData resources.

# ── Constants ─────────────────────────────────────────────────────────────────
const AUTO_SPAWN_INTERVAL: float = 30.0  ## Real seconds between auto-spawns at 1× speed
const MAX_ADVENTURERS: int = 10

# ── State ─────────────────────────────────────────────────────────────────────
var _next_id: int = 1
var _active_adventurers: Dictionary = {}  ## { id: String → in_dungeon: bool }
var _spawn_timer: Timer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.name = "SpawnTimer"
	_spawn_timer.wait_time = AUTO_SPAWN_INTERVAL
	_spawn_timer.autostart = true
	_spawn_timer.timeout.connect(_on_spawn_timer)
	add_child(_spawn_timer)

	EventBus.adventurer_entered_dungeon.connect(_on_adventurer_entered_dungeon)
	EventBus.adventurer_returned.connect(_on_adventurer_returned)
	EventBus.debug_log_message.emit("AdventurerSpawner: ready (cap: %d)" % MAX_ADVENTURERS)

# ── Public API ────────────────────────────────────────────────────────────────

func spawn_adventurer() -> String:
	## Spawns one adventurer. Returns its ID, or "" if at capacity.
	if _active_adventurers.size() >= MAX_ADVENTURERS:
		EventBus.debug_log_message.emit(
			"Spawn refused: at capacity (%d/%d)" % [_active_adventurers.size(), MAX_ADVENTURERS]
		)
		return ""

	var adv_id: String = "adv_%04d" % _next_id
	_next_id += 1
	_active_adventurers[adv_id] = false  # false = not in dungeon

	EventBus.adventurer_spawned.emit(adv_id)
	EventBus.debug_log_message.emit(
		"Adventurer arrived: %s  [%d/%d]" % [adv_id, _active_adventurers.size(), MAX_ADVENTURERS]
	)
	return adv_id

func get_idle_adventurer() -> String:
	## Returns an available (not-in-dungeon) adventurer ID, or "".
	for id in _active_adventurers.keys():
		if not _active_adventurers[id]:
			return id
	return ""

func get_active_count() -> int:
	return _active_adventurers.size()

func get_idle_count() -> int:
	var count: int = 0
	for in_dungeon in _active_adventurers.values():
		if not in_dungeon:
			count += 1
	return count

# ── Internal ──────────────────────────────────────────────────────────────────

func _on_spawn_timer() -> void:
	if not GameState.is_paused:
		spawn_adventurer()

func _on_adventurer_entered_dungeon(adv_id: String) -> void:
	if adv_id in _active_adventurers:
		_active_adventurers[adv_id] = true

func _on_adventurer_returned(adv_id: String, _result: Dictionary) -> void:
	if adv_id in _active_adventurers:
		_active_adventurers[adv_id] = false
