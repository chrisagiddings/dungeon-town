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

# ── Item Quality (RPG standard colours) ──────────────────────────────────────
const QUALITY_COMMON    := Color(0.78, 0.78, 0.78)  # Silver-white
const QUALITY_UNCOMMON  := Color(0.12, 0.75, 0.12)  # Green
const QUALITY_RARE      := Color(0.10, 0.45, 1.00)  # Blue
const QUALITY_EPIC      := Color(0.64, 0.21, 0.93)  # Purple
const QUALITY_LEGENDARY := Color(1.00, 0.50, 0.00)  # Orange

static func get_quality_color(quality: String) -> Color:
	match quality.to_lower():
		"common":    return QUALITY_COMMON
		"uncommon":  return QUALITY_UNCOMMON
		"rare":      return QUALITY_RARE
		"epic":      return QUALITY_EPIC
		"legendary": return QUALITY_LEGENDARY
	return Color.WHITE

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

# ── Terrain Types ─────────────────────────────────────────────────────────────
const TERRAIN_PLAINS  := Color(0.60, 0.72, 0.35)  # Light grassy green — buildable, farmable
const TERRAIN_FOREST  := Color(0.18, 0.42, 0.18)  # Deep forest green — lumber, quests, monsters
const TERRAIN_MOUNTAIN := Color(0.52, 0.50, 0.46) # Grey-brown — mining, impassable peaks
const TERRAIN_ROCKY   := Color(0.46, 0.44, 0.40)  # Lighter rock — quarry sites
const TERRAIN_WATER   := Color(0.20, 0.50, 0.70)  # Water blue — impassable
const TERRAIN_MARSH   := Color(0.30, 0.42, 0.25)  # Murky olive — slow, limited building
const TERRAIN_SAND    := Color(0.78, 0.72, 0.50)  # Sandy yellow — poor fertility
const TERRAIN_ROAD    := Color(0.45, 0.40, 0.35)  # Dusty brown (road tiles)

static func get_terrain_color(terrain_type: String) -> Color:
	match terrain_type.to_lower():
		"plains":   return TERRAIN_PLAINS
		"forest":   return TERRAIN_FOREST
		"mountain": return TERRAIN_MOUNTAIN
		"rocky":    return TERRAIN_ROCKY
		"water":    return TERRAIN_WATER
		"marsh":    return TERRAIN_MARSH
		"sand":     return TERRAIN_SAND
		"road":     return TERRAIN_ROAD
		_:          return TERRAIN_PLAINS  # default to plains

# ── Legacy environment names (kept for compatibility) ─────────────────────────
const ENV_TERRAIN := TERRAIN_PLAINS
const ENV_ROAD    := TERRAIN_ROAD
const ENV_WATER   := TERRAIN_WATER

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
