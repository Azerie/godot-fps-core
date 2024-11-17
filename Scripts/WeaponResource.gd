extends Resource

class_name WeaponResource

@export var WeaponName : String
@export var EquipAnimation : String
@export var UnequipAnimation : String
@export var ShotAnimation : String

@export var IsFullAuto : bool
@export_flags("Hitscan", "Projectile") var BulletType
@export var Damage : int
