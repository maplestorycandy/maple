# MapManager.gd
extends Node2D

@export var current_map_id: String = "100000000"
@export var goddess_scene: PackedScene
@export var monster_scene: PackedScene

var active_wild_monsters: Array = []
var wild_spawn_timer: float = 0.0
var wild_spawn_interval: float = 3.5
var max_wild_mobs: int = 16

# Map Portals & NPCs
var current_portals: Array = []
var current_npcs: Array = []

@onready var platforms_container: StaticBody2D = $Platforms
@onready var background_rect: ColorRect = $BackgroundRect
@onready var ground_collision: CollisionShape2D = $Platforms/GroundCollision

func _ready():
	Global.map_change_requested.connect(load_map)
	if not MapDatabase.MAPS.has(Global.current_map_id):
		Global.current_map_id = "100000000"
	load_map(Global.current_map_id)

func _process(delta):
	wild_spawn_timer += delta
	if wild_spawn_timer >= wild_spawn_interval:
		wild_spawn_timer = 0.0
		clean_wild_monster_list()
		if active_wild_monsters.size() < max_wild_mobs:
			spawn_wild_monster()
			
	check_portal_interactions()

func clean_wild_monster_list():
	var valid_list = []
	for m in active_wild_monsters:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			valid_list.append(m)
	active_wild_monsters = valid_list

func load_map(map_id: String):
	if not MapDatabase.MAPS.has(map_id):
		map_id = "100000000"
		
	current_map_id = map_id
	var map_info = MapDatabase.MAPS[map_id]
	
	# Clear old wild monsters
	for m in active_wild_monsters:
		if is_instance_valid(m):
			m.queue_free()
	active_wild_monsters.clear()
	
	# Clean up portal & NPC visual indicators
	for p_node in get_tree().get_nodes_in_group("map_portals"):
		p_node.queue_free()
	for npc_node in get_tree().get_nodes_in_group("map_npcs"):
		npc_node.queue_free()
		
	# Update background atmosphere
	if background_rect:
		background_rect.color = map_info.bg_bottom_color
		
	# Setup Portals
	setup_map_portals(map_info)
	
	# Setup Town NPCs
	setup_map_npcs(map_info)
		
	# Spawn initial batch of wild monsters if field map
	if not map_info.is_town and not map_info.monsters.is_empty():
		for i in range(min(10, max_wild_mobs)):
			spawn_wild_monster()
		
	queue_redraw()

func setup_map_portals(map_info: Dictionary):
	var n_portals = map_info.get("normal_portals", [])
	var h_portals = map_info.get("hidden_portals", [])
	
	var portal_positions = [
		Vector2(-1400, 380),
		Vector2(1400, 380),
		Vector2(-800, 240),
		Vector2(650, 220),
		Vector2(0, 380)
	]
	
	var p_idx = 0
	for p in n_portals:
		if p_idx >= portal_positions.size():
			break
		create_portal_node(portal_positions[p_idx], p.get("title", "傳送點"), p.get("target", ""), false)
		p_idx += 1
		
	for p in h_portals:
		if p_idx >= portal_positions.size():
			break
		create_portal_node(portal_positions[p_idx] + Vector2(0, -50), p.get("title", "隱藏傳送點"), p.get("target", ""), true)
		p_idx += 1

func create_portal_node(pos: Vector2, title: String, target_map_id: String, is_hidden: bool):
	var p_node = Node2D.new()
	p_node.name = "Portal_" + target_map_id
	p_node.global_position = pos
	p_node.set_meta("target_map_id", target_map_id)
	p_node.set_meta("title", title)
	p_node.set_meta("is_hidden", is_hidden)
	p_node.add_to_group("map_portals")
	
	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-100, -60)
	label.custom_minimum_size = Vector2(200, 24)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.modulate = Color(0.4, 0.9, 1.0) if not is_hidden else Color(1.0, 0.8, 0.2)
	p_node.add_child(label)
	
	add_child(p_node)

func setup_map_npcs(map_info: Dictionary):
	var npcs = map_info.get("npcs", [])
	var npc_x_positions = [-1100, -600, -200, 200, 700, 1100]
	
	for i in range(min(npcs.size(), npc_x_positions.size())):
		var npc_name = npcs[i]
		var npc_node = Node2D.new()
		npc_node.global_position = Vector2(npc_x_positions[i], 380)
		npc_node.add_to_group("map_npcs")
		
		var lbl = Label.new()
		lbl.text = "【NPC】%s" % npc_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(-80, -45)
		lbl.custom_minimum_size = Vector2(160, 20)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.modulate = Color(1.0, 0.9, 0.4)
		npc_node.add_child(lbl)
		
		add_child(npc_node)

func check_portal_interactions():
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
		
	if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_UP):
		for p in get_tree().get_nodes_in_group("map_portals"):
			if player.global_position.distance_to(p.global_position) < 55.0:
				var target_map_id = p.get_meta("target_map_id")
				if target_map_id != "" and MapDatabase.MAPS.has(target_map_id):
					Global.change_map(target_map_id)
					player.global_position = Vector2(0, 350)
					break

func spawn_wild_monster():
	if NetworkManager.is_multiplayer_active and not NetworkManager.is_host:
		return
		
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	var mob_list = map_info.get("monsters", [])
	if mob_list.is_empty():
		return
		
	# Weighted random choice based on authentic spawn slot counts
	var total_slots = 0
	for m in mob_list:
		total_slots += m.get("slots", 1)
		
	var roll = randi() % max(1, total_slots)
	var chosen_id = mob_list[0].mob_id
	var running_sum = 0
	for m in mob_list:
		running_sum += m.get("slots", 1)
		if roll < running_sum:
			chosen_id = m.mob_id
			break
			
	var spawn_x = randf_range(-1300, 1300)
	var spawn_y = randf_range(200, 360)
	if randf() < 0.4:
		spawn_y = randf_range(20, 180)
		
	var mob = NetworkManager.spawn_network_monster(chosen_id, Vector2(spawn_x, spawn_y), Vector2.ZERO, false)
	if is_instance_valid(mob):
		active_wild_monsters.append(mob)

func _draw():
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	var ground_col = map_info.ground_color
	var plat_col = map_info.platform_color
	
	# 1. Main Ground Floor
	draw_rect(Rect2(-1800, 380, 3600, 420), ground_col)
	draw_rect(Rect2(-1800, 375, 3600, 8), ground_col.lightened(0.2))
	
	# 2. Elevated Floating Maple Platforms
	var platforms = [
		Rect2(-800, 240, 260, 22),
		Rect2(-350, 150, 300, 22),
		Rect2(150, 180, 280, 22),
		Rect2(650, 220, 250, 22),
		Rect2(-1200, 160, 240, 22),
		Rect2(1100, 140, 240, 22)
	]
	
	for p in platforms:
		draw_rect(p, plat_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 6)), plat_col.lightened(0.3))
		draw_line(Vector2(p.position.x + 20, p.position.y + p.size.y), Vector2(p.position.x + 20, 380), plat_col.darkened(0.3), 3.0)
		draw_line(Vector2(p.position.x + p.size.x - 20, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 20, 380), plat_col.darkened(0.3), 3.0)
		
	# 3. Portal visual effects (Portal Aura)
	for p in get_tree().get_nodes_in_group("map_portals"):
		var p_pos = p.global_position - global_position
		var is_hidden = p.get_meta("is_hidden", false)
		var aura_col = Color(0.2, 0.7, 1.0, 0.4) if not is_hidden else Color(1.0, 0.8, 0.2, 0.5)
		draw_circle(p_pos + Vector2(0, -20), 22.0, aura_col)
		draw_circle(p_pos + Vector2(0, -20), 14.0, Color(1.0, 1.0, 1.0, 0.6))
		
	# 4. NPC dummy standing visuals if town
	if map_info.is_town:
		for npc in get_tree().get_nodes_in_group("map_npcs"):
			var npc_pos = npc.global_position - global_position
			draw_circle(npc_pos + Vector2(0, -18), 12.0, Color(0.95, 0.8, 0.5))
			draw_rect(Rect2(Vector2(npc_pos.x - 8, npc_pos.y - 12), Vector2(16, 16)), Color(0.3, 0.5, 0.8), true)
