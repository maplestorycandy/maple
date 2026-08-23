# BaseMonster.gd
extends CharacterBody2D

@export var monster_id: int = 1
@export var monster_name: String = "綠水靈"
@export var monster_type: String = "Slime"
@export var max_hp: int = 150
@export var hp: int = 150
@export var atk: int = 15
@export var speed: float = 60.0
@export var ai_type: String = "hop"
@export var body_scale: float = 1.0
@export var body_color: Color = Color(0.2, 0.9, 0.2)
@export var exp_reward: int = 20
@export var meso_reward: int = 15

var target_position: Vector2 = Vector2.ZERO
var is_wave_attacker: bool = false
var is_boss: bool = false
var facing_direction: int = 1

# AI Timers & State
var ai_timer: float = 0.0
var jump_cooldown: float = 1.5
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var boss_skill_timer: float = 0.0
var anim_frame: float = 0.0
var hurt_flash: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	add_to_group("enemies")
	setup_visuals()

func setup(data: Dictionary, target_pos: Vector2 = Vector2.ZERO):
	monster_name = data.get("name", "Monster")
	monster_type = data.get("type", "Slime")
	max_hp = data.get("hp", 100)
	hp = max_hp
	atk = data.get("atk", 10)
	speed = data.get("speed", 50.0)
	ai_type = data.get("ai", "patrol")
	body_scale = data.get("scale", 1.0)
	body_color = data.get("color", Color.GREEN)
	exp_reward = data.get("exp", 20)
	meso_reward = data.get("meso", 15)
	
	if target_pos != Vector2.ZERO:
		target_position = target_pos
		is_wave_attacker = true
	
	if monster_type == "Boss" or monster_type == "FinalBoss" or data.get("name", "").begins_with("【Boss】"):
		is_boss = true
		add_to_group("bosses")
	
	setup_visuals()

func setup_visuals():
	scale = Vector2(body_scale, body_scale)
	queue_redraw()

func _physics_process(delta):
	anim_frame += delta * 6.0
	if hurt_flash > 0.0:
		hurt_flash -= delta * 5.0
	
	if not is_on_floor() and not (monster_type == "Fly" or monster_type == "Ghost" or monster_type == "Void"):
		velocity.y += 980.0 * delta
	
	# Determine navigation goal
	var goal_pos = target_position
	if not is_wave_attacker:
		# Wild monster: check for nearby player
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 350.0:
			goal_pos = player.global_position
		else:
			goal_pos = global_position # idle/patrol
			
	handle_ai_behavior(delta, goal_pos)
	move_and_slide()
	queue_redraw()
	
	# Attack target in melee range
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		check_melee_attack()

func handle_ai_behavior(delta: float, goal: Vector2):
	ai_timer += delta
	boss_skill_timer += delta
	
	var dir_x = 0.0
	if goal != global_position:
		dir_x = sign(goal.x - global_position.x)
		if dir_x != 0:
			facing_direction = int(dir_x)
			
	match ai_type:
		"hop":
			if is_on_floor() and ai_timer >= jump_cooldown:
				ai_timer = 0.0
				velocity.y = -350.0
				velocity.x = dir_x * speed * 1.5
			elif is_on_floor():
				velocity.x = move_toward(velocity.x, 0, speed * 2.0 * delta)
				
		"crawl", "patrol":
			if is_wave_attacker:
				velocity.x = dir_x * speed
			else:
				# Wild mob wandering
				if int(ai_timer) % 4 < 2:
					velocity.x = facing_direction * speed * 0.5
				else:
					velocity.x = 0
				if is_on_wall():
					facing_direction = -facing_direction
					
		"charge", "pack_rush":
			velocity.x = dir_x * speed * 1.6
			if is_on_floor() and randf() < 0.02:
				velocity.y = -250.0
				
		"fly_swoop", "fly_shoot":
			var fly_target = goal + Vector2(0, -50 + sin(anim_frame) * 40)
			var move_vec = (fly_target - global_position).normalized()
			velocity = move_vec * speed
			
		"heavy_smash", "slow_aura":
			velocity.x = dir_x * speed * 0.8
			if is_on_floor() and ai_timer >= 3.0:
				ai_timer = 0.0
				cast_ground_quake()
				
		"ranged_magic", "turret_spit":
			if global_position.distance_to(goal) > 250:
				velocity.x = dir_x * speed
			else:
				velocity.x = 0
			if ai_timer >= 2.0:
				ai_timer = 0.0
				shoot_magic_orb(goal)
				
		_: # Bosses & others
			if speed > 0:
				velocity.x = dir_x * speed
			if is_boss and boss_skill_timer >= 5.0:
				boss_skill_timer = 0.0
				cast_boss_ultimate()

func check_melee_attack():
	# Check collision with Player
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < (45.0 * body_scale):
		attack_timer = 0.0
		Global.damage_player(atk)
		
	# Check collision with Goddess
	var goddess = get_tree().get_first_node_in_group("goddess")
	if is_instance_valid(goddess) and global_position.distance_to(goddess.global_position) < (60.0 * body_scale):
		attack_timer = 0.0
		Global.damage_goddess(atk)

func cast_ground_quake():
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 180.0:
		Global.damage_player(int(atk * 1.3))

func shoot_magic_orb(target: Vector2):
	# Spawn simple projectile
	var bullet_dir = (target - global_position).normalized()
	var slash = load("res://scenes/skills/SwordWave.tscn").instantiate()
	slash.global_position = global_position
	slash.target_direction = bullet_dir
	slash.damage = int(atk * 1.2)
	# Modulate bullet to enemy color
	slash.modulate = Color(1.0, 0.2, 0.2)
	get_parent().add_child(slash)

func cast_boss_ultimate():
	Global.broadcast_message("【BOSS技能釋放】%s 發動了毀滅咆哮！" % monster_name, Color(1.0, 0.2, 0.2))
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 400.0:
			Global.damage_player(int(atk * 1.8))

func take_damage_custom(amount: int, is_crit: bool = false, hit_index: int = 0):
	hp -= amount
	hurt_flash = 1.0
	spawn_damage_text(amount, is_crit, hit_index)
	
	if Global.passive_buffs.get("vampiric_drain", false):
		var v_heal = int(amount * 0.15)
		Global.heal_player(v_heal)
	
	if hp <= 0:
		die()

func take_damage(amount: int, is_crit: bool = false):
	take_damage_custom(amount, is_crit, 0)

func spawn_damage_text(amount: int, is_crit: bool, hit_index: int = 0):
	var dmg_scene = load("res://scenes/skills/DamageNumber.tscn")
	if dmg_scene:
		var num = dmg_scene.instantiate()
		num.global_position = global_position + Vector2(randf_range(-10, 10), -35 * body_scale)
		num.setup(amount, is_crit, false, false, hit_index)
		get_tree().current_scene.add_child.call_deferred(num)

func die():
	Global.add_exp(exp_reward)
	Global.meso_gold += meso_reward
	queue_free()

func on_captured():
	# Cleanly freed upon capture
	queue_free()

func get_capture_data() -> Dictionary:
	return {
		"id": monster_id,
		"name": monster_name + " (寵物)",
		"type": monster_type,
		"hp": max_hp,
		"max_hp": max_hp,
		"atk": atk,
		"speed": speed,
		"color": body_color,
		"scale": body_scale,
		"level": 1
	}

func _draw():
	var draw_col = body_color
	if hurt_flash > 0.0:
		draw_col = draw_col.lerp(Color.WHITE, hurt_flash)
		
	var bounce = sin(anim_frame) * 3.0
	
	# 1. BOSS Glowing Aura
	if is_boss:
		draw_circle(Vector2.ZERO, 36.0, Color(0.8, 0.2, 0.9, 0.25 + 0.15 * sin(anim_frame)))
		draw_arc(Vector2.ZERO, 38.0, 0, TAU, 24, Color(1.0, 0.4, 0.1, 0.6), 3.0)
	
	# 2. Draw procedural body by monster type
	match monster_type:
		"Slime":
			# Jelly droplet
			draw_circle(Vector2(0, -14 + bounce), 16.0, draw_col)
			draw_circle(Vector2(0, -8), 18.0, draw_col)
			# Eyes
			draw_circle(Vector2(-5 * facing_direction, -15 + bounce), 3.0, Color.BLACK)
			draw_circle(Vector2(5 * facing_direction, -15 + bounce), 3.0, Color.BLACK)
			draw_circle(Vector2(-4 * facing_direction, -16 + bounce), 1.0, Color.WHITE)
			draw_circle(Vector2(6 * facing_direction, -16 + bounce), 1.0, Color.WHITE)
			# Rosy cheeks
			draw_circle(Vector2(-9 * facing_direction, -10 + bounce), 2.5, Color(1.0, 0.4, 0.6, 0.6))
			draw_circle(Vector2(9 * facing_direction, -10 + bounce), 2.5, Color(1.0, 0.4, 0.6, 0.6))
			
		"Snail":
			# Snail Shell
			draw_circle(Vector2(-6 * facing_direction, -16), 14.0, draw_col)
			draw_arc(Vector2(-6 * facing_direction, -16), 8.0, 0, TAU, 12, Color(0.1, 0.1, 0.2), 2.0)
			# Body & eyestalks
			draw_circle(Vector2(8 * facing_direction, -8), 8.0, Color(0.95, 0.9, 0.7))
			draw_circle(Vector2(12 * facing_direction, -18 + bounce), 3.0, Color.WHITE)
			draw_circle(Vector2(12 * facing_direction, -18 + bounce), 1.5, Color.BLACK)
			
		"Mushroom":
			# Stem
			draw_circle(Vector2(0, -10), 12.0, Color(0.95, 0.92, 0.8))
			# Mushroom Cap
			draw_circle(Vector2(0, -22 + bounce), 18.0, draw_col)
			# Spots
			draw_circle(Vector2(-7, -24 + bounce), 3.5, Color.WHITE)
			draw_circle(Vector2(7, -24 + bounce), 3.5, Color.WHITE)
			# Face
			draw_circle(Vector2(-4 * facing_direction, -10), 2.0, Color.BLACK)
			draw_circle(Vector2(4 * facing_direction, -10), 2.0, Color.BLACK)
			
		"Beast", "Centaur", "TempleBeast":
			# Beast body & head
			draw_circle(Vector2(0, -14), 16.0, draw_col)
			draw_circle(Vector2(10 * facing_direction, -20 + bounce), 12.0, draw_col)
			# Ears & Snout
			draw_circle(Vector2(6 * facing_direction, -30 + bounce), 5.0, draw_col.darkened(0.2))
			draw_circle(Vector2(16 * facing_direction, -18 + bounce), 5.0, Color(1.0, 0.6, 0.7))
			
		"Golem", "Mud":
			# Rocky rugged body
			draw_circle(Vector2(0, -18), 22.0, draw_col)
			draw_circle(Vector2(0, -32 + bounce), 12.0, draw_col.darkened(0.15))
			# Glowing rune eyes
			draw_circle(Vector2(-4 * facing_direction, -32 + bounce), 3.0, Color(0.2, 1.0, 0.8))
			draw_circle(Vector2(4 * facing_direction, -32 + bounce), 3.0, Color(0.2, 1.0, 0.8))
			
		"Fly", "Dragon", "Demon", "UndeadDragon":
			# Floating demonic / winged body
			draw_circle(Vector2(0, -16 + bounce), 14.0, draw_col)
			# Wings
			var wing_flap = sin(anim_frame * 2.0) * 10.0
			draw_line(Vector2(-6, -20 + bounce), Vector2(-22, -32 + wing_flap), draw_col.lightened(0.3), 5.0)
			draw_line(Vector2(6, -20 + bounce), Vector2(22, -32 + wing_flap), draw_col.lightened(0.3), 5.0)
			# Horns
			draw_line(Vector2(-4, -26 + bounce), Vector2(-10, -38 + bounce), Color(0.2, 0.1, 0.1), 3.0)
			draw_line(Vector2(4, -26 + bounce), Vector2(10, -38 + bounce), Color(0.2, 0.1, 0.1), 3.0)
			
		"Ghost", "ToyGhost", "Void":
			# Translucent spectral body
			draw_circle(Vector2(0, -16 + bounce), 15.0, Color(draw_col.r, draw_col.g, draw_col.b, 0.75))
			draw_circle(Vector2(0, -8 + bounce * 1.5), 10.0, Color(draw_col.r, draw_col.g, draw_col.b, 0.4))
			# Ghostly hollow eyes
			draw_circle(Vector2(-4 * facing_direction, -18 + bounce), 3.5, Color.BLACK)
			draw_circle(Vector2(4 * facing_direction, -18 + bounce), 3.5, Color.BLACK)
			
		_:
			# Default standard monster appearance
			draw_circle(Vector2(0, -15 + bounce), 16.0, draw_col)
			draw_circle(Vector2(0, -28 + bounce), 10.0, draw_col.lightened(0.2))
			draw_circle(Vector2(-4 * facing_direction, -28 + bounce), 2.5, Color.BLACK)
			draw_circle(Vector2(4 * facing_direction, -28 + bounce), 2.5, Color.BLACK)

	# 3. Health Bar over head
	var hp_ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_w = 32.0
	var bar_h = 4.0
	var bar_y = -38.0 + bounce
	if is_boss:
		bar_w = 50.0
		bar_h = 6.0
		bar_y = -46.0 + bounce
		
	draw_rect(Rect2(-bar_w/2, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(Rect2(-bar_w/2, bar_y, bar_w * hp_ratio, bar_h), Color(1.0, 0.2, 0.2, 0.9))
