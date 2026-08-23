# SwordWave.gd
extends Area2D

@export var speed: float = 650.0
@export var damage: int = 150
var target_direction: Vector2 = Vector2.RIGHT
var lifetime: float = 2.0
var timer: float = 0.0
var hit_enemies: Array = []

func _ready():
	add_to_group("player_attacks")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = target_direction.angle()
	damage = int(Global.player_atk * 2.2)

func _process(delta):
	position += target_direction * speed * delta
	timer += delta
	queue_redraw()
	if timer >= lifetime:
		queue_free()

func _draw():
	# Draw animated crescent energy wave
	var wave_color = Color(0.3, 0.8, 1.0, 0.9)
	var glow_color = Color(1.0, 1.0, 1.0, 0.8)
	
	draw_arc(Vector2.ZERO, 32.0, -PI/2.5, PI/2.5, 16, wave_color, 6.0)
	draw_arc(Vector2(4, 0), 28.0, -PI/3.0, PI/3.0, 12, glow_color, 3.0)

func _on_body_entered(body: Node2D):
	handle_hit(body)

func _on_area_entered(area: Area2D):
	handle_hit(area.get_parent())

func handle_hit(target: Node2D):
	if target and target.is_in_group("enemies") and not target in hit_enemies:
		hit_enemies.append(target)
		if target.has_method("take_damage"):
			var is_crit = randf() < (0.2 + Global.passive_buffs.get("crit_rate_boost", 0.0))
			var final_dmg = int(damage * (1.8 if is_crit else 1.0))
			target.take_damage(final_dmg, is_crit)
			
			# Trigger Chain Thunder if active
			if Global.passive_buffs.get("chain_thunder", false) and randf() < 0.35:
				trigger_chain_lightning(target)

func trigger_chain_lightning(origin_enemy: Node2D):
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	for e in enemies:
		if is_instance_valid(e) and e != origin_enemy and origin_enemy.global_position.distance_to(e.global_position) < 300:
			if e.has_method("take_damage"):
				e.take_damage(int(damage * 0.8), false)
				hit_count += 1
				if hit_count >= 4:
					break
