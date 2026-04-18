class_name HitBox
extends Area2D

@export var animated_sprite: AnimatedSprite2D
@export var damage: int = 1 : set = set_damage, get = get_damage

var facing_direction: String = ""

const DIR_TO_ANIM_SUFFIX: Dictionary = {
	"N": ["N", "u"],
	"S": ["S", "d"],
	"E": ["E", "r"],
	"W": ["W", "l"],
}

const ACTIVE_FRAMES: Dictionary = {
	# Player
	"attack1_r": [3, 4],
	"attack1_l": [3, 4],
	"attack1_u": [3, 4],
	"attack1_d": [3, 4],
	"attack2_r": [3, 4],
	"attack2_l": [3, 4],
	"attack2_u": [3, 4],
	"attack2_d": [3, 4],
	# Enemy
	"attack_S": [14, 15],
	"attack_N": [14, 15],
	"attack_E": [14, 15],
	"attack_W": [14, 15],
}

func _ready() -> void:
	var parts = name.split("_")
	if parts.size() > 1:
		facing_direction = parts[-1]

	_disable()

	if animated_sprite == null:
		animated_sprite = get_parent().get_node_or_null("AnimatedSprite2D")

	if animated_sprite != null:
		animated_sprite.frame_changed.connect(_on_frame_changed)
	else:
		push_error("HitBox: No AnimatedSprite2D found on " + get_parent().name)

func _on_frame_changed() -> void:
	var anim: String = animated_sprite.animation
	var frame: int = animated_sprite.frame

	if not anim.begins_with("attack"):
		_disable()
		return

	# Check if this anim direction matches this hitbox's facing direction
	var valid_suffixes: Array = DIR_TO_ANIM_SUFFIX.get(facing_direction, [])
	var direction_matches := false
	for suffix in valid_suffixes:
		if anim.ends_with(suffix):
			direction_matches = true
			break

	if not direction_matches:
		_disable()
		return

	if anim in ACTIVE_FRAMES and frame in ACTIVE_FRAMES[anim]:
		_enable()
	else:
		_disable()

func _enable() -> void:
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)
	$CollisionShape2D.set_deferred("disabled", false)

func _disable() -> void:
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)

func set_damage(value: int) -> void:
	damage = value

func get_damage() -> int:
	return damage
