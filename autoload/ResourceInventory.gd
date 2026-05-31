extends Node
## ResourceInventory — town-wide resource stockpile.
## Authoritative store for all material resources. Buildings read from and write
## to this autoload. Gold lives in EconomyState; all other resources live here.
##
## All T1/T2 resource ids are pre-seeded at 0 so UI and production systems can
## always reference them without nil-checks.

# ── Seeded resource IDs ───────────────────────────────────────────────────────
const RESOURCE_IDS: Array[String] = [
	# Tier 1
	"grain", "wood", "stone", "herbs", "leather",
	# Tier 2
	"iron_ore", "iron_ingot", "ale", "bread", "cloth", "rope_lumber",
	# Tier 3 (pre-seeded so production chains can reference them)
	"steel", "coal", "arcane_dust", "crystal", "fine_cloth", "basic_potions",
]

## Human-readable display names per resource id
const DISPLAY_NAMES: Dictionary = {
	"grain":        "Grain",
	"wood":         "Wood",
	"stone":        "Stone",
	"herbs":        "Herbs",
	"leather":      "Leather",
	"iron_ore":     "Iron Ore",
	"iron_ingot":   "Iron Ingot",
	"ale":          "Ale",
	"bread":        "Bread",
	"cloth":        "Cloth",
	"rope_lumber":  "Rope & Lumber",
	"steel":        "Steel",
	"coal":         "Coal",
	"arcane_dust":  "Arcane Dust",
	"crystal":      "Crystal",
	"fine_cloth":   "Fine Cloth",
	"basic_potions":"Basic Potions",
}

# ── State ─────────────────────────────────────────────────────────────────────
var _stock: Dictionary = {}  ## resource_id → int

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_seed_resources()
	EventBus.debug_log_message.emit("ResourceInventory: ready (%d resource types)" % _stock.size())

# ── Public API ────────────────────────────────────────────────────────────────

func add_resource(id: String, amount: int) -> void:
	## Add amount to the stockpile. Silently seeds the id if not present.
	if amount <= 0:
		push_warning("ResourceInventory.add_resource: non-positive amount %d for '%s'" % [amount, id])
		return
	_stock[id] = _stock.get(id, 0) + amount
	EventBus.resource_changed.emit(id, _stock[id], amount)

func consume_resource(id: String, amount: int) -> bool:
	## Deduct amount. Returns false (no-op) if insufficient.
	if amount <= 0:
		push_warning("ResourceInventory.consume_resource: non-positive amount %d for '%s'" % [amount, id])
		return false
	var current: int = _stock.get(id, 0)
	if current < amount:
		return false
	_stock[id] = current - amount
	EventBus.resource_changed.emit(id, _stock[id], -amount)
	if _stock[id] == 0:
		EventBus.resource_depleted.emit(id)
	return true

func has_resource(id: String, amount: int = 1) -> bool:
	return _stock.get(id, 0) >= amount

func get_amount(id: String) -> int:
	return _stock.get(id, 0)

func get_all() -> Dictionary:
	## Returns a copy of the full stockpile dict.
	return _stock.duplicate()

func get_display_name(id: String) -> String:
	return DISPLAY_NAMES.get(id, id.capitalize().replace("_", " "))

func clear() -> void:
	_seed_resources()

# ── Save / Load ───────────────────────────────────────────────────────────────

func get_save_data() -> Dictionary:
	return _stock.duplicate()

func restore_from_save(data: Dictionary) -> void:
	_seed_resources()
	for id in data.keys():
		_stock[str(id)] = int(data[id])

# ── Internal ──────────────────────────────────────────────────────────────────

func _seed_resources() -> void:
	_stock.clear()
	for id in RESOURCE_IDS:
		_stock[id] = 0
