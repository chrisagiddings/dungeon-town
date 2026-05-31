extends GutTest
## Unit tests for ProductionManager and production chains.

var _pm:   ProductionManager
var _grid: BuildingGrid
var _saved_day: int

func before_each() -> void:
	_saved_day = GameState.current_day
	ResourceInventory.clear()
	_grid = BuildingGrid.new()
	_pm   = ProductionManager.new()
	_pm._grid = _grid
	add_child_autofree(_grid)
	add_child_autofree(_pm)

func after_each() -> void:
	GameState.current_day = _saved_day

# ── Basic production ──────────────────────────────────────────────────────────

func test_farm_produces_grain_on_day_tick() -> void:
	var data := DataRegistry.get_building("farm_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "farm_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("grain") > 0,
		"Farm should produce grain after a day tick")

func test_lumber_camp_produces_wood() -> void:
	var data := DataRegistry.get_building("lumber_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "lumber_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("wood") > 0)

func test_quarry_produces_stone() -> void:
	var data := DataRegistry.get_building("quarry_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "quarry_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("stone") > 0)

func test_herb_garden_produces_herbs() -> void:
	var data := DataRegistry.get_building("herb_garden_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "herb_garden_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("herbs") > 0)

func test_mine_produces_iron_ore() -> void:
	var data := DataRegistry.get_building("mine_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "mine_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("iron_ore") > 0)

# ── Chains with inputs ────────────────────────────────────────────────────────

func test_smelter_consumes_iron_ore_and_produces_ingot() -> void:
	var data := DataRegistry.get_building("smelter_t1") as BuildingData
	if data == null: return
	ResourceInventory.add_resource("iron_ore", 20)
	_grid.reserve(Vector2i(0, 0), data.footprint, "smelter_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("iron_ingot") > 0, "Smelter should produce iron ingot")
	assert_true(ResourceInventory.get_amount("iron_ore") < 20, "Smelter should consume iron ore")

func test_brewery_consumes_grain_and_produces_ale() -> void:
	var data := DataRegistry.get_building("brewery_t1") as BuildingData
	if data == null: return
	ResourceInventory.add_resource("grain", 20)
	_grid.reserve(Vector2i(0, 0), data.footprint, "brewery_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("ale") > 0)
	assert_true(ResourceInventory.get_amount("grain") < 20)

func test_bakery_consumes_grain_and_produces_bread() -> void:
	var data := DataRegistry.get_building("bakery_t1") as BuildingData
	if data == null: return
	ResourceInventory.add_resource("grain", 20)
	_grid.reserve(Vector2i(0, 0), data.footprint, "bakery_t1", "production")
	_pm._on_day_started(1)
	assert_true(ResourceInventory.get_amount("bread") > 0)

# ── Shortage / halt ───────────────────────────────────────────────────────────

func test_smelter_halts_when_no_iron_ore() -> void:
	var data := DataRegistry.get_building("smelter_t1") as BuildingData
	if data == null: return
	# No iron ore added — should not produce
	_grid.reserve(Vector2i(0, 0), data.footprint, "smelter_t1", "production")
	_pm._on_day_started(1)
	assert_eq(ResourceInventory.get_amount("iron_ingot"), 0, "Smelter should not produce without input")

func test_smelter_halt_emits_production_halted_signal() -> void:
	var data := DataRegistry.get_building("smelter_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "smelter_t1", "production")
	watch_signals(EventBus)
	_pm._on_day_started(1)
	assert_signal_emitted(EventBus, "production_halted")

func test_brewery_does_not_halt_when_grain_available() -> void:
	var data := DataRegistry.get_building("brewery_t1") as BuildingData
	if data == null: return
	ResourceInventory.add_resource("grain", 100)
	_grid.reserve(Vector2i(0, 0), data.footprint, "brewery_t1", "production")
	watch_signals(EventBus)
	_pm._on_day_started(1)
	assert_signal_not_emitted(EventBus, "production_halted")

# ── Production tick signal ────────────────────────────────────────────────────

func test_production_tick_emitted_on_success() -> void:
	var data := DataRegistry.get_building("farm_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "farm_t1", "production")
	watch_signals(EventBus)
	_pm._on_day_started(1)
	assert_signal_emitted(EventBus, "production_tick")

func test_production_tick_not_emitted_on_halt() -> void:
	var data := DataRegistry.get_building("smelter_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "smelter_t1", "production")
	watch_signals(EventBus)
	_pm._on_day_started(1)
	assert_signal_not_emitted(EventBus, "production_tick")

# ── Construction blocks production ───────────────────────────────────────────

func test_building_under_construction_does_not_produce() -> void:
	var data := DataRegistry.get_building("farm_t1") as BuildingData
	if data == null: return
	var manager := UpgradeManager.new()
	manager._grid = _grid
	add_child_autofree(manager)
	_pm._manager = manager
	var iid := _grid.reserve(Vector2i(0, 0), data.footprint, "farm_t1", "production")
	manager.start_new_construction(iid, 3)
	_pm._on_day_started(1)
	assert_eq(ResourceInventory.get_amount("grain"), 0,
		"Building under construction should not produce")

# ── Non-production buildings skipped ─────────────────────────────────────────

func test_lodging_does_not_produce_resources() -> void:
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "lodging_t1", "hospitality")
	_pm._on_day_started(1)
	# No production tick should fire
	watch_signals(EventBus)
	_pm._on_day_started(2)
	assert_signal_not_emitted(EventBus, "production_tick")

# ── Output amounts match BuildingData ────────────────────────────────────────

func test_farm_produces_correct_grain_amount() -> void:
	var data := DataRegistry.get_building("farm_t1") as BuildingData
	if data == null: return
	_grid.reserve(Vector2i(0, 0), data.footprint, "farm_t1", "production")
	_pm._on_day_started(1)
	assert_eq(ResourceInventory.get_amount("grain"), int(data.produces.get("grain", 0)))

func test_smelter_consumes_exact_input_amount() -> void:
	var data := DataRegistry.get_building("smelter_t1") as BuildingData
	if data == null: return
	var needed: int = int(data.consumes.get("iron_ore", 0))
	ResourceInventory.add_resource("iron_ore", needed + 5)
	_grid.reserve(Vector2i(0, 0), data.footprint, "smelter_t1", "production")
	_pm._on_day_started(1)
	assert_eq(ResourceInventory.get_amount("iron_ore"), 5,
		"Smelter should consume exactly %d iron ore" % needed)
