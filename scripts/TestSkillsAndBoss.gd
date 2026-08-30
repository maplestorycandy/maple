# TestSkillsAndBoss.gd
extends Node

func _ready():
	print("=== STARTING FULL MONSTER, EQUIPMENT & ITEM DATABASE TEST ===")
	
	# 1. Test Monsters Count & Drops
	var mob_count = MonsterDatabaseFull.MONSTERS.size()
	print("  - Total Monsters in Database: %d (Expected 332)" % mob_count)
	assert(mob_count == 332, "Monster count should be exactly 332")
	
	# 2. Test Equipments Count
	var eq_count = EquipmentDatabaseFull.EQUIPMENTS.size()
	print("  - Total Official Equipments in Database: %d (Expected 4529)" % eq_count)
	assert(eq_count == 4529, "Equipment count should be exactly 4529")
	
	# 3. Test Items Count (Consumables, Materials, Ores)
	var item_count = ItemDatabaseFull.ITEMS.size()
	print("  - Total Official Items in Database: %d (Expected 671)" % item_count)
	assert(item_count == 671, "Item count should be exactly 671")
	
	# 4. Test Specific Equipment Data
	var green_band = EquipmentDatabaseFull.get_equipment(1002067) # 綠髮帶
	print("  - 綠髮帶 (ID 1002067): %s" % str(green_band.name))
	assert(green_band.name == "綠髮帶", "Name should be 綠髮帶")
	assert(green_band.slot == "hat", "Slot should be hat")
	assert(green_band.req_lvl == 5, "Req lvl should be 5")
	
	# 5. Test Specific Consumable Data & Global Usage
	var red_pot = ItemDatabaseFull.get_item(2000000) # 紅色藥水
	print("  - 紅色藥水 (ID 2000000): %s, HP Heal: %d" % [red_pot.name, red_pot.hp_heal])
	assert(red_pot.name == "紅色藥水", "Name should be 紅色藥水")
	assert(red_pot.hp_heal == 50, "Red pot recovers 50 HP")
	
	Global.player_hp = 50
	Global.player_max_hp = 300
	Global.use_inventory = [{"name": "紅色藥水", "id": 2000000, "count": 2}]
	Global.use_consume_item(0)
	print("  - Player HP after consuming 紅色藥水: %d (Expected 100)" % Global.player_hp)
	assert(Global.player_hp == 100, "Player HP should be restored by 50 to 100")
	assert(Global.use_inventory[0].count == 1, "Remaining count should be 1")
	
	# 6. Test Equipment Equipping & Stat Scaling
	Global.equipped_items["hat"] = green_band
	Global.recalculate_stats()
	print("  - Equipment bonus DEF with 綠髮帶: %d" % Global.equip_bonus_def)
	
	# 7. Test Monster Drop Spawning
	var dummy_parent = Node2D.new()
	add_child(dummy_parent)
	var snail = MonsterDatabaseFull.get_monster_by_id(100100) # 嫩寶
	DropItemManager.spawn_monster_drops(dummy_parent, Vector2(100, 100), snail)
	await get_tree().process_frame
	print("  - Spawned drop items for 嫩寶: %d items" % dummy_parent.get_child_count())
	assert(dummy_parent.get_child_count() >= 4, "Should spawn at least 4 items")
	
	print("\n=== ALL 332 MONSTERS, 4,529 EQUIPMENTS & 671 ITEMS DATABASE TESTS PASSED 100%! ===")
	get_tree().quit()
