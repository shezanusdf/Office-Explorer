extends Node

# Game state
var total_tasks := 9
var completed_tasks := 0
var game_time := 360.0  # 6 minutes in seconds
var game_running := false
var game_over := false
var player_name := "Alex"

# Inventory
var inventory := []

# Dialogue state
var dialogue_active := false
var dialogue_queue := []
var current_dialogue_index := 0
var talk_sound_timer := 0.0

# UI References
@onready var tasks_label = get_node_or_null("/root/World/CanvasLayer/TopPanel/VBox/TasksLabel")
@onready var timer_label = get_node_or_null("/root/World/CanvasLayer/TopPanel/VBox/TimerLabel")
@onready var instruction_panel = get_node_or_null("/root/World/CanvasLayer/InstructionPanel")
@onready var instruction_label = get_node_or_null("/root/World/CanvasLayer/InstructionPanel/InstructionLabel")
@onready var interaction_panel = get_node_or_null("/root/World/CanvasLayer/InteractionPanel")
@onready var interaction_popup = get_node_or_null("/root/World/CanvasLayer/InteractionPanel/InteractionPopup")
@onready var end_screen = get_node_or_null("/root/World/CanvasLayer/EndScreen")
@onready var end_title = get_node_or_null("/root/World/CanvasLayer/EndScreen/EndTitle")
@onready var end_message = get_node_or_null("/root/World/CanvasLayer/EndScreen/EndMessage")
@onready var restart_button = get_node_or_null("/root/World/CanvasLayer/EndScreen/RestartButton")
@onready var dialogue_panel = get_node_or_null("/root/World/CanvasLayer/DialoguePanel")
@onready var dialogue_name = get_node_or_null("/root/World/CanvasLayer/DialoguePanel/VBox/NameLabel")
@onready var dialogue_text = get_node_or_null("/root/World/CanvasLayer/DialoguePanel/VBox/DialogueLabel")
@onready var talk_sound = get_node_or_null("/root/World/TalkSound")

# Player reference
var player: CharacterBody2D

func _ready():
	player = get_node_or_null("/root/World/Player")
	start_game()

func start_game():
	game_running = true
	game_over = false
	completed_tasks = 0
	game_time = 360.0
	inventory.clear()
	dialogue_active = false

	update_ui()

	# Show instruction briefly
	if instruction_panel:
		instruction_panel.visible = true
		if instruction_label:
			instruction_label.text = "Complete all tasks before time runs out!"
		get_tree().create_timer(4.0).timeout.connect(func():
			if instruction_panel and not dialogue_active:
				instruction_panel.visible = false
		)

	# Hide end screen
	if end_screen:
		end_screen.visible = false

	# Hide interaction popup
	if interaction_panel:
		interaction_panel.visible = false

	# Hide dialogue
	if dialogue_panel:
		dialogue_panel.visible = false

func _process(delta):
	if not game_running or game_over:
		return

	# Update timer (pause during dialogue)
	if not dialogue_active:
		game_time -= delta
		update_timer_display()

	# Check for time warnings
	if game_time <= 60.0 and game_time > 59.5:
		show_warning("1 minute remaining!")
	elif game_time <= 30.0 and game_time > 29.5:
		show_warning("30 seconds remaining!")

	# Check lose condition
	if game_time <= 0:
		game_time = 0
		lose_game()

	# Play talk sound during dialogue
	if dialogue_active and talk_sound:
		talk_sound_timer -= delta
		if talk_sound_timer <= 0:
			talk_sound.pitch_scale = randf_range(0.9, 1.3)
			talk_sound.play()
			talk_sound_timer = randf_range(0.06, 0.12)

func _input(event):
	if dialogue_active and event.is_action_pressed("interact"):
		advance_dialogue()

func update_ui():
	if tasks_label:
		tasks_label.text = "Tasks: %d / %d" % [completed_tasks, total_tasks]
	update_timer_display()

func update_timer_display():
	if timer_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		timer_label.text = "Time: %d:%02d" % [minutes, seconds]

func show_warning(message: String):
	if dialogue_active:
		return
	if instruction_panel and instruction_label:
		instruction_label.text = message
		instruction_panel.visible = true
		instruction_label.modulate = Color.RED
		get_tree().create_timer(2.0).timeout.connect(func():
			if instruction_panel and not dialogue_active:
				instruction_panel.visible = false
			if instruction_label:
				instruction_label.modulate = Color.WHITE
		)

func show_interaction_popup(message: String):
	if dialogue_active:
		return
	if interaction_panel and interaction_popup:
		interaction_popup.text = message
		interaction_panel.visible = true

func hide_interaction_popup():
	if interaction_panel:
		interaction_panel.visible = false

# Dialogue system
func show_dialogue(npc_name: String, messages: Array):
	if messages.is_empty():
		return

	dialogue_active = true
	dialogue_queue = messages
	current_dialogue_index = 0
	talk_sound_timer = 0.0

	# Hide other UI
	if interaction_panel:
		interaction_panel.visible = false
	if instruction_panel:
		instruction_panel.visible = false

	# Show dialogue panel
	if dialogue_panel:
		dialogue_panel.visible = true
	if dialogue_name:
		dialogue_name.text = npc_name

	# Show first message
	_show_current_dialogue()

	# Disable player movement
	if player:
		player.set_physics_process(false)

func _show_current_dialogue():
	if dialogue_text and current_dialogue_index < dialogue_queue.size():
		var msg = dialogue_queue[current_dialogue_index]
		# Replace {player} with player name
		msg = msg.replace("{player}", player_name)
		dialogue_text.text = msg

func advance_dialogue():
	current_dialogue_index += 1
	if current_dialogue_index >= dialogue_queue.size():
		close_dialogue()
	else:
		_show_current_dialogue()

func close_dialogue():
	dialogue_active = false
	dialogue_queue = []
	current_dialogue_index = 0

	if dialogue_panel:
		dialogue_panel.visible = false

	# Re-enable player movement
	if player:
		player.set_physics_process(true)

func complete_task(task_name: String):
	if game_over:
		return

	completed_tasks += 1
	update_ui()

	# Show task completion notification
	show_task_completed(task_name)

	# Check win condition
	if completed_tasks >= total_tasks:
		# Delay win to let dialogue finish
		get_tree().create_timer(1.5).timeout.connect(func():
			win_game()
		)

func show_task_completed(task_name: String):
	if instruction_panel and instruction_label:
		instruction_label.text = "Task %d/%d completed!" % [completed_tasks, total_tasks]
		instruction_label.modulate = Color.GREEN
		instruction_panel.visible = true
		get_tree().create_timer(2.5).timeout.connect(func():
			if instruction_panel and not dialogue_active:
				instruction_panel.visible = false
			if instruction_label:
				instruction_label.modulate = Color.WHITE
		)

func add_to_inventory(item_name: String):
	inventory.append(item_name)

func has_item(item_name: String) -> bool:
	return item_name in inventory

func remove_from_inventory(item_name: String):
	inventory.erase(item_name)

func win_game():
	game_running = false
	game_over = true

	# Disable player movement
	if player:
		player.set_physics_process(false)

	# Show end screen
	if end_screen:
		end_screen.visible = true
	if end_title:
		end_title.text = "YOU WIN!"
		end_title.modulate = Color.GREEN
	if end_message:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		end_message.text = "All tasks completed!\nTime remaining: %d:%02d" % [minutes, seconds]

func lose_game():
	game_running = false
	game_over = true

	# Disable player movement
	if player:
		player.set_physics_process(false)

	# Show end screen
	if end_screen:
		end_screen.visible = true
	if end_title:
		end_title.text = "GAME OVER"
		end_title.modulate = Color.RED
	if end_message:
		end_message.text = "Time ran out!\nTasks completed: %d / %d" % [completed_tasks, total_tasks]

func restart_game():
	# Reset player position
	if player:
		player.position = Vector2(260, -12)
		player.set_physics_process(true)

	# Reset all interactables
	get_tree().call_group("interactables", "reset")
	get_tree().call_group("npcs", "reset")

	start_game()

func _on_restart_button_pressed():
	restart_game()

# Legacy support for old item system
func _on_item_collected(item_name: Variant) -> void:
	complete_task(str(item_name))
