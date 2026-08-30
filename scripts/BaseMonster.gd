# BaseMonster.gd
extends CharacterBody2D

@export var net_id: int = 0
@export var monster_id: int = 1
@export var monster_name: String = "嫩寶"
@export var monster_level: int = 1
@export var monster_type: String = "Slime"
@export var max_hp: int = 150
@export var hp: int = 150
@export var atk: int = 15
@export var speed: float = 60.0
@export var ai_type: String = "hop"
@export var body_scale: float = 1.0
@export var body_color: Color = Color.WHITE
@export var exp_reward: int = 20
@export var meso_reward: int = 15
@export var sprite_path: String = ""

var target_position: Vector2 = Vector2.ZERO
var is_wave_attacker: bool = false
var is_boss: bool = false
var facing_direction: int = 1
var has_sprite_texture: bool = false

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
@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel

func _ready():
	add_to_group("enemies")
	target_net_pos = global_position
	if net_id != 0 and not NetworkManager.monsters.has(net_id):
		NetworkManager.monsters[net_id] = self
	setup_visuals()

func setup(data: Dictionary, target_pos: Vector2 = Vector2.ZERO):
	monster_id = data.get("id", 1)
	monster_name = data.get("name", "Monster")
	monster_level = data.get("level", 1)
	monster_type = data.get("type", "Normal")
	max_hp = data.get("hp", 100)
	hp = max_hp
	atk = data.get("atk", 10)
	speed = data.get("speed", 60.0)
	ai_type = data.get("ai", "patrol")
	body_color = data.get("color", Color.WHITE)
	exp_reward = data.get("exp", 20)
	meso_reward = max(10, int(exp_reward * 0.7))
	sprite_path = data.get("sprite", "")
	
	is_boss = data.get("is_boss", false) or monster_level >= 100 or monster_name.find("王") != -1 or monster_name.find("巴洛古") != -1
	
	if is_boss:
		body_scale = 1.5 if monster_level < 100 else 2.0
		add_to_group("bosses")
	else:
		body_scale = 1.0
	
	if target_pos != Vector2.ZERO:
		target_position = target_pos
		is_wave_attacker = true
	
	setup_visuals()

func setup_visuals():
	if not is_node_ready():
		return
		
	if name_label:
		name_label.text = "Lv.%d %s" % [monster_level, monster_name]
		if is_boss:
			name_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			name_label.modulate = Color(0.9, 0.95, 1.0)
			
	# Attempt loading authentic sprite texture
	has_sprite_texture = false
	if sprite and sprite_path != "":
		var tex = null
		if ResourceLoader.exists(sprite_path):
			tex = load(sprite_path)
		if not tex:
			var img = Image.load_from_file(sprite_path)
			if img:
				tex = ImageTexture.create_from_image(img)
		if tex:
			sprite.texture = tex
			has_sprite_texture = true
			sprite.scale = Vector2(body_scale, body_scale)
			sprite.visible = true
	
	if not has_sprite_texture and sprite:
		sprite.visible = false
		
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
	var is_moving = abs(velocity.x) > 10.0 and is_on_floor()
	anim_frame += delta * (9.0 if is_moving else 4.0)
	
	if hurt_flash > 0.0:
		hurt_flash -= delta * 5.0
		if sprite:
			sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
		queue_redraw()
	else:
		if sprite:
			sprite.modulate = Color.WHITE
			
	# Dynamic MapleStory Sprite Hopping, Walking, and Breathing Animation
	if sprite and has_sprite_texture:
		if is_moving:
			var hop_y = -abs(sin(anim_frame * 2.2)) * 6.5
			sprite.position.y = -22.0 * body_scale + hop_y
			var squish_x = 1.0 + sin(anim_frame * 2.2) * 0.12
			var squish_y = 1.0 - sin(anim_frame * 2.2) * 0.10
			sprite.scale = Vector2(body_scale * squish_x, body_scale * squish_y)
		elif not is_on_floor():
			sprite.position.y = -24.0 * body_scale
			sprite.scale = Vector2(body_scale * 0.88, body_scale * 1.15)
		else:
			# Idle Organic Breathing
			var breath_y = sin(anim_frame * 2.0) * 2.2
			sprite.position.y = -24.0 * body_scale + breath_y
			var breath_sy = 1.0 + sin(anim_frame * 2.0) * 0.07
			var breath_sx = 1.0 - sin(anim_frame * 2.0) * 0.05
			sprite.scale = Vector2(body_scale * breath_sx, body_scale * breath_sy)
			
		sprite.flip_h = (facing_direction < 0) # Flip sprite towards movement
	else:
		queue_redraw()
	
	# Client interpolation in multiplayer
	if is_client_puppet():
		global_position = global_position.lerp(target_net_pos, 0.4)
		velocity = target_net_vel
		return
		
	# --- HOST / SINGLE PLAYER AUTHORITATIVE AI ---
	if not is_on_floor() and not (monster_type == "Fly" or monster_type == "Ghost"):
		velocity.y += 980.0 * delta
	
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
	# Automatic wall-bounce & unstuck logic
	if is_on_wall():
		facing_direction *= -1
		if is_on_floor() and randf() < 0.6:
			velocity.y = -320.0 # Jump over obstacle/step
			
	# Map Boundary wrap
	if global_position.x < -1650:
		facing_direction = 1
	elif global_position.x > 1650:
		facing_direction = -1
		
	if is_wave_attacker:
		var dir_x = sign(goal.x - global_position.x)
		if dir_x != 0:
			facing_direction = int(dir_x)
		velocity.x = facing_direction * speed
		if is_on_floor() and (is_on_wall() or randf() < 0.015):
			velocity.y = -280.0
	else:
		# Wild Monster Patrol & Aggro Chase
		var player = get_tree().get_first_node_in_group("player")
		var is_chasing = false
		if is_instance_valid(player) and global_position.distance_to(player.global_position) < 360.0:
			is_chasing = true
			var p_dir = sign(player.global_position.x - global_position.x)
			if p_dir != 0:
				facing_direction = int(p_dir)
			velocity.x = facing_direction * speed * 0.9
			if is_on_floor() and (is_on_wall() or player.global_position.y < global_position.y - 40):
				if randf() < 0.08:
					velocity.y = -360.0 # Jump towards higher platform
		else:
			# Gentle wander & turn around periodically
			if int(ai_timer) % 5 < 3:
				velocity.x = facing_direction * speed * 0.5
			else:
				velocity.x = 0
				if randf() < 0.02:
					facing_direction *= -1
			
	if is_boss and boss_skill_timer >= 6.0:
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

func cast_boss_ultimate():
	Global.broadcast_message("【BOSS技能】%s 發動了全屏威壓咆哮！" % monster_name, Color(1.0, 0.2, 0.2))
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 400.0:
			Global.damage_player(int(atk * 1.6))

# Networked Damage Entrypoint
func take_damage_custom(amount: int, is_crit: bool = false, hit_index: int = 0):
	if NetworkManager.is_multiplayer_active:
		NetworkManager.request_damage_on_monster(net_id, amount, is_crit, hit_index)
	else:
		take_damage_authoritative(amount, is_crit, hit_index)

func take_damage(amount: int, is_crit: bool = false, hit_index: int = 0):
	take_damage_custom(amount, is_crit, hit_index)
	take_damage_custom(amount, is_crit, 0)

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
		num.global_position = global_position + Vector2(randf_range(-10, 10), -45 * body_scale)
		num.setup(amount, is_crit, false, false, hit_index)
		get_tree().current_scene.add_child.call_deferred(num)

func die_synchronized(exp_amt: int, meso_amt: int):
	Global.add_exp(exp_amt)
	Global.meso_gold += meso_amt
	
	# Spawn authentic item drops
	if not is_client_puppet():
		var mob_data = MonsterDatabaseFull.get_monster(monster_id)
		DropItemManager.spawn_monster_drops(get_parent(), global_position, mob_data)
		
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
		"level": monster_level,
		"hp": max_hp,
		"max_hp": max_hp,
		"atk": atk,
		"speed": speed,
		"color": body_color,
		"scale": body_scale,
		"sprite": sprite_path
	}

func _draw():
	var is_moving = abs(velocity.x) > 10.0 and is_on_floor()
	var hop_y = -abs(sin(anim_frame * 2.2)) * 6.5 if is_moving else sin(anim_frame * 2.0) * 2.0
	var squish_x = (1.0 + sin(anim_frame * 2.2) * 0.12) if is_moving else (1.0 - sin(anim_frame * 2.0) * 0.05)
	var squish_y = (1.0 - sin(anim_frame * 2.2) * 0.10) if is_moving else (1.0 + sin(anim_frame * 2.0) * 0.07)
	
	# Boss Glowing Aura
	if is_boss:
		var aura_pulse = (sin(anim_frame * 3.0) + 1.0) * 0.5
		draw_circle(Vector2(0, -22 * body_scale + hop_y), 32 * body_scale + aura_pulse * 6.0, Color(1.0, 0.2, 0.2, 0.18 + aura_pulse * 0.12))
		draw_circle(Vector2(0, -22 * body_scale + hop_y), 24 * body_scale, Color(1.0, 0.8, 0.2, 0.12))

	# If no texture, draw procedural animated model
	if not has_sprite_texture:
		var col = body_color if hurt_flash <= 0.0 else Color.RED
		var base_y = -18.0 * body_scale + hop_y
		
		# 1. Shadow underneath
		draw_rect(Rect2(-12 * body_scale * squish_x, -3, 24 * body_scale * squish_x, 4 * body_scale), Color(0, 0, 0, 0.35), true)
		
		# 2. Dynamic Monster Types
		if "Snail" in monster_type or "嫩寶" in monster_name or "藍寶" in monster_name or "紅寶" in monster_name:
			# Snail Shell + Body
			var shell_col = Color(0.3, 0.6, 0.9) if "藍寶" in monster_name else (Color(0.9, 0.3, 0.3) if "紅寶" in monster_name else Color(0.4, 0.8, 0.4))
			draw_circle(Vector2(-6 * facing_direction * squish_x, base_y), 12 * body_scale * squish_x, shell_col)
			draw_circle(Vector2(4 * facing_direction * squish_x, base_y + 4), 8 * body_scale * squish_y, Color(0.9, 0.85, 0.7))
			draw_line(Vector2(6 * facing_direction, base_y), Vector2(10 * facing_direction, base_y - 8), Color(0.9, 0.85, 0.7), 2.5)
			draw_circle(Vector2(10 * facing_direction, base_y - 8), 2.5, Color.BLACK)
		elif "Slime" in monster_type or "水靈" in monster_name:
			# Slime wobble
			draw_circle(Vector2(0, base_y), 15 * body_scale * squish_x, col)
			draw_circle(Vector2(-4 * facing_direction, base_y - 5), 4 * body_scale, Color(1, 1, 1, 0.6))
			draw_circle(Vector2(4 * facing_direction, base_y - 2), 2.5 * body_scale, Color.BLACK)
			draw_circle(Vector2(9 * facing_direction, base_y - 2), 2.5 * body_scale, Color.BLACK)
		elif "Mushroom" in monster_type or "菇" in monster_name:
			# Mushroom Cap & Stem
			draw_rect(Rect2(-7 * body_scale * squish_x, base_y, 14 * body_scale * squish_x, 14 * body_scale), Color(0.95, 0.9, 0.8), true)
			draw_circle(Vector2(0, base_y - 4), 16 * body_scale * squish_x, col)
			draw_circle(Vector2(-6, base_y - 8), 3.5 * body_scale, Color.WHITE)
			draw_circle(Vector2(6, base_y - 8), 3.5 * body_scale, Color.WHITE)
			draw_circle(Vector2(3 * facing_direction, base_y + 4), 2.2 * body_scale, Color.BLACK)
		elif "Pig" in monster_type or "肥肥" in monster_name or "豬" in monster_name:
			# Pig body & Snout
			draw_circle(Vector2(0, base_y), 16 * body_scale * squish_x, col)
			draw_circle(Vector2(12 * facing_direction, base_y + 2), 6 * body_scale, Color(0.95, 0.7, 0.75))
			draw_circle(Vector2(13 * facing_direction, base_y + 2), 1.8 * body_scale, Color.BLACK)
			draw_circle(Vector2(6 * facing_direction, base_y - 4), 2.8 * body_scale, Color.BLACK)
			if "緞帶" in monster_name:
				draw_circle(Vector2(-4, base_y - 12), 4 * body_scale, Color.RED)
		elif "木妖" in monster_name or "Stump" in monster_name:
			# Tree Stump with waving branch
			draw_rect(Rect2(-10 * body_scale * squish_x, base_y - 12, 20 * body_scale * squish_x, 26 * body_scale), Color(0.45, 0.28, 0.15), true)
			draw_line(Vector2(0, base_y - 12), Vector2(8 * facing_direction, base_y - 20 + sin(anim_frame * 3.0) * 4.0), Color(0.3, 0.7, 0.2), 3.0)
			draw_circle(Vector2(4 * facing_direction, base_y - 2), 2.5 * body_scale, Color.WHITE)
			draw_circle(Vector2(5 * facing_direction, base_y - 2), 1.5 * body_scale, Color.BLACK)
		elif "石巨人" in monster_name or "Golem" in monster_name:
			# Stone Golem heavy rock body
			draw_rect(Rect2(-14 * body_scale * squish_x, base_y - 14, 28 * body_scale * squish_x, 30 * body_scale), Color(0.4, 0.45, 0.5), true)
			draw_circle(Vector2(5 * facing_direction, base_y - 4), 3.5 * body_scale, Color.GOLD)
			draw_rect(Rect2(-8 * body_scale, base_y + 14, 6 * body_scale, 6 * body_scale), Color(0.3, 0.35, 0.4), true)
			draw_rect(Rect2(2 * body_scale, base_y + 14, 6 * body_scale, 6 * body_scale), Color(0.3, 0.35, 0.4), true)
		elif "章魚" in monster_name or "Octopus" in monster_name:
			# Octopus with 4 waving tentacles
			draw_circle(Vector2(0, base_y - 6), 15 * body_scale * squish_x, Color(0.85, 0.4, 0.2))
			for t_i in range(4):
				var tent_x = -9 + t_i * 6
				var wave = sin(anim_frame * 3.0 + t_i) * 5.0
				draw_line(Vector2(tent_x, base_y + 4), Vector2(tent_x + wave, base_y + 14), Color(0.85, 0.4, 0.2), 3.0)
			draw_circle(Vector2(4 * facing_direction, base_y - 6), 2.5 * body_scale, Color.WHITE)
			draw_circle(Vector2(5 * facing_direction, base_y - 6), 1.5 * body_scale, Color.BLACK)
		elif "幽靈" in monster_name or "Wraith" in monster_name:
			# Floating spooky ghost
			var wave = sin(anim_frame * 3.0) * 4.0
			draw_circle(Vector2(0, base_y - 6), 14 * body_scale * squish_x, Color(0.7, 0.8, 1.0, 0.8))
			draw_line(Vector2(-6, base_y + 4), Vector2(-8 + wave, base_y + 16), Color(0.7, 0.8, 1.0, 0.6), 4.0)
			draw_line(Vector2(6, base_y + 4), Vector2(8 - wave, base_y + 16), Color(0.7, 0.8, 1.0, 0.6), 4.0)
			draw_circle(Vector2(4 * facing_direction, base_y - 6), 3.0 * body_scale, Color(1, 0.2, 0.2))
		elif "龍" in monster_name or "Drake" in monster_name or "巴洛古" in monster_name or "Balrog" in monster_name:
			# Dragon / Drake / Boss Winged Form
			draw_circle(Vector2(0, base_y), 18 * body_scale * squish_x, col)
			# Flapping wings
			var wing_y = sin(anim_frame * 4.0) * 8.0
			draw_line(Vector2(-6 * facing_direction, base_y - 8), Vector2(-18 * facing_direction, base_y - 20 + wing_y), Color(0.2, 0.2, 0.3), 4.0)
			draw_circle(Vector2(10 * facing_direction, base_y - 4), 3.5 * body_scale, Color.YELLOW)
			draw_circle(Vector2(11 * facing_direction, base_y - 4), 1.5 * body_scale, Color.BLACK)
		else:
			# Universal Animated Organic Monster
			draw_circle(Vector2(0, base_y), 16 * body_scale * squish_x, col)
			draw_circle(Vector2(6 * facing_direction * squish_x, base_y - 3), 3.5 * body_scale, Color.BLACK)
			draw_circle(Vector2(7 * facing_direction * squish_x, base_y - 4), 1.2 * body_scale, Color.WHITE)
	
	# Overhead Monster HP Bar
	if hp < max_hp or is_boss:
		var bar_w = 46.0 * body_scale
		var bar_y = -52.0 * body_scale + hop_y
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, 4), Color(0.1, 0.1, 0.1, 0.8), true)
		var fill_w = clamp(float(hp) / float(max_hp), 0.0, 1.0) * bar_w
		var hp_col = Color.RED if hp < max_hp * 0.3 else (Color.GOLD if is_boss else Color(0.2, 1.0, 0.4))
		draw_rect(Rect2(-bar_w / 2, bar_y, fill_w, 4), hp_col, true)
