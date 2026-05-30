@tool
extends Node2D
class_name PlaceholderMesh
## PlaceholderMesh — a colored rectangle placeholder with optional label.
## Used for all placeholder buildings, NPCs, and objects during development.
## Accepts color and label via exported properties or set_placeholder() method.

@export var placeholder_color: Color = Color.WHITE:
	set(value):
		placeholder_color = value
		queue_redraw()

@export var placeholder_label: String = "":
	set(value):
		placeholder_label = value
		if _label_node:
			_label_node.text = value

@export var placeholder_size: Vector2 = Vector2(64, 64):
	set(value):
		placeholder_size = value
		queue_redraw()
		_update_label_position()

@export var show_outline: bool = false:
	set(value):
		show_outline = value
		queue_redraw()

@export var outline_color: Color = PlaceholderColors.ZONE_BOSS:
	set(value):
		outline_color = value
		if show_outline:
			queue_redraw()

@export var outline_width: float = 3.0

var _label_node: Label

func _ready() -> void:
	_setup_label()
	queue_redraw()

func _setup_label() -> void:
	_label_node = Label.new()
	_label_node.text = placeholder_label
	_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_node.add_theme_font_size_override("font_size", 10)
	_label_node.add_theme_color_override("font_color", Color.BLACK)
	_label_node.add_theme_color_override("font_outline_color", Color.WHITE)
	_label_node.add_theme_constant_override("outline_size", 2)
	add_child(_label_node)
	_update_label_position()

func _update_label_position() -> void:
	if _label_node:
		_label_node.position = Vector2(-placeholder_size.x / 2, -placeholder_size.y / 2)
		_label_node.size = placeholder_size

func _draw() -> void:
	var half_size := placeholder_size / 2
	var rect := Rect2(-half_size, placeholder_size)
	
	# Fill
	draw_rect(rect, placeholder_color)
	
	# Outline (for bosses or selected items)
	if show_outline:
		draw_rect(rect, outline_color, false, outline_width)

## Configure the placeholder in one call
func set_placeholder(color: Color, label: String, size: Vector2 = Vector2(64, 64)) -> void:
	placeholder_color = color
	placeholder_label = label
	placeholder_size = size

## Create a building placeholder with category-based color
static func create_building(category: String, label: String, size: Vector2 = Vector2(64, 64)) -> PlaceholderMesh:
	var instance := PlaceholderMesh.new()
	instance.set_placeholder(PlaceholderColors.get_building_color(category), label, size)
	return instance

## Create a mob placeholder with zone-based color
static func create_mob(zone: int, label: String, size: Vector2 = Vector2(32, 32), is_boss: bool = false) -> PlaceholderMesh:
	var instance := PlaceholderMesh.new()
	instance.set_placeholder(PlaceholderColors.get_mob_color(zone), label, size)
	if is_boss:
		instance.show_outline = true
		instance.outline_color = PlaceholderColors.ZONE_BOSS
	return instance

## Create an adventurer placeholder
static func create_adventurer(label: String, size: Vector2 = Vector2(24, 48)) -> PlaceholderMesh:
	var instance := PlaceholderMesh.new()
	instance.set_placeholder(PlaceholderColors.ADVENTURER, label, size)
	return instance

## Create a citizen placeholder
static func create_citizen(label: String, size: Vector2 = Vector2(20, 40)) -> PlaceholderMesh:
	var instance := PlaceholderMesh.new()
	instance.set_placeholder(PlaceholderColors.CITIZEN, label, size)
	return instance
