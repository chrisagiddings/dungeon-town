extends Node
## EventBus — cross-system signal hub.
## All game systems communicate through here to avoid tight coupling.
## No system should hold a direct reference to another; use these signals instead.

# ── Economy ──────────────────────────────────────────────────────────────────
signal gold_changed(new_amount: int, delta: int)
signal income_recorded(amount: int, source: String)
signal expense_recorded(amount: int, reason: String)

# ── Time ─────────────────────────────────────────────────────────────────────
signal day_started(day_number: int)
signal time_tick(hour: float)
signal phase_changed(new_phase: int)  # GameState.Phase enum value

# ── Adventurers ──────────────────────────────────────────────────────────────
signal adventurer_spawned(adventurer_id: String)
signal adventurer_entered_dungeon(adventurer_id: String)
signal adventurer_returned(adventurer_id: String, result: Dictionary)

# ── Dungeon ───────────────────────────────────────────────────────────────────
signal dungeon_run_started(adventurer_id: String)
signal dungeon_run_completed(adventurer_id: String, loot: Dictionary)

# ── Simulation ────────────────────────────────────────────────────────────────
signal sim_speed_changed(new_speed: float)
signal sim_paused(is_paused: bool)

# ── Building Placement ────────────────────────────────────────────────────────
signal building_placement_started(building_data: BuildingData)
signal building_placed(instance_id: String, origin: Vector2i)
signal building_placement_cancelled()

# ── Building Selection ────────────────────────────────────────────────────────
signal building_selected(instance_id: String)
signal building_deselected()
signal building_demolished(instance_id: String)

# ── Building Upgrades ─────────────────────────────────────────────────────────
signal building_upgrade_started(instance_id: String, target_data_id: String, complete_day: int)
signal building_upgrade_completed(old_instance_id: String, new_instance_id: String)

# ── Roads ─────────────────────────────────────────────────────────────────────
signal road_placed(tile: Vector2i)
signal road_removed(tile: Vector2i)
signal road_mode_entered()
signal road_mode_exited()

# ── Debug / UI ───────────────────────────────────────────────────────────────
signal debug_log_message(message: String)
