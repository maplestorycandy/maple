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

# Movement state
var keyboard_move_dir: float = 0.0

# Skill cooldowns
var skill_1_cd: float = 0.0
var skill_2_cd: float = 0.0
var skill_3_cd: float = 0.0
var skill_4_cd: float = 0.0
var skill_5_cd: float = 0.0
var skill_6_cd: float = 0.0
var ultimate_cd: float = 0.0

var passive_proc_timer: float = 0.0
var net_sync_timer: float = 0.0

# Down-jump mechanics
var is_down_jumping: bool = false
var down_jump_timer: float = 0.0

func _ready():
	add_to_group("player")
	collision_layer = 1
	collision_mask = 3 # Layer 1 (Ground) & Layer 2 (One-way Platforms)
	
	Global.player_hp_changed.connect(_on_hp_changed)
	Global.player_job_changed.connect(_on_job_changed)
	Global.pet_summoned.connect(_on_pet_summoned)
	Global.pet_unsummoned.connect(_on_pet_unsummoned)
	
	if not Global.pet_inventory.is_empty():
		Global.select_active_pet(0)

func _input(event: InputEvent):
	if event is InputEventKey:
		var code = event.keycode if event.keycode != 0 else (event.physical_keycode if event.physical_keycode != 0 else event.key_label)
		
		# Movement Keys (Arrows & WASD)
		if code == KEY_LEFT or code == KEY_A:
			if event.pressed:
				keyboard_move_dir = -1.0
			elif not event.pressed and keyboard_move_dir < 0.0:
				keyboard_move_dir = 1.0 if (Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) else 0.0
		elif code == KEY_RIGHT or code == KEY_D:
			if event.pressed:
				keyboard_move_dir = 1.0
			elif not event.pressed and keyboard_move_dir > 0.0:
				keyboard_move_dir = -1.0 if (Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)) else 0.0
				
		# Action Keys Trigger on press
		if event.pressed and not event.echo:
			# Check custom keybindings
			var matched = false
			for action in Global.custom_keybindings.keys():
				if Global.custom_keybindings[action] == code:
					trigger_custom_action(action)
					matched = true
					break
			if not matched:
				if code == KEY_SPACE or code == KEY_ALT:
					do_jump()
				elif code == KEY_Z or code == KEY_CTRL:
					trigger_custom_action("attack")
				elif code == KEY_X:
					trigger_custom_action("skill_1")
				elif code == KEY_C:
					trigger_custom_action("skill_2")
				elif code == KEY_V:
					trigger_custom_action("skill_3")

func _physics_process(delta):
	anim_frame += delta * 8.0
	
	if hurt_flash > 0.0:
		hurt_flash -= delta * 4.0
		
	# Down jump timer recovery
	if is_down_jumping:
		down_jump_timer -= delta
		if down_jump_timer <= 0:
			is_down_jumping = false
			set_collision_mask_value(2, true) # Re-enable one-way platforms
		
	# Cooldown timers
	skill_1_cd = max(0.0, skill_1_cd - delta)
	skill_2_cd = max(0.0, skill_2_cd - delta)
	skill_3_cd = max(0.0, skill_3_cd - delta)
	skill_4_cd = max(0.0, skill_4_cd - delta)
	skill_5_cd = max(0.0, skill_5_cd - delta)
	skill_6_cd = max(0.0, skill_6_cd - delta)
	ultimate_cd = max(0.0, ultimate_cd - delta)
	
	# Handle Automatic Passive Talents
	passive_proc_timer += delta
	if passive_proc_timer >= 3.5:
		passive_proc_timer = 0.0
		trigger_passive_procs()
	
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
			
	handle_movement(delta)
	move_and_slide()
	queue_redraw()

func handle_movement(delta: float):
	if Global.is_game_over:
		return
		
	# Multi-source horizontal movement input (Keyboard Events + Polling + Touch Buttons)
	var input_x = keyboard_move_dir
	if input_x == 0.0:
		if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			input_x -= 1.0
		if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			input_x += 1.0
	if Global.touch_move_dir != 0.0:
		input_x = Global.touch_move_dir
		
	var target_speed = max(260.0, Global.player_speed)
	if input_x != 0.0:
		facing_direction = 1 if input_x > 0 else -1
		velocity.x = input_x * target_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, target_speed * 12.0 * delta)

func do_jump():
	var is_down = Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
	if is_down and is_on_floor() and position.y < 350:
		# Down-jump
		is_down_jumping = true
		down_jump_timer = 0.22
		set_collision_mask_value(2, false)
		position.y += 12.0
		velocity.y = 220.0
	elif is_on_floor():
		velocity.y = jump_velocity
	elif flash_jump_available:
		flash_jump_available = false
		velocity.x = facing_direction * max(260.0, Global.player_speed) * 2.2
		velocity.y = jump_velocity * 0.75
		Global.broadcast_message("二段跳 Flash Jump!", Color(0.3, 0.9, 1.0))

func consume_mp(amount: int) -> bool:
	if amount <= 0:
		return true
	if Global.player_mp < amount:
		Global.broadcast_message("MP 不足！無法施放技能！", Color.SALMON)
		return false
	Global.player_mp -= amount
	Global.emit_signal("player_mp_changed", Global.player_mp, Global.player_max_mp)
	return true

func spawn_skill_visual(effect_type: String, target_pos: Vector2, facing: int = 1, duration: float = 0.55):
	var eff_scene = load("res://scenes/skills/SkillEffect.tscn")
	if eff_scene:
		var eff = eff_scene.instantiate()
		eff.setup(effect_type, target_pos, facing, duration)
		get_parent().add_child.call_deferred(eff)

func trigger_custom_action(action_name: String):
	var cd_mult = (1.0 - Global.passive_buffs.get("cooldown_reduction", 0.0))
	
	match action_name:
		"attack":
			var s = Global.get_player_skill_stats("basic")
			perform_job_skill(s, "basic")
		"jump":
			do_jump()
		"skill_1":
			if skill_1_cd <= 0:
				var s = Global.get_player_skill_stats("skill_1")
				if consume_mp(s.get("mp", 0)):
					skill_1_cd = s.get("cd", 1.0) * cd_mult
					perform_job_skill(s, "skill_1")
		"skill_2":
			if skill_2_cd <= 0:
				var s = Global.get_player_skill_stats("skill_2")
				if consume_mp(s.get("mp", 0)):
					skill_2_cd = s.get("cd", 1.5) * cd_mult
					perform_job_skill(s, "skill_2")
		"skill_3":
			if skill_3_cd <= 0:
				var s = Global.get_player_skill_stats("skill_3")
				if consume_mp(s.get("mp", 0)):
					skill_3_cd = s.get("cd", 2.0) * cd_mult
					perform_job_skill(s, "skill_3")
		"skill_4":
			if skill_4_cd <= 0 and ("skill_4" in Global.unlocked_skills or Global.player_level >= 10):
				var s = Global.get_player_skill_stats("skill_4")
				if consume_mp(s.get("mp", 0)):
					skill_4_cd = s.get("cd", 3.0) * cd_mult
					perform_job_skill(s, "skill_4")
		"skill_5":
			if skill_5_cd <= 0 and ("skill_5" in Global.unlocked_skills or Global.player_level >= 20):
				var s = Global.get_player_skill_stats("skill_5")
				if consume_mp(s.get("mp", 0)):
					skill_5_cd = s.get("cd", 4.0) * cd_mult
					perform_job_skill(s, "skill_5")
		"skill_6":
			if skill_6_cd <= 0 and ("skill_6" in Global.unlocked_skills or Global.player_level >= 30):
				var s = Global.get_player_skill_stats("skill_6")
				if consume_mp(s.get("mp", 0)):
					skill_6_cd = s.get("cd", 5.0) * cd_mult
					perform_job_skill(s, "skill_6")
		"ultimate":
			if ultimate_cd <= 0 and ("ultimate" in Global.unlocked_skills or Global.player_level >= 40):
				var s = Global.get_player_skill_stats("ultimate")
				if consume_mp(s.get("mp", 0)):
					ultimate_cd = s.get("cd", 10.0) * cd_mult
					perform_job_skill(s, "ultimate")
		"potion_hp":
			use_quick_potion("hp")
		"potion_mp":
			use_quick_potion("mp")
		"tame_monster":
			attempt_tame_nearby_monster()
		"summon_pet":
			toggle_pet_summon()

func use_quick_potion(type: String):
	for i in range(Global.use_inventory.size()):
		var item = Global.use_inventory[i]
		var iname = item.get("name", "")
		if type == "hp" and ("紅" in iname or "白" in iname or "超級" in iname or "HP" in iname or "水" in iname):
			Global.use_consume_item(i)
			return
		elif type == "mp" and ("藍" in iname or "超級" in iname or "MP" in iname or "水" in iname):
			Global.use_consume_item(i)
			return
	Global.broadcast_message("無可用【%s】藥水！" % ("生命 HP" if type == "hp" else "魔力 MP"), Color.SALMON)

func trigger_passive_procs():
	if Global.passive_buffs.get("auto_lightning", false):
		execute_screen_magic(5.0, 3)
		spawn_skill_visual("lightning_storm", global_position, facing_direction, 0.6)
		Global.broadcast_message("⚡ 天神神罰天雷轟頂！", Color(0.4, 0.9, 1.0))
	if Global.passive_buffs.get("auto_cannon", false):
		execute_dragon_strike(4.0, 2)
		spawn_skill_visual("dragon_strike", global_position + Vector2(facing_direction * 40, -10), facing_direction, 0.6)
		Global.broadcast_message("💣 戰艦重砲全自動開火！", Color.GOLD)

func perform_job_skill(skill_data: Dictionary, skill_key: String):
	is_attacking = true
	attack_type = skill_key
	attack_anim_timer = 0.28
	
	var mult = skill_data.get("multiplier", 1.0)
	var hits = skill_data.get("hits", 1)
	var s_type = skill_data.get("type", "melee")
	var job = Global.player_job_id
	var cur_lvl = skill_data.get("current_level", 1)
	
	if NetworkManager.is_multiplayer_active:
		rpc("sync_skill_cast", skill_key)
	
	Global.broadcast_message("【%s】%s (Lv.%d) !" % [Global.player_job_data.name, skill_data.get("name", ""), cur_lvl], Global.player_job_data.color)
	
	# Spawn skill cast visual on player
	var cast_pos = global_position + Vector2(facing_direction * 35, -20)
	spawn_skill_visual(s_type, cast_pos, facing_direction, 0.45)
	
	match job:
		"warrior":
			if skill_key in ["skill_5", "ultimate"]:
				execute_screen_warrior(mult, hits, s_type)
			elif skill_key in ["skill_3", "skill_4", "skill_6"]:
				execute_melee_cone_damage(mult, hits, 130.0, s_type)
			else:
				execute_melee_cone_damage(mult, hits, 95.0 if skill_key == "skill_2" else 75.0, s_type)
		"magician":
			if skill_key in ["skill_4", "skill_5", "ultimate"]:
				execute_screen_magic(mult, hits, s_type)
			elif skill_key in ["skill_2", "skill_3", "skill_6"]:
				execute_lightning_storm(mult, hits, s_type)
			else:
				execute_magic_claw(mult, hits, s_type)
		"bowman":
			if skill_key in ["skill_5", "ultimate"]:
				execute_screen_magic(mult, hits, s_type)
			else:
				shoot_arrows(mult, hits, skill_key in ["skill_2", "skill_3", "skill_4", "skill_6"], s_type)
		"thief":
			if skill_key in ["skill_3", "skill_4", "skill_6"]:
				execute_savage_blow(mult, hits, s_type)
			elif skill_key == "ultimate":
				execute_screen_magic(mult, hits, s_type)
			else:
				shoot_throwing_stars(mult, hits, s_type)
		"pirate":
			if skill_key in ["skill_5", "skill_6", "ultimate"]:
				execute_dragon_strike(mult, hits, s_type)
			elif skill_key in ["skill_2", "skill_3"]:
				execute_somersault_kick(mult, hits, s_type)
			else:
				shoot_pirate_bullet(mult, hits, s_type)
		_:
			if skill_key in ["skill_5", "skill_6", "ultimate"]:
				execute_screen_magic(mult, hits, s_type)
			else:
				execute_melee_cone_damage(mult, hits, 90.0, s_type)

func execute_melee_cone_damage(multiplier: float, hits: int, radius: float, effect_type: String = "power_strike"):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_center = global_position + Vector2(facing_direction * 50, -20)
	
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if hit_center.distance_to(e.global_position) <= radius or global_position.distance_to(e.global_position) <= (radius + 30.0):
				spawn_skill_visual(effect_type, e.global_position + Vector2(0, -20), facing_direction, 0.4)
				apply_multi_hit_damage(e, multiplier, hits)

func execute_screen_warrior(multiplier: float, hits: int, effect_type: String = "dragon_roar"):
	var enemies = get_tree().get_nodes_in_group("enemies")
	spawn_skill_visual(effect_type, global_position + Vector2(0, -30), facing_direction, 0.8)
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if global_position.distance_to(e.global_position) < 850.0:
				spawn_skill_visual(effect_type, e.global_position + Vector2(0, -20), facing_direction, 0.4)
				apply_multi_hit_damage(e, multiplier, hits)

func execute_screen_magic(multiplier: float, hits: int, effect_type: String = "genesis"):
	var enemies = get_tree().get_nodes_in_group("enemies")
	spawn_skill_visual(effect_type, global_position + Vector2(0, -40), facing_direction, 0.85)
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if global_position.distance_to(e.global_position) < 850.0:
				spawn_skill_visual(effect_type, e.global_position + Vector2(0, -20), facing_direction, 0.5)
				apply_multi_hit_damage(e, multiplier, hits)
			
	var rain_scene = load("res://scenes/skills/HolyRain.tscn")
	if rain_scene:
		var rain = rain_scene.instantiate()
		rain.global_position = global_position
		get_parent().add_child.call_deferred(rain)

func execute_lightning_storm(multiplier: float, hits: int, effect_type: String = "lightning_storm"):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if global_position.distance_to(e.global_position) < 500.0:
				spawn_skill_visual(effect_type, e.global_position + Vector2(0, -25), facing_direction, 0.45)
				apply_multi_hit_damage(e, multiplier, hits)

func execute_magic_claw(multiplier: float, hits: int, effect_type: String = "magic_claw"):
	var enemy = find_target_in_direction(350.0)
	if enemy:
		spawn_skill_visual(effect_type, enemy.global_position + Vector2(0, -20), facing_direction, 0.45)
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 90.0, effect_type)

func execute_savage_blow(multiplier: float, hits: int, effect_type: String = "savage_blow"):
	var enemy = find_target_in_direction(240.0)
	if enemy:
		spawn_skill_visual(effect_type, enemy.global_position + Vector2(0, -20), facing_direction, 0.5)
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 90.0, effect_type)

func execute_somersault_kick(multiplier: float, hits: int, effect_type: String = "aoe_slash"):
	execute_melee_cone_damage(multiplier, hits, 120.0, effect_type)

func execute_dragon_strike(multiplier: float, hits: int, effect_type: String = "dragon_strike"):
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if global_position.distance_to(e.global_position) < 420.0:
				spawn_skill_visual(effect_type, e.global_position + Vector2(0, -20), facing_direction, 0.5)
				apply_multi_hit_damage(e, multiplier, hits)

func shoot_arrows(multiplier: float, hits: int, is_spread: bool = false, effect_type: String = "arrow_rain"):
	var enemy = find_target_in_direction(650.0)
	if enemy:
		spawn_skill_visual(effect_type, enemy.global_position + Vector2(0, -20), facing_direction, 0.45)
		apply_multi_hit_damage(enemy, multiplier, hits)
		if is_spread:
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if e != enemy and is_instance_valid(e) and global_position.distance_to(e.global_position) < 400.0:
					spawn_skill_visual(effect_type, e.global_position + Vector2(0, -20), facing_direction, 0.4)
					apply_multi_hit_damage(e, multiplier * 0.8, max(1, hits - 1))
	else:
		execute_melee_cone_damage(multiplier, hits, 100.0, effect_type)

func shoot_throwing_stars(multiplier: float, hits: int, effect_type: String = "lucky_seven"):
	var enemy = find_target_in_direction(550.0)
	if enemy:
		spawn_skill_visual(effect_type, enemy.global_position + Vector2(0, -20), facing_direction, 0.45)
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 90.0, effect_type)

func shoot_pirate_bullet(multiplier: float, hits: int, effect_type: String = "power_strike"):
	var enemy = find_target_in_direction(500.0)
	if enemy:
		spawn_skill_visual(effect_type, enemy.global_position + Vector2(0, -20), facing_direction, 0.45)
		apply_multi_hit_damage(enemy, multiplier, hits)
	else:
		execute_melee_cone_damage(multiplier, hits, 90.0, effect_type)

func find_target_in_direction(max_range: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist: float = max_range
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var diff_x = e.global_position.x - global_position.x
			if (facing_direction > 0 and diff_x > -20.0) or (facing_direction < 0 and diff_x < 20.0):
				var dist = global_position.distance_to(e.global_position)
				if dist < min_dist:
					min_dist = dist
					closest = e
	return closest

func apply_multi_hit_damage(target: Node2D, multiplier: float, hits: int):
	var is_magic = (Global.player_job_id in ["magician", "mage"])
	var mob_lvl = target.get("monster_level", 1) if "monster_level" in target else 1
	var mob_avoid = target.get("monster_avoid", 0) if "monster_avoid" in target else 0
	
	for i in range(hits):
		var timer = get_tree().create_timer(i * 0.07)
		timer.timeout.connect(func():
			if is_instance_valid(target) and not target.is_queued_for_deletion():
				var is_hit = Global.check_attack_hit_against_mob(mob_lvl, mob_avoid, is_magic)
				if not is_hit:
					if target.has_method("take_damage"):
						target.take_damage(0, false, i)
					return
					
				var dmg_info = Global.calculate_player_damage(multiplier)
				var is_crit = dmg_info.is_crit
				var dmg_val = dmg_info.damage
				
				# Life steal passive
				var life_steal_pct = Global.passive_buffs.get("life_steal", 0.0)
				if life_steal_pct > 0.0:
					Global.heal_player(max(1, int(float(dmg_val) * life_steal_pct)))
					
				if target.has_method("take_damage"):
					target.take_damage(dmg_val, is_crit, i)
		)

func attempt_tame_nearby_monster():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 140.0:
			if e.has_method("get_capture_data"):
				var pet_data = e.get_capture_data()
				var hp_pct = float(e.hp) / float(e.max_hp)
				var success_chance = 0.40 if hp_pct > 0.5 else 0.85
				if randf() < success_chance:
					Global.add_pet_to_inventory(pet_data)
					Global.broadcast_message("🎉 恭喜成功捕捉【%s】成為寵物夥伴！" % pet_data.name, Color(0.2, 1.0, 0.4))
					e.queue_free()
					return
				else:
					Global.broadcast_message("❌ 捕捉失敗！怪物掙脫了！", Color.SALMON)
					return
	Global.broadcast_message("周圍沒有可捕捉的怪物！", Color.GRAY)

func toggle_pet_summon():
	if not Global.active_pet_data.is_empty():
		Global.dismiss_active_pet()
	else:
		if not Global.pet_inventory.is_empty():
			Global.select_active_pet(0)
		else:
			Global.broadcast_message("寵物欄中沒有寵物！請按 E 捕捉怪物！", Color.GOLD)

func _on_hp_changed(_cur, _max_hp):
	pass

func _on_job_changed(_job_data):
	queue_redraw()

func _on_pet_summoned(pet_data):
	if is_instance_valid(Global.active_pet_node):
		Global.active_pet_node.queue_free()
	var pet_scene = load("res://scenes/Pet.tscn")
	if pet_scene:
		var pet = pet_scene.instantiate()
		pet.setup_pet(pet_data, self)
		get_parent().add_child.call_deferred(pet)
		Global.active_pet_node = pet

func _on_pet_unsummoned():
	if is_instance_valid(Global.active_pet_node):
		Global.active_pet_node.queue_free()
		Global.active_pet_node = null

func _draw():
	var body_color = Global.player_job_data.get("color", Color(0.9, 0.3, 0.2))
	if hurt_flash > 0.0:
		body_color = Color.WHITE
		
	# Head
	draw_circle(Vector2(0, -32), 11, Color(1.0, 0.82, 0.65))
	
	# Hair
	draw_arc(Vector2(0, -35), 11, -PI, 0, 16, Color(0.4, 0.25, 0.1), 4.0)
	
	# Eyes
	var eye_x = 4 if facing_direction > 0 else -4
	draw_circle(Vector2(eye_x, -33), 2.0, Color.BLACK)
	
	# Torso
	draw_rect(Rect2(-8, -22, 16, 16), body_color)
	
	# Legs / Walk anim
	var walk_cycle = sin(anim_frame) * 4.0 if (velocity.x != 0 and is_on_floor()) else 0.0
	draw_rect(Rect2(-6 + walk_cycle, -6, 4, 10), Color(0.15, 0.15, 0.25))
	draw_rect(Rect2(2 - walk_cycle, -6, 4, 10), Color(0.15, 0.15, 0.25))
	
	# Weapon / Attack swing visual
	if is_attacking:
		var swing_offset = Vector2(facing_direction * 22, -18)
		draw_line(Vector2(0, -18), swing_offset, Color.GOLD, 4.0)
		draw_circle(swing_offset, 6.0, Color(1.0, 0.9, 0.4, 0.8))
