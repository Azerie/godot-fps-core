extends Node3D

@onready var animationPlayer = $WeaponRig/AnimationPlayer
@onready var bulletSource = $WeaponRig/BulletSource

@onready var audio556 = $"5_56"
@onready var audio792x39 = $"7_92x39"
@onready var audio792x54 = $"7_92x54"

var currentWeapon = null # this has the resource of the current weapon
var weaponStack = [] # this has the names of weapons player has
var weaponID = 0
var allWeaponList = {}
var deployed = false

@export var weaponResources : Array[WeaponResource]
@export var startWeapons : Array[String]

enum {NULL, HITSCAN, PROJECTILE}

signal WeaponChanged
signal WeaponListChanged

func _ready():
	Initialize();

func Initialize():
	for weapon in weaponResources:
		allWeaponList[weapon.WeaponName] = weapon
	
	for weapon in startWeapons:
		weaponStack.push_back(weapon)
	
	currentWeapon = allWeaponList[weaponStack[0]]
	emit_signal("WeaponChanged", currentWeapon.WeaponName)
	emit_signal("WeaponListChanged", weaponStack)
	enter()

func _input(event):
	if event.is_action_pressed("WeaponUp"):
		if weaponID == weaponStack.size() - 1:
			weaponID = 0
		else:
			weaponID += 1
		exit()
	elif event.is_action_pressed("WeaponDown"):
		if weaponID == 0:
			weaponID = weaponStack.size() - 1
		else:
			weaponID -= 1
		exit()
	elif event.is_action_pressed("Weapon1") && weaponStack.size() >= 1:
		weaponID = 0
		exit()
	elif event.is_action_pressed("Weapon2") && weaponStack.size() >= 2:
		weaponID = 1
		exit()
	elif event.is_action_pressed("Weapon3") && weaponStack.size() >= 3:
		weaponID = 2
		exit()
	elif event.is_action_pressed("Shoot"):
		shoot()

func enter(): # on changing weapons
	emit_signal("WeaponChanged", currentWeapon.WeaponName)
	animationPlayer.stop()
	animationPlayer.queue(currentWeapon.EquipAnimation)

func exit(): # before changing weapons
	deployed = false
	animationPlayer.stop()
	animationPlayer.play(currentWeapon.UnequipAnimation)

func ChangeWeapon():
	currentWeapon = allWeaponList[weaponStack[weaponID]]
	WeaponChanged
	enter()

func shoot():
	# deployed is not needed here, should be deleted if i dont use it anywhere else later
	if deployed && !animationPlayer.is_playing(): # maybe queue inputs if not deployed
		animationPlayer.play(currentWeapon.ShotAnimation)
		match currentWeapon.BulletType:
			NULL:
				print("no bullet type")
			HITSCAN:
				var hit = HitscanCameraCollision()
				if !hit.is_empty():
					HitscanDamage(hit.collider)
			PROJECTILE:
				pass
		match currentWeapon.WeaponName:
			"Pistol":
				audio556.play()
			"Rifle":
				audio792x39.play()
			"Sniper":
				audio792x54.play()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == currentWeapon.EquipAnimation:
		deployed = true
	elif anim_name == currentWeapon.UnequipAnimation:
		ChangeWeapon()
	elif anim_name == currentWeapon.ShotAnimation && currentWeapon.IsFullAuto:
		if Input.is_action_pressed("Shoot"):
			shoot()


func HitscanCameraCollision()->Dictionary:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size() / 2
	var rayOrigin = camera.project_ray_origin(viewport)
	var rayEnd = rayOrigin + camera.project_ray_normal(viewport) * 1000 # change 1000 to weapon range if needed
	var ray = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
	var hit = get_world_3d().direct_space_state.intersect_ray(ray)
	
	return hit


func HitscanTrace(collisionPoint): # gotta find some way to draw it
	var direction = collisionPoint - bulletSource.get_global_position()
	var ray = PhysicsRayQueryParameters3D.create(bulletSource.get_global_position(), bulletSource.get_global_position() + direction)

func HitscanDamage(targetCollider):
	if targetCollider.is_in_group("Target") && targetCollider.has_method("TakeDamage"):
		targetCollider.TakeDamage(currentWeapon.Damage)
