extends RigidBody3D


var throw_force = 1000

func _ready():
	# Initial setup
	pass

func throw(direction):
	#apply_impulse(Vector3.ZERO, direction * throw_force)
	pass

func _on_Snowball_body_entered(body):
	# Handle collision
	# Add impact effects here
	queue_free()  # Remove the snowball after impact
