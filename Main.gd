extends Node2D

# Scene References
@export var ball_scene: PackedScene
@onready var initial_ui: CanvasLayer = $InitialUI
@onready var background: TextureRect = $InitialUI/Background
@onready var background_start: TextureRect = $InitialUI/BackgroundStart
@onready var start_button: Button = $InitialUI/StartButton
@onready var countdown_label: Label = $InitialUI/CountdownLabel
@onready var spawn_timer: Timer = $SpawnTimer
@onready var countdown_timer: Timer = $CountdownTimer
@onready var loading_timer: Timer = $LoadingTimer
@onready var counter_area: Area2D = $CounterArea
@onready var game_timer: Timer = $GameTimer
@onready var game_timer_label: Label = $InitialUI/GameTimerLabel

# Exported variables with type hints
@export var max_monkeys: int = 10
@export var spawn_count: int = 5
@export var spawn_interval: float = 0.5
@export var game_duration: float = 10.0

# Game Variables
var ball_count = 0
var countdown_time = 3
var game_active = false
var updating_timer = false

func _ready() -> void:
	# Initial UI setup
	countdown_label.visible = false
	game_active = false
	background_start.visible = false
	start_button.visible = false
	
	# Set timer properties
	spawn_timer.wait_time = spawn_interval
	game_timer.wait_time = game_duration
	game_timer.one_shot = true
	game_timer.timeout.connect(_on_game_timer_timeout)

	# Verify and setup loading timer
	if loading_timer:
		loading_timer.wait_time = 3.0
		loading_timer.one_shot = true
		loading_timer.timeout.connect(_on_initial_loading_complete)
		loading_timer.start()
	else:
		push_error("LoadingTimer node is missing!")
		_on_initial_loading_complete()

	_safe_signal_connections()

func _safe_signal_connections() -> void:
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
	background.visible = false
	background_start.visible = true
	start_button.visible = true
	countdown_label.visible = false

func _on_start_button_pressed() -> void:
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
		background_start.visible = false
		game_active = true
		countdown_timer.stop()
		game_timer.start()
		spawn_timer.start()
		updating_timer = true
		game_timer_label.visible = true  # Ensure label is visible

func _on_game_timer_timeout():
	game_active = false
	spawn_timer.stop()
	updating_timer = false
	game_timer_label.text = "00:00"
	for monkey in get_tree().get_nodes_in_group("ball"):
		monkey.can_move = false
	countdown_label.text = "TIME'S UP!"
	countdown_label.visible = true

func _on_spawn_timer_timeout() -> void:
	if not game_active:
		return
	var current_monkeys = get_tree().get_nodes_in_group("ball").size()
	if current_monkeys < max_monkeys:
		for i in spawn_count:
			var ball_instance = ball_scene.instantiate()
			var viewport_rect = get_viewport_rect()
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
	game_timer.stop()
	game_timer_label.text = ""
	for ball in get_tree().get_nodes_in_group("ball"):
		ball.queue_free()
	ball_count = 0
	initial_ui.visible = true
	background.visible = true
	background_start.visible = false
	start_button.visible = false
	loading_timer.start(3.0)
	if game_timer.is_connected("timeout", _on_game_timer_timeout):
		game_timer.timeout.disconnect(_on_game_timer_timeout)
	game_timer.timeout.connect(_on_game_timer_timeout)

func _process(delta):
	if updating_timer:
		var time_left_int = int(ceil(game_timer.time_left))
		var minutes = time_left_int / 60
		var seconds = time_left_int % 60
		game_timer_label.text = "%02d:%02d" % [minutes, seconds]
		#print("Time left: ", game_timer.time_left)
