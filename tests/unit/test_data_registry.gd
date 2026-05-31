extends GutTest
## Unit tests for DataRegistry autoload.
## Verifies that all expected T1 buildings are loaded from resources/buildings/.

# ── Expected T1 building IDs (all .tres files in resources/buildings/ except dungeon_entrance) ──

const EXPECTED_T1_IDS: Array = [
	"alchemist_t1",
	"bunkhouse_t1",
	"farm_t1",
	"farmstead_t1",
	"guard_t1",
	"guild_t1",
	"house_t1",
	"lodging_t1",
	"lumber_t1",
	"mayor_t1",
	"notice_board_t1",
	"quarry_t1",
	"smith_t1",
	"store_t1",
	"tavern_t1",
	"temple_t1",
]

# ── Registry is populated ─────────────────────────────────────────────────────

func test_registry_has_buildings() -> void:
	assert_true(DataRegistry.buildings.size() > 0, "DataRegistry should have buildings loaded")

func test_all_expected_t1_buildings_present() -> void:
	for id in EXPECTED_T1_IDS:
		assert_not_null(DataRegistry.get_building(id), "Missing building: %s" % id)

func test_dungeon_entrance_is_loaded() -> void:
	assert_not_null(DataRegistry.get_building("dungeon_entrance"))

func test_unknown_id_returns_null() -> void:
	assert_null(DataRegistry.get_building("does_not_exist"))

# ── BuildingData integrity ────────────────────────────────────────────────────

func test_all_buildings_have_non_empty_id() -> void:
	for id in DataRegistry.get_all_building_ids():
		var data := DataRegistry.get_building(id) as BuildingData
		assert_ne(data.id, "", "Building at key '%s' has empty id" % id)

func test_all_buildings_have_display_name() -> void:
	for id in DataRegistry.get_all_building_ids():
		var data := DataRegistry.get_building(id) as BuildingData
		assert_ne(data.display_name, "", "Building '%s' has no display_name" % id)

func test_all_buildings_have_valid_footprint() -> void:
	for id in DataRegistry.get_all_building_ids():
		var data := DataRegistry.get_building(id) as BuildingData
		assert_true(data.footprint.x > 0 and data.footprint.y > 0,
			"Building '%s' has invalid footprint %s" % [id, data.footprint])

func test_all_buildings_have_category() -> void:
	for id in DataRegistry.get_all_building_ids():
		var data := DataRegistry.get_building(id) as BuildingData
		assert_ne(data.category, "", "Building '%s' has no category" % id)

# ── Specific building data spot-checks ───────────────────────────────────────

func test_lodging_t1_footprint_is_2x2() -> void:
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	assert_eq(data.footprint, Vector2i(2, 2))

func test_farm_t1_footprint_is_3x3() -> void:
	var data := DataRegistry.get_building("farm_t1") as BuildingData
	assert_eq(data.footprint, Vector2i(3, 3))

func test_house_t1_footprint_is_1x1() -> void:
	var data := DataRegistry.get_building("house_t1") as BuildingData
	assert_eq(data.footprint, Vector2i(1, 1))

func test_notice_board_t1_footprint_is_1x1() -> void:
	var data := DataRegistry.get_building("notice_board_t1") as BuildingData
	assert_eq(data.footprint, Vector2i(1, 1))

func test_dungeon_entrance_is_fixed_position() -> void:
	var data := DataRegistry.get_building("dungeon_entrance") as BuildingData
	assert_true(data.fixed_position)

func test_lodging_t1_unlocks_at_start() -> void:
	var data := DataRegistry.get_building("lodging_t1") as BuildingData
	assert_true(data.unlock_at_start)

# ── get_buildings_by_tier ─────────────────────────────────────────────────────

func test_get_buildings_by_tier_returns_only_t1() -> void:
	var t1 := DataRegistry.get_buildings_by_tier(1)
	for data in t1:
		assert_eq(data.tier, 1, "get_buildings_by_tier(1) returned a non-T1 building: %s" % data.id)

func test_get_buildings_by_tier_t1_not_empty() -> void:
	var t1 := DataRegistry.get_buildings_by_tier(1)
	assert_true(t1.size() > 0)

func test_get_buildings_by_tier_nonexistent_returns_empty() -> void:
	var t99 := DataRegistry.get_buildings_by_tier(99)
	assert_eq(t99.size(), 0)
