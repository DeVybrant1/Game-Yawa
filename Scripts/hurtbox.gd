class_name HurtBox
extends Area2D

signal received_damage(damage: int)

@export var health: Health

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	

func _on_area_entered(area: Area2D) -> void:
	# Only react if it's actually a HitBox
	print("hitter")
	if area is HitBox:
		var hitbox: HitBox = area
		
		if health != null:
			health.health -= hitbox.damage
			received_damage.emit(hitbox.damage)
