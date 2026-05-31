extends Resource
class_name BuildingData
## BuildingData — complete definition for a placeable town building.
## Create instances as .tres files or load from data/buildings.json via DataRegistry.

# ── Identity ──────────────────────────────────────────────────────────────────
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("hospitality", "commerce", "gear", "services", "production", "residential", "civic", "special") var category: String = "hospitality"
@export_range(1, 4) var tier: int = 1

# ── Placement ─────────────────────────────────────────────────────────────────
@export var footprint: Vector2i = Vector2i(2, 2)  ## Grid size in tiles

# ── Economy ───────────────────────────────────────────────────────────────────
@export_group("Economy")
@export var build_cost: int = 100  ## Initial construction gold cost
@export var upkeep: int = 5  ## Daily gold cost
@export var base_income: int = 0  ## Daily gold income (if any)
@export var income_per_guest: int = 0  ## For lodging buildings
@export var income_per_suite: int = 0  ## For higher-tier lodging
@export var transaction_fee_percent: float = 0.0  ## For banks
@export var auction_cut_percent: float = 0.0  ## For auction houses

# ── Staffing ──────────────────────────────────────────────────────────────────
@export_group("Staffing")
@export var staffing: int = 1  ## Workers required from population
@export var capacity: int = 0  ## How many can use at once (adventurers, citizens)
@export var workers_provided: int = 0  ## For residential buildings

# ── Production ────────────────────────────────────────────────────────────────
@export_group("Production")
@export var produces: Dictionary = {}  ## {"resource_id": amount_per_day}
@export var consumes: Dictionary = {}  ## {"resource_id": amount_per_day}
@export_enum("none", "common", "uncommon", "rare", "epic", "legendary") var gear_quality: String = "none"

# ── Services ──────────────────────────────────────────────────────────────────
@export_group("Services")
@export var rest_quality: float = 0.0  ## 0.0-1.0 HP recovery
@export var morale_bonus: int = 0
@export var healing_percent: float = 0.0  ## For temples
@export var resurrection_available: bool = false
@export var quest_board_size: int = 0  ## For guild buildings
@export var training_xp_bonus: float = 0.0  ## For guild buildings

# ── Market Accessibility ───────────────────────────────────────────────────────
@export_group("Market Accessibility")
@export var cost_per_use: int = 0          ## Gold charged to the customer per visit/use
@export var min_customer_wealth: int = 0   ## Minimum wealth bracket (0=anyone; see issue #136)
@export var max_customer_wealth: int = 99  ## Maximum wealth bracket (99=no upper limit)

# ── Unlock Conditions ─────────────────────────────────────────────────────────
@export_group("Unlock Conditions")
@export var unlock_at_start: bool = false
@export var unlock_population: int = 0  ## Town population required
@export var unlock_dungeon_depth: int = 0  ## Minimum dungeon floor discovered
@export var unlock_prerequisites: Array[String] = []  ## Building IDs that must exist
@export var unlock_supply_chains: int = 0  ## Production buildings required
@export var unlock_faction: String = ""  ## Faction reputation required
@export var unlock_faction_level: String = ""  ## neutral, friendly, allied

# ── Upgrade Path ──────────────────────────────────────────────────────────────
@export_group("Upgrade")
@export var upgrade_from: String = ""  ## Previous tier building ID
@export var upgrade_to: String = ""  ## Next tier building ID
@export var upgrade_cost: int = 0  ## Gold required
@export var upgrade_resources: Dictionary = {}  ## {"resource_id": amount}
@export var upgrade_prerequisites: Array[String] = []  ## Building IDs required
@export var upgrade_dungeon_depth: int = 0  ## Minimum floor
@export var upgrade_patron_count: int = 0  ## Lifetime patrons/customers
@export var upgrade_population: int = 0  ## Town population required
@export var upgrade_supply_chains: int = 0  ## Active production buildings required
@export var upgrade_reputation: String = ""  ## known, renowned, legendary
@export var upgrade_time_days: int = 5  ## In-game days to complete

# ── Construction ──────────────────────────────────────────────────────────────
@export_group("Construction")
@export var construction_days: int = 0  ## Days to build from scratch

# ── Visuals ───────────────────────────────────────────────────────────────────
@export_group("Visuals")
@export var placeholder_color: Color = Color.WHITE
@export var sprite_path: String = ""

# ── Special ───────────────────────────────────────────────────────────────────
@export_group("Special")
@export_multiline var special_notes: String = ""  ## Any special mechanics
@export var fixed_position: bool = false  ## Cannot be moved (dungeon entrance)

# ── Helper Methods ────────────────────────────────────────────────────────────

func get_footprint_tiles() -> int:
	return footprint.x * footprint.y

func get_daily_profit() -> int:
	return base_income - upkeep

func can_upgrade() -> bool:
	return upgrade_to != ""

func is_production_building() -> bool:
	return not produces.is_empty()

func is_service_building() -> bool:
	return category in ["gear", "services", "hospitality"]
