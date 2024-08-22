extends Node3D
class_name BulletImpact

@export var base_debris_size: float = 0.03
@export var max_debris_size: float = 0.3
@export var base_debris_amount: int = 30
@export var max_debris_amount: int = 150
@export var base_effect_lifetime: float = 0.8
@export var max_effect_lifetime: float = 2.0
@export var base_debris_speed_min: float = 2.0
@export var base_debris_speed_max: float = 5.0
@export var max_debris_speed_min: float = 8.0
@export var max_debris_speed_max: float = 20.0
@export var base_smoke_size: float = 0.08
@export var max_smoke_size: float = 0.2
@export var base_smoke_amount: int = 8
@export var max_smoke_amount: int = 25
@export var max_damage_for_scaling: float = 100.0

@onready var debris = $Debris
@onready var smoke = $Smoke

func _ready():
	debris.emitting = false
	smoke.emitting = false

func explode(damage: float):
	# Calculate scaling factor
	var scale_factor = clamp(damage / max_damage_for_scaling, 0, 1)
	
	# Scale debris size
	var scaled_debris_size = lerp(base_debris_size, max_debris_size, scale_factor)
	debris.process_material.scale_min = scaled_debris_size
	debris.process_material.scale_max = scaled_debris_size * 1.5
	
	# Scale debris amount
	debris.amount = int(lerp(base_debris_amount, max_debris_amount, scale_factor))
	
	# Scale debris speed
	var scaled_speed_min = lerp(base_debris_speed_min, max_debris_speed_min, scale_factor)
	var scaled_speed_max = lerp(base_debris_speed_max, max_debris_speed_max, scale_factor)
	debris.process_material.initial_velocity_min = scaled_speed_min
	debris.process_material.initial_velocity_max = scaled_speed_max
	
	# Scale effect lifetime
	var scaled_lifetime = lerp(base_effect_lifetime, max_effect_lifetime, scale_factor)
	debris.lifetime = scaled_lifetime
	
	# Scale emission sphere radius
	if debris.process_material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
		debris.process_material.emission_sphere_radius = 0.1 * (1 + 2 * scale_factor)
	
	# Scale smoke
	var scaled_smoke_size = lerp(base_smoke_size, max_smoke_size, scale_factor)
	smoke.process_material.scale_min = scaled_smoke_size
	smoke.process_material.scale_max = scaled_smoke_size * 2.0
	smoke.amount = int(lerp(base_smoke_amount, max_smoke_amount, scale_factor))
	smoke.lifetime = scaled_lifetime * 1.5
	
	if smoke.process_material.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:
		smoke.process_material.emission_sphere_radius = 0.05 * (1 + scale_factor)
	
	# Start emitting
	debris.emitting = true
	smoke.emitting = true
	
	# Set up destruction timer
	await get_tree().create_timer(scaled_lifetime * 1.5).timeout
	queue_free()
