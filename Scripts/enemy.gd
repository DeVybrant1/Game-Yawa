class_name Enemy
extends CharacterBody2D

# =====================
# CONFIG
# =====================
@export var move_speed: float = 70.0
@export var attack_range: float = 25.0
@export var attack_cooldown: float = 1.0

# =====================
# STATE
# =====================
var player: Node2D = null
var player_in_aggro: bool = false

var attacking: bool = false
var can_attack: bool = true

# =====================
# DIRECTION (NSEW)
# =====================
var dir: Vector2 = Vector2.ZERO
var facing: String = "S"

# =====================
# NODES
# =====================
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Health = $health


# =====================
# INIT
# =====================
func _ready():
	print("Enemy _ready called on: ", name)
	player = get_tree().get_first_node_in_group("player")
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)


# =====================
# HEALTH CALLBACKS
# =====================
func _on_health_changed(new_health: int, max_health: int) -> void:
	print("Enemy HP: %d / %d" % [new_health, max_health])

func _on_died() -> void:
	print("Enemy died!")
	queue_free()
