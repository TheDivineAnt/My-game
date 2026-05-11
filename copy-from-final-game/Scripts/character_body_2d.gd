extends CharacterBody2D

## The maxiumum speed allowed, in pixels per second
@export var max_speed:  float = 200.0
## Accleration as form of [code]pixels/s2 [/code]. [br]
@export var acceleration: float = 400.0

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(_direction() * max_speed, _adjusted_acceleration(delta))

	move_and_slide()

func _adjusted_acceleration(delta:float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
