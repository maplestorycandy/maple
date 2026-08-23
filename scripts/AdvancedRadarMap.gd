# AdvancedRadarMap.gd
extends Control

@export var radar_size: Vector2 = Vector2(240, 150)
@export var map_world_size: Rect2 = Rect2(-1800, -800, 3600, 1600)

var pulse_timer: float = 0.0

func _ready():
	custom_minimum_size = radar_size

func _process(delta):
	pulse_timer += delta * 4.0
	queue_redraw()

func _draw():
	# 1. Classic Semi-transparent Dark Grid Background
	draw_rect(Rect2(Vector2.ZERO, radar_size), Color(0.04, 0.07, 0.12, 0.85))
	draw_rect(Rect2(Vector2.ZERO, radar_size), Color(0.2, 0.6, 1.0, 0.9), false, 2.0)
	
	# Grid Reference Lines
	draw_line(Vector2(radar_size.x * 0.5, 0), Vector2(radar_size.x * 0.5, radar_size.y), Color(1, 1, 1, 0.12), 1.0)
	draw_line(Vector2(0, radar_size.y * 0.5), Vector2(radar_size.x, radar_size.y * 0.5), Color(1, 1, 1, 0.12), 1.0)
	
	# 2. Outer Gate Spawn Point (Orange Gate Marker)
	var gate = get_tree().get_first_node_in_group("outer_gate")
	if is_instance_valid(gate):
		var gate_pos = world_to_radar(gate.global_position)
		draw_rect(Rect2(gate_pos - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.5, 0.0, 0.9))
		draw_line(gate_pos + Vector2(-6, -6), gate_pos + Vector2(6, 6), Color.ORANGE, 1.5)
	
	# 3. Central Goddess (Cyan Square + Shield Arc)
	var goddess = get_tree().get_first_node_in_group("goddess")
	if is_instance_valid(goddess):
		var g_pos = world_to_radar(goddess.global_position)
		draw_rect(Rect2(g_pos - Vector2(4, 4), Vector2(8, 8)), Color(0.0, 1.0, 1.0, 0.95))
		draw_arc(g_pos, 8.0, 0, TAU, 16, Color(0.0, 0.8, 1.0, 0.5), 1.5)

	# 4. Wild Monsters (Yellow Dots)
	for mob in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(mob) and not mob.is_in_group("wave_attackers"):
			var pos = world_to_radar(mob.global_position)
			draw_circle(pos, 2.5, Color(1.0, 0.85, 0.2, 0.85))

	# 5. 50-Wave Attackers (Red Dots)
	for attacker in get_tree().get_nodes_in_group("wave_attackers"):
		if is_instance_valid(attacker) and not attacker.is_in_group("bosses"):
			var pos = world_to_radar(attacker.global_position)
			draw_circle(pos, 3.0, Color(1.0, 0.25, 0.2, 0.95))

	# 6. Boss Monsters (Purple Circle + Pulsing Aura)
	var pulse_radius = 6.0 + sin(pulse_timer) * 2.5
	for boss in get_tree().get_nodes_in_group("bosses"):
		if is_instance_valid(boss):
			var pos = world_to_radar(boss.global_position)
			draw_circle(pos, 5.5, Color(0.85, 0.1, 1.0, 1.0))
			draw_arc(pos, pulse_radius, 0, TAU, 16, Color(1.0, 0.3, 0.3, 0.85), 2.0)

	# 7. Pet Companion (Cyan Dot)
	if is_instance_valid(Global.active_pet_node):
		var pet_pos = world_to_radar(Global.active_pet_node.global_position)
		draw_circle(pet_pos, 3.0, Color(0.2, 1.0, 0.8, 1.0))

	# 8. Player (Green Blip + Direction Indicator)
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		var p_pos = world_to_radar(player.global_position)
		draw_circle(p_pos, 4.0, Color(0.1, 1.0, 0.3, 1.0))
		var facing_vec = Vector2(player.facing_direction * 7, 0)
		draw_line(p_pos, p_pos + facing_vec, Color(0.2, 1.0, 0.4), 2.0)

func world_to_radar(w_pos: Vector2) -> Vector2:
	var nx = (w_pos.x - map_world_size.position.x) / map_world_size.size.x
	var ny = (w_pos.y - map_world_size.position.y) / map_world_size.size.y
	return Vector2(
		clamp(nx * radar_size.x, 3, radar_size.x - 3),
		clamp(ny * radar_size.y, 3, radar_size.y - 3)
	)
