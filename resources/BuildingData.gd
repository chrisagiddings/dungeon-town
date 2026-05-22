extends Resource
class_name BuildingData
## Resource definition for a placeable town building.
## Create instances as .tres files via Godot editor: New Resource → BuildingData.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Economy")
@export var build_cost: int = 100
@export var income_per_day: int = 0
@export var upkeep_per_day: int = 0

@export_group("Placement")
@export var size: Vector2i = Vector2i(1, 1)
@export var max_workers: int = 0
@export var category: String = "misc"
## Valid categories: inn, shop, guild, barracks, storage, misc

@export_group("Visuals")
@export var sprite_path: String = ""  ## Path to building sprite texture
@export var tint: Color = Color.WHITE
