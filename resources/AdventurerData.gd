extends Resource
class_name AdventurerData
## Resource definition for an adventurer archetype.
## Each instance represents a class template (Fighter, Rogue, Mage, etc.).

@export var id: String = ""
@export var display_name: String = ""
@export var class_label: String = "Fighter"

@export_group("Combat Stats")
@export var base_hp: int = 100
@export var base_attack: int = 10
@export var base_defense: int = 5
@export_range(0.0, 1.0) var luck: float = 0.5

@export_group("Progression")
@export var starting_level: int = 1
@export var preferred_dungeon_depth: int = 1

@export_group("Economy")
@export var hire_cost: int = 50
@export var daily_wage: int = 20

@export_group("Visuals")
@export var sprite_path: String = ""
@export var portrait_path: String = ""
