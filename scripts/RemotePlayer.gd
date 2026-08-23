# RemotePlayer.gd
extends CharacterBody2D

@export var peer_id: int = 1
@export var player_name: String = "遠端冒險者"
@export var job_id: String = "warrior"
@export var player_level: int = 1
@export var current_hp: int = 750
@export var max_hp: int = 750

var target_position: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var facing_direction: int = 1
var is_attacking: bool = false
var attack_anim_timer: float = 0.0
var anim_frame: float = 0.0

@onready var name_label: Label = $NamePlate/NameLabel
@onready var hp_bar: ProgressBar = $NamePlate/HPBar

func _ready():
	add_to_group("allies")
	add_to_group("remote_players")
	update_nameplate()
	queue_redraw()

func setup_remote_player(id: int, info: Dictionary):
	peer_id = id
	player_name = info.get("name", "玩家 %d" % id)
	job_id = info.get("job_id", "warrior")
	player_level = info.get("level", 1)
	current_hp = info.get("hp", 750)
	max_hp = info.get("max_hp", 750)
	update_nameplate()
	queue_redraw()

func update_nameplate():
	if name_label:
		name_label.text = "Lv.%d %s" % [player_level, player_name]
		var job_data = JobDatabase.get_job(job_id)
		name_label.modulate = job_data.get("color", Color.WHITE)
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp

func update_state(pos: Vector2, vel: Vector2, facing: int, attacking: bool, job: String, hp_val: int, max_hp_val: int):
	target_position = pos
	target_velocity = vel
	facing_direction = facing
	is_attacking = attacking
	job_id = job
	current_hp = hp_val
	max_hp = max_hp_val
	update_nameplate()

func _physics_process(delta):
	anim_frame += delta * 8.0
	
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0:
			is_attacking = false
			
	# Smooth interpolation towards synced position
	if target_position != Vector2.ZERO:
		global_position = global_position.lerp(target_position, 15.0 * delta)
		
	velocity = target_velocity
	queue_redraw()

func trigger_skill_visual(skill_key: String):
	is_attacking = true
	attack_anim_timer = 0.3
	queue_redraw()

func _draw():
	var body_col = Color(1.0, 0.85, 0.7)
	var hair_col = Color(0.85, 0.55, 0.2)
	var job_data = JobDatabase.get_job(job_id)
	var cloth_col = job_data.get("color", Color(0.2, 0.5, 0.9))
	var pants_col = Color(0.3, 0.3, 0.4)
	
	var leg_swing = sin(anim_frame) * 4.0 if (velocity.x != 0) else 0.0
	
	# 1. Denim Pants & Shoes
	draw_rect(Rect2(-7 + leg_swing, -8, 5, 8), pants_col)
	draw_rect(Rect2(2 - leg_swing, -8, 5, 8), pants_col)
	draw_rect(Rect2(-8 + leg_swing, -2, 7, 3), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(1 - leg_swing, -2, 7, 3), Color(0.35, 0.2, 0.1))
	
	# 2. Armor / Robe
	draw_rect(Rect2(-9, -22, 18, 14), cloth_col)
	draw_rect(Rect2(-7, -20, 14, 4), cloth_col.lightened(0.3))
	
	# 3. Head & Face
	draw_circle(Vector2(0, -32), 10.0, body_col)
	draw_circle(Vector2(3 * facing_direction, -32), 2.5, Color.BLACK)
	draw_circle(Vector2(4 * facing_direction, -33), 1.0, Color.WHITE)
	draw_line(Vector2(1 * facing_direction, -27), Vector2(4 * facing_direction, -27), Color(0.5, 0.2, 0.2), 1.5)
	
	# 4. Hair / Hat
	match job_id:
		"magician":
			draw_polygon(
				PackedVector2Array([
					Vector2(-14, -36),
					Vector2(14, -36),
					Vector2(0, -56)
				]),
				PackedColorArray([Color(0.2, 0.3, 0.7), Color(0.2, 0.3, 0.7), Color(0.3, 0.5, 0.9)])
			)
		"thief":
			draw_rect(Rect2(-11, -38, 22, 7), Color(0.15, 0.15, 0.2))
		_:
			draw_polygon(
				PackedVector2Array([
					Vector2(-11, -34),
					Vector2(-14, -42),
					Vector2(-6, -45),
					Vector2(0, -47),
					Vector2(8, -44),
					Vector2(13, -38),
					Vector2(10 * facing_direction, -35),
					Vector2(0, -38)
				]),
				PackedColorArray([hair_col, hair_col, hair_col, hair_col, hair_col, hair_col, hair_col, hair_col])
			)
			
	# 5. Weapon Visuals
	if is_attacking:
		draw_arc(Vector2(facing_direction * 25, -20), 38.0, -PI/2, PI/2, 12, cloth_col.lightened(0.4), 4.0)
		draw_line(Vector2(0, -18), Vector2(facing_direction * 40, -18), Color.SILVER, 4.0)
	else:
		draw_line(Vector2(-6 * facing_direction, -14), Vector2(-16 * facing_direction, -38), Color.SILVER, 3.0)
