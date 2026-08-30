# MapManager.gd
# 完美實裝全地圖正版地貌、多層實體跳台(一向碰撞)、上下層生怪與場景特色
extends Node2D

@export var current_map_id: String = "100000000"
@export var goddess_scene: PackedScene
@export var monster_scene: PackedScene

var active_wild_monsters: Array = []
var wild_spawn_timer: float = 0.0
var wild_spawn_interval: float = 3.0
var max_wild_mobs: int = 18

# Dynamic Platforms Container
var dynamic_platforms_node: Node2D
var active_platform_rects: Array[Rect2] = []

@onready var background_rect: ColorRect = $BackgroundRect

func _ready():
	# Create dynamic container for physical platform colliders
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
		background_rect.color = map_info.bg_bottom_color
		
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
	
	# 1. Main Ground Base (-1800 to 1800, y=380)
	var main_ground = Rect2(Vector2(-1800, 380), Vector2(3600, 420))
	create_static_collider(main_ground, false)
	
	# 2. Regional Multi-Tier Platforms
	match theme:
		"ellinia":
			# Giant hollow tree vertical levels (media_1788065013227.png)
			var plats = [
				Rect2(Vector2(-1250, 270), Vector2(340, 20)),
				Rect2(Vector2(-1250, 150), Vector2(340, 20)),
				Rect2(Vector2(-1250, 30), Vector2(300, 20)),
				Rect2(Vector2(-1250, -90), Vector2(240, 20)),
				Rect2(Vector2(-200, 250), Vector2(400, 20)),
				Rect2(Vector2(-200, 130), Vector2(400, 20)),
				Rect2(Vector2(-150, 10), Vector2(300, 20)),
				Rect2(Vector2(750, 270), Vector2(350, 20)),
				Rect2(Vector2(750, 150), Vector2(350, 20)),
				Rect2(Vector2(750, 30), Vector2(300, 20))
			]
			for p in plats:
				create_static_collider(p, true)
				active_platform_rects.append(p)
				
		"perion":
			# Multi-tier Canyon Sandstone Cliffs (media_1788063697800.png)
			var cliffs = [
				Rect2(Vector2(-1400, 240), Vector2(420, 24)),
				Rect2(Vector2(-900, 140), Vector2(380, 24)),
				Rect2(Vector2(-400, 220), Vector2(320, 24)),
				Rect2(Vector2(150, 160), Vector2(460, 24)),
				Rect2(Vector2(750, 240), Vector2(420, 24)),
				Rect2(Vector2(1250, 180), Vector2(350, 24))
			]
			for c in cliffs:
				create_static_collider(c, true)
				active_platform_rects.append(c)
				
		"kerning", "subway":
			# Scaffolding Girders & Subway Platforms
			var scaffolds = [
				Rect2(Vector2(-1300, 240), Vector2(360, 20)),
				Rect2(Vector2(-800, 140), Vector2(340, 20)),
				Rect2(Vector2(-200, 220), Vector2(400, 20)),
				Rect2(Vector2(350, 140), Vector2(360, 20)),
				Rect2(Vector2(850, 240), Vector2(420, 20)),
				Rect2(Vector2(-300, 50), Vector2(280, 20))
			]
			for s in scaffolds:
				create_static_collider(s, true)
				active_platform_rects.append(s)
				
		"sleepywood":
			# Cavern Stone Platforms & Runic Altars
			var caves = [
				Rect2(Vector2(-1200, 230), Vector2(380, 24)),
				Rect2(Vector2(-700, 130), Vector2(340, 24)),
				Rect2(Vector2(-150, 200), Vector2(420, 24)),
				Rect2(Vector2(400, 120), Vector2(380, 24)),
				Rect2(Vector2(950, 220), Vector2(380, 24))
			]
			for cv in caves:
				create_static_collider(cv, true)
				active_platform_rects.append(cv)
				
		"lith_harbor", "nautilus", "florina":
			# Palm tree ledges & Ship Wooden Piers (media_1788065027181.png / media_1788065030445.png)
			var beach_plats = [
				Rect2(Vector2(-1350, 250), Vector2(340, 22)),
				Rect2(Vector2(-900, 150), Vector2(300, 22)),
				Rect2(Vector2(-450, 230), Vector2(380, 22)),
				Rect2(Vector2(100, 140), Vector2(360, 22)),
				Rect2(Vector2(650, 220), Vector2(420, 22)),
				Rect2(Vector2(1200, 150), Vector2(320, 22))
			]
			for bp in beach_plats:
				create_static_collider(bp, true)
				active_platform_rects.append(bp)
				
		_:
			# Henesys Stepped Hills, Field Islands, and Park Towers (media_1788065019213.png / media_1788065023767.png)
			var henesys_plats = [
				# Right stepped hill
				Rect2(Vector2(950, 320), Vector2(140, 60)),
				Rect2(Vector2(1090, 260), Vector2(140, 120)),
				Rect2(Vector2(1230, 200), Vector2(370, 180)),
				# Floating Grass Platforms
				Rect2(Vector2(-1300, 240), Vector2(320, 22)),
				Rect2(Vector2(-850, 140), Vector2(300, 22)),
				Rect2(Vector2(-350, 220), Vector2(360, 22)),
				Rect2(Vector2(150, 130), Vector2(320, 22)),
				Rect2(Vector2(600, 210), Vector2(280, 22)),
				# High Tower Floating Island
				Rect2(Vector2(-100, 40), Vector2(220, 22))
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
		col.one_way_collision_margin = 8.0
	
	body.add_child(col)
	dynamic_platforms_node.add_child(body)

func setup_map_portals(map_info: Dictionary):
	var n_portals = map_info.get("normal_portals", [])
	var h_portals = map_info.get("hidden_portals", [])
	
	var portal_positions = [
		Vector2(-1450, 380),
		Vector2(1450, 380),
		Vector2(-850, 140),
		Vector2(650, 210),
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
			
	# Pick random spawn spot (Ground OR on an elevated platform)
	var spawn_x = randf_range(-1350, 1350)
	var spawn_y = 370.0 # ground
	
	if not active_platform_rects.is_empty() and randf() < 0.55:
		var chosen_plat = active_platform_rects[randi() % active_platform_rects.size()]
		spawn_x = randf_range(chosen_plat.position.x + 20, chosen_plat.position.x + chosen_plat.size.x - 20)
		spawn_y = chosen_plat.position.y - 5
		
	var mob = NetworkManager.spawn_network_monster(chosen_id, Vector2(spawn_x, spawn_y), Vector2.ZERO, false)
	if is_instance_valid(mob):
		active_wild_monsters.append(mob)

# =========================================================================
# AUTHENTIC TERRAIN & PROPS RENDERING (MATCHING USER'S SCREENSHOTS)
# =========================================================================
func _draw():
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	var theme = map_info.get("terrain_theme", "henesys")
	
	match theme:
		"ellinia":
			draw_ellinia_terrain(map_info)
		"perion":
			draw_perion_terrain(map_info)
		"kerning", "subway":
			draw_kerning_terrain(map_info)
		"sleepywood":
			draw_sleepywood_terrain(map_info)
		"lith_harbor", "nautilus", "florina":
			draw_beach_terrain(map_info)
		_:
			draw_henesys_terrain(map_info)

# 1. 弓箭手村 (Henesys) - 綠色草皮土層、階梯石階、木製路燈、花草岩石、白色木柵欄 (media_1788065019213.png / media_1788065023767.png)
func draw_henesys_terrain(_map_info: Dictionary):
	var ground_col = Color(0.42, 0.30, 0.16)
	var grass_col = Color(0.38, 0.78, 0.22)
	var grass_top = Color(0.55, 0.90, 0.30)
	
	# Main Ground Floor
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), ground_col)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 10)), grass_col)
	draw_rect(Rect2(Vector2(-1800, 373), Vector2(3600, 4)), grass_top)
	
	# Right Stepped Hill / Stairs (media_1788065023767.png)
	var steps = [
		Rect2(Vector2(950, 320), Vector2(140, 60)),
		Rect2(Vector2(1090, 260), Vector2(140, 120)),
		Rect2(Vector2(1230, 200), Vector2(370, 180))
	]
	for s in steps:
		draw_rect(s, ground_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 8)), grass_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 3)), grass_top)
		
	# Draw all active floating grass platforms
	for p in active_platform_rects:
		draw_rect(p, ground_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 7)), grass_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 3)), grass_top)
		# Support rope / pole down
		draw_line(Vector2(p.position.x + 25, p.position.y + p.size.y), Vector2(p.position.x + 25, 380), Color(0.32, 0.22, 0.12), 2.0)
		draw_line(Vector2(p.position.x + p.size.x - 25, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 25, 380), Color(0.32, 0.22, 0.12), 2.0)
		
	# Scenery Props: Autumn Trees & White Picket Fences (media_1788065023767.png)
	for fx in [1000, 1250]:
		# White fence
		for fi in range(6):
			draw_rect(Rect2(Vector2(fx + fi * 16, 180), Vector2(6, 20)), Color(0.95, 0.95, 0.9))
		draw_line(Vector2(fx, 188), Vector2(fx + 90, 188), Color(0.9, 0.9, 0.85), 3.0)
		
	# Autumn Trees with leaf bunches
	for tx in [-600, 250, 1350]:
		draw_rect(Rect2(Vector2(tx, 220), Vector2(14, 160)), Color(0.85, 0.75, 0.65))
		draw_circle(Vector2(tx + 7, 210), 32.0, Color(0.85, 0.55, 0.2))
		draw_circle(Vector2(tx - 15, 230), 24.0, Color(0.75, 0.65, 0.25))
		draw_circle(Vector2(tx + 25, 225), 26.0, Color(0.9, 0.45, 0.2))
		
	# Streetlights & Flowers
	for lx in [-1200, -200, 750]:
		draw_rect(Rect2(Vector2(lx, 300), Vector2(8, 75)), Color(0.35, 0.22, 0.12))
		draw_circle(Vector2(lx + 4, 295), 14.0, Color(1.0, 0.9, 0.4, 0.4))
		draw_circle(Vector2(lx + 4, 295), 6.0, Color(1.0, 1.0, 0.7))

# 2. 魔法森林 (Ellinia) - 參天巨樹、幽綠樹洞、青苔藤蔓 (media_1788065013227.png)
func draw_ellinia_terrain(_map_info: Dictionary):
	var bark_col = Color(0.32, 0.20, 0.12)
	var leaf_col = Color(0.18, 0.55, 0.28)
	var leaf_glow = Color(0.30, 0.85, 0.45)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), bark_col)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 10)), leaf_col)
	
	# Giant Tree Trunks with Hollow Doors (media_1788065013227.png)
	for gx in [-1100, 0, 900]:
		draw_rect(Rect2(Vector2(gx - 45, -300), Vector2(90, 680)), bark_col.darkened(0.15))
		draw_rect(Rect2(Vector2(gx - 40, -300), Vector2(80, 680)), bark_col)
		# Hollow Doors at vertical tiers
		for dy in [320, 200, 80, -40]:
			draw_circle(Vector2(gx, dy), 22.0, Color(0.06, 0.04, 0.02))
			draw_circle(Vector2(gx, dy - 2), 16.0, Color(0.12, 0.35, 0.15, 0.6))
			
	# Floating Tree Ledges & Vines
	for p in active_platform_rects:
		draw_rect(p, bark_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 6)), leaf_col)
		# Hanging Vines
		draw_line(Vector2(p.position.x + 15, p.position.y + p.size.y), Vector2(p.position.x + 15, p.position.y + 45), leaf_glow, 3.0)
		draw_line(Vector2(p.position.x + p.size.x - 15, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 15, p.position.y + 45), leaf_glow, 3.0)

# 3. 勇士之村 (Perion) - 紅黃砂岩岩壁、木製圖騰柱、風蝕斷崖
func draw_perion_terrain(_map_info: Dictionary):
	var rock_col = Color(0.78, 0.52, 0.30)
	var rock_dark = Color(0.55, 0.34, 0.18)
	var rock_top = Color(0.92, 0.68, 0.42)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), rock_dark)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), rock_col)
	draw_rect(Rect2(Vector2(-1800, 373), Vector2(3600, 3)), rock_top)
	
	for p in active_platform_rects:
		draw_rect(p, rock_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 6)), rock_top)
		draw_line(Vector2(p.position.x + 20, p.position.y + p.size.y), Vector2(p.position.x + 20, 380), rock_dark, 6.0)
		draw_line(Vector2(p.position.x + p.size.x - 20, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 20, 380), rock_dark, 6.0)
		
	# Native American Totem Poles
	for tx in [-1100, -300, 500, 1100]:
		draw_rect(Rect2(Vector2(tx, 270), Vector2(16, 105)), Color(0.4, 0.22, 0.12))
		draw_circle(Vector2(tx + 8, 265), 12.0, Color(0.85, 0.3, 0.2))
		draw_line(Vector2(tx - 12, 285), Vector2(tx + 28, 285), Color(0.9, 0.8, 0.2), 4.0)

# 4. 墮落城市 & 地鐵 (Kerning City & Subway) - 鋼鐵鷹架、水泥柏油、鐵軌與警示條紋
func draw_kerning_terrain(_map_info: Dictionary):
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

# 5. 奇幻村 (Sleepywood) - 幽暗洞窟鐘乳石、骷髏祭壇、紫晶結晶
func draw_sleepywood_terrain(_map_info: Dictionary):
	var cave_rock = Color(0.18, 0.14, 0.22)
	var stalactite_col = Color(0.32, 0.25, 0.38)
	var crystal_glow = Color(0.85, 0.35, 1.0, 0.6)
	
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

# 6. 維多利亞港 / 鯨魚號 / 黃金海岸 (Beach & Harbor) - 蔚藍海灣沙灘、棕櫚樹平台、擱淺帆船 (media_1788065027181.png / media_1788065030445.png)
func draw_beach_terrain(_map_info: Dictionary):
	var sand = Color(0.88, 0.82, 0.55)
	var wood_pier = Color(0.55, 0.38, 0.22)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), sand)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), sand.lightened(0.1))
	
	# Stranded Ship on left (media_1788065027181.png)
	var ship_hull = PackedVector2Array([
		Vector2(-1300, 380),
		Vector2(-1420, 320),
		Vector2(-1150, 320),
		Vector2(-1100, 380)
	])
	draw_colored_polygon(ship_hull, Color(0.45, 0.25, 0.12))
	# Mast & White Sail
	draw_line(Vector2(-1260, 320), Vector2(-1260, 200), Color(0.3, 0.18, 0.08), 5.0)
	var sail = PackedVector2Array([
		Vector2(-1260, 210),
		Vector2(-1200, 240),
		Vector2(-1260, 270)
	])
	draw_colored_polygon(sail, Color(0.92, 0.92, 0.88))
	
	# Palm Tree Platforms (media_1788065030445.png)
	for p in active_platform_rects:
		draw_rect(p, wood_pier)
		# Palm trunk support
		draw_line(Vector2(p.position.x + p.size.x / 2.0, p.position.y + p.size.y), Vector2(p.position.x + p.size.x / 2.0, 380), Color(0.48, 0.32, 0.18), 8.0)
		# Palm fronds canopy
		draw_circle(Vector2(p.position.x + p.size.x / 2.0, p.position.y - 12), 35.0, Color(0.2, 0.72, 0.28))
		# Blue umbrella or coconuts
		draw_circle(Vector2(p.position.x + p.size.x / 2.0 - 15, p.position.y - 18), 6.0, Color(0.3, 0.7, 0.95))
