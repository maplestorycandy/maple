# Goddess.gd
extends Node2D

var anim_timer: float = 0.0
var aura_radius: float = 240.0
var heal_tick_timer: float = 0.0

func _ready():
	add_to_group("goddess")
	Global.goddess_hp = Global.goddess_max_hp

func _process(delta):
	anim_timer += delta
	heal_tick_timer += delta
	
	# Sanctuary passive healing aura
	if heal_tick_timer >= 1.5:
		heal_tick_timer = 0.0
		heal_nearby_allies()
		
	queue_redraw()

func heal_nearby_allies():
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= aura_radius:
		Global.heal_player(int(Global.player_max_hp * 0.05))
		
	if is_instance_valid(Global.active_pet_node) and global_position.distance_to(Global.active_pet_node.global_position) <= aura_radius:
		Global.active_pet_node.heal_pet(int(Global.active_pet_node.max_hp * 0.05))

func _draw():
	var float_y = sin(anim_timer * 2.0) * 8.0
	
	# 1. Divine Aura Circles
	var pulse = 0.8 + 0.2 * sin(anim_timer * 3.0)
	draw_circle(Vector2(0, -60 + float_y), aura_radius * 0.2, Color(0.2, 0.8, 1.0, 0.15 * pulse))
	draw_arc(Vector2(0, -60 + float_y), aura_radius, 0, TAU, 32, Color(0.3, 0.9, 1.0, 0.3 * pulse), 2.0)
	
	# 2. Goddess Pedestal / Altar
	draw_rect(Rect2(-40, -15, 80, 15), Color(0.3, 0.35, 0.45))
	draw_rect(Rect2(-30, -25, 60, 10), Color(0.4, 0.45, 0.55))
	
	# 3. Holy Wings
	var wing_col = Color(0.9, 0.95, 1.0, 0.85)
	draw_polygon(
		PackedVector2Array([
			Vector2(-10, -65 + float_y),
			Vector2(-45, -95 + float_y),
			Vector2(-55, -60 + float_y),
			Vector2(-35, -40 + float_y)
		]),
		PackedColorArray([wing_col, wing_col, wing_col, wing_col])
	)
	draw_polygon(
		PackedVector2Array([
			Vector2(10, -65 + float_y),
			Vector2(45, -95 + float_y),
			Vector2(55, -60 + float_y),
			Vector2(35, -40 + float_y)
		]),
		PackedColorArray([wing_col, wing_col, wing_col, wing_col])
	)
	
	# 4. Goddess Body & Robes
	draw_polygon(
		PackedVector2Array([
			Vector2(-12, -55 + float_y),
			Vector2(12, -55 + float_y),
			Vector2(20, -25),
			Vector2(-20, -25)
		]),
		PackedColorArray([Color.WHITE, Color.WHITE, Color(0.85, 0.92, 1.0), Color(0.85, 0.92, 1.0)])
	)
	
	# 5. Face & Halo
	draw_circle(Vector2(0, -70 + float_y), 12.0, Color(1.0, 0.92, 0.85))
	# Divine Golden Halo
	draw_arc(Vector2(0, -88 + float_y), 16.0, 0, TAU, 24, Color(1.0, 0.85, 0.2, 0.9), 3.0)
	
	# 6. Goddess HP Bar
	var hp_ratio = clamp(float(Global.goddess_hp) / float(Global.goddess_max_hp), 0.0, 1.0)
	var bar_w = 90.0
	var bar_h = 8.0
	draw_rect(Rect2(-bar_w/2, -115 + float_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(Rect2(-bar_w/2, -115 + float_y, bar_w * hp_ratio, bar_h), Color(0.1, 0.9, 0.8, 0.9))
