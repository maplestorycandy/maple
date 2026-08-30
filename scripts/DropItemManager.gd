# DropItemManager.gd
extends Node

static var drop_scene = preload("res://scenes/entities/DropItem.tscn")

static func spawn_monster_drops(parent: Node, spawn_pos: Vector2, monster_data: Dictionary):
	if not is_instance_valid(parent):
		return
		
	# 1. Meso Drop (100% Guaranteed)
	var meso_val = max(10, int(monster_data.get("exp", 15) * randf_range(0.8, 1.4)))
	spawn_single_drop(parent, spawn_pos, {
		"name": "%d 楓幣" % meso_val,
		"type": "meso",
		"meso_amount": meso_val
	})
	
	var drops = monster_data.get("drops", {})
	var eq_list = drops.get("equipments", [])
	var con_list = drops.get("consumables", [])
	var mat_list = drops.get("materials", [])
	
	# 2. Material / ETC Drop (65% Chance)
	if not mat_list.is_empty() and randf() < 0.65:
		var mat = mat_list[randi() % mat_list.size()]
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-15, 15), 0), {
			"name": mat.get("name", "材料"),
			"type": "material"
		})
		
	# 3. Consumable / Potion Drop (35% Chance)
	if not con_list.is_empty() and randf() < 0.35:
		var con = con_list[randi() % con_list.size()]
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-20, 20), 0), {
			"name": con.get("name", "藥水"),
			"type": "consumable"
		})
		
	# 4. Equipment Drop (18% Rare Chance, Bosses 100%)
	if not eq_list.is_empty() and (randf() < 0.18 or monster_data.get("is_boss", false)):
		var eq = eq_list[randi() % eq_list.size()]
		spawn_single_drop(parent, spawn_pos + Vector2(randf_range(-25, 25), 0), {
			"name": eq.get("name", "裝備"),
			"type": "equipment",
			"req_lvl": eq.get("req_lvl", 0),
			"job": eq.get("job", "")
		})

static func spawn_single_drop(parent: Node, pos: Vector2, item_data: Dictionary):
	if not drop_scene:
		drop_scene = load("res://scenes/entities/DropItem.tscn")
	var item = drop_scene.instantiate()
	item.setup(item_data, pos)
	parent.add_child.call_deferred(item)
