extends RigidBody3D

@export var damage = 10

func _on_area_3d_body_entered(body):

	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	else:
		queue_free()

