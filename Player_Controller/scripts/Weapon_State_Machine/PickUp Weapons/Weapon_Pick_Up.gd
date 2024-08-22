extends RigidBody3D
class_name Weapon_Pick_Up

@export var weapon_resource: Weapon_Resource
const TYPE = "Weapon"
var Pick_Up_Ready: bool = false
var player_in_range: bool = false

# Use these properties to match the naming in the weapon_manager script
var _current_ammo: int
var _reserve_ammo: int
var _weapon_name: String

func _ready():
	if weapon_resource:
		_current_ammo = weapon_resource.Current_Ammo
		_reserve_ammo = weapon_resource.Reserve_Ammo
		_weapon_name = weapon_resource.Weapon_Name
	else:
		push_error("Weapon_Resource not assigned for " + name)
	
	await get_tree().create_timer(0.5).timeout
	Pick_Up_Ready = true

func _input(event):
	pass
	if event.is_action_pressed("Weapon_Pick_Up") and player_in_range and Pick_Up_Ready:
		pickup_weapon()

func Set_Ammo(w_name: String, c_ammo: int, r_ammo: int):
	if weapon_resource and weapon_resource.Weapon_Name == w_name:
		_current_ammo = c_ammo
		_reserve_ammo = r_ammo
		weapon_resource.Current_Ammo = c_ammo
		weapon_resource.Reserve_Ammo = r_ammo

func _on_pick_up_area_body_entered(body):
	if body.is_in_group("player"):
		print("player in range ")
		player_in_range = true
		GameEvents.emit_signal("weapon_pickup_entered_range", weapon_resource)

func _on_pick_up_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		GameEvents.emit_signal("weapon_pickup_exited_range")

func pickup_weapon():
	if weapon_resource:
		print("Weapon picked up: ", _weapon_name)
		var player = get_tree().get_nodes_in_group("player")[0]
		player.swap_weapon(self)
	else:
		push_error("Cannot pickup weapon: Weapon_Resource not assigned")

# Add this function to allow updating ammo from the weapon_manager
func update_ammo(current: int, reserve: int):
	_current_ammo = current
	_reserve_ammo = reserve
	if weapon_resource:
		weapon_resource.Current_Ammo = current
		weapon_resource.Reserve_Ammo = reserve
