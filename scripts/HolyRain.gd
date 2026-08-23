# HolyRain.gd
extends Node2D

var lifetime: float = 1.6
var timer: float = 0.0
var damage_timer: float = 0.0
var damage_interval: float = 0.25
var radius: float = 160.0
var damage: int = 80
var beams: Array = []

func _ready():
	damage = int(Global.player_atk * 1.5)
	# Generate random holy beam positions
	for i in range(8):
		beams.append({
			"offset_x": randf_range(-radius, radius),
			"width": randf_range(12, 28),
			"alpha": randf_range(0.4, 0.9),
			"speed": randf_range(3.0, 7.0)
		})

func _process(delta):
	timer += delta
	damage_timer += delta
	
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		deal_holy_damage()
	
	queue_redraw()
	if timer >= lifetime:
		queue_free()

func _draw():
	var progress = timer / lifetime
	var main_alpha = 1.0 - progress
	
	# Draw divine ground circle
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.9, 0.3, main_alpha * 0.8), 3.0)
	draw_circle(Vector2.ZERO, radius * (0.8 + 0.2 * sin(timer * 10)), Color(1.0, 0.95, 0.6, main_alpha * 0.15))
	
	# Draw vertical light beams striking down
	for b in beams:
		var x = b.offset_x
		var w = b.width
		var a = b.alpha * main_alpha
		var top_y = -500
		var bot_y = 0
		draw_line(Vector2(x, top_y), Vector2(x, bot_y), Color(1.0, 1.0, 0.8, a), w)
		draw_circle(Vector2(x, bot_y), w * 1.5, Color(1.0, 0.9, 0.4, a))

func deal_holy_damage():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and global_position.distance_to(e.global_position) <= radius:
			if e.has_method("take_damage"):
				var is_crit = randf() < 0.25
				var dmg = int(damage * (1.6 if is_crit else 1.0))
				e.take_damage(dmg, is_crit)
