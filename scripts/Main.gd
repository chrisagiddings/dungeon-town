extends Node2D
class_name Main
## Main scene entry point.
## Handles scene-level initialization and any cross-system wiring
## that can't be done within individual scripts.

func _ready() -> void:
	EventBus.debug_log_message.emit("=== DUNGEON TOWN — M0 Bootstrap ===")
	EventBus.debug_log_message.emit(
		"Day %d  %s  |  Gold: %d" % [
			GameState.current_day,
			GameState.get_time_string(),
			EconomyState.gold
		]
	)
	EventBus.debug_log_message.emit("Controls: WASD/arrows=pan  scroll=zoom  mid-drag=pan")
	EventBus.debug_log_message.emit("Debug panel: use buttons below to test systems.")
