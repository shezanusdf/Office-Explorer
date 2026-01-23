extends Area2D

@export var item_name: String = "Item"
@export var pickup_item: String = ""  # What item to add to inventory when picked up
@export var is_task_item: bool = true  # Whether picking this up counts as a task

signal collected(item_name)

var is_collected := false
var game_manager: Node = null

func _ready():
	add_to_group("interactables")
	game_manager = get_node_or_null("/root/World/GameManager")

func get_interaction_text() -> String:
	if is_collected:
		return ""
	return "Press E to pick up " + item_name

func interact(player):
	if is_collected:
		return
	_collect()

func _collect():
	if is_collected:
		return
	is_collected = true

	if game_manager == null:
		game_manager = get_node_or_null("/root/World/GameManager")

	# Add item to inventory if specified
	if pickup_item != "" and game_manager:
		game_manager.add_to_inventory(pickup_item)

	# Complete as task if enabled
	if is_task_item:
		emit_signal("collected", item_name)

	queue_free()

func reset():
	is_collected = false
	visible = true
