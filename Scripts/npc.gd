extends CharacterBody2D

@export var npc_name: String = "NPC"
@export var animation: String = "idle"
@export var has_task: bool = false
@export var task_name: String = ""
@export var required_item: String = ""
@export var gives_item: String = ""

# Dialogue arrays
@export var task_dialogue: Array[String] = []
@export var complete_dialogue: Array[String] = []
@export var need_item_dialogue: Array[String] = []

var task_completed := false
var game_manager: Node = null
var interaction_cooldown := 0.0
const COOLDOWN_TIME := 5.0

func _ready():
	add_to_group("npcs")
	$AnimatedSprite2D.play(animation)
	game_manager = get_node_or_null("/root/World/GameManager")

func _process(delta):
	if interaction_cooldown > 0:
		interaction_cooldown -= delta

func get_interaction_text() -> String:
	if interaction_cooldown > 0:
		return ""
	if has_task and not task_completed:
		return "Press E to talk to " + npc_name
	return ""

func can_interact() -> bool:
	return interaction_cooldown <= 0

func interact(_player):
	if interaction_cooldown > 0:
		return

	if game_manager == null:
		game_manager = get_node_or_null("/root/World/GameManager")

	if game_manager == null:
		return

	# Start cooldown
	interaction_cooldown = COOLDOWN_TIME

	if has_task and not task_completed:
		# Check if player has required item for delivery
		if required_item != "":
			if game_manager.has_item(required_item):
				# Complete delivery task
				game_manager.remove_from_inventory(required_item)
				task_completed = true

				var messages = complete_dialogue if not complete_dialogue.is_empty() else [
					"Perfect! Thanks for bringing the " + required_item + "!",
					"You're a lifesaver, {player}!"
				]
				game_manager.show_dialogue(npc_name, messages)
				game_manager.complete_task(task_name)
			else:
				# Player doesn't have the item
				var messages = need_item_dialogue if not need_item_dialogue.is_empty() else [
					"Hey {player}!",
					"I really need that " + required_item + "...",
					"Can you find one and bring it to me?"
				]
				game_manager.show_dialogue(npc_name, messages)
		elif gives_item != "":
			# NPC gives item to player
			task_completed = true

			var messages = task_dialogue if not task_dialogue.is_empty() else [
				"Oh {player}, perfect timing!",
				"Here, take this " + gives_item + ".",
				"Make sure it gets where it needs to go!"
			]
			game_manager.show_dialogue(npc_name, messages)
			game_manager.add_to_inventory(gives_item)
			game_manager.complete_task(task_name)
		else:
			# Simple interaction task
			task_completed = true

			var messages = task_dialogue if not task_dialogue.is_empty() else [
				"Thanks for stopping by, {player}!",
				"I appreciate you checking in."
			]
			game_manager.show_dialogue(npc_name, messages)
			game_manager.complete_task(task_name)
	# No idle dialogue - task NPCs only talk for tasks

func reset():
	task_completed = false
	interaction_cooldown = 0.0
