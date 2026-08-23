# MapManager.gd
extends Node2D

@export var current_map_id: String = "henesys_field"
@export var goddess_scene: PackedScene
@export var monster_scene: PackedScene

var active_wild_monsters: Array = []
var wild_spawn_timer: float = 0.0
var wild_spawn_interval: float = 4.0
var max_wild_mobs: int = 14

@onready var platforms_container: StaticBody2D = $Platforms
@onready var background_rect: ColorRect = $BackgroundRect
@onready var ground_collision: CollisionShape2D = $Platforms/GroundCollision

func _ready():
	Global.map_change_requested.connect(load_map)
	load_map(Global.current_map_id)

func _process(delta):
	wild_spawn_timer += delta
	if wild_spawn_timer >= wild_spawn_interval:
		wild_spawn_timer = 0.0
		clean_wild_monster_list()
		if active_wild_monsters.size() < max_wild_mobs:
			spawn_wild_monster()

func clean_wild_monster_list():
	var valid_list = []
	for m in active_wild_monsters:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			valid_list.append(m)
	active_wild_monsters = valid_list

func load_map(map_id: String):
	if not MapDatabase.MAPS.has(map_id):
		return
		
	current_map_id = map_id
	var map_info = MapDatabase.MAPS[map_id]
	
	# Clear old wild monsters (keep wave attackers)
	for m in active_wild_monsters:
		if is_instance_valid(m):
			m.queue_free()
	active_wild_monsters.clear()
	
	# Update background atmosphere
	if background_rect:
		background_rect.color = map_info.bg_bottom_color
		
	# Spawn initial batch of wild monsters
	for i in range(8):
		spawn_wild_monster()
		
	queue_redraw()

func spawn_wild_monster():
	if not MapDatabase.MAPS.has(current_map_id):
		return
	var map_info = MapDatabase.MAPS[current_map_id]
	var pool: Array = map_info.wild_mob_ids
	if pool.is_empty():
		return
		
	var chosen_id = pool.pick_random()
	if not MonsterDatabaseFull.FULL_DATABASE.has(chosen_id):
		return
		
	var data = MonsterDatabaseFull.FULL_DATABASE[chosen_id]
	var mob = load("res://scenes/monsters/BaseMonster.tscn").instantiate()
	
	# Random spawn location on platforms
	var spawn_x = randf_range(-1200, 1200)
	var spawn_y = randf_range(200, 350)
	if randf() < 0.4:
		spawn_y = randf_range(0, 150) # on elevated platforms
		
	mob.global_position = Vector2(spawn_x, spawn_y)
	mob.setup(data, Vector2.ZERO) # Wild mob: no direct goddess target
	
	active_wild_monsters.append(mob)
	get_parent().add_child.call_deferred(mob)

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
		draw_rect(Rect2(p.position.x, p.position.y, p.size.x, 6), plat_col.lightened(0.3))
		# Support wooden pillars or vines
		draw_line(Vector2(p.position.x + 20, p.position.y + p.size.y), Vector2(p.position.x + 20, 380), plat_col.darkened(0.3), 3.0)
		draw_line(Vector2(p.position.x + p.size.x - 20, p.position.y + p.size.y), Vector2(p.position.x + p.size.x - 20, 380), plat_col.darkened(0.3), 3.0)
		
	# 3. Ambient thematic decorations
	draw_decorative_props(map_info)

func draw_decorative_props(map_info: Dictionary):
	var theme_col = map_info.ground_color.lightened(0.4)
	# Draw background trees/crystals
	for x in [-1400, -900, -500, 500, 950, 1350]:
		draw_rect(Rect2(x, 300, 24, 80), map_info.platform_color.darkened(0.4))
		draw_circle(Vector2(x + 12, 280), 38.0, theme_col)
