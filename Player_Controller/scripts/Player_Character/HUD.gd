extends CanvasLayer

@onready var Debug_HUD = $debug_hud
@onready var CurrentWeaponLabel = $debug_hud/HBoxContainer/CurrentWeapon
@onready var CurrentAmmoLabel = $debug_hud/HBoxContainer2/CurrentAmmo
@onready var CurrentWeaponStack = $debug_hud/HBoxContainer3/WeaponStack
@onready var CurrentHealth = $debug_hud/HBoxContainer4/Health
@onready var weapon_icon = $debug_hud/HBoxContainer5/WeaponIcon

@onready var pick_up_contrainer = $VBoxContainer/PickUPContrainer
@onready var weapon_name_pickup = $VBoxContainer/PickUPContrainer/weapon_name_pickup



@onready var Hit_Sight = $Hit_Sight
@onready var Hit_Sight_Timer = $Hit_Sight/Hit_Sight_Timer
@onready var OverLay = $Overlay
@onready var display_ammo = $SubViewport/Display_Ammo
@onready var plasma_bar = $Plasma_ViewPort/plasma_bar
var damage_flash: ColorRect
var health_warning: ColorRect
var health_warning_tween: Tween

func _ready():
	GameEvents.connect("weapon_pickup_entered_range", Callable(self, "_on_weapon_pickup_entered_range"))
	GameEvents.connect("weapon_pickup_exited_range", Callable(self, "_on_weapon_pickup_exited_range"))

	# Hide the pickup info initially
	pick_up_contrainer.hide()
	# Create the damage flash ColorRect
	damage_flash = ColorRect.new()
	damage_flash.name = "DamageFlash"
	damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(1, 0, 0, 0)  # Red with 0 alpha (invisible)
	add_child(damage_flash)
	
	# Create the health warning ColorRect
	health_warning = ColorRect.new()
	health_warning.name = "HealthWarning"
	health_warning.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_warning.color = Color(1, 0, 0, 0)  # Red with 0 alpha (invisible)
	add_child(health_warning)
	
	# Ensure the damage flash and health warning are on top of other elements
	move_child(damage_flash, get_child_count() - 1)
	move_child(health_warning, get_child_count() - 1)

func flash_damage():
	var tween = create_tween()
	tween.tween_property(damage_flash, "color:a", 0.3, 0.05)  # Fade in
	tween.tween_property(damage_flash, "color:a", 0.0, 0.2)   # Fade out

func start_health_warning():
	if health_warning_tween:
		health_warning_tween.kill()
	
	health_warning_tween = create_tween()
	health_warning_tween.set_loops()  # Make the tween repeat indefinitely
	health_warning_tween.tween_property(health_warning, "color:a", 0.3, 0.5)  # Fade in
	health_warning_tween.tween_property(health_warning, "color:a", 0.0, 0.5)  # Fade out

func stop_health_warning():
	if health_warning_tween:
		health_warning_tween.kill()
	health_warning.color.a = 0  # Ensure the warning is invisible

func _on_weapons_manager_update_weapon_stack(WeaponStack):
	CurrentWeaponStack.text = ""
	for i in range(min(WeaponStack.size(), 2)):
		CurrentWeaponStack.text += "\n" + WeaponStack[i]

func _on_weapons_manager_update_ammo(Ammo):
	CurrentAmmoLabel.set_text(str(Ammo[0])+" / "+str(Ammo[1]))
	display_ammo.set_text(str(Ammo[0]))
	plasma_bar.value = Ammo[0]

func _on_hit_sight_timer_timeout():
	Hit_Sight.set_visible(false)

func _on_weapons_manager_add_signal_to_hud(_projectile):
	_projectile.connect("Hit_Successfull", Callable(self,"_on_weapons_manager_hit_successfull"))

func _on_weapons_manager_hit_successfull():
	Hit_Sight.set_visible(true)
	Hit_Sight_Timer.start()

func LoadOverLayTexture(Active:bool, txtr: Texture2D = null):
		OverLay.set_texture(txtr)
		OverLay.set_visible(Active)

func _on_weapons_manager_connect_weapon_to_hud(_weapon_resouce):
	_weapon_resouce.connect("UpdateOverlay", Callable(self, "LoadOverLayTexture"))

func set_plasma_bar_max(max_value: int):
	plasma_bar.max_value = max_value
	plasma_bar.value = max_value  

func _on_player_character_player_damaged():
	flash_damage()

func _on_player_character_player_health_changed(new_health):
	CurrentHealth.set_text(str(new_health))
	if new_health <= 20:
		start_health_warning()
	else:
		stop_health_warning()

func _on_weapons_manager_weapon_changed(current_weapon : Weapon_Resource):
	CurrentWeaponLabel.text = current_weapon.Weapon_Name
	print("icon is",current_weapon.Weapon_Icon)
	if weapon_icon is TextureRect:
		weapon_icon.texture = current_weapon.Weapon_Icon
	else:
		push_error("weapon_icon is not a TextureRect. Current type: " + str(typeof(weapon_icon)))

func _on_weapon_pickup_entered_range(weapon_resource: Weapon_Resource):
	# Show the pickup info
	pick_up_contrainer.show()
	weapon_name_pickup.text = "Pick up " + weapon_resource.Weapon_Name

func _on_weapon_pickup_exited_range():
	# Hide the pickup info
	pick_up_contrainer.hide()
