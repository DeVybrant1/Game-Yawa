extends CharacterBody2D

# ---------------------------------------------------
# MOVEMENT / AI
# ---------------------------------------------------
var movement_speed: float = 90.0
@export var target: Node2D = null
@export var stop_distance := 25.0

var player_in_range := false
var attacking := false

# ---------------------------------------------------
# DIRECTION
# ---------------------------------------------------
var last_direction := "S"

# ---------------------------------------------------
# NODES
# ---------------------------------------------------
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D2
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection: Area2D = $detection
@onready var health: Health = $health

@onready var hit_s: Area2D = $hit_S
@onready var hit_e: Area2D = $hit_E
@onready var hit_w: Area2D = $hit_W
@onready var hit_n: Area2D = $hit_N
@onready var healthbar: ProgressBar = $Healthbar

var hitboxes := {}

# ---------------------------------------------------
# READY
# ---------------------------------------------------
func _ready() -> void:
	hitboxes = {
		"N": hit_n,
		"S": hit_s,
		"E": hit_e,
		"W": hit_w
	}

	_disable_all_hitboxes()

	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)

	for box in hitboxes.values():
		box.area_entered.connect(_on_hitbox_area_entered)

	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	call_deferred("seeker_setup")
	healthbar.max_value = health.max_health
	healthbar.value = health.max_health
# ---------------------------------------------------
# INIT NAV
# ---------------------------------------------------
func seeker_setup():
	await get_tree().physics_frame
	if target:
		navigation_agent.target_position = target.global_position

# ---------------------------------------------------
# PHYSICS LOOP
# ---------------------------------------------------
func _physics_process(_delta: float) -> void:
	if not player_in_range:
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation("idle")
		return

	if target:
		navigation_agent.target_position = target.global_position

	var distance_to_target = global_position.distance_to(target.global_position)

	if distance_to_target <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		if not attacking:
			attack()
		return

	if navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		play_animation("idle")
		return

	var next_pos = navigation_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()

	velocity = dir * movement_speed
	move_and_slide()

	update_direction(dir)
	play_animation("run")

# ---------------------------------------------------
# ATTACK
# ---------------------------------------------------
func attack():
	attacking = true
	play_animation("attack")
	_update_hitboxes()
	await get_tree().create_timer(0.4).timeout
	_disable_all_hitboxes()
	attacking = false

# ---------------------------------------------------
# HITBOX SYSTEM
# ---------------------------------------------------
func _update_hitboxes() -> void:
	_disable_all_hitboxes()
	var active = hitboxes.get(last_direction, null)
	if active:
		active.monitoring = true

func _disable_all_hitboxes() -> void:
	for box in hitboxes.values():
		box.set_deferred("monitoring", false)

# ---------------------------------------------------
# DIRECTION
# ---------------------------------------------------
func update_direction(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		last_direction = "E" if dir.x > 0 else "W"
	else:
		last_direction = "S" if dir.y > 0 else "N"

# ---------------------------------------------------
# ANIMATION
# ---------------------------------------------------
func play_animation(state: String):
	var anim_name = state + "_" + last_direction
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

# ---------------------------------------------------
# DETECTION
# ---------------------------------------------------
func _on_detection_body_entered(body):
	if body == target:
		player_in_range = true

func _on_detection_body_exited(body):
	if body == target:
		player_in_range = false

# ---------------------------------------------------
# HEALTH CALLBACKS
# ---------------------------------------------------
func _on_health_changed(new_health: int, max_health: int) -> void:
	print("Enemy HP: %d / %d" % [new_health, max_health])
	healthbar.value = new_health
@onready var label: Label = $Control/Label
	
func _on_died() -> void:
	set_physics_process(false)
	_disable_all_hitboxes()
	$hurtbox/CollisionShape2D2.set_deferred("disabled", true)
	animated_sprite_2d.play("dying_" + last_direction)
	await animated_sprite_2d.animation_finished
	
	queue_free()

# ---------------------------------------------------
# HITBOX CONTACT (ENEMY DAMAGES PLAYER)
# ---------------------------------------------------
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		if area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(1)
