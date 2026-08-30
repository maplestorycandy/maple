# MapManager.gd
# 完美復刻楓之谷經典版各大分區地貌、階梯地勢、圖騰、路燈、樹洞與場景氛圍
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
		
	# Update background sky gradient atmosphere
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
		Vector2(-1450, 380),
		Vector2(1450, 380),
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

# =========================================================================
# AUTHENTIC TERRAIN RENDERING FOR EACH REGION
# =========================================================================
func _draw():
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	var theme = map_info.get("terrain_theme", "henesys")
	
	match theme:
		"perion":
			draw_perion_terrain(map_info)
		"ellinia":
			draw_ellinia_terrain(map_info)
		"kerning", "subway":
			draw_kerning_terrain(map_info)
		"sleepywood":
			draw_sleepywood_terrain(map_info)
		"lith_harbor", "nautilus", "florina":
			draw_beach_terrain(map_info)
		_:
			draw_henesys_terrain(map_info)

# 1. 弓箭手村 (Henesys) - 綠色青草土層、階梯石階、木製路燈、花草岩石
func draw_henesys_terrain(map_info: Dictionary):
	var ground_col = Color(0.42, 0.30, 0.16)
	var grass_col = Color(0.38, 0.78, 0.22)
	var grass_top = Color(0.55, 0.90, 0.30)
	
	# Main Ground Floor
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), ground_col)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 10)), grass_col)
	draw_rect(Rect2(Vector2(-1800, 373), Vector2(3600, 4)), grass_top)
	
	# Right Stepped Hill / Stairs (as in media_1788064524584.jpg)
	var steps = [
		Rect2(Vector2(950, 340), Vector2(120, 40)),
		Rect2(Vector2(1070, 300), Vector2(120, 80)),
		Rect2(Vector2(1190, 260), Vector2(120, 120)),
		Rect2(Vector2(1310, 220), Vector2(350, 160))
	]
	for s in steps:
		draw_rect(s, ground_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 8)), grass_col)
		draw_rect(Rect2(Vector2(s.position.x, s.position.y), Vector2(s.size.x, 3)), grass_top)
		
	# Floating Island in Center (media_1788064524584.jpg)
	var island = Rect2(Vector2(-100, 230), Vector2(200, 35))
	draw_rect(island, ground_col)
	draw_rect(Rect2(Vector2(island.position.x, island.position.y), Vector2(island.size.x, 7)), grass_col)
	draw_rect(Rect2(Vector2(island.position.x, island.position.y), Vector2(island.size.x, 3)), grass_top)
	
	# Floating Platforms
	var platforms = [
		Rect2(Vector2(-800, 240), Vector2(260, 22)),
		Rect2(Vector2(-400, 150), Vector2(280, 22)),
		Rect2(Vector2(350, 160), Vector2(260, 22))
	]
	for p in platforms:
		draw_rect(p, ground_col)
		draw_rect(Rect2(Vector2(p.position.x, p.position.y), Vector2(p.size.x, 6)), grass_col)
		draw_line(Vector2(p.position.x + 20, p.position.y + p.size.y), Vector2(p.position.x + 20, 380), Color(0.3, 0.2, 0.1), 3.0)
		draw_line(Vector2(p.position.x + p.size.x - 20, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 20, 380), Color(0.3, 0.2, 0.1), 3.0)
		
	# Scenery Props: Streetlights, Bushes, Tombstones
	for lx in [-1200, -700, 200, 800]:
		# Wooden Streetlight with warm glow
		draw_rect(Rect2(Vector2(lx, 300), Vector2(8, 75)), Color(0.35, 0.22, 0.12))
		draw_circle(Vector2(lx + 4, 295), 14.0, Color(1.0, 0.9, 0.4, 0.4))
		draw_circle(Vector2(lx + 4, 295), 6.0, Color(1.0, 1.0, 0.7))
		
	for bx in [-1050, -500, -50, 450, 1000]:
		# Bush & wildflowers
		draw_circle(Vector2(bx, 368), 16.0, grass_col.darkened(0.1))
		draw_circle(Vector2(bx + 14, 370), 12.0, grass_col)
		draw_circle(Vector2(bx + 5, 362), 4.0, Color(1.0, 0.9, 0.3))

# 2. 勇士之村 (Perion) - 紅黃砂岩岩壁、木製圖騰柱、風蝕斷崖 (media_1788063697800.png)
func draw_perion_terrain(_map_info: Dictionary):
	var rock_col = Color(0.78, 0.52, 0.30)
	var rock_dark = Color(0.55, 0.34, 0.18)
	var rock_top = Color(0.92, 0.68, 0.42)
	
	# Ground
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), rock_dark)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), rock_col)
	draw_rect(Rect2(Vector2(-1800, 373), Vector2(3600, 3)), rock_top)
	
	# Multi-tier Canyon Rock Cliffs
	var cliffs = [
		Rect2(Vector2(-1400, 220), Vector2(400, 160)),
		Rect2(Vector2(-900, 160), Vector2(320, 220)),
		Rect2(Vector2(200, 180), Vector2(450, 200)),
		Rect2(Vector2(850, 240), Vector2(400, 140))
	]
	for c in cliffs:
		draw_rect(c, rock_col)
		draw_rect(Rect2(Vector2(c.position.x, c.position.y), Vector2(c.size.x, 8)), rock_top)
		# Support Rock Arches
		draw_line(Vector2(c.position.x + 30, c.position.y + c.size.y), Vector2(c.position.x + 30, 380), rock_dark, 8.0)
		draw_line(Vector2(c.position.x + c.size.x - 30, c.position.y + c.size.y), Vector2(c.position.x + c.size.x - 30, 380), rock_dark, 8.0)
		
	# Native American Totem Poles
	for tx in [-1100, -300, 500, 1100]:
		draw_rect(Rect2(Vector2(tx, 270), Vector2(16, 105)), Color(0.4, 0.22, 0.12))
		draw_circle(Vector2(tx + 8, 265), 12.0, Color(0.85, 0.3, 0.2))
		draw_line(Vector2(tx - 12, 285), Vector2(tx + 28, 285), Color(0.9, 0.8, 0.2), 4.0)

# 3. 魔法森林 (Ellinia) - 參天巨樹、幽綠樹洞、青苔藤蔓
func draw_ellinia_terrain(_map_info: Dictionary):
	var bark_col = Color(0.32, 0.20, 0.12)
	var leaf_col = Color(0.18, 0.55, 0.28)
	var leaf_glow = Color(0.30, 0.85, 0.45)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), bark_col)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 10)), leaf_col)
	
	# Giant Tree Trunks
	for gx in [-1300, -500, 350, 1150]:
		draw_rect(Rect2(Vector2(gx, -400), Vector2(80, 780)), bark_col.darkened(0.2))
		# Hollow Tree Door
		draw_circle(Vector2(gx + 40, 330), 22.0, Color(0.08, 0.05, 0.03))
		# Foliage Canopies
		draw_circle(Vector2(gx + 40, 180), 70.0, leaf_col)
		draw_circle(Vector2(gx + 40, 175), 50.0, leaf_glow)
		
	# Hanging Wooden Platforms
	for py in [240, 150]:
		draw_rect(Rect2(Vector2(-900, py), Vector2(300, 20)), bark_col)
		draw_rect(Rect2(Vector2(600, py), Vector2(300, 20)), bark_col)

# 4. 墮落城市 & 地鐵 (Kerning City & Subway) - 鋼鐵鷹架、水泥柏油、鐵軌與警示條紋
func draw_kerning_terrain(_map_info: Dictionary):
	var asphalt = Color(0.20, 0.20, 0.24)
	var steel = Color(0.38, 0.40, 0.46)
	var hazard = Color(0.95, 0.80, 0.10)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), asphalt)
	# Subway Tracks
	draw_line(Vector2(-1800, 376), Vector2(1800, 376), steel.lightened(0.3), 3.0)
	draw_line(Vector2(-1800, 379), Vector2(1800, 379), steel.lightened(0.3), 3.0)
	
	# Scaffolding Girders
	for kx in [-1100, -300, 500, 1200]:
		draw_rect(Rect2(Vector2(kx, 140), Vector2(280, 18)), steel)
		draw_line(Vector2(kx + 20, 158), Vector2(kx + 20, 380), steel, 5.0)
		draw_line(Vector2(kx + 260, 158), Vector2(kx + 260, 380), steel, 5.0)
		# Cross Bracing
		draw_line(Vector2(kx + 20, 158), Vector2(kx + 260, 380), steel.darkened(0.2), 2.0)
		draw_line(Vector2(kx + 260, 158), Vector2(kx + 20, 380), steel.darkened(0.2), 2.0)
		# Warning Stripes
		draw_rect(Rect2(Vector2(kx + 100, 142), Vector2(80, 14)), hazard)

# 5. 奇幻村 (Sleepywood) - 幽暗洞窟鐘乳石、骷髏祭壇、紫晶結晶
func draw_sleepywood_terrain(_map_info: Dictionary):
	var cave_rock = Color(0.18, 0.14, 0.22)
	var stalactite_col = Color(0.32, 0.25, 0.38)
	var crystal_glow = Color(0.85, 0.35, 1.0, 0.6)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), cave_rock)
	
	# Hanging Stalactites from ceiling
	for sx in [-1300, -900, -400, 100, 650, 1150]:
		var poly = PackedVector2Array([
			Vector2(sx - 25, -200),
			Vector2(sx + 25, -200),
			Vector2(sx, 50)
		])
		draw_colored_polygon(poly, stalactite_col)
		
	# Cavern Stone Platforms
	var cave_plats = [
		Rect2(Vector2(-800, 220), Vector2(320, 24)),
		Rect2(Vector2(250, 180), Vector2(340, 24))
	]
	for cp in cave_plats:
		draw_rect(cp, cave_rock.lightened(0.2))
		# Glowing Purple Crystals
		draw_circle(Vector2(cp.position.x + 30, cp.position.y - 8), 10.0, crystal_glow)
		draw_circle(Vector2(cp.position.x + cp.size.x - 30, cp.position.y - 8), 10.0, crystal_glow)

# 6. 維多利亞港 / 鯨魚號 / 黃金海岸 (Beach & Harbor) - 蔚藍海灣沙灘、鯨魚號龍骨
func draw_beach_terrain(_map_info: Dictionary):
	var sand = Color(0.88, 0.82, 0.55)
	var wood_pier = Color(0.55, 0.38, 0.22)
	var sea_blue = Color(0.2, 0.6, 0.9)
	
	draw_rect(Rect2(Vector2(-1800, 380), Vector2(3600, 420)), sand)
	draw_rect(Rect2(Vector2(-1800, 375), Vector2(3600, 8)), sand.lightened(0.1))
	
	# Pier Wooden Planks
	for px in [-1200, -400, 400, 1100]:
		draw_rect(Rect2(Vector2(px, 250), Vector2(260, 22)), wood_pier)
		draw_line(Vector2(px + 20, 272), Vector2(px + 20, 380), wood_pier.darkened(0.3), 6.0)
		draw_line(Vector2(px + 240, 272), Vector2(px + 240, 380), wood_pier.darkened(0.3), 6.0)
		# Palm Trees
		draw_line(Vector2(px + 130, 250), Vector2(px + 140, 150), Color(0.4, 0.25, 0.15), 10.0)
		draw_circle(Vector2(px + 140, 140), 35.0, Color(0.2, 0.7, 0.3))
