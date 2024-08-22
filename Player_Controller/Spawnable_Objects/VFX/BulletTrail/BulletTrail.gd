extends MeshInstance3D
class_name BulletTrail

@export var base_trail_width: float = 0.05
@export var lifetime: float = 0.5
@export var trail_color: Color = Color(0.4, 0.4, 0.4, 0.7)  # Light grey color
@export var min_damage: float = 10.0  # Damage value for AR (smallest trail)
@export var max_damage: float = 50.0  # Damage value for sniper (largest trail)
@export var min_width_multiplier: float = 0.2  # Multiplier for smallest trail (40% of base width)
@export var max_width_multiplier: float = 1.0  # Multiplier for largest trail (100% of base width)

var start_point: Vector3
var end_point: Vector3
var time_elapsed: float = 0.0
var trail_width: float

func _ready():
	mesh = ImmediateMesh.new()
	material_override = StandardMaterial3D.new()
	material_override.albedo_color = trail_color
	material_override.emission_enabled = true
	material_override.emission = trail_color
	material_override.emission_energy = 1  # Slightly reduced for a softer glow
	material_override.flags_unshaded = true
	material_override.flags_transparent = true
	material_override.flags_no_depth_test = true

func initialize(start: Vector3, end: Vector3, damage: float):
	start_point = start
	end_point = end
	time_elapsed = 0.0
	
	# Calculate trail width based on damage
	var t = inverse_lerp(min_damage, max_damage, damage)
	var width_multiplier = lerp(min_width_multiplier, max_width_multiplier, t)
	trail_width = base_trail_width * width_multiplier
	
	update_trail()

func _process(delta):
	time_elapsed += delta
	if time_elapsed > lifetime:
		queue_free()
	else:
		material_override.albedo_color.a = 1.0 - (time_elapsed / lifetime)
		material_override.emission_energy = 1.5 * (1.0 - (time_elapsed / lifetime))
		update_trail()

func update_trail():
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var forward = (end_point - start_point).normalized()
	var up = Vector3.UP
	if forward.dot(up) > 0.99:
		up = Vector3.BACK
	var right = forward.cross(up).normalized()
	
	mesh.surface_add_vertex(start_point + right * trail_width)
	mesh.surface_add_vertex(start_point - right * trail_width)
	mesh.surface_add_vertex(end_point + right * trail_width)
	
	mesh.surface_add_vertex(start_point - right * trail_width)
	mesh.surface_add_vertex(end_point - right * trail_width)
	mesh.surface_add_vertex(end_point + right * trail_width)
	
	mesh.surface_end()
