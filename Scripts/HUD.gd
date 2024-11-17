extends CanvasLayer

@onready var currentWeaponLabel = $VBoxContainer/HBoxContainer/CurrentWeapon
@onready var weaponListLabel = $VBoxContainer/HBoxContainer2/CurrentWeapons

func _on_weapon_manager_weapon_changed(weaponName):
	currentWeaponLabel.text = weaponName


func _on_weapon_manager_weapon_list_changed(weaponNameList):
	weaponListLabel.text = ""
	for weaponName in weaponNameList:
		weaponListLabel.text += weaponName + "\n"
	weaponListLabel.text = weaponListLabel.text.rstrip("\n")
