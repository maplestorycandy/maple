# BaseMonster.gd
extends CharacterBody2D

@export var net_id: int = 0
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

# Network interpolation variables
var target_net_pos: Vector2 = Vector2.ZERO
var target_net_vel: Vector2 = Vector2.ZERO

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
	target_net_pos = global_position
	if net_id != 0 and not NetworkManager.monsters.has(net_id):
		NetworkManager.monsters[net_id] = self
	setup_visuals()

func setup(data: Dictionary, target_pos: Vector2 = Vector2.ZERO):
	monster_id = data.get("id", 1)
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

func is_client_puppet() -> bool:
	return NetworkManager.is_multiplayer_active and not NetworkManager.is_host

func network_sync_position(pos: Vector2, vel: Vector2, cur_hp: int, facing: int):
	target_net_pos = pos
	target_net_vel = vel
	hp = cur_hp
	facing_direction = facing
	queue_redraw()

func _physics_process(delta):
	anim_frame += delta * 6.0
	if hurt_flash > 0.0:
		hurt_flash -= delta * 5.0
		queue_redraw()
	
	# If this is a Client in multiplayer, interpolate from Host's state
	if is_client_puppet():
		global_position = global_position.lerp(target_net_pos, 0.4)
		velocity = target_net_vel
		return
		
	# --- HOST / SINGLE PLAYER AUTHORITATIVE AI ---
	if not is_on_floor() and not (monster_type == "Fly" or monster_type == "Ghost" or monster_type == "Void"):
		velocity.y += 980.0 * delta
	
	# Determine navigation goal
	var goal_pos = target_position
	if not is_wave_attacker:
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 350.0:
			goal_pos = player.global_position
		else:
			goal_pos = global_position
	
	ai_timer += delta
	attack_timer += delta
	boss_skill_timer += delta
	
	update_monster_ai(delta, goal_pos)
	move_and_slide()
	
	if attack_timer >= attack_cooldown:
		check_melee_attack()

func update_monster_ai(_delta: float, goal: Vector2):
	var dir_x = sign(goal.x - global_position.x)
	if dir_x != 0:
		facing_direction = int(dir_x)
		
	match ai_type:
		"hop", "jump_charge":
			if is_on_floor():
				if ai_timer >= jump_cooldown:
					ai_timer = 0.0
					velocity.x = dir_x * speed * 1.5
					velocity.y = -350.0
				else:
					velocity.x = move_toward(velocity.x, 0, speed * 2.0)
					
		"crawl", "patrol":
			if is_wave_attacker:
				velocity.x = dir_x * speed
			else:
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
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < (45.0 * body_scale):
		attack_timer = 0.0
		Global.damage_player(atk)
		
	var goddess = get_tree().get_first_node_in_group("goddess")
	if is_instance_valid(goddess) and global_position.distance_to(goddess.global_position) < (60.0 * body_scale):
		attack_timer = 0.0
		Global.damage_goddess(atk)

func cast_ground_quake():
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 180.0:
		Global.damage_player(int(atk * 1.3))

func shoot_magic_orb(target: Vector2):
	var bullet_dir = (target - global_position).normalized()
	var slash = load("res://scenes/skills/SwordWave.tscn").instantiate()
	slash.global_position = global_position
	slash.target_direction = bullet_dir
	slash.damage = int(atk * 1.2)
	slash.modulate = Color(1.0, 0.2, 0.2)
	get_parent().add_child(slash)

func cast_boss_ultimate():
	Global.broadcast_message("【BOSS技能釋放】%s 發動了毀滅咆哮！" % monster_name, Color(1.0, 0.2, 0.2))
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 400.0:
			Global.damage_player(int(atk * 1.8))

# Networked Damage Entrypoint
func take_damage_custom(amount: int, is_crit: bool = false, hit_index: int = 0):
	if NetworkManager.is_multiplayer_active:
		NetworkManager.request_damage_on_monster(net_id, amount, is_crit, hit_index)
	else:
		take_damage_authoritative(amount, is_crit, hit_index)

func take_damage(amount: int, is_crit: bool = false):
	take_damage_custom(amount, is_crit, 0)

# Authoritative damage execution on Host / Single Player
func take_damage_authoritative(amount: int, is_crit: bool = false, hit_index: int = 0):
	hp -= amount
	hurt_flash = 1.0
	spawn_damage_text(amount, is_crit, hit_index)
	
	if Global.passive_buffs.get("vampiric_drain", false):
		var v_heal = int(amount * 0.15)
		Global.heal_player(v_heal)
	
	if NetworkManager.is_multiplayer_active and NetworkManager.is_host:
		NetworkManager.rpc("broadcast_mob_hit", net_id, amount, is_crit, hit_index, hp)
		
	if hp <= 0:
		if NetworkManager.is_multiplayer_active and NetworkManager.is_host:
			NetworkManager.rpc("broadcast_mob_death", net_id, exp_reward, meso_reward)
		else:
			die_synchronized(exp_reward, meso_reward)

func spawn_damage_text(amount: int, is_crit: bool, hit_index: int = 0):
	var dmg_scene = load("res://scenes/skills/DamageNumber.tscn")
	if dmg_scene:
		var num = dmg_scene.instantiate()
		num.global_position = global_position + Vector2(randf_range(-10, 10), -35 * body_scale)
		num.setup(amount, is_crit, false, false, hit_index)
		get_tree().current_scene.add_child.call_deferred(num)

func die_synchronized(exp_amt: int, meso_amt: int):
	Global.add_exp(exp_amt)
	Global.meso_gold += meso_amt
	queue_free()

func die():
	die_synchronized(exp_reward, meso_reward)

func on_captured():
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

# Procedural Drawing of 10 MapleStory Archetypes
func _draw():
	var col = body_color
	if hurt_flash > 0.0:
		col = Color(1.0, 0.4, 0.4)
		
	var bounce = sin(anim_frame) * 3.0
	var f = facing_direction
	
	match monster_type:
		"Slime":
			draw_circle(Vector2(0, -14 + bounce), 14, col)
			draw_circle(Vector2(0, -18 + bounce), 4, Color(1, 1, 0.3, 0.8))
			draw_circle(Vector2(4 * f, -15 + bounce), 3, Color.BLACK)
			draw_circle(Vector2(4 * f + 1, -16 + bounce), 1.2, Color.WHITE)
			
		"Snail":
			draw_circle(Vector2(0, -12), 12, col.darkened(0.2))
			draw_circle(Vector2(0, -12), 8, col.lightened(0.3))
			draw_circle(Vector2(9 * f, -8), 7, col)
			draw_circle(Vector2(11 * f, -10), 2.5, Color.BLACK)
			
		"Mushroom":
			draw_circle(Vector2(0, -6), 8, Color(1.0, 0.95, 0.8))
			draw_arc(Vector2(0, -14), 16, PI, 2 * PI, 16, col, 14.0)
			draw_circle(Vector2(3 * f, -6), 2, Color.BLACK)
			draw_circle(Vector2(-6, -18), 3, Color.WHITE)
			draw_circle(Vector2(6, -18), 3, Color.WHITE)
			
		"Beast":
			draw_rect(Rect2(-16, -20 + bounce, 32, 20), col, true)
			draw_circle(Vector2(12 * f, -16 + bounce), 9, col.lightened(0.1))
			draw_circle(Vector2(15 * f, -18 + bounce), 2.5, Color.BLACK)
			draw_colored_polygon(PackedVector2Array([
				Vector2(10 * f, -24 + bounce),
				Vector2(15 * f, -32 + bounce),
				Vector2(18 * f, -22 + bounce)
			]), col.darkened(0.3))
			
		"Golem":
			draw_rect(Rect2(-20, -35, 40, 35), col, true)
			draw_circle(Vector2(-8, -26), 4, Color.ORANGE_RED)
			draw_circle(Vector2(8, -26), 4, Color.ORANGE_RED)
			draw_rect(Rect2(-26, -28, 10, 20), col.darkened(0.2), true)
			draw_rect(Rect2(16, -28, 10, 20), col.darkened(0.2), true)
			
		"Dragon", "Demon":
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, -35 + bounce),
				Vector2(-20, -10 + bounce),
				Vector2(0, 0 + bounce),
				Vector2(20, -10 + bounce)
			]), col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-10, -20 + bounce),
				Vector2(-35 * f, -35 + bounce),
				Vector2(-25 * f, -10 + bounce)
			]), col.darkened(0.4))
			draw_circle(Vector2(8 * f, -22 + bounce), 4, Color.YELLOW)
			
		"Ghost":
			draw_circle(Vector2(0, -18 + bounce), 14, col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-14, -18 + bounce),
				Vector2(14, -18 + bounce),
				Vector2(10, 0 + bounce),
				Vector2(0, -6 + bounce),
				Vector2(-10, 0 + bounce)
			]), col)
			draw_circle(Vector2(4 * f, -18 + bounce), 3.5, Color.RED)
			
		"Aqua":
			draw_circle(Vector2(0, -12 + bounce), 12, col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-10 * f, -12 + bounce),
				Vector2(-20 * f, -20 + bounce),
				Vector2(-20 * f, -4 + bounce)
			]), col.lightened(0.3))
			draw_circle(Vector2(5 * f, -14 + bounce), 3, Color.BLACK)
			
		"Toy":
			draw_rect(Rect2(-12, -24, 24, 24), col, true)
			draw_rect(Rect2(-6, -34, 12, 10), Color(0.9, 0.8, 0.3), true)
			draw_circle(Vector2(4 * f, -20), 2.5, Color.BLACK)
			draw_circle(Vector2(0, -36), 3, Color.RED)
			
		_: # Bosses / Temple
			draw_circle(Vector2(0, -28 + bounce), 26, col)
			draw_arc(Vector2(0, -28 + bounce), 32, 0, TAU, 24, Color.GOLD, 3.0)
			draw_circle(Vector2(-8 * f, -32 + bounce), 5, Color.CYAN)
			draw_circle(Vector2(8 * f, -32 + bounce), 5, Color.CYAN)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -54 + bounce),
				Vector2(0, -66 + bounce),
				Vector2(12, -54 + bounce)
			]), Color.GOLD)
			
	# Overhead Monster HP Bar
	if hp < max_hp or is_boss:
		var bar_w = 40.0 * body_scale
		var bar_y = -35.0 - (10.0 * body_scale)
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 4), Color(0.1, 0.1, 0.1, 0.8), true)
		var fill_w = clamp(float(hp) / float(max_hp), 0.0, 1.0) * bar_w
		var hp_col = Color.RED if hp < max_hp * 0.3 else (Color.GOLD if is_boss else Color.GREEN)
		draw_rect(Rect2(-bar_w / 2, bar_y, fill_w, 4), hp_col, true)
