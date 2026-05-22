extends Resource
class_name QuestData
## Resource definition for a quest posted on the guild board.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var flavor_text: String = ""

@export_group("Requirements")
@export var min_adventurer_level: int = 1
@export var dungeon_depth_required: int = 1

@export_group("Rewards")
@export var gold_reward: int = 50
@export var exp_reward: int = 100
@export var bonus_item_id: String = ""

@export_group("Timing")
@export var time_limit_days: int = 7
@export var is_repeatable: bool = false

@export_group("Objectives")
@export var objectives: Array = []
## Array of Dictionaries: { "type": String, "target": String, "count": int }
## type values: "kill", "collect", "explore", "escort"

func get_objective_summary() -> String:
	var parts: Array[String] = []
	for obj in objectives:
		parts.append("%s x%d %s" % [
			str(obj.get("type", "?")),
			int(obj.get("count", 1)),
			str(obj.get("target", "?"))
		])
	return ", ".join(parts)
