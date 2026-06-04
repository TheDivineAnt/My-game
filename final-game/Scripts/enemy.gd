extends CharacterBody2D

@export var base_speed: float = 120.0
@export var speed_increase_rate: float = 0.7 
@export var fear_speed: float = 180.0       
@export var stun_duration: float = 3.0 
@export var flee_duration: float = 2.5 

var current_speed: float = 120.0
var time_elapsed: float = 0.0

enum State { IDLE, CHASE, STUNNED, FLEE }
var current_state = State.IDLE

var stun_timer: float = 0.0
var flee_timer: float = 0.0
var player_in_range: Node2D = null

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var sprite = get_node_or_null("Walking") 
@onready var nav_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D") 
@onready var los_ray = get_node_or_null("LOSRayCast")

func _ready() -> void:
	# Automatically join the Enemy group so the player script tracks this node flawlessly
	add_to_group("Enemy")

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			handle_idle_state(delta)
		State.CHASE:
			handle_chase_state(delta)
		State.STUNNED:
			handle_stunned_state(delta)
		State.FLEE:
			handle_flee_state(delta)

	handle_sprite_flipping()

func handle_idle_state(_delta: float) -> void:
	if sprite and sprite is AnimatedSprite2D:
		sprite.stop() 
	
	velocity = Vector2.ZERO
	move_and_slide()
	
	if player_in_range and check_line_of_sight():
		current_state = State.CHASE
		time_elapsed = 0.0 

func handle_chase_state(delta: float) -> void:
	if not check_line_of_sight():
		current_state = State.IDLE
		return

	# Calculate speed scaling dynamically over time
	time_elapsed += delta
	current_speed = base_speed + (time_elapsed * speed_increase_rate)
	current_speed = max(base_speed, current_speed)

	if sprite and sprite is AnimatedSprite2D:
		if sprite.has_animation("Walking"):
			sprite.play("Walking")
			sprite.speed_scale = current_speed / base_speed

	if nav_agent and player:
		# Set the pathfinding target directly to the player
		nav_agent.target_position = player.global_position
		
		# Get the next path movement vector
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		var direction: Vector2 = global_position.direction_to(next_path_position).normalized()
		
		velocity = direction * current_speed
		move_and_slide()

func check_line_of_sight() -> bool:
	if not player or not los_ray:
		return false
		
	los_ray.target_position = los_ray.to_local(player.global_position)
	los_ray.force_raycast_update() 
	
	if los_ray.is_colliding():
		var collider = los_ray.get_collider()
		if collider == player or collider.is_in_group("Player"):
			return true
			
	return false 

func handle_stunned_state(delta: float) -> void:
	if sprite and sprite is AnimatedSprite2D:
		sprite.stop()

	velocity = Vector2.ZERO
	move_and_slide() 

	stun_timer -= delta
	if stun_timer <= 0:
		current_state = State.FLEE
		flee_timer = flee_duration 

func handle_flee_state(delta: float) -> void:
	if sprite and sprite is AnimatedSprite2D:
		if sprite.has_animation("Walking"): 
			sprite.play("Walking")
			sprite.speed_scale = fear_speed / base_speed 

	if player:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * fear_speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	flee_timer -= delta
	if flee_timer <= 0:
		current_state = State.IDLE

func handle_sprite_flipping() -> void:
	if sprite and sprite is AnimatedSprite2D:
		if velocity.x > 0:
			sprite.flip_h = false 
		elif velocity.x < 0:
			sprite.flip_h = true  

func flash_blind() -> void:
	if current_state != State.STUNNED:
		current_state = State.STUNNED
		stun_timer = stun_duration 
		print("Enemy smart-blinded!")

# === SIGNAL CONNECTIONS ===

func _on_sight_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = body

func _on_sight_range_body_exited(_body: Node2D) -> void:
	player_in_range = null
	if current_state == State.CHASE:
		current_state = State.IDLE

func _on_kill_area_body_entered(body: Node2D) -> void:
	if body == self or body is TileMap or body is TileMapLayer:
		return
	if body.is_in_group("Player") or body.name == "Player":
		print("GAME OVER")
		get_tree().reload_current_scene()
