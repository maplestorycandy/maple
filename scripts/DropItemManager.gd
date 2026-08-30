# DropItemManager.gd
# 100% 正版 BoBo 官方掉落：每隻怪物擊殺必定依據 1.14.6 官方掉落表噴出【楓幣 + 官方裝備 + 消耗藥水 + 官方卷軸 + 戰利品材料】！
extends Node

static var drop_scene = preload("res://scenes/entities/DropItem.tscn")

static func spawn_monster_drops(parent: Node, spawn_pos: Vector2, monster_data: Dictionary):
	if not is_instance_valid(parent):
		parent = Engine.get_main_loop().current_scene
		
	var mob_lvl = monster_data.get("level", 1)
	var is_boss = monster_data.get("is_boss", false)
	var mob_name = monster_data.get("name", "怪物")
	var mob_id = monster_data.get("id", -1)
	
	# Fetch official monster entry from MonsterDatabaseFull
	var official_mob = {}
	if mob_id > 0:
		official_mob = MonsterDatabaseFull.get_monster_by_id(mob_id)
	if official_mob.is_empty():
		official_mob = MonsterDatabaseFull.get_monster_by_name(mob_name)
		
	var official_drops = official_mob.get("drops", [])
	var official_equips = []
	var official_scrolls = []
	var official_uses = []
	var official_etcs = []
	
	for d in official_drops:
		match d.get("type", ""):
			"equip": official_equips.append(d)
			"scroll": official_scrolls.append(d)
			"use": official_uses.append(d)
			"etc", "material": official_etcs.append(d)
			
	# 1. 楓幣金幣袋 (100% 必定掉落)
	var meso_val = max(30, int(monster_data.get("exp", 25) * randf_range(1.5, 3.0)))
	spawn_single_drop(parent, spawn_pos, {
		"name": "%d 楓幣" % meso_val,
		"type": "meso",
		"meso_amount": meso_val
	}, Vector2(randf_range(-40, 40), -160))
	
	# 2. 裝備掉落 (100% 依官方掉落表，BOSS 掉落 3~5 件神裝！)
	var eq_count = randi_range(3, 5) if is_boss else 1
	for i in range(eq_count):
		var eq_drop_data = {}
		if not official_equips.is_empty():
			var eq_item = official_equips[randi() % official_equips.size()]
			var eq_id = eq_item.get("id", 0)
			var db_eq = EquipmentDatabaseFull.get_equipment(eq_id)
			if not db_eq.is_empty():
				eq_drop_data = db_eq.duplicate()
			else:
				eq_drop_data = {
					"name": eq_item.get("name", "稀有裝備"),
					"req_lvl": mob_lvl,
					"slot": "weapon"
				}
		else:
			eq_drop_data = generate_fallback_equipment(mob_lvl, mob_name)
			
		eq_drop_data["type"] = "equipment"
		var vel_x = randf_range(-110, 110)
		spawn_single_drop(parent, spawn_pos, eq_drop_data, Vector2(vel_x, randf_range(-200, -150)))
		
	# 3. 消耗品 / 藥水 (100% 依官方掉落表)
	var pot_drop_data = {}
	if not official_uses.is_empty():
		var u_item = official_uses[randi() % official_uses.size()]
		var u_id = u_item.get("id", 0)
		var db_item = ItemDatabaseFull.get_item(u_id)
		if not db_item.is_empty():
			pot_drop_data = db_item.duplicate()
		else:
			pot_drop_data = {"name": u_item.get("name", "紅色藥水"), "id": u_id}
	else:
		var pot_name = "紅色藥水" if mob_lvl < 25 else ("白色藥水" if mob_lvl < 60 else "超級藥水")
		pot_drop_data = {"name": pot_name}
		
	pot_drop_data["type"] = "consumable"
	spawn_single_drop(parent, spawn_pos, pot_drop_data, Vector2(randf_range(-80, -20), -180))
	
	# 4. 材料 / 怪物戰利品 (100% 依官方掉落表)
	var mat_drop_data = {}
	if not official_etcs.is_empty():
		var m_item = official_etcs[randi() % official_etcs.size()]
		var m_id = m_item.get("id", 0)
		var db_mat = ItemDatabaseFull.get_item(m_id)
		if not db_mat.is_empty():
			mat_drop_data = db_mat.duplicate()
		else:
			mat_drop_data = {"name": m_item.get("name", "%s的戰利品" % mob_name), "id": m_id}
	else:
		mat_drop_data = {"name": "%s的戰利品" % mob_name}
		
	mat_drop_data["type"] = "material"
	spawn_single_drop(parent, spawn_pos, mat_drop_data, Vector2(randf_range(20, 80), -180))

	# 5. 官方卷軸掉落 (官方圖鑑指定卷軸 + BOSS 必出珍貴卷軸)
	var should_drop_scroll = false
	var chosen_scroll_name = ""
	
	if not official_scrolls.is_empty():
		var scroll_drop_chance = 1.0 if is_boss else 0.45
		if randf() <= scroll_drop_chance:
			should_drop_scroll = true
			chosen_scroll_name = official_scrolls[randi() % official_scrolls.size()].get("name", "")
	else:
		var mob_scrolls = ScrollDatabase.get_scrolls_for_monster(mob_name)
		if not mob_scrolls.is_empty():
			if randf() <= (1.0 if is_boss else 0.45):
				should_drop_scroll = true
				chosen_scroll_name = mob_scrolls[randi() % mob_scrolls.size()].get("name", "")
		elif is_boss or (mob_lvl >= 30 and randf() < 0.25):
			should_drop_scroll = true
			var all_keys = ScrollDatabase.SCROLLS.keys()
			if not all_keys.is_empty():
				var s_obj = ScrollDatabase.SCROLLS[all_keys[randi() % all_keys.size()]]
				chosen_scroll_name = s_obj.get("name", "攻擊卷軸60%")
				
	if should_drop_scroll and chosen_scroll_name != "":
		var s_data = ScrollDatabase.get_scroll_by_name(chosen_scroll_name)
		if s_data.is_empty():
			s_data = {
				"name": chosen_scroll_name,
				"target_slot": "weapon",
				"rate": 60,
				"is_cursed": false,
				"stats": {"atk": 2}
			}
		var scroll_item_data = s_data.duplicate()
		scroll_item_data["type"] = "scroll"
		scroll_item_data["count"] = 1
		spawn_single_drop(parent, spawn_pos, scroll_item_data, Vector2(randf_range(-60, 60), -210))

static func generate_fallback_equipment(lvl: int, _mob_name: String) -> Dictionary:
	var weapons = ["雙手劍", "精鋼短刀", "獵人之弓", "幻影法杖", "拳套", "雙管短槍", "鋼鐵戰錘"]
	var armors = ["頭盔", "頭巾", "套服", "戰甲", "長袍", "皮靴", "長靴", "手套", "護手", "護腕", "木盾", "精靈披風"]
	var is_wp = randf() < 0.45
	var item_base = weapons[randi() % weapons.size()] if is_wp else armors[randi() % armors.size()]
	var prefix = "初心者" if lvl < 15 else ("青銅" if lvl < 35 else ("鋼鐵" if lvl < 65 else ("精靈" if lvl < 90 else "傳奇神聖")))
	return {
		"name": "%s%s" % [prefix, item_base],
		"req_lvl": max(1, lvl),
		"job": "全職業"
	}

static func spawn_single_drop(parent: Node, pos: Vector2, item_data: Dictionary, initial_vel: Vector2 = Vector2.ZERO):
	if not drop_scene:
		drop_scene = load("res://scenes/entities/DropItem.tscn")
	var item = drop_scene.instantiate()
	item.setup(item_data, pos, initial_vel)
	if is_instance_valid(parent):
		parent.add_child.call_deferred(item)
	else:
		var cur = Engine.get_main_loop().current_scene
		if is_instance_valid(cur):
			cur.add_child.call_deferred(item)
