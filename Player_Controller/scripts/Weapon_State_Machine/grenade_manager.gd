extends Node

@export var grenade_scene: PackedScene 
@export var explosion_scene: PackedScene  # New export for the explosion scene
@onready var camera = %MainCamera
@onready var animation_player = %AnimationPlayer
var throw_force = 15
var explosion_delay = 3.0  # Time in seconds before the grenade explodes

func _ready():
	pass

func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("grenade"):
		print('threw a grenade')
		throw()

func throw():
	if grenade_scene:
		# Play the grenade throw animation
		if animation_player and animation_player.has_animation("grenade_throw"):
			animation_player.play("grenade_throw")
		
		# Spawn and throw the grenade immediately
		var grenade = grenade_scene.instantiate()
		get_tree().current_scene.add_child(grenade)
		
		# Set initial position to be slightly in front of the camera
		var spawn_pos = camera.global_transform.origin - camera.global_transform.basis.z * 2
		grenade.global_transform.origin = spawn_pos
		
		# Calculate throw direction from camera
		var throw_direction = -camera.global_transform.basis.z.normalized()
		
		# Apply force to the grenade
		grenade.linear_velocity = throw_direction * throw_force
		
		var physics_material = PhysicsMaterial.new()
		physics_material.friction = 1000
		grenade.physics_material_override = physics_material

		# Set up the explosion timer
		var timer = get_tree().create_timer(explosion_delay)
		timer.timeout.connect(explode.bind(grenade))
	else:
		print("Grenade scene not set")

func explode(grenade: Node3D):
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_transform.origin = grenade.global_transform.origin
		explosion.explode()
	
	grenade.queue_free()
