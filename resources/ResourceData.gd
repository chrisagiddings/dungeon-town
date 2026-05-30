extends Resource
class_name ResourceData
## ResourceData — defines a tradeable/consumable resource in the economy.
## Used by production buildings, shops, and adventurer consumables.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_enum("T1", "T2", "T3", "T4") var tier: String = "T1"

## Where this resource comes from (building ID or "import")
@export var source: String = ""

## Base consumption rate per day (for buildings that use this resource)
@export var base_consumption_rate: float = 1.0

## Base market value in gold
@export var base_value: int = 10

## Icon for UI display (placeholder path)
@export var icon_path: String = ""

## Category for grouping in stockpile UI
@export_enum("Raw", "Processed", "Consumable", "Luxury") var category: String = "Raw"
