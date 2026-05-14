extends CharacterBody2D

func _process(_delta):
	var target_angle = (get_global_mouse_position() - global_position).angle()
	rotation = lerp_angle(rotation, target_angle, 10)
	# This makes the player node rotate to face the mouse cursor
	look_at(get_global_mouse_position())
func _input(event):
	# Check for a right-click to toggle the light
	if event.is_action_pressed("ui_right"):
		$PointLight2D.enabled = !$PointLight2D.enabled


## The maxiumum speed allowed, in pixels per second
@export var max_speed: float = 200.0
## Accleration as form of [code]pixels/s2 [/code]. [br]
@export var acceleration: float = 800.0

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(_direction() * max_speed, _adjusted_acceleration(delta))

	move_and_slide()

func _adjusted_acceleration(delta:float) -> float:
	return acceleration * delta

func _direction() -> Vector2:
	return Input.get_vector("left", "right" , "up" , "down")
