extends Resource
class_name LootTableData
## Resource definition for a loot table.
## Defines what drops when a mob is defeated or a chest is opened.

@export var id: String = ""
@export var display_name: String = ""

@export_group("Gold")
@export var guaranteed_gold_min: int = 0
@export var guaranteed_gold_max: int = 0

@export_group("Items")
@export var item_rolls: int = 1
## Number of times to roll the item_entries table per drop event

@export var item_entries: Array = []
## Array of Dictionaries: { "item_id": String, "weight": float, "count_min": int, "count_max": int }
## Weights are relative (e.g., 10 = 10× more likely than weight 1).

func roll_gold() -> int:
	if guaranteed_gold_max <= 0:
		return 0
	return randi_range(guaranteed_gold_min, guaranteed_gold_max)

func roll_items() -> Array[Dictionary]:
	## Returns a list of { item_id, count } for this loot roll.
	var results: Array[Dictionary] = []
	if item_entries.is_empty():
		return results
	var total_weight: float = 0.0
	for entry in item_entries:
		total_weight += float(entry.get("weight", 1.0))
	for _i in range(item_rolls):
		var roll: float = randf() * total_weight
		var cumulative: float = 0.0
		for entry in item_entries:
			cumulative += float(entry.get("weight", 1.0))
			if roll <= cumulative:
				var count: int = randi_range(
					int(entry.get("count_min", 1)),
					int(entry.get("count_max", 1))
				)
				results.append({ "item_id": str(entry.get("item_id", "")), "count": count })
				break
	return results
