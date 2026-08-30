# MapManager.gd
# 100% 完美還原各大分區正版地形跳台座標、多層一向碰撞、上下層生怪與場景特色
extends Node2D

@export var current_map_id: String = "100000000"
@export var goddess_scene: PackedScene
@export var monster_scene: PackedScene

var active_wild_monsters: Array = []
var wild_spawn_timer: float = 0.0
var wild_spawn_interval: float = 2.8
var max_wild_mobs: int = 18

# Dynamic Platforms Container
var dynamic_platforms_node: Node2D
var active_platform_rects: Array[Rect2] = []
var current_theme: String = "henesys"

@onready var background_rect: ColorRect = $BackgroundRect

func _ready():
	dynamic_platforms_node = Node2D.new()
	dynamic_platforms_node.name = "DynamicPhysicalPlatforms"
	add_child(dynamic_platforms_node)
	
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
	current_theme = map_info.get("terrain_theme", "henesys")
	
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
		
	# Rebuild physical collision platforms for this specific map theme
	rebuild_physical_platforms(map_info)
		
	# Update background sky gradient atmosphere
	if background_rect:
		background_rect.color = map_info.get("bg_bottom_color", Color(0.4, 0.7, 0.95))
		
	# Setup Portals
	setup_map_portals(map_info)
	
	# Setup Town NPCs
	setup_map_npcs(map_info)
		
	# Initial batch of wild monsters across ground and platforms
	for i in range(min(12, max_wild_mobs)):
		spawn_wild_monster()
		
	queue_redraw()

# =========================================================================
# REBUILD PHYSICAL COLLISION PLATFORMS (ONE-WAY COLLISION)
# =========================================================================
func rebuild_physical_platforms(map_info: Dictionary):
	active_platform_rects.clear()
	if not is_instance_valid(dynamic_platforms_node):
		return
		
	for child in dynamic_platforms_node.get_children():
		child.queue_free()
		
	var theme = map_info.get("terrain_theme", "henesys")
	
	# Base Ground Collider
	match theme:
		"perion":
			# Canyon ground with center ravine (media_1788065677610.jpg)
			create_static_collider(Rect2(Vector2(-1800, 340), Vector2(1000, 460)), false) # Left rock
			create_static_collider(Rect2(Vector2(-800, 400), Vector2(1600, 400)), false)  # Ravine floor
			create_static_collider(Rect2(Vector2(800, 340), Vector2(1000, 460)), false)  # Right rock
			
			# Multi-tier Canyon Sandstone Cliffs
			var perion_cliffs = [
				Rect2(Vector2(-1400, 200), Vector2(2800, 26)), # Tier 1
				Rect2(Vector2(-1200, 50), Vector2(2400, 26)),  # Tier 2
				Rect2(Vector2(-700, -90), Vector2(1400, 26))   # Tier 3 Summit
			]
			for c in perion_cliffs:
				create_static_collider(c, true)
				active_platform_rects.append(c)
				
		"ellinia":
			# Giant hollow tree vertical levels (media_1788065686413.jpg)
			create_static_collider(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), false)
			var ellinia_plats = [
				# Left Trunk Ledges
				Rect2(Vector2(-1150, 280), Vector2(300, 22)),
				Rect2(Vector2(-1150, 140), Vector2(300, 22)),
				Rect2(Vector2(-1150, 0), Vector2(280, 22)),
				Rect2(Vector2(-1150, -130), Vector2(240, 22)),
				# Center Trunk Ledges & Vine Bridges
				Rect2(Vector2(-250, 270), Vector2(500, 22)),
				Rect2(Vector2(-250, 130), Vector2(500, 22)),
				Rect2(Vector2(-200, -10), Vector2(400, 22)),
				# Right Trunk Ledges
				Rect2(Vector2(650, 280), Vector2(320, 22)),
				Rect2(Vector2(650, 140), Vector2(320, 22)),
				Rect2(Vector2(650, 0), Vector2(280, 22))
			]
			for p in ellinia_plats:
				create_static_collider(p, true)
				active_platform_rects.append(p)
				
		"florina", "lith_harbor", "nautilus":
			# Palm tree ledges & Ship Wooden Piers (media_1788065688479.jpg & Victoria Port)
			create_static_collider(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), false)
			var beach_plats = [
				# Tier 1 (Low)
				Rect2(Vector2(-1350, 280), Vector2(320, 22)),
				Rect2(Vector2(-750, 280), Vector2(340, 22)),
				Rect2(Vector2(-150, 280), Vector2(360, 22)),
				Rect2(Vector2(450, 280), Vector2(340, 22)),
				Rect2(Vector2(1050, 280), Vector2(320, 22)),
				# Tier 2 (Mid)
				Rect2(Vector2(-1100, 180), Vector2(360, 22)),
				Rect2(Vector2(-450, 180), Vector2(380, 22)),
				Rect2(Vector2(200, 180), Vector2(360, 22)),
				Rect2(Vector2(850, 180), Vector2(360, 22)),
				# Tier 3 (High)
				Rect2(Vector2(-800, 80), Vector2(300, 22)),
				Rect2(Vector2(-50, 80), Vector2(260, 22)), # Umbrella platform
				Rect2(Vector2(600, 80), Vector2(300, 22))
			]
			for bp in beach_plats:
				create_static_collider(bp, true)
				active_platform_rects.append(bp)
				
		"kerning", "subway":
			# Scaffolding Girders & Subway Rails
			create_static_collider(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), false)
			var scaffolds = [
				Rect2(Vector2(-1300, 260), Vector2(380, 20)),
				Rect2(Vector2(-750, 160), Vector2(360, 20)),
				Rect2(Vector2(-200, 240), Vector2(420, 20)),
				Rect2(Vector2(350, 150), Vector2(380, 20)),
				Rect2(Vector2(900, 250), Vector2(400, 20)),
				Rect2(Vector2(-300, 50), Vector2(320, 20))
			]
			for s in scaffolds:
				create_static_collider(s, true)
				active_platform_rects.append(s)
				
		"sleepywood":
			# Cavern Stone Platforms & Runic Altars
			create_static_collider(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), false)
			var caves = [
				Rect2(Vector2(-1250, 240), Vector2(380, 24)),
				Rect2(Vector2(-700, 140), Vector2(360, 24)),
				Rect2(Vector2(-150, 220), Vector2(420, 24)),
				Rect2(Vector2(400, 130), Vector2(380, 24)),
				Rect2(Vector2(950, 230), Vector2(380, 24))
			]
			for cv in caves:
				create_static_collider(cv, true)
				active_platform_rects.append(cv)
				
		_:
			# Henesys Stepped Hills & Floating Islands (media_1788065678411.jpg)
			create_static_collider(Rect2(Vector2(-1800, 340), Vector2(1300, 460)), false) # Left cliff
			create_static_collider(Rect2(Vector2(-500, 400), Vector2(900, 400)), false)   # Center trench
			create_static_collider(Rect2(Vector2(400, 340), Vector2(550, 460)), false)   # Right step 1
			create_static_collider(Rect2(Vector2(950, 280), Vector2(300, 520)), false)   # Right step 2
			create_static_collider(Rect2(Vector2(1250, 210), Vector2(550, 590)), false)  # Right step 3 top
			
			var henesys_plats = [
				# Floating Central Island (media_1788065678411.jpg)
				Rect2(Vector2(-120, 240), Vector2(240, 24)),
				# Mid & High Floating Grass Islands
				Rect2(Vector2(-1300, 220), Vector2(340, 22)),
				Rect2(Vector2(-800, 130), Vector2(320, 22)),
				Rect2(Vector2(350, 140), Vector2(340, 22)),
				Rect2(Vector2(850, 120), Vector2(300, 22)),
				Rect2(Vector2(-250, 40), Vector2(260, 22))
			]
			for hp in henesys_plats:
				create_static_collider(hp, true)
				active_platform_rects.append(hp)

func create_static_collider(rect: Rect2, is_one_way: bool):
	var body = StaticBody2D.new()
	body.position = rect.position + rect.size / 2.0
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	if is_one_way:
		col.one_way_collision = true
		col.one_way_collision_margin = 12.0
		body.collision_layer = 2 # One-way platform layer
		body.add_to_group("one_way_platforms")
	else:
		body.collision_layer = 1 # Solid ground layer
	
	body.add_child(col)
	dynamic_platforms_node.add_child(body)

func setup_map_portals(map_info: Dictionary):
	var n_portals = map_info.get("normal_portals", [])
	var h_portals = map_info.get("hidden_portals", [])
	
	var portal_positions = [
		Vector2(-1450, 340),
		Vector2(1450, 210),
		Vector2(-800, 130),
		Vector2(650, 180),
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
		create_portal_node(portal_positions[p_idx] + Vector2(0, -40), p.get("title", "隱藏傳送點"), p.get("target", ""), true)
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
		npc_node.global_position = Vector2(npc_x_positions[i], 340)
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
			if player.global_position.distance_to(p.global_position) < 60.0:
				var target_map_id = p.get_meta("target_map_id")
				if target_map_id != "" and MapDatabase.MAPS.has(target_map_id):
					Global.change_map(target_map_id)
					player.global_position = Vector2(0, 300)
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
		
	var chosen_mob = mob_list[randi() % mob_list.size()]
	var chosen_id = 0
	if chosen_mob.has("mob_id"):
		chosen_id = int(chosen_mob.mob_id)
	elif chosen_mob.has("id"):
		chosen_id = int(chosen_mob.id)
	else:
		var found_data = MonsterDatabaseFull.get_monster_by_name(chosen_mob.get("name", ""))
		chosen_id = found_data.get("id", 100100)
		
	var is_boss_mob = chosen_mob.get("is_boss", false) or chosen_mob.get("level", 1) >= 100
		
	var spawn_x = randf_range(-1350, 1350)
	var spawn_y = 330.0
	
	if not active_platform_rects.is_empty() and randf() < 0.6:
		var chosen_plat = active_platform_rects[randi() % active_platform_rects.size()]
		spawn_x = randf_range(chosen_plat.position.x + 20, chosen_plat.position.x + chosen_plat.size.x - 20)
		spawn_y = chosen_plat.position.y - 5
		
	var mob = NetworkManager.spawn_network_monster(chosen_id, Vector2(spawn_x, spawn_y), Vector2.ZERO, is_boss_mob)
	if is_instance_valid(mob):
		active_wild_monsters.append(mob)

# =========================================================================
# AUTHENTIC TERRAIN RENDERING (100% FAITHFUL TO OFFICIAL MAPLESTORY SCREENSHOTS)
# =========================================================================
func _draw():
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	
	match current_theme:
		"perion":
			draw_perion_canyon(map_info)
		"ellinia":
			draw_ellinia_tree(map_info)
		"florina", "lith_harbor", "nautilus":
			draw_florina_beach(map_info)
		"kerning", "subway":
			draw_kerning_subway(map_info)
		"sleepywood":
			draw_sleepywood_cavern(map_info)
		_:
			draw_henesys_field(map_info)

# 1. 勇士之村與石巨人寺院 (Perion / Golem Temple - media_1788066772563.png & media_1788065677610.jpg)
func draw_perion_canyon(_map_info: Dictionary):
	var stone_base = Color(0.72, 0.72, 0.70)
	var stone_dark = Color(0.48, 0.48, 0.46)
	var stone_moss = Color(0.35, 0.68, 0.25)
	
	# Canyon Ground & Temple Foundations
	draw_rect(Rect2(Vector2(-1800, 340), Vector2(1000, 460)), stone_dark)
	draw_rect(Rect2(Vector2(-1800, 335), Vector2(1000, 8)), stone_base)
	draw_rect(Rect2(Vector2(-800, 400), Vector2(1600, 400)), stone_dark)
	draw_rect(Rect2(Vector2(-800, 395), Vector2(1600, 8)), stone_base)
	draw_rect(Rect2(Vector2(800, 340), Vector2(1000, 460)), stone_dark)
	draw_rect(Rect2(Vector2(800, 335), Vector2(1000, 8)), stone_base)
	
	# Temple Carved Stone Block Platforms
	for p in active_platform_rects:
		draw_rect(p, stone_base)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 6)), stone_moss)
		# Carved stone brick grid lines
		for bx in range(int(p.position.x), int(p.position.x + p.size.x), 45):
			draw_line(Vector2(bx, p.position.y), Vector2(bx, p.position.y + p.size.y), stone_dark, 2.0)
		# Support Pillars & Ivy Vines
		for rx in range(int(p.position.x + 60), int(p.position.x + p.size.x - 30), 180):
			draw_rect(Rect2(Vector2(rx, p.position.y + p.size.y), Vector2(28, 120)), stone_dark)
			# Vines on pillars
			draw_line(Vector2(rx + 6, p.position.y + p.size.y), Vector2(rx + 6, p.position.y + p.size.y + 70), stone_moss, 3.0)

# 2. 弓箭手村海岸草叢與肥肥公園 (Henesys Coast & Pig Park - media_1788066779892.png & media_1788066796111.png)
func draw_henesys_field(_map_info: Dictionary):
	var soil_col = Color(0.38, 0.28, 0.16)
	var soil_dark = Color(0.24, 0.17, 0.10)
	var grass_col = Color(0.36, 0.76, 0.20)
	var grass_top = Color(0.55, 0.90, 0.30)
	var fence_col = Color(0.96, 0.94, 0.88)
	
	# Ground & Stepped Cliffs
	draw_rect(Rect2(Vector2(-1800, 340), Vector2(1300, 460)), soil_col)
	draw_rect(Rect2(Vector2(-1800, 335), Vector2(1300, 8)), grass_col)
	draw_rect(Rect2(Vector2(-1800, 333), Vector2(1300, 3)), grass_top)
	
	draw_rect(Rect2(Vector2(-500, 400), Vector2(900, 400)), soil_col)
	draw_rect(Rect2(Vector2(-500, 395), Vector2(900, 8)), grass_col)
	
	var steps = [
		Rect2(Vector2(400, 340), Vector2(550, 460)),
		Rect2(Vector2(950, 280), Vector2(300, 520)),
		Rect2(Vector2(1250, 210), Vector2(550, 590))
	]
	for s in steps:
		draw_rect(s, soil_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 8)), grass_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 3)), grass_top)
		
	# Floating Earthy Soil Platforms with White Picket Fences (media_1788066779892.png)
	for p in active_platform_rects:
		# Soil Body
		draw_rect(p, soil_col)
		# Hanging Roots / soil texture
		for sx in range(int(p.position.x + 10), int(p.position.x + p.size.x - 10), 30):
			draw_line(Vector2(sx, p.position.y + p.size.y), Vector2(sx, p.position.y + p.size.y + 12), soil_dark, 2.0)
		# Grass Carpet
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 7)), grass_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 3)), grass_top)
		
		# White Wooden Picket Fence along platform
		if p.size.x >= 200:
			for fx in range(int(p.position.x + 15), int(p.position.x + min(120, p.size.x - 20)), 16):
				draw_rect(Rect2(Vector2(fx, p.position.y - 18), Vector2(5, 18)), fence_col)
				draw_line(Vector2(fx, p.position.y - 18), Vector2(fx + 2.5, p.position.y - 22), fence_col, 2.0)
			draw_line(Vector2(p.position.x + 15, p.position.y - 10), Vector2(p.position.x + min(120, p.size.x - 20) + 5, p.position.y - 10), fence_col, 2.5)

	# Autumn Orange & Emerald Leaf Trees (media_1788066779892.png)
	for tx in [-1150, -450, 350, 1100]:
		# Trunk
		draw_rect(Rect2(Vector2(tx - 6, 210), Vector2(12, 130)), Color(0.75, 0.72, 0.68))
		# Autumn Foliage Canopy
		draw_circle(Vector2(tx - 18, 200), 28.0, Color(0.85, 0.45, 0.15))
		draw_circle(Vector2(tx + 18, 195), 26.0, Color(0.88, 0.62, 0.20))
		draw_circle(Vector2(tx, 175), 32.0, Color(0.35, 0.75, 0.25))
		
	# Climbing Wooden Rope Ladders (media_1788066779892.png)
	for lx in [-220, 680]:
		draw_line(Vector2(lx, 100), Vector2(lx, 340), Color(0.55, 0.38, 0.22), 3.0)
		draw_line(Vector2(lx + 22, 100), Vector2(lx + 22, 340), Color(0.55, 0.38, 0.22), 3.0)
		for ry in range(115, 335, 20):
			draw_line(Vector2(lx, ry), Vector2(lx + 22, ry), Color(0.70, 0.52, 0.32), 3.5)

# 3. 巫婆森林與魔法森林巨木 (Witch Forest & Ellinia Tree Canopy - media_1788066785173.png)
func draw_ellinia_tree(_map_info: Dictionary):
	var bark_col = Color(0.28, 0.18, 0.10)
	var wood_ring_outer = Color(0.52, 0.34, 0.18)
	var wood_ring_inner = Color(0.75, 0.54, 0.32)
	var moss_green = Color(0.22, 0.68, 0.26)
	var vine_glow = Color(0.30, 0.85, 0.45)
	
	# Massive Ancient Tree Trunk Columns in Background
	for gx in [-1050, -150, 750]:
		draw_rect(Rect2(Vector2(gx - 60, -350), Vector2(120, 750)), bark_col)
		# Circular wood cuts on trunk sides (media_1788066785173.png)
		for dy in [280, 160, 40, -80]:
			draw_circle(Vector2(gx + 40, dy), 14.0, wood_ring_outer)
			draw_circle(Vector2(gx + 40, dy), 8.0, wood_ring_inner)
			
	# Sliced Round Log Platforms (media_1788066785173.png)
	for p in active_platform_rects:
		# Draw horizontal row of sliced round logs
		var log_radius = 12.0
		var num_logs = int(p.size.x / (log_radius * 2.0))
		for i in range(num_logs):
			var cx = p.position.x + log_radius + i * (log_radius * 2.0)
			var cy = p.position.y + log_radius
			draw_circle(Vector2(cx, cy), log_radius, wood_ring_outer)
			draw_circle(Vector2(cx, cy), log_radius - 3.0, wood_ring_inner)
			draw_circle(Vector2(cx, cy), 2.5, bark_col)
		# Green Moss Top Carpet
		draw_rect(Rect2(Vector2(p.position.x, p.position.y - 2), Vector2(p.size.x, 5)), moss_green)
		# Hanging Vines
		draw_line(Vector2(p.position.x + 20, p.position.y + p.size.y), Vector2(p.position.x + 20, p.position.y + 65), vine_glow, 3.0)
		draw_line(Vector2(p.position.x + p.size.x - 20, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 20, p.position.y + 55), vine_glow, 3.0)

	# Ground Log Floor
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), bark_col)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), moss_green)

# 4. 黃金海岸與維多利亞港 (Florina Beach & Lith Harbor - media_1788066772563.png)
func draw_florina_beach(_map_info: Dictionary):
	var sand = Color(0.92, 0.86, 0.58)
	var wood_pier = Color(0.58, 0.40, 0.24)
	var palm_green = Color(0.20, 0.75, 0.30)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), sand)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), sand.lightened(0.12))
	
	# Stranded Viking Exploration Ship
	var ship_hull = PackedVector2Array([
		Vector2(-1400, 380),
		Vector2(-1540, 310),
		Vector2(-1220, 310),
		Vector2(-1180, 380)
	])
	draw_colored_polygon(ship_hull, Color(0.45, 0.25, 0.12))
	draw_line(Vector2(-1360, 310), Vector2(-1360, 170), Color(0.3, 0.18, 0.08), 7.0)
	# Orange Striped Sails
	draw_rect(Rect2(Vector2(-1410, 180), Vector2(100, 60)), Color(0.95, 0.45, 0.15))
	draw_rect(Rect2(Vector2(-1390, 180), Vector2(25, 60)), Color(0.95, 0.95, 0.95))
	
	# Palm Tree Platforms & Tropical Umbrellas
	for p in active_platform_rects:
		draw_rect(p, wood_pier)
		draw_line(Vector2(p.position.x + p.size.x / 2.0, p.position.y + p.size.y), Vector2(p.position.x + p.size.x / 2.0, 380), Color(0.48, 0.32, 0.18), 8.0)
		draw_circle(Vector2(p.position.x + p.size.x / 2.0, p.position.y - 12), 34.0, palm_green)
		if p.position.y < 100:
			draw_circle(Vector2(p.position.x + p.size.x / 2.0, p.position.y - 20), 20.0, Color(0.2, 0.65, 0.95))

# 5. 墮落城市與地鐵 (Kerning City & Subway)
func draw_kerning_subway(_map_info: Dictionary):
	var asphalt = Color(0.20, 0.20, 0.24)
	var steel = Color(0.38, 0.40, 0.46)
	var hazard = Color(0.95, 0.80, 0.10)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), asphalt)
	draw_line(Vector2(-1800, 376), Vector2(1800, 376), steel.lightened(0.3), 3.0)
	
	for p in active_platform_rects:
		draw_rect(p, steel)
		draw_rect(Rect2(Vector2(p.position.x + 20, p.position.y + 3), Vector2(60, 12)), hazard)
		draw_line(Vector2(p.position.x + 15, p.position.y + p.size.y), Vector2(p.position.x + 15, 380), steel, 4.0)
		draw_line(Vector2(p.position.x + p.size.x - 15, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 15, 380), steel, 4.0)

# 6. 奇幻村洞穴 (Sleepywood Cavern)
func draw_sleepywood_cavern(_map_info: Dictionary):
	var cave_rock = Color(0.18, 0.14, 0.22)
	var stalactite_col = Color(0.32, 0.25, 0.38)
	var crystal_glow = Color(0.85, 0.35, 1.0, 0.7)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), cave_rock)
	
	for sx in [-1300, -850, -400, 150, 700, 1200]:
		var poly = PackedVector2Array([
			Vector2(sx - 25, -200),
			Vector2(sx + 25, -200),
			Vector2(sx, 40)
		])
		draw_colored_polygon(poly, stalactite_col)
		
	for p in active_platform_rects:
		draw_rect(p, cave_rock.lightened(0.2))
		draw_circle(Vector2(p.position.x + 25, p.position.y - 6), 8.0, crystal_glow)
		draw_circle(Vector2(p.position.x + p.size.x - 25, p.position.y - 6), 8.0, crystal_glow)

