## djinn_boss.gd
## Replace res://Scripts/djinn.gd with this file.
##
## SETUP CHECKLIST (read before testing!):
##   1. In level1boss.tscn select the "Player" node → Node tab → Groups → add "player"
##   2. Create res://Scenes/fireball.tscn (see fireball.gd) and assign it to
##      "Fireball Scene" in this boss's Inspector.
##   3. Save the mage_guardian.tscn – no other scene changes needed.

extends CharacterBody2D

# ─────────────────────────────────────────
#  EXPORTS  (tweak in Inspector)
# ─────────────────────────────────────────
@export var fireball_scene: PackedScene       ## res://Scenes/fireball.tscn
@export var move_speed: float       = 70.0
@export var patrol_radius: float    = 180.0
@export var shoot_interval: float   = 2.8    ## seconds between volleys
@export var fireball_count: int     = 3      ## projectiles per volley
@export var dash_interval: float    = 5.0    ## seconds between dash attacks
@export var dash_speed: float       = 340.0
@export var dash_duration: float    = 0.45
@export var dash_damage: int        = 2      ## hearts removed on dash hit

# ─────────────────────────────────────────
#  NODES
# ─────────────────────────────────────────
@onready var sprite:      AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox:     HurtBox          = $hurtbox
@onready var health:      Health           = $health
@onready var health_bar:  ProgressBar      = $CanvasLayer/healthbar

# ─────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────
enum State { WANDER, SHOOTING, DASHING, DEAD }
var _state: State = State.WANDER

var _player:         Node2D  = null
var _start_pos:      Vector2
var _wander_target:  Vector2
var _wander_timer:   float   = 0.0
var _shoot_timer:    float   = 1.5   # short first-shot delay
var _dash_timer:     float   = 3.0   # short first-dash delay
var _dash_dir:       Vector2 = Vector2.ZERO
var _dash_elapsed:   float   = 0.0
var _is_phase2:      bool    = false
var _dash_hit_area:  Area2D  = null

const WANDER_INTERVAL := 2.2

# ─────────────────────────────────────────
#  READY
# ─────────────────────────────────────────
func _ready() -> void:
	hurtbox.health = health          # wire damage so health bar actually changes
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	health_bar.max_value = health.max_health
	health_bar.value     = health.max_health

	_start_pos = global_position
	_pick_wander_target()
	sprite.play("first")
	_build_dash_hitbox()

	await get_tree().process_frame
	_find_player()

# ─────────────────────────────────────────
#  PLAYER LOOKUP
#  Works whether or not you've added a group.
# ─────────────────────────────────────────
func _find_player() -> void:
	var group = get_tree().get_nodes_in_group("player")
	if group.size() > 0:
		_player = group[0]
		return
	# Fallback: search by class name
	for node in get_tree().get_nodes_in_group(""):
		pass
	_player = get_tree().current_scene.find_child("Player", true, false)
	if _player == null:
		# Last resort: walk the whole tree looking for a Player class instance
		for node in get_tree().root.find_children("*", "CharacterBody2D", true, false):
			if node is Player:
				_player = node
				break
	if _player == null:
		push_warning("DjinnBoss: Player not found. Add 'player' group to Player node in level1boss.tscn.")

# ─────────────────────────────────────────
#  DASH HITBOX (built at runtime)
# ─────────────────────────────────────────
func _build_dash_hitbox() -> void:
	_dash_hit_area = Area2D.new()
	_dash_hit_area.name             = "DashHitArea"
	_dash_hit_area.collision_layer  = 4   # HitBox layer
	_dash_hit_area.collision_mask   = 8   # Player HurtBox layer
	_dash_hit_area.monitoring       = false
	_dash_hit_area.monitorable      = false

	var shape  = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 22.0
	shape.shape   = circle
	_dash_hit_area.add_child(shape)
	add_child(_dash_hit_area)
	_dash_hit_area.area_entered.connect(_on_dash_hit)

func _set_dash_hitbox(enabled: bool) -> void:
	if not _dash_hit_area:
		return
	_dash_hit_area.monitoring  = enabled
	_dash_hit_area.monitorable = enabled
	var s = _dash_hit_area.get_child(0) as CollisionShape2D
	if s:
		s.set_deferred("disabled", not enabled)

# ─────────────────────────────────────────
#  PHYSICS / PROCESS
# ─────────────────────────────────────────
func _physics_process(delta: float) -> void:
	match _state:
		State.WANDER:  _do_wander(delta)
		State.DASHING: _do_dash(delta)

func _process(delta: float) -> void:
	if _state in [State.DEAD, State.SHOOTING, State.DASHING]:
		return

	_shoot_timer -= delta
	_dash_timer  -= delta

	# Dash takes priority over shooting
	if _dash_timer <= 0.0:
		_dash_timer = dash_interval * (0.7 if _is_phase2 else 1.0)
		_begin_dash()
		return

	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval * (0.65 if _is_phase2 else 1.0)
		_begin_shoot_volley()

# ─────────────────────────────────────────
#  WANDER
# ─────────────────────────────────────────
func _do_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0 or global_position.distance_to(_wander_target) < 12.0:
		_pick_wander_target()
	velocity = (_wander_target - global_position).normalized() * move_speed
	move_and_slide()

func _pick_wander_target() -> void:
	_wander_timer  = WANDER_INTERVAL
	var angle      = randf() * TAU
	var dist       = randf_range(60.0, patrol_radius)
	_wander_target = _start_pos + Vector2(cos(angle), sin(angle)) * dist

# ─────────────────────────────────────────
#  FIREBALL VOLLEY
# ─────────────────────────────────────────
func _begin_shoot_volley() -> void:
	if _player == null:
		_find_player()
		return

	_state    = State.SHOOTING
	velocity  = Vector2.ZERO

	# Brief windup
	await get_tree().create_timer(0.3).timeout
	if _state == State.DEAD:
		return

	# Snapshot player position RIGHT NOW so all bullets aim at the same spot
	var target_pos  = _player.global_position
	var to_player   = (target_pos - global_position).normalized()
	var base_angle  = to_player.angle()

	# Fan spread: e.g. 3 bullets = centre, +15°, -15°
	var spread_deg  = 18.0
	var half_fan    = spread_deg * (fireball_count - 1) / 2.0

	for i in range(fireball_count):
		var angle_offset = deg_to_rad(-half_fan + spread_deg * i)
		var dir          = Vector2(cos(base_angle + angle_offset),
								  sin(base_angle + angle_offset))
		_spawn_fireball(dir)

	_state = State.WANDER
	sprite.play("first")

func _spawn_fireball(direction: Vector2) -> void:
	if fireball_scene == null:
		push_warning("DjinnBoss: assign fireball_scene in Inspector!")
		return

	var fb: Node2D = fireball_scene.instantiate()
	# Parent to the level root, not the boss, so it keeps moving after boss moves
	get_parent().add_child(fb)
	fb.global_position = global_position

	if fb.has_method("set_direction"):
		fb.set_direction(direction)
	elif "direction" in fb:
		fb.set("direction", direction)

# ─────────────────────────────────────────
#  DASH ATTACK
# ─────────────────────────────────────────
func _begin_dash() -> void:
	if _player == null:
		_find_player()
		return

	_state = State.DASHING
	sprite.play("second")    # red animation = danger telegraph

	# Telegraph pause – player can dodge during this
	await get_tree().create_timer(0.5).timeout
	if _state == State.DEAD:
		return

	# Lock direction at the moment of launch
	_dash_dir     = (_player.global_position - global_position).normalized()
	_dash_elapsed = 0.0
	_set_dash_hitbox(true)

func _do_dash(delta: float) -> void:
	_dash_elapsed += delta
	velocity       = _dash_dir * dash_speed
	move_and_slide()

	if _dash_elapsed >= dash_duration:
		_end_dash()

func _end_dash() -> void:
	_set_dash_hitbox(false)
	velocity = Vector2.ZERO
	_state   = State.WANDER
	sprite.play("first")

func _on_dash_hit(area: Area2D) -> void:
	if area is HurtBox and area.get_parent() != self:
		if area.health != null:
			area.health.take_damage(dash_damage)
		_end_dash()   # stop dash immediately after connecting

# ─────────────────────────────────────────
#  HEALTH CALLBACKS
# ─────────────────────────────────────────
func _on_health_changed(new_health: int, max_health: int) -> void:
	health_bar.value = new_health
	print("Mage Guardian HP: %d / %d" % [new_health, max_health])

	if not _is_phase2 and new_health <= max_health / 2:
		_is_phase2  = true
		move_speed *= 1.4
		print("Phase 2 – boss enraged!")

func _on_died() -> void:
	_state = State.DEAD
	_set_dash_hitbox(false)
	velocity = Vector2.ZERO
	queue_free()
