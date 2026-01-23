extends Area2D

@export var item_name: String = "Item"
@export var pickup_text: String = "Press E to pick up"
@export var is_delivery_point: bool = false
@export var required_item: String = ""
@export var task_name: String = ""

signal collected(item_name)

var is_collected := false
var game_manager: Node = null

func _ready():
	add_to_group("interactables")
	game_manager = get_node_or_null("/root/World/GameManager")
	body_entered.connect(_on_body_entered)

func get_interaction_text() -> String:
	if is_delivery_point:
		return "Press E to deliver " + required_item
	return pickup_text

func interact(player):
	if is_collected:
		return

	if game_manager == null:
		game_manager = get_node_or_null("/root/World/GameManager")

	if is_delivery_point:
		# This is a delivery location
		if game_manager and game_manager.has_item(required_item):
			game_manager.remove_from_inventory(required_item)
			game_manager.complete_task(task_name)
			is_collected = true
			visible = false
	else:
		# This is a pickup item
		is_collected = true
		visible = false
		collected.emit(item_name)
		if game_manager:
			game_manager.add_to_inventory(item_name)

func _on_body_entered(body):
	# Auto-collect small items when walked over (optional)
	pass

func reset():
	is_collected = false
	visible = true
