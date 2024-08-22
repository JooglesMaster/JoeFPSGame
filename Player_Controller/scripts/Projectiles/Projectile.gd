#projectile scrupt
extends Node3D
class_name Projectile

signal Hit_Successfull

@export_enum ("Hitscan","Rigidbody_Projectile") var Projectile_Type: String = "Hitscan"
@export var Projectile_Velocity: int
@export var Expirey_Time: int = 10
@export var Display_Debug_Decal: bool = true
@export var Rigid_Body_Projectile: PackedScene
@export var muzzle_offset: Vector3 = Vector3(0.8, -0.6, -4)

@onready var Debug_Bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")
@onready var Bullet_Impact_Effect = preload("res://Player_Controller/Spawnable_Objects/VFX/BulletImpact/BulletImpact.tscn")
@onready var Bullet_Trail = preload("res://Player_Controller/Spawnable_Objects/VFX/BulletTrail/Bullet_Trail.tscn") 

var Damage: float = 0
var Projectiles_Spawned = []

func _ready() -> void:
	get_tree().create_timer(Expirey_Time).timeout.connect(_on_timer_timeout)

func _Set_Projectile(_Damage: int = 0,_spread:Vector2 = Vector2.ZERO, _Range: int = 1000):
	Damage = _Damage
	Fire_Projectile(_spread,_Range,Rigid_Body_Projectile)

func Fire_Projectile(_spread,_range, _proj):
	var Camera_Collision = Camera_Ray_Cast(_spread,_range)
	
	print("projectile ",_proj)
	
	match Projectile_Type:
		"Hitscan":
			var camera = get_viewport().get_camera_3d()
			var start_point = camera.global_transform.origin + camera.global_transform.basis * muzzle_offset
			var end_point = Camera_Collision[1]
			if Damage >= 50 or (Damage < 50 and randf() <= 0.5):
				Create_Bullet_Trail(start_point, end_point)
			Hit_Scan_Collision(Camera_Collision, Damage)
		"Rigidbody_Projectile":
			Launch_Rigid_Body_Projectile(Camera_Collision, _proj)

func Camera_Ray_Cast(_spread: Vector2 = Vector2.ZERO, _range: float = 1000):
	var _Camera = get_viewport().get_camera_3d()
	var _Viewport = get_viewport().size
	
	var Ray_Origin = _Camera.project_ray_origin((_Viewport/2))
	var Ray_End = (Ray_Origin + _Camera.project_ray_normal((_Viewport/2)+Vector2i(_spread))*_range)
	var space_state = get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	query.collision_mask = (1 << 5) | (1 << 9)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var intersections = []
	var current_origin = Ray_Origin
	var max_intersections = 5
	
	for i in range(max_intersections):
		var result = space_state.intersect_ray(query)
		if result.is_empty():
			break
		
		intersections.append(result)
		current_origin = result.position + (Ray_End - Ray_Origin).normalized() * 0.01
		query.from = current_origin
	
	if intersections.is_empty():
		return [null, Ray_End, null]
	else:
		var first_hit = intersections[0]
		return [first_hit.collider, first_hit.position, first_hit.normal]

func Hit_Scan_Collision(Collision: Array, _damage):
	var Point = Collision[1]
	var Bullet_Point = get_parent()
	
	if Collision[0]:
		Load_Decal(Point, Collision[2])
		
		var head_hit = false
		var body_hit = false
		
		if Collision[0] is Area3D and Collision[0].name == "HeadArea":
			head_hit = true
		elif Collision[0] is CharacterBody3D and Collision[0].is_in_group("Target"):
			body_hit = true
		
		if head_hit:
			var target = Collision[0].get_parent()
			if target.has_method("_on_head_hit"):
				target._on_head_hit(self,Damage)
			Hit_Scan_Damage(target, (Point - Bullet_Point.global_transform.origin).normalized(), Point, _damage * 2)
		elif body_hit:
			Hit_Scan_Damage(Collision[0], (Point - Bullet_Point.global_transform.origin).normalized(), Point, _damage)

func Hit_Scan_Damage(Collider, Direction, Position, _damage):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Hit_Successfull.emit()
		Collider.Hit_Successful(_damage, Direction, Position)
		queue_free()

func Load_Decal(_pos,_normal):
	if Display_Debug_Decal && Projectile_Type == "Hitscan":
		var impact_effect = Bullet_Impact_Effect.instantiate()
		get_tree().get_root().add_child(impact_effect)
		impact_effect.global_translate(_pos + (_normal * 0.01))
		impact_effect.explode(Damage)
		
func Create_Bullet_Trail(start: Vector3, end: Vector3):
	var trail = Bullet_Trail.instantiate()
	get_tree().current_scene.add_child(trail)
	trail.initialize(start, end, Damage)
		
func Launch_Rigid_Body_Projectile(Collision_Data, _projectile):
	print("launched rigid body ")
	var camera = get_viewport().get_camera_3d()
	var start_point = camera.global_transform.origin + camera.global_transform.basis * muzzle_offset
	var _Point = Collision_Data[1]
	var _Norm = Collision_Data[2]
	var _proj = _projectile.instantiate()
	add_child(_proj)
	
	Projectiles_Spawned.push_back(_proj)

	_proj.body_entered.connect(_on_body_entered.bind(_proj,_Norm))
	
	_proj.set_as_top_level(true)
	_proj.global_transform.origin = start_point

	# Initial scale
	var initial_scale = _proj.scale
	var target_scale = initial_scale * 3.0

	# Set initial velocity to zero
	_proj.linear_velocity = Vector3.ZERO

	# Create a timer for scaling and launching
	var scale_timer = get_tree().create_timer(0.1)
	scale_timer.timeout.connect(func(): 
		_proj.scale = target_scale
		var _Direction = (_Point - start_point).normalized()
		_proj.linear_velocity = _Direction * Projectile_Velocity
	)

	# Tween for smooth scaling
	var tween = get_tree().create_tween()
	tween.tween_property(_proj, "scale", target_scale, 0.1)

	print("Projectile spawned at: ", start_point)
	print("Projectile will launch after scaling")

func _on_body_entered(body, _proj, _norm):
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
		Hit_Successfull.emit()

	Load_Decal(_proj.get_position(),_norm)
	_proj.queue_free()
		
	Projectiles_Spawned.erase(_proj)
	
	if Projectiles_Spawned.is_empty():
		queue_free()

func _on_timer_timeout():
	queue_free()
