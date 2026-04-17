class_name Health
extends Node

@export var max_health: int = 5
var health: int

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = clampi(health - amount, 0, max_health)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()

func heal(amount: int) -> void:
	health = clampi(health + amount, 0, max_health)
	health_changed.emit(health, max_health)
