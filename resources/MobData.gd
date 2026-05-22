extends Resource
class_name MobData
## Resource definition for a dungeon mob/enemy.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Dungeon")
@export var dungeon_depth: int = 1
@export_range(0.0, 10.0) var spawn_weight: float = 1.0
## Higher weight = more likely to appear in random encounters

@export_group("Combat Stats")
@export var hp: int = 30
@export var attack: int = 5
@export var defense: int = 2

@export_group("Rewards")
@export var exp_reward: int = 10
@export var gold_drop_min: int = 1
@export var gold_drop_max: int = 10
@export var loot_table_id: String = ""
## ID of a LootTableData resource to roll on defeat

@export_group("Visuals")
@export var sprite_path: String = ""
