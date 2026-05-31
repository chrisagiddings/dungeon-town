extends Node
class_name ProductionManager
## Ticks all producing buildings once per in-game day.
## Reads BuildingData.produces and .consumes, writes to ResourceInventory.
##
## Staffing is currently stubbed at 100% efficiency.
## Connect to StaffingManager when issue #120 is implemented.

var _grid:    BuildingGrid   = null
var _manager: UpgradeManager = null

func _ready() -> void:
	await get_tree().process_frame
	_grid    = get_tree().root.find_child("BuildingGrid",   true, false) as BuildingGrid
	_manager = get_tree().root.find_child("UpgradeManager", true, false) as UpgradeManager
	if _grid == null:
		push_error("ProductionManager: BuildingGrid not found")
	EventBus.day_started.connect(_on_day_started)
	EventBus.debug_log_message.emit("ProductionManager: ready")

# ── Internal ──────────────────────────────────────────────────────────────────

func _on_day_started(_day: int) -> void:
	if _grid == null:
		return
	for placement in _grid.get_placements():
		_tick_building(placement)

func _tick_building(placement: Dictionary) -> void:
	var data_id: String    = placement.get("data_id", "")
	var instance_id: String = placement.get("instance_id", "")
	var data: BuildingData = DataRegistry.get_building(data_id) as BuildingData
	if data == null or data.produces.is_empty():
		return

	# Skip buildings under construction or upgrade
	if _manager != null and _manager.is_under_construction(instance_id):
		return

	# TODO (#120): query StaffingManager for actual efficiency
	# var efficiency: float = StaffingManager.get_efficiency(instance_id)
	var efficiency: float = 1.0

	# Check all inputs are available
	for resource_id in data.consumes.keys():
		var needed: int = int(data.consumes[resource_id])
		if not ResourceInventory.has_resource(resource_id, needed):
			EventBus.production_halted.emit(instance_id, resource_id)
			EventBus.debug_log_message.emit(
				"%s halted — needs %d %s" % [data.display_name, needed, resource_id]
			)
			return

	# Consume inputs
	for resource_id in data.consumes.keys():
		ResourceInventory.consume_resource(resource_id, int(data.consumes[resource_id]))

	# Produce outputs (scaled by efficiency)
	var outputs: Dictionary = {}
	for resource_id in data.produces.keys():
		var amount: int = maxi(1, int(float(data.produces[resource_id]) * efficiency))
		ResourceInventory.add_resource(resource_id, amount)
		outputs[resource_id] = amount

	EventBus.production_tick.emit(instance_id, outputs)
