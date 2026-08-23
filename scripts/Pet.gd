# Pet.gd
extends CharacterBody2D

@export var pet_name: String = "寵物"
@export var pet_type: String = "Snail"
@export var max_hp: int = 300
@export var hp: int = 300
@export var atk: int = 35
@export var speed: float = 220.0
@export var pet_color: Color = Color(0.2, 0.5, 0.9)
@export var pet_scale: float = 1.0

var player_ref: CharacterBody2D = null
var facing_direction: int = 1
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var anim_frame: float = 0.0
var is_boosted: bool = false

func _ready():
	add_to_group("allies")
	add_to_group("pets")
	Global.active_pet_node = self
	
	if Global.passive_buffs.get("tame_mastery", false):
		apply_tame_mastery_buff()
	
	queue_redraw()

func setup_pet(data: Dictionary, player: CharacterBody2D):
	player_ref = player
	pet_name = data.get("name", "寵物")
	pet_type = data.get("type", "Snail")
	max_hp = data.get("max_hp", 300)
	hp = max_hp
	atk = data.get("atk", 35)
	speed = data.get("speed", 220.0)
	pet_color = data.get("color", Color(0.2, 0.5, 0.9))
	pet_scale = data.get("scale", 1.0)
	
	global_position = player.global_position + Vector2(-40, 0)
	scale = Vector2(pet_scale, pet_scale)
	
	if Global.passive_buffs.get("tame_mastery", false):
		apply_tame_mastery_buff()
		
	queue_redraw()

func apply_tame_mastery_buff():
	if not is_boosted:
		is_boosted = true
		atk = int(atk * 2.0)
		max_hp = int(max_hp * 2.0)
		hp = max_hp
		speed *= 1.3

func _physics_process(delta):
	anim_frame += delta * 6.0
	attack_timer += delta
	
	if not is_on_floor() and pet_type != "Fly" and pet_type != "Ghost":
		velocity.y += 980.0 * delta
		
	if not is_instance_valid(player_ref):
		var p = get_tree().get_first_node_in_group("player")
		if is_instance_valid(p):
			player_ref = p
			
	if is_instance_valid(player_ref):
		# Follow Player or engage nearby enemy
		var target_enemy = find_nearest_enemy()
		var follow_target_x = player_ref.global_position.x - (50 * player_ref.facing_direction)
		
		# If too far from player, teleport / dash to player
		var dist_to_player = global_position.distance_to(player_ref.global_position)
		if dist_to_player > 500.0:
			global_position = player_ref.global_position + Vector2(-30 * player_ref.facing_direction, 0)
			velocity = Vector2.ZERO
		elif target_enemy and global_position.distance_to(target_enemy.global_position) < 300.0:
			# Move towards enemy and attack
			var dir_x = sign(target_enemy.global_position.x - global_position.x)
			velocity.x = dir_x * speed
			facing_direction = int(dir_x) if dir_x != 0 else facing_direction
			
			if global_position.distance_to(target_enemy.global_position) < 60.0 and attack_timer >= attack_cooldown:
				attack_timer = 0.0
				perform_pet_attack(target_enemy)
		else:
			# Follow player smoothly
			var dist_x = follow_target_x - global_position.x
			if abs(dist_x) > 30:
				var dir_x = sign(dist_x)
				velocity.x = dir_x * speed
				facing_direction = int(dir_x)
			else:
				velocity.x = move_toward(velocity.x, 0, speed * 3.0 * delta)
				
		# Jump if needed
		if is_on_floor() and (is_on_wall() or (player_ref.global_position.y < global_position.y - 40)):
			velocity.y = -380.0
			
	move_and_slide()
	queue_redraw()

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("wave_attackers")
	enemies.append_array(get_tree().get_nodes_in_group("enemies"))
	
	var closest: Node2D = null
	var min_d = 400.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_d:
				min_d = d
				closest = e
	return closest

func perform_pet_attack(enemy: Node2D):
	if is_instance_valid(enemy):
		var dmg = int(atk * randf_range(0.85, 1.15))
		var is_crit = randf() < 0.25
		if is_crit:
			dmg = int(dmg * 1.5)
		if enemy.has_method("take_damage_custom"):
			enemy.take_damage_custom(dmg, is_crit, 0)
		elif enemy.has_method("take_damage"):
			enemy.take_damage(dmg, is_crit)
		
		# If tame mastery is active, emit area shockwave
		if Global.passive_buffs.get("tame_mastery", false):
			var mobs = get_tree().get_nodes_in_group("enemies")
			for other in mobs:
				if is_instance_valid(other) and other != enemy and global_position.distance_to(other.global_position) < 150.0:
					if other.has_method("take_damage_custom"):
						other.take_damage_custom(int(dmg * 0.7), false, 1)
					elif other.has_method("take_damage"):
						other.take_damage(int(dmg * 0.7), false)

func heal_pet(amount: int):
	hp = clamp(hp + amount, 0, max_hp)

func _exit_tree():
	if Global.active_pet_node == self:
		Global.active_pet_node = null

func _draw():
	var bounce = sin(anim_frame) * 2.5
	var draw_col = pet_color
	
	# Summon / companion glowing aura
	draw_circle(Vector2(0, -12), 22.0, Color(0.2, 0.9, 0.4, 0.2 + 0.1 * sin(anim_frame)))
	draw_arc(Vector2(0, -12), 24.0, 0, TAU, 16, Color(0.2, 1.0, 0.5, 0.6), 2.0)
	
	# Draw pet body
	draw_circle(Vector2(0, -14 + bounce), 14.0, draw_col)
	draw_circle(Vector2(5 * facing_direction, -14 + bounce), 3.0, Color.BLACK)
	draw_circle(Vector2(6 * facing_direction, -15 + bounce), 1.0, Color.WHITE)
	
	# Crown / Pet accessory
	draw_polygon(
		PackedVector2Array([
			Vector2(-6, -26 + bounce),
			Vector2(-3, -32 + bounce),
			Vector2(0, -28 + bounce),
			Vector2(3, -32 + bounce),
			Vector2(6, -26 + bounce)
		]),
		PackedColorArray([Color.GOLD, Color.GOLD, Color.GOLD, Color.GOLD, Color.GOLD])
	)
