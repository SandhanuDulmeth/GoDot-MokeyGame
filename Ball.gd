extends Node2D

@export var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("ball")

func _process(delta: float) -> void:
	position += velocity * delta
	var screen_size = get_viewport_rect().size
	if position.x < -50 or position.x > screen_size.x + 50 or position.y < -50 or position.y > screen_size.y + 50:
		queue_free()

# _draw() function removed since we're using a Sprite2D for the ball image.
