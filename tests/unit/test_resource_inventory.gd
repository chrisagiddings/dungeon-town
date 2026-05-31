extends GutTest
## Unit tests for ResourceInventory autoload.

func before_each() -> void:
	ResourceInventory.clear()

func after_each() -> void:
	ResourceInventory.clear()

# ── Seeding ───────────────────────────────────────────────────────────────────

func test_all_t1_resources_seeded_at_zero() -> void:
	for id in ["grain", "wood", "stone", "herbs", "leather"]:
		assert_eq(ResourceInventory.get_amount(id), 0,
			"'%s' should be seeded at 0" % id)

func test_all_t2_resources_seeded() -> void:
	for id in ["iron_ore", "iron_ingot", "ale", "bread", "cloth", "rope_lumber"]:
		assert_eq(ResourceInventory.get_amount(id), 0,
			"'%s' should be seeded at 0" % id)

func test_unseeded_resource_returns_zero() -> void:
	assert_eq(ResourceInventory.get_amount("dragon_scale"), 0)

# ── add_resource ──────────────────────────────────────────────────────────────

func test_add_increases_amount() -> void:
	ResourceInventory.add_resource("grain", 10)
	assert_eq(ResourceInventory.get_amount("grain"), 10)

func test_add_accumulates() -> void:
	ResourceInventory.add_resource("wood", 15)
	ResourceInventory.add_resource("wood", 5)
	assert_eq(ResourceInventory.get_amount("wood"), 20)

func test_add_emits_resource_changed() -> void:
	watch_signals(EventBus)
	ResourceInventory.add_resource("stone", 5)
	assert_signal_emitted(EventBus, "resource_changed")

func test_add_zero_does_nothing() -> void:
	ResourceInventory.add_resource("grain", 0)
	assert_eq(ResourceInventory.get_amount("grain"), 0)

func test_add_negative_does_nothing() -> void:
	ResourceInventory.add_resource("grain", 5)
	ResourceInventory.add_resource("grain", -3)
	assert_eq(ResourceInventory.get_amount("grain"), 5)

func test_add_unseeded_resource_works() -> void:
	ResourceInventory.add_resource("mithril", 3)
	assert_eq(ResourceInventory.get_amount("mithril"), 3)

# ── consume_resource ──────────────────────────────────────────────────────────

func test_consume_deducts_amount() -> void:
	ResourceInventory.add_resource("grain", 20)
	ResourceInventory.consume_resource("grain", 8)
	assert_eq(ResourceInventory.get_amount("grain"), 12)

func test_consume_returns_true_on_success() -> void:
	ResourceInventory.add_resource("wood", 10)
	assert_true(ResourceInventory.consume_resource("wood", 5))

func test_consume_returns_false_when_insufficient() -> void:
	ResourceInventory.add_resource("stone", 3)
	assert_false(ResourceInventory.consume_resource("stone", 10))

func test_consume_does_not_deduct_when_insufficient() -> void:
	ResourceInventory.add_resource("herbs", 3)
	ResourceInventory.consume_resource("herbs", 10)
	assert_eq(ResourceInventory.get_amount("herbs"), 3)

func test_consume_exact_amount_succeeds() -> void:
	ResourceInventory.add_resource("ale", 5)
	assert_true(ResourceInventory.consume_resource("ale", 5))
	assert_eq(ResourceInventory.get_amount("ale"), 0)

func test_consume_emits_resource_changed() -> void:
	ResourceInventory.add_resource("iron_ore", 10)
	watch_signals(EventBus)
	ResourceInventory.consume_resource("iron_ore", 3)
	assert_signal_emitted(EventBus, "resource_changed")

func test_consume_emits_resource_depleted_when_reaching_zero() -> void:
	ResourceInventory.add_resource("cloth", 5)
	watch_signals(EventBus)
	ResourceInventory.consume_resource("cloth", 5)
	assert_signal_emitted(EventBus, "resource_depleted")

func test_consume_does_not_emit_depleted_when_partial() -> void:
	ResourceInventory.add_resource("bread", 10)
	watch_signals(EventBus)
	ResourceInventory.consume_resource("bread", 5)
	assert_signal_not_emitted(EventBus, "resource_depleted")

func test_consume_zero_returns_false() -> void:
	assert_false(ResourceInventory.consume_resource("grain", 0))

# ── has_resource ──────────────────────────────────────────────────────────────

func test_has_resource_false_when_empty() -> void:
	assert_false(ResourceInventory.has_resource("grain", 1))

func test_has_resource_true_when_exact() -> void:
	ResourceInventory.add_resource("stone", 5)
	assert_true(ResourceInventory.has_resource("stone", 5))

func test_has_resource_true_when_more_than_enough() -> void:
	ResourceInventory.add_resource("wood", 20)
	assert_true(ResourceInventory.has_resource("wood", 10))

func test_has_resource_false_when_insufficient() -> void:
	ResourceInventory.add_resource("iron_ingot", 3)
	assert_false(ResourceInventory.has_resource("iron_ingot", 10))

# ── get_all ───────────────────────────────────────────────────────────────────

func test_get_all_returns_all_seeded_ids() -> void:
	var all := ResourceInventory.get_all()
	for id in ResourceInventory.RESOURCE_IDS:
		assert_true(id in all, "get_all should include '%s'" % id)

func test_get_all_returns_copy_not_reference() -> void:
	var all := ResourceInventory.get_all()
	all["grain"] = 9999
	assert_eq(ResourceInventory.get_amount("grain"), 0, "get_all should return a copy")

# ── get_display_name ──────────────────────────────────────────────────────────

func test_display_name_known_resource() -> void:
	assert_eq(ResourceInventory.get_display_name("iron_ore"), "Iron Ore")

func test_display_name_unknown_resource_capitalizes() -> void:
	var name := ResourceInventory.get_display_name("dragon_scale")
	assert_ne(name, "", "Unknown resource should return a non-empty fallback")

# ── save/load round-trip ──────────────────────────────────────────────────────

func test_resources_survive_save_load() -> void:
	ResourceInventory.add_resource("grain",    50)
	ResourceInventory.add_resource("wood",     30)
	ResourceInventory.add_resource("iron_ore", 12)
	SaveSystem.save(5)
	ResourceInventory.clear()
	SaveSystem.load_slot(5)
	assert_eq(ResourceInventory.get_amount("grain"),    50)
	assert_eq(ResourceInventory.get_amount("wood"),     30)
	assert_eq(ResourceInventory.get_amount("iron_ore"), 12)
	SaveSystem.delete_save(5)

func test_clear_resets_to_zero() -> void:
	ResourceInventory.add_resource("grain", 100)
	ResourceInventory.clear()
	assert_eq(ResourceInventory.get_amount("grain"), 0)
