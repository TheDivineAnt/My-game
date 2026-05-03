extends CharacterBody2D

## The maxiumum speed allowed, in pixels per second
@export var max_speed:  float = 200.0
## Accleration as form of [code]pixels/s2 [/code]. [br]
@export var acceleration: float = 400.0

func _physics_process(delta: float) -> void:
	var direction: Vector2 = _direction()

if direction != Vector2.ZERO:
	velocity += direction * acceleration * delta
else:
	# Reduce the length of our velocity vector by a linear amount each frame
	var new_length = velocity.length() - (acceleration * delta)
	velocity = velocity.normalized() * new_length
func _physics_process(_delta: float) -> void:
	velocity = _direction() * max_speed
	move_and_slide()

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
