extends RigidBody3D


@export var health : int

func TakeDamage(damage):
	health -= damage
	if health <= 0:
		queue_free()
