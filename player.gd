extends CharacterBody2D

@export var speed: float = 80.0

var character_direction: Vector2 = Vector2.ZERO
var sitting: bool = false
var last_facing_right: bool = false
var anim_state: String = "idle"
var is_sitting: bool = false

# Interaction system
var nearby_interactable: Node = null
var game_manager: Node = null

@onready var furni: TileMap = get_parent().get_node("furni")

func _ready():
	game_manager = get_node_or_null("/root/World/GameManager")

func _physics_process(delta):
	if sitting:
		velocity = Vector2.ZERO
		return

	# Get input
	character_direction.x = Input.get_axis("move_left", "move_right")
	character_direction.y = Input.get_axis("move_up", "move_down")

	if character_direction.length() > 0:
		character_direction = character_direction.normalized()

	# Flip sprite based on direction
	if character_direction.x > 0:
		$AnimatedSprite2D.flip_h = false
		last_facing_right = false
	elif character_direction.x < 0:
		$AnimatedSprite2D.flip_h = true
		last_facing_right = true

	# Move and animate
	var new_anim = "idle"
	if sitting:
		new_anim = "sit"
	elif character_direction != Vector2.ZERO:
		new_anim = "walking"

	if new_anim != anim_state or sitting != is_sitting:
		anim_state = new_anim
		is_sitting = sitting
		$AnimatedSprite2D.play(anim_state)

	if character_direction != Vector2.ZERO:
		velocity = character_direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()

	# Check for nearby interactables
	check_nearby_interactables()

func check_nearby_interactables():
	var found_interactable: Node = null
	var closest_distance := 50.0  # Interaction range

	# Check for interactable objects
	var interactables = get_tree().get_nodes_in_group("interactables")
	for obj in interactables:
		var dist = global_position.distance_to(obj.global_position)
		if dist < closest_distance:
			closest_distance = dist
			found_interactable = obj

	# Check for NPCs
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		var dist = global_position.distance_to(npc.global_position)
		if dist < closest_distance:
			# Check if NPC can be interacted with (cooldown and has task)
			if npc.has_method("can_interact") and npc.can_interact():
				if npc.has_method("get_interaction_text"):
					var text = npc.get_interaction_text()
					if text != "":
						closest_distance = dist
						found_interactable = npc

	# Update interaction popup
	if found_interactable != nearby_interactable:
		nearby_interactable = found_interactable
		if nearby_interactable and game_manager:
			var interact_text = "Press E to interact"
			if nearby_interactable.has_method("get_interaction_text"):
				interact_text = nearby_interactable.get_interaction_text()
			if interact_text != "":
				game_manager.show_interaction_popup(interact_text)
			else:
				game_manager.hide_interaction_popup()
		elif game_manager:
			game_manager.hide_interaction_popup()

func _input(event):
	# Don't process input while dialogue is active
	if game_manager and game_manager.dialogue_active:
		return

	if event.is_action_pressed("interact"):
		# First check for interactable objects/NPCs
		if nearby_interactable:
			if nearby_interactable.has_method("interact"):
				nearby_interactable.interact(self)
				return

		# Otherwise check for chairs
		if sitting:
			stand_up()
		else:
			try_sit()

func try_sit():
	var local_pos = furni.to_local(global_position)
	var player_cell = furni.local_to_map(local_pos)

	var cells_to_check = [
		player_cell,
		player_cell + Vector2i(0, -1),
		player_cell + Vector2i(0, 1),
		player_cell + Vector2i(-1, 0),
		player_cell + Vector2i(1, 0),
		player_cell + Vector2i(-1, -1),
		player_cell + Vector2i(1, -1),
		player_cell + Vector2i(-1, 1),
		player_cell + Vector2i(1, 1),
	]

	for cell in cells_to_check:
		var tile_data = furni.get_cell_tile_data(0, cell)
		if tile_data != null and tile_data.get_custom_data("interaction") == "chair":
			sit_down(cell)
			return

func sit_down(cell: Vector2i):
	sitting = true
	var chair_world_pos = furni.to_global(furni.map_to_local(cell))
	global_position = chair_world_pos + Vector2(0, 8.0)
	$AnimatedSprite2D.play("sit")

func stand_up():
	sitting = false
	$AnimatedSprite2D.flip_h = last_facing_right
	$AnimatedSprite2D.play("idle")

func update_animation(new_anim: String, sitting_state: bool, facing_right: bool):
	anim_state = new_anim
	is_sitting = sitting_state
	last_facing_right = facing_right
	$AnimatedSprite2D.flip_h = last_facing_right
	$AnimatedSprite2D.play(anim_state)
