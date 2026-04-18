class_name HurtBox
extends Area2D

signal received_damage(damage: int)
@export var health: Health

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	print("HurtBox ready on: ", get_parent().name, " | health assigned: ", health != null)

func _on_area_entered(area: Area2D) -> void:
	print("HurtBox area_entered fired on ", get_parent().name, " by ", area.name)
	if area is HitBox:
		print("  -> is HitBox, damage: ", area.damage)
		if area.get_parent() == get_parent():
			print("  -> same parent, ignoring")
			return
		if health != null:
			print("  -> health ref: ", health, " | calling take_damage")
			health.take_damage(area.damage)
			received_damage.emit(area.damage)
		else:
			print("  -> health is NULL — drag the health node into hurtbox's Health slot in the Inspector")
	else:
		print("  -> not a HitBox, it is: ", area.get_class())
