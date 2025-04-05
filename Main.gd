extends Node2D

@export var ball_scene: PackedScene
@onready var spawn_timer = $SpawnTimer
@onready var countdown_timer = $CountdownTimer
@onready var start_button = $StartButton
@onready var countdown_label = $CountdownLabel
@onready var count_label = $CountLabel

var ball_count = 0
var countdown_time = 3

func _ready() -> void:
	spawn_timer.stop()
	countdown_timer.wait_time = 1.0
	countdown_label.hide()
	start_button.pressed.connect(_on_start_button_pressed)
	countdown_timer.timeout.connect(_on_countdown_timer_timeout)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_start_button_pressed() -> void:
	start_button.hide()
	countdown_label.show()
	countdown_time = 3
	countdown_label.text = str(countdown_time)
	countdown_timer.start()

func _on_countdown_timer_timeout() -> void:
	countdown_time -= 1
	if countdown_time > 0:
		countdown_label.text = str(countdown_time)
	else:
		countdown_label.text = "GO!"
		await get_tree().create_timer(0.5).timeout
		countdown_label.hide()
		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	var ball_instance = ball_scene.instantiate()
	var viewport_rect = get_viewport_rect()
	
	# Random edge spawning logic
	var spawn_pos := Vector2()
	var direction := Vector2()
	
	match randi() % 4:
		0:  # Top
			spawn_pos = Vector2(randf_range(0, viewport_rect.size.x), -50)
			direction = Vector2(randf_range(-0.5, 0.5), 1)
		1:  # Right
			spawn_pos = Vector2(viewport_rect.size.x + 50, randf_range(0, viewport_rect.size.y))
			direction = Vector2(-1, randf_range(-0.5, 0.5))
		2:  # Bottom
			spawn_pos = Vector2(randf_range(0, viewport_rect.size.x), viewport_rect.size.y + 50)
			direction = Vector2(randf_range(-0.5, 0.5), -1)
		3:  # Left
			spawn_pos = Vector2(-50, randf_range(0, viewport_rect.size.y))
			direction = Vector2(1, randf_range(-0.5, 0.5))
	
	ball_instance.position = spawn_pos
	ball_instance.velocity = direction.normalized() * randf_range(150, 250)
	add_child(ball_instance)

func _on_counter_area_body_entered(body: Node) -> void:
	if body.is_in_group("ball"):
		ball_count += 1
		count_label.text = "Balls: %d" % ball_count
