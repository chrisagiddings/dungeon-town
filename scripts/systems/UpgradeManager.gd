extends Node
class_name UpgradeManager
## Tracks active construction timers and completes upgrades when the
## required number of in-game days have passed.
##
## Start an upgrade:  UpgradeManager.start_upgrade(instance_id, data, grid)
## Completion fires:  EventBus.building_upgrade_completed(old_id, new_id)

# ── State ─────────────────────────────────────────────────────────────────────
## instance_id → {target_data_id, complete_day, origin, footprint, category}
var _constructions: Dictionary = {}

var _grid: BuildingGrid = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	_grid = get_tree().root.find_child("BuildingGrid", true, false) as BuildingGrid
	if _grid == null:
		push_error("UpgradeManager: BuildingGrid not found")
	EventBus.day_started.connect(_on_day_started)
	EventBus.debug_log_message.emit("UpgradeManager: ready")

# ── Public API ────────────────────────────────────────────────────────────────

func start_upgrade(instance_id: String, data: BuildingData) -> void:
	## Begin construction of the upgrade for instance_id.
	## Deducts gold, registers the timer, emits building_upgrade_started.
	if _constructions.has(instance_id):
		push_warning("UpgradeManager: %s is already under construction" % instance_id)
		return
	if not EconomyState.spend_gold(data.upgrade_cost, "upgrade:%s" % instance_id):
		EventBus.debug_log_message.emit("Upgrade failed: insufficient gold")
		return

	var placement := _grid.get_placement_for_instance(instance_id)
	if placement.is_empty():
		push_error("UpgradeManager: placement not found for %s" % instance_id)
		return

	var complete_day := GameState.current_day + data.upgrade_time_days
	_constructions[instance_id] = {
		"target_data_id": data.upgrade_to,
		"complete_day":   complete_day,
		"origin":         placement["origin"],
		"footprint":      placement["footprint"],
		"category":       placement["category"],
	}

	EventBus.building_upgrade_started.emit(instance_id, data.upgrade_to, complete_day)
	EventBus.debug_log_message.emit(
		"Construction started: %s → %s (done day %d)" % [instance_id, data.upgrade_to, complete_day]
	)

func is_under_construction(instance_id: String) -> bool:
	return _constructions.has(instance_id)

func days_remaining(instance_id: String) -> int:
	if not _constructions.has(instance_id):
		return 0
	return maxi(0, _constructions[instance_id]["complete_day"] - GameState.current_day)

func get_construction_ids() -> Array:
	return _constructions.keys()

# ── Internal ──────────────────────────────────────────────────────────────────

func _on_day_started(_day: int) -> void:
	var completed: Array = []
	for instance_id in _constructions.keys():
		if GameState.current_day >= _constructions[instance_id]["complete_day"]:
			completed.append(instance_id)
	for instance_id in completed:
		_complete_upgrade(instance_id)

func _complete_upgrade(instance_id: String) -> void:
	var info: Dictionary = _constructions[instance_id]
	_constructions.erase(instance_id)

	var origin:    Vector2i = info["origin"]
	var footprint: Vector2i = info["footprint"]
	var category:  String   = info["category"]

	_grid.release(instance_id)
	var new_id := _grid.reserve(origin, footprint, info["target_data_id"], category)

	EventBus.building_upgrade_completed.emit(instance_id, new_id)
	EventBus.debug_log_message.emit("Upgrade complete: %s → %s" % [instance_id, new_id])
