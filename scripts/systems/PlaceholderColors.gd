extends Node
class_name PlaceholderColors
## PlaceholderColors — color coding constants per GDD §15.
## All placeholder assets use these colors for visual category identification.

# ── Building Categories ───────────────────────────────────────────────────────
const HOSPITALITY := Color(0.96, 0.65, 0.14)      # Warm orange — inns, taverns
const COMMERCE := Color(0.93, 0.79, 0.13)         # Gold/yellow — shops, markets
const GEAR := Color(0.55, 0.56, 0.58)             # Steel grey — smithy, armorer
const PRODUCTION := Color(0.55, 0.39, 0.21)       # Earthy brown — farms, mines
const RESIDENTIAL := Color(0.47, 0.62, 0.45)      # Muted green — housing
const CIVIC := Color(0.25, 0.41, 0.88)            # Royal blue — guild, temple, mayor

# ── Entity Types ──────────────────────────────────────────────────────────────
const ADVENTURER := Color(0.0, 0.85, 0.95)        # Bright cyan
const CITIZEN := Color(0.95, 0.93, 0.88)          # Warm white

# ── Monster Zones ─────────────────────────────────────────────────────────────
const MOB_ZONE_1 := Color(0.42, 0.56, 0.14)       # Olive — Goblin Warren
const MOB_ZONE_2 := Color(0.68, 0.78, 0.81)       # Pale blue — Undead Crypts
const MOB_ZONE_3 := Color(1.0, 0.35, 0.14)        # Orange-red — Elemental Rifts
const MOB_ZONE_4 := Color(0.55, 0.09, 0.09)       # Deep red — Demon Warrens
const MOB_ZONE_5 := Color(0.05, 0.0, 0.1)         # Void black — Void Wastes

# ── Special ───────────────────────────────────────────────────────────────────
const ZONE_BOSS := Color(1.0, 0.84, 0.0)          # Gold — zone bosses get gold outline
const DUNGEON_ENTRANCE := Color(0.25, 0.2, 0.35) # Dark purple-grey

# ── Environment ───────────────────────────────────────────────────────────────
const ENV_TERRAIN := Color(0.35, 0.45, 0.25)      # Grass green
const ENV_ROAD := Color(0.45, 0.4, 0.35)          # Dusty brown
const ENV_WATER := Color(0.2, 0.5, 0.7)           # Water blue

## Get mob color by zone number (1-5)
static func get_mob_color(zone: int) -> Color:
	match zone:
		1: return MOB_ZONE_1
		2: return MOB_ZONE_2
		3: return MOB_ZONE_3
		4: return MOB_ZONE_4
		5: return MOB_ZONE_5
		_: return Color.MAGENTA  # Error indicator

## Get building color by category string
static func get_building_color(category: String) -> Color:
	match category.to_lower():
		"hospitality", "lodging": return HOSPITALITY
		"commerce", "shop", "market": return COMMERCE
		"gear", "equipment", "smithy": return GEAR
		"production", "resource": return PRODUCTION
		"residential", "housing": return RESIDENTIAL
		"civic", "guild", "temple", "government": return CIVIC
		_: return Color.WHITE
