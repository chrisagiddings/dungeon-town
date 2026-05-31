extends Node
class_name UpgradeManager
## Tracks active construction timers for both new placements and upgrades.
##
## New build:  start_new_construction(instance_id, days)
##             → EventBus.building_construction_completed(instance_id)
##
## Upgrade:    start_upgrade(instance_id, data)
##             → EventBus.building_upgrade_completed(old_id, new_id)
##
## Construction automatically pauses when the sim is paused because
## GameState stops emitting day_started.

# ── State ─────────────────────────────────────────────────────────────────────
## instance_id →
##   { kind: "build"|"upgrade", complete_day, total_days,
##     [upgrade only] target_data_id, origin, footprint, category }
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

func start_new_construction(instance_id: String, days: int) -> void:
	## Register a freshly-placed building as under construction.
	## No gold deduction — cost was paid at placement time.
	if _constructions.has(instance_id):
		push_warning("UpgradeManager: %s already under construction" % instance_id)
		return
	var complete_day := GameState.current_day + days
	_constructions[instance_id] = {
		"kind":         "build",
		"complete_day": complete_day,
		"total_days":   days,
	}
	EventBus.building_construction_started.emit(instance_id, complete_day)
	EventBus.debug_log_message.emit(
		"Construction started: %s (%d days, done day %d)" % [instance_id, days, complete_day]
	)

func start_upgrade(instance_id: String, data: BuildingData) -> void:
	## Begin an upgrade. Deducts gold, registers timer, emits upgrade_started.
	if _constructions.has(instance_id):
		push_warning("UpgradeManager: %s already under construction" % instance_id)
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
		"kind":           "upgrade",
		"complete_day":   complete_day,
		"total_days":     data.upgrade_time_days,
		"target_data_id": data.upgrade_to,
		"origin":         placement["origin"],
		"footprint":      placement["footprint"],
		"category":       placement["category"],
	}
	EventBus.building_upgrade_started.emit(instance_id, data.upgrade_to, complete_day)
	EventBus.debug_log_message.emit(
		"Upgrade started: %s → %s (done day %d)" % [instance_id, data.upgrade_to, complete_day]
	)

func is_under_construction(instance_id: String) -> bool:
	return _constructions.has(instance_id)

func days_remaining(instance_id: String) -> int:
	if not _constructions.has(instance_id):
		return 0
	return maxi(0, _constructions[instance_id]["complete_day"] - GameState.current_day)

func total_days(instance_id: String) -> int:
	return _constructions.get(instance_id, {}).get("total_days", 0)

func construction_progress(instance_id: String) -> float:
	## Returns 0.0 (just started) → 1.0 (complete).
	var total: int = total_days(instance_id)
	if total <= 0:
		return 1.0
	var remaining: int = days_remaining(instance_id)
	return clampf(float(total - remaining) / float(total), 0.0, 1.0)

func get_construction_ids() -> Array:
	return _constructions.keys()

# ── Internal ──────────────────────────────────────────────────────────────────

func _on_day_started(_day: int) -> void:
	var completed: Array = []
	for iid in _constructions.keys():
		if GameState.current_day >= _constructions[iid]["complete_day"]:
			completed.append(iid)
	for iid in completed:
		_complete_construction(iid)

func _complete_construction(instance_id: String) -> void:
	var info: Dictionary = _constructions[instance_id]
	_constructions.erase(instance_id)

	if info["kind"] == "upgrade":
		var origin:    Vector2i = info["origin"]
		var footprint: Vector2i = info["footprint"]
		var category:  String   = info["category"]
		_grid.release(instance_id)
		var new_id := _grid.reserve(origin, footprint, info["target_data_id"], category)
		EventBus.building_upgrade_completed.emit(instance_id, new_id)
		EventBus.debug_log_message.emit("Upgrade complete: %s → %s" % [instance_id, new_id])
	else:
		EventBus.building_construction_completed.emit(instance_id)
		EventBus.debug_log_message.emit("Construction complete: %s" % instance_id)
