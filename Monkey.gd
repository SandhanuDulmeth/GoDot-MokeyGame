#Monkey.gd
extends Node2D


@export var velocity: Vector2 = Vector2.ZERO
var has_entered: bool = false
var counting_active: bool = true  # Control whether counting is active
var target_rect := Rect2(0, 0, 1150, 650)

var direction: Vector2
var can_move := true
@export var min_speed = 150
@export var max_speed = 500


func _ready() -> void:
	add_to_group("ball")
	# Set a timer to stop counting after 10 seconds
	var timer = get_tree().create_timer(10.0)
	timer.timeout.connect(_on_counting_timeout)
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	velocity = direction.normalized() * randf_range(min_speed, max_speed)
	var random_scale = randf_range(0.8, 1.2)
	scale = Vector2(random_scale, random_scale)
	
	# Random color variation
	$MonkeySprite.modulate = Color(
		randf_range(0.7, 1.0),
		randf_range(0.7, 1.0),
		randf_range(0.7, 1.0)
	)
func _process(delta: float) -> void:
	if can_move:
		position += velocity * delta
		var screen_size = get_viewport_rect().size
	
		# Only count if counting is still active
		if counting_active and not has_entered and target_rect.has_point(position):
			has_entered = true
			GameState.monkeys_entered += 1
			print("Monkeys entered: ", GameState.monkeys_entered)
	
		if position.x < -50 or position.x > screen_size.x + 50 or position.y < -50 or position.y > screen_size.y + 50:
			queue_free()

func _on_counting_timeout():
	counting_active = false
	print("Counting period ended. Total monkeys entered: ", GameState.monkeys_entered)
	
