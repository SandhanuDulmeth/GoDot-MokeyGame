#main.gd
extends Node2D

# Scene References
@export var ball_scene: PackedScene
@onready var initial_ui: CanvasLayer = $InitialUI
@onready var background: TextureRect = $InitialUI/Background
@onready var background_start: TextureRect = $InitialUI/BackgroundStart
@onready var start_button: Button = $InitialUI/StartButton
@onready var countdown_label: Label = $InitialUI/CountdownLabel  # Moved to InitialUI
@onready var spawn_timer: Timer = $SpawnTimer
@onready var countdown_timer: Timer = $CountdownTimer
@onready var loading_timer: Timer = $LoadingTimer
@onready var counter_area: Area2D = $CounterArea

@export var max_monkeys = 10  # Maximum allowed monkeys on screen
@export var spawn_count = 5   # Number of monkeys per spawn
@export var spawn_interval = 0.5  # Time between spawn waves

# Game Variables
var ball_count = 0
var countdown_time = 3
var game_active = false

func _ready() -> void:

	# Initial UI setup
	countdown_label.visible = false
	game_active = false
	background_start.visible = false
	start_button.visible = false
	spawn_timer.wait_time = spawn_interval
	# Verify and setup loading timer
	if loading_timer:
		loading_timer.wait_time = 3.0
		loading_timer.one_shot = true
		loading_timer.timeout.connect(_on_initial_loading_complete)
		loading_timer.start()
	else:
		push_error("LoadingTimer node is missing!")
		_on_initial_loading_complete()  # Fallback

	# Connect signals safely
	_safe_signal_connections()  # Now properly defined below

# NEW FUNCTION: Safely connect all signal dependencies
func _safe_signal_connections() -> void:
	# Connect UI and timer signals
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if countdown_timer:
		countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	if counter_area:
		counter_area.body_entered.connect(_on_counter_area_body_entered)

func _on_initial_loading_complete():
	
	start_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	start_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	start_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	start_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Show main menu UI
	background.visible = false
	background_start.visible = true
	start_button.visible = true
	countdown_label.visible = false  # Ensure countdown is hidden initially

func _on_start_button_pressed() -> void:
	# Start game sequence
	start_button.visible = false
	countdown_label.visible = true
	countdown_time = 3
	countdown_label.text = "3"
	countdown_timer.start()

func _on_countdown_timer_timeout() -> void:
	
	countdown_time -= 1
	
	if countdown_time > 0:
		countdown_label.text = str(countdown_time)
	else:
		countdown_label.text = "GO!"
		await get_tree().create_timer(0.5).timeout
		countdown_label.visible = false
		background_start.visible = false  # Add this line
		game_active = true
		spawn_timer.start()



func _on_spawn_timer_timeout() -> void:
	if not game_active:
		return
		
	var current_monkeys = get_tree().get_nodes_in_group("ball").size()
	
	if current_monkeys < max_monkeys:
		for i in spawn_count:
			var ball_instance = ball_scene.instantiate()
			var viewport_rect = get_viewport_rect()
	
	# Random edge spawning
			var edge = randi() % 4
			var spawn_pos := Vector2()
			var direction := Vector2()
	
			match edge:
				0:  # Top
					spawn_pos = Vector2(randf_range(50, viewport_rect.size.x-50), -50)
					direction = Vector2(randf_range(-0.3, 0.3), 1)
				1:  # Right
					spawn_pos = Vector2(viewport_rect.size.x+50, randf_range(50, viewport_rect.size.y-50))
					direction = Vector2(-1, randf_range(-0.3, 0.3))
				2:  # Bottom
					spawn_pos = Vector2(randf_range(50, viewport_rect.size.x-50), viewport_rect.size.y+50)
					direction = Vector2(randf_range(-0.3, 0.3), -1)
				3:  # Left
					spawn_pos = Vector2(-50, randf_range(50, viewport_rect.size.y-50))
					direction = Vector2(1, randf_range(-0.3, 0.3))
	
			ball_instance.position = spawn_pos
			ball_instance.velocity = direction.normalized() * randf_range(100, 350)
			add_child(ball_instance)

func _on_counter_area_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		ball_count += 1


func reset_game() -> void:
	game_active = false
	spawn_timer.stop()
	countdown_timer.stop()
	
	# Clear existing balls
	for ball in get_tree().get_nodes_in_group("ball"):
		ball.queue_free()
	
	# Reset counters
	ball_count = 0

	
	# Show initial UI
	initial_ui.visible = true
	background.visible = true
	background_start.visible = false
	start_button.visible = false
	loading_timer.start(3.0)
