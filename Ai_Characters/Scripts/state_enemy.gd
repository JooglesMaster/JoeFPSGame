extends CharacterBody3D

@export var Health = 2
@export var move_speed = 5.0
@export var base_attack_range = 5.0
@export var base_chase_range = 7.0
@export var attack_cooldown = 0.5
@export var noise_amplitude = 0.5
@export var noise_frequency = 0.5
@export var range_variation = 2.0
@export var chase_probability = 0.7
@export var min_chase_delay = 0.5
@export var max_chase_delay = 3.0
@export var gravity = -9.8
@export var update_interval = 0.1
@export var rotation_speed = 5.0

@export var helmet_ejection_force = 10.0
@export var helmet_spawn_height = 5
@export var helmet_collision_layer = 1 << 10

@export var projectile_speed = 20.0
@export var projectile_spawn_height = 1.5
@export var projectile_arc_height = 2.0 

@onready var helmet = %Helmet
@onready var head_area = $HeadArea
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var projectile_spawn_point = $projectile_spawn_point

var ProjectileScene = preload("res://Ai_Characters/Projectile/Ray_Projectile.tscn")
var WeaponScene = preload("res://Player_Controller/Spawnable_Objects/Weapons/plasma.tscn")

var has_helmet = true
var attack_timer = 0.0
var chase_delay_timer = 0.0
var noise = FastNoiseLite.new()
var time = 0.0
var current_attack_range: float
var current_chase_range: float
var update_timer: float = 0.0

@onready var player: CharacterBody3D = get_node("/root/World/Player_Character")

enum State {
	IDLE,
	PREPARE_CHASE,
	CHASE,
	ATTACK
}

var current_state = State.IDLE


func _ready():
	if not player:
		push_error("Player not found. Check the path to Player_Character.")
	else:
		print("Player found successfully.")
	
	noise.seed = randi()
	noise.frequency = noise_frequency
	randomize()
	update_ranges()
	
	# Make sure to add a NavigationAgent3D node as a child of this character
	if not nav_agent:
		push_error("NavigationAgent3D not found. Add it as a child of this node.")

func update_ranges():
	current_attack_range = base_attack_range + randf_range(-range_variation, range_variation)
	current_chase_range = base_chase_range + randf_range(-range_variation, range_variation)


func _physics_process(delta):
	update_timer += delta
	
	if update_timer >= update_interval:
		update_timer = 0.0
		update_ai_logic(delta)
	
	rotate_to_player(delta)
	
	if current_state == State.CHASE:
		move_to_target()
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()

func move_to_target():
	if nav_agent.is_navigation_finished():
		return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	
	# Only consider horizontal movement
	direction.y = 0
	direction = direction.normalized()
	
	velocity = direction * move_speed
func update_ai_logic(delta):
	if not player:
		return
	
	attack_timer -= update_interval
	time += update_interval
	
	var distance_to_player = calculate_horizontal_distance(global_position, player.global_position)
	
	match current_state:
		State.IDLE:
			if distance_to_player > current_chase_range and randf() < chase_probability:
				transition_to(State.PREPARE_CHASE)
			elif attack_timer <= 0 and distance_to_player <= current_attack_range:
				attack_player()
		State.PREPARE_CHASE:
			chase_delay_timer -= update_interval
			if chase_delay_timer <= 0:
				transition_to(State.CHASE)
		State.CHASE:
			if distance_to_player <= current_attack_range:
				transition_to(State.ATTACK)
			else:
				nav_agent.set_target_position(player.global_position)
				if attack_timer <= 0:
					fire_projectile()
		State.ATTACK:
			if distance_to_player > current_attack_range:
				if randf() < chase_probability:
					transition_to(State.PREPARE_CHASE)
				else:
					transition_to(State.IDLE)
			else:
				attack_player()
func calculate_horizontal_distance(pos1: Vector3, pos2: Vector3) -> float:
	var diff = pos2 - pos1
	return Vector2(diff.x, diff.z).length()

func chase_player(delta, distance):
	nav_agent.set_target_position(player.global_position)
	
	var noise_x = noise.get_noise_2d(time, 0.0) * noise_amplitude
	var noise_z = noise.get_noise_2d(0.0, time) * noise_amplitude
	var noise_offset = Vector3(noise_x, 0, noise_z)
	
	nav_agent.set_target_position(player.global_position + noise_offset)

func rotate_to_player(delta):
	if player:
		var direction = player.global_position - global_position
		direction.y = 0  # Keep the AI upright
		
		if direction.length() > 0.01:  # Avoid rotating when too close to prevent jitter
			var target_rotation = atan2(direction.x, direction.z)
			var current_rotation = rotation.y
			
			# Smoothly interpolate between current and target rotation
			rotation.y = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)

func attack_player():
	if attack_timer <= 0:
		fire_projectile()

func transition_to(new_state):
	current_state = new_state
	match new_state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			update_ranges()
		State.PREPARE_CHASE:
			velocity.x = 0
			velocity.z = 0
			chase_delay_timer = randf_range(min_chase_delay, max_chase_delay)
		State.CHASE:
			pass
		State.ATTACK:
			pass



func fire_projectile():
	var projectile = ProjectileScene.instantiate()
	get_parent().add_child(projectile)
	
	# Use the ProjectileSpawnPoint for the initial position
	var spawn_position = projectile_spawn_point.global_position
	projectile.global_transform.origin = spawn_position
	
	# Calculate direction to the player
	var target_position = player.global_position + Vector3.UP * 1.5  # Aiming at player's upper body
	var direction = (target_position - spawn_position).normalized()
	
	# Calculate the distance to the target
	var distance = spawn_position.distance_to(target_position)
	
	# Calculate the time it will take for the projectile to reach the target
	var time = distance / projectile_speed
	
	# Calculate the initial velocity for the arc
	var velocity = Vector3.ZERO
	velocity.x = direction.x * projectile_speed
	velocity.z = direction.z * projectile_speed
	velocity.y = (target_position.y - spawn_position.y) / time + 0.5 * abs(gravity) * time
	
	# Apply velocity to the projectile
	projectile.linear_velocity = velocity
	
	# Make the projectile look in the direction it's moving
	projectile.look_at(spawn_position + velocity, Vector3.UP)
	
	# Reset the attack timer
	attack_timer = attack_cooldown
	

func Hit_Successful(Damage, Direction: Vector3 = Vector3.ZERO, Position: Vector3 = Vector3.ZERO):
	Health -= Damage
	if Health <= 0:
		drop_weapon()
		queue_free()
		
func drop_weapon():
	var weapon_instance = WeaponScene.instantiate()
	weapon_instance.global_transform.origin = global_transform.origin
	get_parent().add_child(weapon_instance)
	
	if weapon_instance is RigidBody3D:
		var random_force = Vector3(randf_range(-1, 1), randf_range(2, 4), randf_range(-1, 1))
		weapon_instance.apply_central_impulse(random_force)


func remove_helmet():
	if has_helmet:
		has_helmet = false
		
		# Create a new RigidBody3D for the helmet
		var helmet_body = RigidBody3D.new()
		get_parent().add_child(helmet_body)
		helmet_body.global_transform = helmet.global_transform
		
		# Move the helmet mesh to the new RigidBody3D
		helmet.get_parent().remove_child(helmet)
		helmet_body.add_child(helmet)
		helmet.transform = Transform3D.IDENTITY
		
		# Add a CollisionShape3D to the helmet
		var collision_shape = CollisionShape3D.new()
		var shape = SphereShape3D.new()  # Adjust shape as needed
		shape.radius = 0.2  # Adjust size as needed
		collision_shape.shape = shape
		helmet_body.add_child(collision_shape)
		
		# Set up collision layers and masks
		helmet_body.collision_layer = helmet_collision_layer
		helmet_body.collision_mask = 1  # Only collide with the environment (usually layer 1)
		
		# Apply upward force
		var upward_force = Vector3.UP * helmet_ejection_force
		helmet_body.apply_central_impulse(upward_force)
		
		# Set physics properties
		helmet_body.gravity_scale = 1.0
		helmet_body.linear_damp = 1.0
		helmet_body.angular_damp = 1.0
		
		# Optional: Add a timer to remove the helmet after a few seconds
		var timer = get_tree().create_timer(5.0)
		timer.timeout.connect(func(): helmet_body.queue_free())

func take_extra_damage(Damage):
	# Implement extra damage logic here
	Health -= Damage * 1.5  # Additional damage for headshot

func _on_head_hit(body,Damage):
	if has_helmet:
		remove_helmet()
	else:
		take_extra_damage(Damage)
