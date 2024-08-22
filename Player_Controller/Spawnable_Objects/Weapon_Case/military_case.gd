extends Node3D


@onready var animation_player = $AnimationPlayer
var can_open = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass



func _on_area_3d_body_entered(body):
	if body.is_in_group("player") && can_open:
			animation_player.play("open")
			can_open = false
			


func _on_area_3d_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	if body.is_in_group("player") && !can_open:
		var timer = get_tree().create_timer(3)
		timer.timeout.connect(func(): 
			animation_player.play("close") 
			can_open = true
		)	

