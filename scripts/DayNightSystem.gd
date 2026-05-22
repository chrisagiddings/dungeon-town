extends Node
class_name DayNightSystem
## Responds to phase changes and tweens the world modulate color for day/night atmosphere.
## Operates on TownRoot and DungeonRoot siblings to avoid affecting the UI layer.

# ── Phase colors (world modulate) ─────────────────────────────────────────────
const PHASE_COLORS: Dictionary = {
	0: Color(1.00, 0.90, 0.70),  # MORNING — warm amber
	1: Color(1.00, 1.00, 1.00),  # DAY     — full brightness
	2: Color(1.00, 0.65, 0.45),  # EVENING — orange dusk
	3: Color(0.30, 0.32, 0.58),  # NIGHT   — deep blue
}

const TWEEN_DURATION: float = 2.5

# ── State ─────────────────────────────────────────────────────────────────────
var _town_root: Node2D = null
var _dungeon_root: Node2D = null
var _tween: Tween = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Wait one frame so sibling nodes are ready
	await get_tree().process_frame
	var parent: Node = get_parent()
	_town_root   = parent.get_node_or_null("TownRoot") as Node2D
	_dungeon_root = parent.get_node_or_null("DungeonRoot") as Node2D

	if _town_root == null:
		push_warning("DayNightSystem: TownRoot not found — visual phase changes disabled")
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.debug_log_message.emit("DayNightSystem: ready")

# ── Phase Response ────────────────────────────────────────────────────────────

func _on_phase_changed(phase_int: int) -> void:
	var target: Color = PHASE_COLORS.get(phase_int, Color.WHITE)
	_tween_world_color(target)
	EventBus.debug_log_message.emit(
		"Phase: %s" % GameState.get_phase_name()
	)

func _tween_world_color(target: Color) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	if _town_root:
		_tween.tween_property(_town_root, "modulate", target, TWEEN_DURATION)
	if _dungeon_root:
		_tween.tween_property(_dungeon_root, "modulate", target, TWEEN_DURATION)
