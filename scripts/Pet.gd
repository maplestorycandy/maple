# Pet.gd
extends CharacterBody2D

@export var pet_name: String = "寵物"
@export var pet_type: String = "Snail"
@export var max_hp: int = 300
@export var hp: int = 300
@export var atk: int = 35
@export var speed: float = 220.0
@export var pet_color: Color = Color(0.2, 0.5, 0.9)
@export var pet_scale: float = 0.85
@export var sprite_path: String = ""

var player_ref: CharacterBody2D = null
var facing_direction: int = 1
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var anim_frame: float = 0.0
var is_boosted: bool = false
var has_sprite_texture: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel

func _ready():
	add_to_group("allies")
	add_to_group("pets")
	Global.active_pet_node = self
	
	if Global.passive_buffs.get("tame_mastery", false):
		apply_tame_mastery_buff()
	
	setup_visuals()

func setup_pet(data: Dictionary, player: CharacterBody2D):
	player_ref = player
	pet_name = data.get("name", "寵物")
	pet_type = data.get("type", "Normal")
	max_hp = data.get("max_hp", 300)
	hp = max_hp
	atk = data.get("atk", 35)
	speed = data.get("speed", 220.0)
	pet_color = data.get("color", Color(0.2, 0.5, 0.9))
	pet_scale = data.get("scale", 0.85)
	sprite_path = data.get("sprite", "")
	
	global_position = player.global_position + Vector2(-40, 0)
	
	if Global.passive_buffs.get("tame_mastery", false):
		apply_tame_mastery_buff()
		
	setup_visuals()

func setup_visuals():
	if not is_node_ready():
		return
		
	if name_label:
		name_label.text = "★ %s" % pet_name
		
	has_sprite_texture = false
	if sprite and sprite_path != "":
		if ResourceLoader.exists(sprite_path):
			var tex = load(sprite_path)
			if tex:
				sprite.texture = tex
				has_sprite_texture = true
				sprite.scale = Vector2(pet_scale, pet_scale)
				sprite.visible = true
				
	if not has_sprite_texture and sprite:
		sprite.visible = false
		
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
	
	if sprite and has_sprite_texture:
		sprite.position.y = -20 + sin(anim_frame * 3.0) * 2.0
		sprite.flip_h = (facing_direction < 0)
		
	if not is_on_floor():
		velocity.y += 980.0 * delta
		
	if not is_instance_valid(player_ref):
		player_ref = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player_ref):
			move_and_slide()
			return
			
	var target_pos = player_ref.global_position + Vector2(-40 * player_ref.facing_direction, 0)
	var dist_to_player = global_position.distance_to(player_ref.global_position)
	
	# Teleport back if too far
	if dist_to_player > 800.0:
		global_position = player_ref.global_position + Vector2(-30, -10)
		velocity = Vector2.ZERO
		return
		
	# Find closest enemy to assist attack
	var nearest_enemy = find_nearest_enemy(320.0)
	
	if is_instance_valid(nearest_enemy):
		var dir_to_enemy = sign(nearest_enemy.global_position.x - global_position.x)
		if dir_to_enemy != 0:
			facing_direction = int(dir_to_enemy)
			
		var dist_to_enemy = global_position.distance_to(nearest_enemy.global_position)
		if dist_to_enemy > 45.0:
			velocity.x = dir_to_enemy * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * 2.0)
			if attack_timer >= attack_cooldown:
				attack_timer = 0.0
				perform_pet_attack(nearest_enemy)
	else:
		# Follow Player
		var dir_to_player = sign(target_pos.x - global_position.x)
		if dir_to_player != 0:
			facing_direction = int(dir_to_player)
			
		if dist_to_player > 60.0:
			velocity.x = dir_to_player * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed * 3.0)
			
	if is_on_floor() and (is_on_wall() or (is_instance_valid(nearest_enemy) and nearest_enemy.global_position.y < global_position.y - 40)):
		velocity.y = -360.0
		
	move_and_slide()

func find_nearest_enemy(max_dist: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist = max_dist
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = e
	return closest

func perform_pet_attack(target: Node2D):
	if is_instance_valid(target) and target.has_method("take_damage"):
		var is_crit = randf() < 0.2
		var dmg = atk
		if is_crit:
			dmg = int(dmg * 1.5)
		target.take_damage(dmg, is_crit)

func take_damage(amount: int):
	hp -= amount
	queue_redraw()
	if hp <= 0:
		Global.broadcast_message("【寵物受傷】%s 體力耗盡已返回背包休息！" % pet_name, Color.ORANGE)
		Global.dismiss_active_pet()

func heal_pet(amount: int):
	hp = min(max_hp, hp + amount)
	queue_redraw()

func heal(amount: int):
	heal_pet(amount)

func _draw():
	if not has_sprite_texture:
		var bounce = sin(anim_frame) * 2.0
		draw_circle(Vector2(0, -12 + bounce), 12 * pet_scale, pet_color)
		draw_circle(Vector2(4 * facing_direction, -14 + bounce), 2.5, Color.BLACK)
