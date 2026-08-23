# Player.gd
extends CharacterBody2D

@export var jump_velocity: float = -480.0
@export var gravity: float = 1100.0

var facing_direction: int = 1
var is_attacking: bool = false
var attack_type: String = "basic"
var attack_anim_timer: float = 0.0
var hurt_flash: float = 0.0
var flash_jump_available: bool = true
var anim_frame: float = 0.0

# Skill cooldowns
var skill_1_cd: float = 0.0
var skill_2_cd: float = 0.0
var skill_3_cd: float = 0.0
var net_sync_timer: float = 0.0

func _ready():
	add_to_group("player")
	Global.player_hp_changed.connect(_on_hp_changed)
	Global.player_job_changed.connect(_on_job_changed)
	Global.pet_summoned.connect(_on_pet_summoned)
	Global.pet_unsummoned.connect(_on_pet_unsummoned)
	
	if not Global.pet_inventory.is_empty():
		Global.select_active_pet(0)

func _physics_process(delta):
	anim_frame += delta * 8.0
	
	if hurt_flash > 0.0:
		hurt_flash -= delta * 4.0
		
	# Cooldown timers
	if skill_1_cd > 0: skill_1_cd -= delta
	if skill_2_cd > 0: skill_2_cd -= delta
	if skill_3_cd > 0: skill_3_cd -= delta
	
	# Multiplayer state sync (20 times per sec)
	if NetworkManager.is_multiplayer_active:
		net_sync_timer += delta
		if net_sync_timer >= 0.05:
			net_sync_timer = 0.0
			rpc("sync_player_state", global_position, velocity, facing_direction, is_attacking, Global.player_job_id, Global.player_hp, Global.player_max_hp)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		flash_jump_available = true
		
	if is_attacking:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0:
			is_attacking = false
			
	handle_input(delta)
	move_and_slide()
	queue_redraw()

func handle_input(delta):
	if Global.is_game_over:
		return
		
	# Horizontal movement
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x != 0:
		facing_direction = sign(input_x)
		velocity.x = input_x * Global.player_speed
	else:
		velocity.x = move_toward(velocity.x, 0, Global.player_speed * 6.0 * delta)
		
	# Jump & Down-jump & Flash Jump
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("move_down") and is_on_floor():
			position.y += 3.0
		elif is_on_floor():
			velocity.y = jump_velocity
		elif flash_jump_available and Input.is_action_just_pressed("jump"):
			flash_jump_available = false
			velocity.x = facing_direction * Global.player_speed * 2.2
			velocity.y = jump_velocity * 0.75
			Global.broadcast_message("二段跳 Flash Jump!", Color(0.3, 0.9, 1.0))
			
	# Attacks & Skills
	var skills = Global.player_job_data.get("skills", {})
	
	if Input.is_action_just_pressed("attack"):
		perform_job_skill(skills.get("basic", {}), "basic")
		
	if Input.is_action_just_pressed("skill_1") and skill_1_cd <= 0:
		var s1 = skills.get("skill_1", {})
		if consume_mp(s1.get("mp", 0)):
			skill_1_cd = s1.get("cd", 1.0) * (1.0 - Global.passive_buffs.get("cooldown_reduction", 0.0))
			perform_job_skill(s1, "skill_1")
			
	if Input.is_action_just_pressed("skill_2") and skill_2_cd <= 0:
		var s2 = skills.get("skill_2", {})
		if consume_mp(s2.get("mp", 0)):
			skill_2_cd = s2.get("cd", 1.5) * (1.0 - Global.passive_buffs.get("cooldown_reduction", 0.0))
			perform_job_skill(s2, "skill_2")
			
	if Input.is_action_just_pressed("skill_3") and skill_3_cd <= 0:
		var s3 = skills.get("skill_3", {})
		if consume_mp(s3.get("mp", 0)):
			skill_3_cd = s3.get("cd", 5.0) * (1.0 - Global.passive_buffs.get("cooldown_reduction", 0.0))
			perform_job_skill(s3, "skill_3")
			
	# Tame Monster (E)
	if Input.is_action_just_pressed("tame_monster"):
		attempt_tame_nearby_monster()
		
	# Summon / Switch Pet (R)
	if Input.is_action_just_pressed("summon_pet"):
		toggle_pet_summon()

func consume_mp(amount: int) -> bool:
	if amount <= 0:
		return true
	if Global.player_mp < amount:
		Global.broadcast_message("MP 不足！無法施放技能！", Color.SALMON)
		return false
	Global.player_mp -= amount
	Global.emit_signal("player_mp_changed", Global.player_mp, Global.player_max_mp)
	return true

func perform_job_skill(skill_data: Dictionary, skill_key: String):
	is_attacking = true
	attack_type = skill_key
	attack_anim_timer = 0.28
	
	var mult = skill_data.get("multiplier", 1.0)
	var hits = skill_data.get("hits", 1)
	var type = skill_data.get("type", "melee")
	var job = Global.player_job_id
	
	if NetworkManager.is_multiplayer_active:
		rpc("sync_skill_cast", skill_key)
	
	Global.broadcast_message("【%s】%s !" % [Global.player_job_data.name, skill_data.get("name", "")], Global.player_job_data.color)
	
	# Execute damage lines with classic multi-hit delay
	match job:
		"warrior":
			execute_melee_cone_damage(mult, hits, 85.0 if skill_key == "skill_2" else 65.0)
		"magician":
			if skill_key == "skill_3":
				execute_screen_magic(mult, hits)
			elif skill_key == "skill_2":
				execute_lightning_storm(mult, hits)
			else:
				execute_magic_claw(mult, hits)
		"bowman":
			shoot_arrows(mult, hits, skill_key == "skill_2")
		"thief":
			if skill_key == "skill_3":
				execute_savage_blow(mult, 6)
			else:
				shoot_throwing_stars(mult, hits)
		"pirate":
			if skill_key == "skill_2":
				execute_somersault_kick(mult, hits)
			elif skill_key == "skill_3":
				execute_dragon_strike(mult, hits)
			else:
				shoot_pirate_bullet(mult, hits)

func execute_melee_cone_damage(multiplier: float, hits: int, radius: float):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_center = global_position + Vector2(facing_direction * 45, -20)
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if hit_center.distance_to(e.global_position) <= radius:
				apply_multi_hit_damage(e, multiplier, hits)

func execute_screen_magic(multiplier: float, hits: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 800.0:
			apply_multi_hit_damage(e, multiplier, hits)
			
	var rain = load("res://scenes/skills/HolyRain.tscn").instantiate()
	rain.global_position = global_position
	get_parent().add_child.call_deferred(rain)

func execute_lightning_storm(multiplier: float, hits: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 450.0:
			apply_multi_hit_damage(e, multiplier, hits)

func execute_magic_claw(multiplier: float, hits: int):
	var enemy = find_target_in_direction(350.0)
	if enemy:
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 90.0)

func shoot_arrows(multiplier: float, hits: int, is_rain: bool):
	if is_rain:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and global_position.distance_to(e.global_position) < 500.0:
				apply_multi_hit_damage(e, multiplier, hits)
	else:
		var enemy = find_target_in_direction(550.0)
		if enemy:
			apply_multi_hit_damage(enemy, multiplier, hits)
		else:
			execute_melee_cone_damage(multiplier, hits, 70.0)

func shoot_throwing_stars(multiplier: float, hits: int):
	var enemy = find_target_in_direction(500.0)
	if enemy:
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 70.0)

func execute_savage_blow(multiplier: float, hits: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_center = global_position + Vector2(facing_direction * 40, -20)
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if hit_center.distance_to(e.global_position) <= 75.0:
				apply_multi_hit_damage(e, multiplier, hits)

func execute_somersault_kick(multiplier: float, hits: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 130.0:
			apply_multi_hit_damage(e, multiplier, hits)

func execute_dragon_strike(multiplier: float, hits: int):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= 380.0:
			apply_multi_hit_damage(e, multiplier, hits)
			
	var meteor = load("res://scenes/skills/Meteor.tscn").instantiate()
	meteor.global_position = global_position + Vector2(facing_direction * 150, -350)
	meteor.target_pos = global_position + Vector2(facing_direction * 150, 0)
	get_parent().add_child.call_deferred(meteor)

func shoot_pirate_bullet(multiplier: float, hits: int):
	var enemy = find_target_in_direction(480.0)
	if enemy:
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 65.0)

func find_target_in_direction(range_dist: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_d = range_dist
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var diff_x = e.global_position.x - global_position.x
			if (facing_direction > 0 and diff_x > 0) or (facing_direction < 0 and diff_x < 0):
				var d = global_position.distance_to(e.global_position)
				if d < min_d:
					min_d = d
					closest = e
	return closest

func apply_multi_hit_damage(target: Node2D, multiplier: float, hits: int):
	if not is_instance_valid(target) or not target.has_method("take_damage_custom"):
		if target.has_method("take_damage"):
			var dmg_info = Global.calculate_skill_damage(multiplier)
			target.take_damage(dmg_info.damage, dmg_info.is_crit)
		return
		
	for i in range(hits):
		var hit_idx = i
		get_tree().create_timer(i * 0.08).timeout.connect(func():
			if is_instance_valid(target):
				var dmg_info = Global.calculate_skill_damage(multiplier)
				target.take_damage_custom(dmg_info.damage, dmg_info.is_crit, hit_idx)
		)

func attempt_tame_nearby_monster():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 280.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				closest = e
				
	if closest:
		var net_scene = load("res://scenes/skills/CaptureNet.tscn")
		if net_scene:
			var net = net_scene.instantiate()
			net.global_position = global_position + Vector2(0, -20)
			net.setup(closest)
			get_parent().add_child.call_deferred(net)
			Global.broadcast_message("擲出精靈封印球！", Color(0.2, 0.8, 1.0))
	else:
		Global.broadcast_message("周圍沒有可捕捉的怪物目標！", Color(1.0, 0.6, 0.4))

func toggle_pet_summon():
	if is_instance_valid(Global.active_pet_node):
		Global.dismiss_active_pet()
		Global.broadcast_message("召回出戰寵物！", Color.GRAY)
	else:
		if not Global.pet_inventory.is_empty():
			Global.select_active_pet(0)
			Global.broadcast_message("召喚寵物出戰！", Color(0.3, 1.0, 0.5))
		else:
			Global.broadcast_message("寵物背包中目前沒有任何寵物！", Color.ORANGE)

func _on_pet_summoned(pet_data: Dictionary):
	if is_instance_valid(Global.active_pet_node):
		Global.active_pet_node.queue_free()
		
	var pet_scene = load("res://scenes/Pet.tscn")
	if pet_scene:
		var p = pet_scene.instantiate()
		p.setup_pet(pet_data, self)
		get_parent().add_child.call_deferred(p)

func _on_pet_unsummoned():
	if is_instance_valid(Global.active_pet_node):
		Global.active_pet_node.queue_free()
		Global.active_pet_node = null

func _on_hp_changed(_cur, _max):
	hurt_flash = 1.0

func _on_job_changed(_job_data):
	queue_redraw()

func _draw():
	var body_col = Color(1.0, 0.85, 0.7)
	var hair_col = Color(0.85, 0.55, 0.2)
	var cloth_col = Global.player_job_data.get("color", Color(0.2, 0.5, 0.9))
	var pants_col = Color(0.3, 0.3, 0.4)
	
	if hurt_flash > 0.0:
		body_col = body_col.lerp(Color.RED, hurt_flash)
		cloth_col = cloth_col.lerp(Color.WHITE, hurt_flash)
		
	var leg_swing = sin(anim_frame) * 4.0 if (velocity.x != 0 and is_on_floor()) else 0.0
	
	# 1. Pants & Shoes
	draw_rect(Rect2(-7 + leg_swing, -8, 5, 8), pants_col)
	draw_rect(Rect2(2 - leg_swing, -8, 5, 8), pants_col)
	draw_rect(Rect2(-8 + leg_swing, -2, 7, 3), Color(0.35, 0.2, 0.1))
	draw_rect(Rect2(1 - leg_swing, -2, 7, 3), Color(0.35, 0.2, 0.1))
	
	# 2. Job Themed Armor / Robe
	draw_rect(Rect2(-9, -22, 18, 14), cloth_col)
	draw_rect(Rect2(-7, -20, 14, 4), cloth_col.lightened(0.3))
	
	# 3. Head & Face
	draw_circle(Vector2(0, -32), 10.0, body_col)
	draw_circle(Vector2(3 * facing_direction, -32), 2.5, Color.BLACK)
	draw_circle(Vector2(4 * facing_direction, -33), 1.0, Color.WHITE)
	draw_line(Vector2(1 * facing_direction, -27), Vector2(4 * facing_direction, -27), Color(0.5, 0.2, 0.2), 1.5)
	
	# 4. Job Hair & Headgear
	match Global.player_job_id:
		"magician":
			# Wizard Hat
			draw_polygon(
				PackedVector2Array([
					Vector2(-14, -36),
					Vector2(14, -36),
					Vector2(0, -56)
				]),
				PackedColorArray([Color(0.2, 0.3, 0.7), Color(0.2, 0.3, 0.7), Color(0.3, 0.5, 0.9)])
			)
		"thief":
			# Ninja Bandana
			draw_rect(Rect2(-11, -38, 22, 7), Color(0.15, 0.15, 0.2))
			draw_line(Vector2(-10 * facing_direction, -34), Vector2(-20 * facing_direction, -30), Color(0.15, 0.15, 0.2), 3.0)
		_:
			# Classic Maple Spiky Hair
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
			
	# 5. Weapon and Attack Visuals
	if is_attacking:
		var slash_col = cloth_col.lightened(0.4)
		match Global.player_job_id:
			"warrior":
				draw_arc(Vector2(facing_direction * 30, -20), 45.0, -PI/2, PI/2, 16, slash_col, 6.0)
				draw_line(Vector2(0, -18), Vector2(facing_direction * 48, -18), Color.SILVER, 5.0)
			"magician":
				draw_circle(Vector2(facing_direction * 35, -24), 22.0, Color(0.4, 0.8, 1.0, 0.6))
				draw_line(Vector2(0, -18), Vector2(facing_direction * 30, -28), Color(0.9, 0.8, 0.3), 4.0)
			"bowman":
				draw_arc(Vector2(facing_direction * 20, -20), 20.0, -PI/2, PI/2, 12, Color(0.6, 0.4, 0.2), 3.0)
				draw_line(Vector2(0, -20), Vector2(facing_direction * 50, -20), Color.YELLOW, 3.0)
			"thief":
				draw_circle(Vector2(facing_direction * 25, -20), 12.0, Color.BLACK)
				draw_arc(Vector2(facing_direction * 25, -20), 16.0, 0, TAU, 8, Color.GOLD, 3.0)
			"pirate":
				draw_circle(Vector2(facing_direction * 32, -20), 18.0, Color(1.0, 0.4, 0.1, 0.8))
				draw_rect(Rect2(facing_direction * 12, -24, 20, 8), Color.DARK_SLATE_GRAY)
	else:
		# Idle weapon on back / side
		match Global.player_job_id:
			"warrior":
				draw_line(Vector2(-6 * facing_direction, -14), Vector2(-18 * facing_direction, -42), Color.SILVER, 4.0)
			"magician":
				draw_line(Vector2(-6 * facing_direction, -12), Vector2(-16 * facing_direction, -40), Color(0.8, 0.6, 0.2), 3.0)
				draw_circle(Vector2(-16 * facing_direction, -40), 4.0, Color(0.3, 0.8, 1.0))
			"bowman":
				draw_arc(Vector2(-8 * facing_direction, -24), 16.0, -PI/2, PI/2, 10, Color(0.5, 0.3, 0.1), 3.0)
			"thief":
				draw_rect(Rect2(-8 * facing_direction, -18, 6, 8), Color.BLACK)
			"pirate":
				draw_rect(Rect2(-8 * facing_direction, -18, 10, 5), Color.DARK_SLATE_GRAY)

@rpc("any_peer", "unreliable_ordered")
func sync_player_state(pos: Vector2, vel: Vector2, facing: int, attacking: bool, job: String, hp_val: int, max_hp_val: int):
	var sender_id = multiplayer.get_remote_sender_id()
	var remote_node = get_parent().get_node_or_null("RemotePlayer_%d" % sender_id)
	if is_instance_valid(remote_node):
		remote_node.update_state(pos, vel, facing, attacking, job, hp_val, max_hp_val)

@rpc("any_peer", "call_local", "reliable")
func sync_skill_cast(skill_key: String):
	var sender_id = multiplayer.get_remote_sender_id()
	var remote_node = get_parent().get_node_or_null("RemotePlayer_%d" % sender_id)
	if is_instance_valid(remote_node):
		remote_node.trigger_skill_visual(skill_key)
