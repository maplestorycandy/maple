# Global.gd
extends Node

signal player_hp_changed(current: int, max_hp: int)
signal player_mp_changed(current: int, max_mp: int)
signal player_exp_changed(current: int, max_exp: int, level: int)
signal player_job_changed(job_data: Dictionary)
signal player_stats_changed()
signal player_sp_changed(available_sp: int)
signal skill_points_allocated(skill_id: String, level: int)
signal equipment_scrolled(result: Dictionary)
signal boss_hp_updated(boss_name: String, current_hp: int, max_hp: int, is_alive: bool)
signal inventory_updated()
signal equipment_updated()
signal goddess_hp_changed(current: int, max_hp: int)
signal wave_changed(current_wave: int, max_wave: int)
signal pet_inventory_updated()
signal pet_summoned(pet_data: Dictionary)
signal pet_unsummoned()
signal message_broadcast(text: String, color: Color)
signal game_over_triggered(is_victory: bool)
signal map_change_requested(map_id: String)
signal skill_draft_requested(cards: Array)
signal keybindings_changed()
signal active_skills_updated()
signal skill_slots_changed()
signal player_cast_skill_requested(skill_id: String)

var equipped_skill_slots: Dictionary = {
	"slot_1": "skill_1",
	"slot_2": "skill_2",
	"slot_3": "skill_3",
	"slot_4": "skill_4",
	"slot_5": "skill_5",
	"slot_6": "skill_6",
	"ultimate": "ultimate"
}

# Job & Character Stats
var player_job_id: String = "warrior"
var player_job_data: Dictionary = {}

var player_level: int = 1
var player_exp: int = 0
var player_max_exp: int = 100
var player_hp: int = 750
var player_max_hp: int = 750
var player_mp: int = 120
var player_max_mp: int = 120

# Classic 4 Attributes & AP Point Allocation
var stat_str: int = 25
var stat_dex: int = 12
var stat_int: int = 4
var stat_luk: int = 4
var available_ap: int = 0 # 5 AP per level gained
var available_sp: int = 3 # 3 SP per level gained (Classic Maple SP)
var player_skill_levels: Dictionary = {} # e.g. {"basic": 1, "skill_1": 1}

# Equipment Bonus Attributes
var equip_bonus_atk: int = 0
var equip_bonus_magic_atk: int = 0
var equip_bonus_def: int = 0
var equip_bonus_acc: int = 0
var equip_bonus_magic_acc: int = 0
var equip_bonus_avoid: int = 0
var equip_bonus_speed: float = 0.0
var equip_bonus_str: int = 0
var equip_bonus_dex: int = 0
var equip_bonus_int: int = 0
var equip_bonus_luk: int = 0

# Base Combat Stats
var weapon_atk: int = 42
var magic_atk: int = 5
var mastery: float = 0.60
var base_crit_rate: float = 0.15
var player_speed: float = 250.0
var touch_move_dir: float = 0.0
var meso_gold: int = 500

# Custom Keybinding System
var custom_keybindings: Dictionary = {
	"attack": KEY_Z,
	"jump": KEY_SPACE,
	"skill_1": KEY_X,
	"skill_2": KEY_C,
	"skill_3": KEY_V,
	"skill_4": KEY_B,
	"skill_5": KEY_N,
	"skill_6": KEY_M,
	"ultimate": KEY_F,
	"tame_monster": KEY_E,
	"summon_pet": KEY_R,
	"potion_hp": KEY_1,
	"potion_mp": KEY_2
}

var unlocked_skills: Array = ["basic", "skill_1", "skill_2", "skill_3"]
var drafted_passives: Array = []

var exp_rate_multiplier: float = 5.0 # 500% EXP Multiplier (5x)

# Inventory System (3 Categories: Equip, Use, Etc)
var equip_inventory: Array[Dictionary] = []
var use_inventory: Array[Dictionary] = []
var etc_inventory: Array[Dictionary] = []

# Equipped Slots
var equipped_items: Dictionary = {
	"weapon": null,
	"hat": null,
	"top": null,
	"bottom": null,
	"overall": null,
	"gloves": null,
	"shoes": null,
	"shield": null,
	"cape": null,
	"accessory": null
}

# Quick Potion Belt State
var quick_hp_potion_name: String = "紅色藥水"
var quick_mp_potion_name: String = "藍色藥水"
signal quick_potions_updated()

# Goddess Stats
var goddess_hp: int = 25000
var goddess_max_hp: int = 25000
var goddess_shield_active: bool = false

# Wave & Game State
var current_wave: int = 1
const MAX_WAVES: int = 50
var is_game_over: bool = false
var current_map_id: String = "100000000"

# Pet System
var pet_inventory: Array = []
var active_pet_data: Dictionary = {}
var active_pet_node: Node2D = null

# Active Passive Buffs
var passive_buffs: Dictionary = {
	"tame_mastery": false,
	"goddess_sanctuary": false,
	"chain_thunder": false,
	"speed_demon": false,
	"vampiric_drain": false,
	"crit_rate_boost": 0.0,
	"bonus_damage_mult": 1.0,
	"cooldown_reduction": 0.0
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_chinese_font()
	set_player_job("warrior")
	
	# Give starter equipment & potions
	give_starter_kit()

func setup_chinese_font():
	var font = load("res://assets/fonts/ChineseFont.ttf")
	if not font:
		var font_path = "res://assets/fonts/ChineseFont.ttf"
		if FileAccess.file_exists(font_path):
			var f = FontFile.new()
			f.data = FileAccess.get_file_as_bytes(font_path)
			font = f
	if font:
		ThemeDB.fallback_font = font

func give_starter_kit():
	# Starter Starter Pets & Consumables
	add_pet_to_inventory({
		"id": 2,
		"name": "藍寶 (夥伴)",
		"type": "Snail",
		"hp": 300,
		"max_hp": 300,
		"atk": 35,
		"speed": 120,
		"color": Color(0.2, 0.5, 0.9),
		"scale": 1.0,
		"level": 1
	})
	
	add_item_to_inventory("use", {"name": "白色藥水", "type": "potion", "heal_hp": 150, "count": 10})
	add_item_to_inventory("use", {"name": "藍色藥水", "type": "potion", "heal_mp": 80, "count": 10})
	
	# Starter Weapon
	add_item_to_inventory("equip", {
		"name": "初心者之劍",
		"slot": "weapon",
		"req_lvl": 1,
		"job": "劍士",
		"atk": 18,
		"str": 3
	})
	
	# Auto equip starter weapon
	equip_item(0)

# =========================================================================
# AP POINT ALLOCATION (STR / DEX / INT / LUK / HP / MP)
# =========================================================================
func allocate_ap(stat_name: String, amount: int = 1) -> bool:
	if available_ap < amount:
		return false
		
	available_ap -= amount
	match stat_name:
		"str":
			stat_str += amount
			player_max_hp += amount * 12
			player_hp = min(player_max_hp, player_hp + amount * 12)
		"dex":
			stat_dex += amount
		"int":
			stat_int += amount
			player_max_mp += amount * 8
			player_mp = min(player_max_mp, player_mp + amount * 8)
		"luk":
			stat_luk += amount
		"hp":
			player_max_hp += amount * 25
			player_hp = min(player_max_hp, player_hp + amount * 25)
		"mp":
			player_max_mp += amount * 18
			player_mp = min(player_max_mp, player_mp + amount * 18)
			
	recalculate_stats()
	emit_signal("player_stats_changed")
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	return true

func auto_allocate_ap():
	if available_ap <= 0:
		return
	var primary_stat = "str"
	var secondary_stat = "dex"
	
	match player_job_id:
		"warrior":
			primary_stat = "str"
			secondary_stat = "dex"
		"archer":
			primary_stat = "dex"
			secondary_stat = "str"
		"mage":
			primary_stat = "int"
			secondary_stat = "luk"
		"rogue":
			primary_stat = "luk"
			secondary_stat = "dex"
		"pirate":
			primary_stat = "str"
			secondary_stat = "dex"
			
	while available_ap >= 5:
		allocate_ap(primary_stat, 4)
		allocate_ap(secondary_stat, 1)
	while available_ap > 0:
		allocate_ap(primary_stat, 1)
		
	broadcast_message("⚡ 自動配點完成！已為【%s】分配最佳屬性！" % player_job_data.get("name", "職業"), Color.GOLD)

const SLOT_PRIORITY: Dictionary = {
	"weapon": 0,
	"hat": 1,
	"overall": 2,
	"gloves": 3,
	"shoes": 4,
	"shield": 5,
	"accessory": 6
}

# =========================================================================
# INVENTORY & EQUIPMENT MANAGEMENT (AUTO-SORT & STACKING)
# =========================================================================
func sort_equipment_inventory():
	equip_inventory.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var slot_a = SLOT_PRIORITY.get(a.get("slot", "weapon"), 99)
		var slot_b = SLOT_PRIORITY.get(b.get("slot", "weapon"), 99)
		if slot_a != slot_b:
			return slot_a < slot_b
		var lvl_a = a.get("req_lvl", 1)
		var lvl_b = b.get("req_lvl", 1)
		if lvl_a != lvl_b:
			return lvl_a < lvl_b
		return a.get("name", "") < b.get("name", "")
	)

func add_item_to_inventory(category: String, item: Dictionary) -> bool:
	# Redirect ammo to use inventory
	var raw_slot = str(item.get("slot", "")).to_lower()
	var raw_name = str(item.get("name", ""))
	if raw_slot in ["arrow", "bullet", "throwing-star", "stars"] or "Arrow" in raw_name or "Bullet" in raw_name or "Throwing-Star" in raw_name:
		category = "use"

	match category.to_lower():
		"equip", "equipment":
			var full_item = build_equipment_stats(item)
			# Auto-stacking only for un-scrolled items with same item name and slot
			if full_item.get("scroll_success_count", 0) == 0 and full_item.get("upgrade_slots_remaining", 7) == full_item.get("upgrade_slots_total", 7):
				for existing in equip_inventory:
					if existing.get("name", "") == full_item.get("name", "") and existing.get("slot", "") == full_item.get("slot", "") and existing.get("scroll_success_count", 0) == 0 and existing.get("upgrade_slots_remaining", 7) == existing.get("upgrade_slots_total", 7):
						existing["count"] = existing.get("count", 1) + item.get("count", 1)
						sort_equipment_inventory()
						emit_signal("inventory_updated")
						return true
					
			if equip_inventory.size() < 40:
				if not full_item.has("count"):
					full_item["count"] = 1
				equip_inventory.append(full_item)
				sort_equipment_inventory()
				emit_signal("inventory_updated")
				return true
		"use", "consumable":
			for existing in use_inventory:
				if existing.name == item.name:
					existing.count = existing.get("count", 1) + item.get("count", 1)
					emit_signal("inventory_updated")
					return true
			if use_inventory.size() < 40:
				var new_item = item.duplicate()
				if not new_item.has("count"):
					new_item["count"] = 1
				use_inventory.append(new_item)
				emit_signal("inventory_updated")
				return true
		"etc", "material":
			for existing in etc_inventory:
				if existing.name == item.name:
					existing.count = existing.get("count", 1) + item.get("count", 1)
					emit_signal("inventory_updated")
					return true
			if etc_inventory.size() < 40:
				var new_item = item.duplicate()
				if not new_item.has("count"):
					new_item["count"] = 1
				etc_inventory.append(new_item)
				emit_signal("inventory_updated")
				return true
	return false

func build_equipment_stats(base_item: Dictionary) -> Dictionary:
	var item = base_item.duplicate()
	var name = item.get("name", "裝備")
	var req_lvl = item.get("req_lvl", 1)
	var raw_slot = str(item.get("slot", "")).to_lower().strip_edges()
	var item_id_str = str(item.get("id", "0"))
	
	var slot = ""
	
	# 1. Check ID Prefix first for 100% Maple exact categorization
	if item_id_str.begins_with("110"):
		slot = "cape"
	elif item_id_str.begins_with("109"):
		slot = "shield"
	elif item_id_str.begins_with("101") or item_id_str.begins_with("102") or item_id_str.begins_with("103") or item_id_str.begins_with("111") or item_id_str.begins_with("112") or item_id_str.begins_with("113"):
		slot = "accessory"
	elif item_id_str.begins_with("100"):
		slot = "hat"
	elif item_id_str.begins_with("108"):
		slot = "gloves"
	elif item_id_str.begins_with("107"):
		slot = "shoes"
	elif item_id_str.begins_with("104"):
		slot = "top"
	elif item_id_str.begins_with("106"):
		slot = "bottom"
	elif item_id_str.begins_with("105"):
		slot = "overall"
	elif item_id_str.begins_with("13") or item_id_str.begins_with("14"):
		slot = "weapon"
		
	# 2. Check raw_slot if not determined
	if slot == "":
		if raw_slot in ["cape", "cloak"]:
			slot = "cape"
		elif raw_slot in ["shield"]:
			slot = "shield"
		elif raw_slot in ["accessory", "earring", "earrings", "ring", "pendant", "belt", "necklace", "eye", "face", "badge"]:
			slot = "accessory"
		elif raw_slot in ["hat", "cap", "helm", "headband", "hood"]:
			slot = "hat"
		elif raw_slot in ["top", "shirt"]:
			slot = "top"
		elif raw_slot in ["bottom", "pants", "skirt"]:
			slot = "bottom"
		elif raw_slot in ["overall", "dress", "robe", "suit", "mail"]:
			slot = "overall"
		elif raw_slot in ["gloves", "glove", "gauntlet", "wrist"]:
			slot = "gloves"
		elif raw_slot in ["shoes", "boots", "slipper", "sandals"]:
			slot = "shoes"
		elif raw_slot in ["weapon", "one_handed", "two_handed", "sword", "axe", "blunt", "spear", "polearm", "staff", "wand", "bow", "crossbow", "dagger", "claw", "knuckle", "gun", "cannon"]:
			slot = "weapon"
			
	# 3. Comprehensive keyword matching
	if slot == "":
		var lname = name.to_lower()
		if "披風" in name or "斗篷" in name or "cape" in lname or "cloak" in lname:
			slot = "cape"
		elif "盾" in name or "鍋蓋" in name or "shield" in lname:
			slot = "shield"
		elif "耳環" in name or "戒指" in name or "項鍊" in name or "墜飾" in name or "眼罩" in name or "腰帶" in name or "臉飾" in name or "earring" in lname or "ring" in lname or "pendant" in lname:
			slot = "accessory"
		elif "帽" in name or "頭巾" in name or "頭盔" in name or "羽冠" in name or "冠" in name or "hat" in lname or "helm" in lname:
			slot = "hat"
		elif "手套" in name or "護手" in name or "護腕" in name or "指套" in name or "glove" in lname or "gloves" in lname:
			slot = "gloves"
		elif "鞋" in name or "靴" in name or "shoe" in lname or "shoes" in lname or "boot" in lname or "boots" in lname:
			slot = "shoes"
		elif "套服" in name or "長袍" in name or "連身" in name or "overall" in lname or "robe" in lname:
			slot = "overall"
		elif "褲" in name or "裙" in name or "pants" in lname or "skirt" in lname:
			slot = "bottom"
		elif "上衣" in name or "短t" in name or "背心" in name or "鎧甲" in name or "戰甲" in name or "top" in lname:
			slot = "top"
		else:
			slot = "weapon"
		
	item["slot"] = slot
	
	# Generate realistic stat values based on level
	if slot == "weapon":
		item["atk"] = item.get("atk", int(15 + req_lvl * 1.8))
		item["magic_atk"] = item.get("magic_atk", int(req_lvl * 1.9) if "杖" in name else 0)
		item["str"] = item.get("str", int(req_lvl * 0.15))
		item["dex"] = item.get("dex", int(req_lvl * 0.15))
		item["int"] = item.get("int", int(req_lvl * 0.15) if "杖" in name else 0)
		item["luk"] = item.get("luk", int(req_lvl * 0.15) if "短刀" in name or "手甲" in name else 0)
	else:
		item["def"] = item.get("def", int(8 + req_lvl * 1.2))
		item["str"] = item.get("str", max(1, int(req_lvl * 0.1)))
		item["dex"] = item.get("dex", max(1, int(req_lvl * 0.1)))
		item["int"] = item.get("int", max(1, int(req_lvl * 0.1)))
		item["luk"] = item.get("luk", max(1, int(req_lvl * 0.1)))
		if slot == "shoes":
			item["speed"] = item.get("speed", 5.0 + float(req_lvl) * 0.2)
			
	# Initialize Scroll & Upgrade Slot Properties
	item["upgrade_slots_total"] = item.get("upgrade_slots_total", 7)
	item["upgrade_slots_remaining"] = item.get("upgrade_slots_remaining", item["upgrade_slots_total"])
	item["scroll_success_count"] = item.get("scroll_success_count", 0)
	item["bonus_stats"] = item.get("bonus_stats", {})
			
	return item

# =========================================================================
# MAPLESTORY SCROLL ENHANCEMENT SYSTEM (衝裝系統)
# =========================================================================
func apply_scroll_to_equipment(scroll_idx_in_use: int, target_type: String, target_key) -> Dictionary:
	if scroll_idx_in_use < 0 or scroll_idx_in_use >= use_inventory.size():
		return {"success": false, "reason": "找不到該卷軸！"}
		
	var scroll_item = use_inventory[scroll_idx_in_use]
	var scroll_data = ScrollDatabase.get_scroll_by_name(scroll_item.get("name", ""))
	if scroll_data.is_empty():
		scroll_data = ScrollDatabase.get_scroll(scroll_item.get("id", ""))
	if scroll_data.is_empty():
		scroll_data = scroll_item
		
	var target_equip: Dictionary = {}
	if target_type == "equipped":
		if not equipped_items.has(target_key) or equipped_items[target_key] == null:
			return {"success": false, "reason": "目標裝備欄為空！"}
		target_equip = equipped_items[target_key]
	else:
		var idx = int(target_key)
		if idx < 0 or idx >= equip_inventory.size():
			return {"success": false, "reason": "找不到目標裝備！"}
		target_equip = equip_inventory[idx]
		
	# Check remaining upgrade slots
	var remaining_slots = target_equip.get("upgrade_slots_remaining", 7)
	if remaining_slots <= 0:
		return {"success": false, "reason": "【%s】已無剩餘可升級次數！" % target_equip.get("name", "裝備")}
		
	# Check slot compatibility
	if not ScrollDatabase.is_scroll_compatible_with_equip(scroll_data, target_equip):
		return {"success": false, "reason": "【%s】無法套用於【%s】！部位不符。" % [scroll_data.get("name", "卷軸"), target_equip.get("name", "裝備")]}
		
	# Deduct scroll from use inventory
	scroll_item["count"] = scroll_item.get("count", 1) - 1
	if scroll_item["count"] <= 0:
		use_inventory.remove_at(scroll_idx_in_use)
	emit_signal("inventory_updated")
	
	# Roll Success / Failure
	var rate = scroll_data.get("rate", 60)
	var roll = randi_range(1, 100)
	var is_success = roll <= rate
	var is_cursed = scroll_data.get("is_cursed", false) or rate in [30, 70]
	var is_destroyed = false
	
	target_equip["upgrade_slots_remaining"] = remaining_slots - 1
	
	if is_success:
		target_equip["scroll_success_count"] = target_equip.get("scroll_success_count", 0) + 1
		var b_stats = target_equip.get("bonus_stats", {})
		var scroll_stats = scroll_data.get("stats", {})
		for k in scroll_stats.keys():
			var val = scroll_stats[k]
			b_stats[k] = b_stats.get(k, 0) + val
			target_equip[k] = target_equip.get(k, 0) + val
		target_equip["bonus_stats"] = b_stats
		
		recalculate_stats()
		emit_signal("equipment_updated")
		emit_signal("inventory_updated")
		emit_signal("player_stats_changed")
		
		var succ_cnt = target_equip["scroll_success_count"]
		var res_dict = {
			"success": true,
			"is_destroyed": false,
			"message": "✨ 衝裝大成功！【%s】強化至 (+%d)！能力值全面提升！" % [target_equip.get("name", "裝備"), succ_cnt],
			"equip": target_equip,
			"scroll_name": scroll_data.get("name", "卷軸")
		}
		emit_signal("equipment_scrolled", res_dict)
		broadcast_message("★ 恭喜！【%s】衝裝成功 (+%d)！" % [target_equip.get("name", "裝備"), succ_cnt], Color(1.0, 0.85, 0.2))
		return res_dict
	else:
		# Failure roll
		if is_cursed and randf() < 0.50:
			# Cursed destruction
			is_destroyed = true
			if target_type == "equipped":
				equipped_items[target_key] = null
			else:
				equip_inventory.remove_at(int(target_key))
				
			recalculate_stats()
			emit_signal("equipment_updated")
			emit_signal("inventory_updated")
			emit_signal("player_stats_changed")
			
			var res_dict = {
				"success": false,
				"is_destroyed": true,
				"message": "💥 詛咒發作！【%s】在黑暗力量中化為灰燼損毀消失了！" % target_equip.get("name", "裝備"),
				"equip": {},
				"scroll_name": scroll_data.get("name", "卷軸")
			}
			emit_signal("equipment_scrolled", res_dict)
			broadcast_message("☠ 詛咒爆裝！【%s】損毀消失！" % target_equip.get("name", "裝備"), Color.RED)
			return res_dict
		else:
			# Normal failure
			recalculate_stats()
			emit_signal("equipment_updated")
			emit_signal("inventory_updated")
			emit_signal("player_stats_changed")
			
			var res_dict = {
				"success": false,
				"is_destroyed": false,
				"message": "💨 強化失敗！卷軸化為一縷灰煙，扣除了 1 次升級次數（剩餘 %d 次）。" % target_equip["upgrade_slots_remaining"],
				"equip": target_equip,
				"scroll_name": scroll_data.get("name", "卷軸")
			}
			emit_signal("equipment_scrolled", res_dict)
			broadcast_message("💨 衝裝失敗！【%s】扣除 1 次升級次數。" % target_equip.get("name", "裝備"), Color(0.7, 0.7, 0.7))
			return res_dict

# =========================================================================
# BINOMIAL DISTRIBUTION SCROLL PROBABILITY CALCULATOR
# https://bobogameguides.com/maplestory-classic/guides/scroll-calculator.html
# =========================================================================
static func combination(n: int, k: int) -> float:
	if k < 0 or k > n:
		return 0.0
	if k == 0 or k == n:
		return 1.0
	k = min(k, n - k)
	var c = 1.0
	for i in range(k):
		c = c * float(n - i) / float(i + 1)
	return c

static func calculate_scroll_probabilities(total_slots: int, success_rate_pct: float, want_success_count: int, unit_price: int = 0) -> Dictionary:
	total_slots = clamp(total_slots, 1, 30)
	var p = clamp(success_rate_pct / 100.0, 0.0, 1.0)
	want_success_count = clamp(want_success_count, 0, total_slots)
	
	var distribution: Array[Dictionary] = []
	var expected_success: float = float(total_slots) * p
	var at_least_prob: float = 0.0
	var max_prob: float = -1.0
	var mode_k: int = 0
	
	for k in range(total_slots + 1):
		var prob: float = 0.0
		if p >= 1.0:
			prob = 1.0 if k == total_slots else 0.0
		elif p <= 0.0:
			prob = 1.0 if k == 0 else 0.0
		else:
			prob = combination(total_slots, k) * pow(p, k) * pow(1.0 - p, total_slots - k)
			
		distribution.append({
			"k": k,
			"probability": prob,
			"pct": prob * 100.0
		})
		
		if prob > max_prob:
			max_prob = prob
			mode_k = k
			
		if k >= want_success_count:
			at_least_prob += prob
			
	var expected_cost = total_slots * unit_price
	
	return {
		"total_slots": total_slots,
		"rate_pct": success_rate_pct,
		"want_k": want_success_count,
		"expected_success": expected_success,
		"at_least_prob_pct": at_least_prob * 100.0,
		"mode_k": mode_k,
		"expected_cost": expected_cost,
		"distribution": distribution
	}

func equip_item(inv_index: int) -> bool:
	if inv_index < 0 or inv_index >= equip_inventory.size():
		return false
		
	var item = equip_inventory[inv_index]
	var req_lvl = item.get("req_lvl", 1)
	if player_level < req_lvl:
		broadcast_message("❌ 等級不足！需要 Lv.%d 才能穿戴【%s】！" % [req_lvl, item.name], Color.RED)
		return false
		
	var slot = item.get("slot", "weapon")
	var cur_count = item.get("count", 1)
	var single_item = item.duplicate()
	single_item["count"] = 1
	
	# Decrement stack count or remove
	if cur_count > 1:
		item["count"] = cur_count - 1
	else:
		equip_inventory.remove_at(inv_index)
	
	# If slot already has equipped item, swap back to inventory
	if equipped_items[slot] != null:
		add_item_to_inventory("equip", equipped_items[slot])
		
	equipped_items[slot] = single_item
	
	sort_equipment_inventory()
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("⚔️ 已穿戴【%s】！屬性已即時實裝！" % single_item.name, Color(0.3, 1.0, 0.5))
	return true

func unequip_item(slot: String) -> bool:
	if not equipped_items.has(slot) or equipped_items[slot] == null:
		return false
		
	var item = equipped_items[slot]
	equipped_items[slot] = null
	add_item_to_inventory("equip", item)
	
	sort_equipment_inventory()
	recalculate_stats()
	emit_signal("inventory_updated")
	emit_signal("equipment_updated")
	emit_signal("player_stats_changed")
	broadcast_message("卸下裝備【%s】。" % item.name, Color.WHITE)
	return true

func use_consume_item(inv_index: int) -> bool:
	if inv_index < 0 or inv_index >= use_inventory.size():
		return false
		
	var item = use_inventory[inv_index]
	var item_name = item.get("name", "")
	var item_id = item.get("id", -1)
	
	var official_item = {}
	if item_id > 0:
		official_item = ItemDatabaseFull.get_item(item_id)
	if official_item.is_empty():
		official_item = ItemDatabaseFull.get_item_by_name(item_name)
		
	var hp_heal = official_item.get("hp_heal", 0)
	var mp_heal = official_item.get("mp_heal", 0)
	
	if "超級藥水" in item_name:
		heal_player(player_max_hp)
		player_mp = player_max_mp
		emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("🌟 使用【超級藥水】: HP 與 MP 全部完全恢復！", Color.GOLD)
	elif hp_heal > 0 or mp_heal > 0:
		if hp_heal > 0:
			heal_player(hp_heal)
		if mp_heal > 0:
			player_mp = min(player_max_mp, player_mp + mp_heal)
			emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("★ 使用【%s】: 恢復 %d HP / %d MP！" % [item_name, hp_heal, mp_heal], Color(0.2, 1.0, 0.4))
	elif "白色" in item_name:
		heal_player(300)
		broadcast_message("★ 使用【%s】: 恢復 300 HP！" % item_name, Color(0.2, 1.0, 0.4))
	elif "藍色" in item_name:
		player_mp = min(player_max_mp, player_mp + 100)
		emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("★ 使用【%s】: 恢復 100 MP！" % item_name, Color(0.3, 0.8, 1.0))
	elif "紅色" in item_name:
		heal_player(50)
		broadcast_message("★ 使用【%s】: 恢復 50 HP！" % item_name, Color(0.2, 1.0, 0.4))
	elif "青蘋果" in item_name or "蘋果" in item_name:
		heal_player(20)
		broadcast_message("★ 使用【%s】: 恢復 20 HP！" % item_name, Color(0.4, 1.0, 0.5))
	else:
		heal_player(100)
		player_mp = min(player_max_mp, player_mp + 50)
		emit_signal("player_mp_changed", player_mp, player_max_mp)
		broadcast_message("★ 使用【%s】！" % item_name, Color.CYAN)
		
	item.count -= 1
	if item.count <= 0:
		use_inventory.remove_at(inv_index)
		
	emit_signal("inventory_updated")
	emit_signal("quick_potions_updated")
	return true

func get_quick_hp_potion_info() -> Dictionary:
	var total = 0
	var found_name = quick_hp_potion_name
	for it in use_inventory:
		var iname = it.get("name", "")
		if iname == quick_hp_potion_name or ("紅" in iname or "白" in iname or "超級" in iname or "HP" in iname or "蘋果" in iname or "水" in iname):
			total += it.get("count", 1)
			if found_name == "":
				found_name = iname
	return {"name": found_name, "count": total}

func get_quick_mp_potion_info() -> Dictionary:
	var total = 0
	var found_name = quick_mp_potion_name
	for it in use_inventory:
		var iname = it.get("name", "")
		if iname == quick_mp_potion_name or ("藍" in iname or "超級" in iname or "MP" in iname or "特水" in iname or "水" in iname):
			total += it.get("count", 1)
			if found_name == "":
				found_name = iname
	return {"name": found_name, "count": total}

func use_quick_hp_potion() -> bool:
	for i in range(use_inventory.size()):
		var it = use_inventory[i]
		var iname = it.get("name", "")
		if iname == quick_hp_potion_name or ("紅" in iname or "白" in iname or "超級" in iname or "HP" in iname or "蘋果" in iname or "水" in iname):
			use_consume_item(i)
			emit_signal("quick_potions_updated")
			return true
	broadcast_message("⚠️ 背包內無可用【補血 HP 藥水】！", Color.SALMON)
	return false

func use_quick_mp_potion() -> bool:
	for i in range(use_inventory.size()):
		var it = use_inventory[i]
		var iname = it.get("name", "")
		if iname == quick_mp_potion_name or ("藍" in iname or "超級" in iname or "MP" in iname or "特水" in iname or "水" in iname):
			use_consume_item(i)
			emit_signal("quick_potions_updated")
			return true
	broadcast_message("⚠️ 背包內無可用【補魔 MP 藥水】！", Color.SALMON)
	return false

func recalculate_stats():
	# Reset equipment bonuses
	equip_bonus_atk = 0
	equip_bonus_magic_atk = 0
	equip_bonus_def = 0
	equip_bonus_acc = 0
	equip_bonus_magic_acc = 0
	equip_bonus_avoid = 0
	equip_bonus_speed = 0.0
	equip_bonus_str = 0
	equip_bonus_dex = 0
	equip_bonus_int = 0
	equip_bonus_luk = 0
	
	for slot in equipped_items.keys():
		var eq = equipped_items[slot]
		if eq != null:
			equip_bonus_atk += eq.get("watk", eq.get("atk", 0))
			equip_bonus_magic_atk += eq.get("matk", eq.get("magic_atk", 0))
			equip_bonus_def += eq.get("wdef", eq.get("def", 0))
			equip_bonus_acc += eq.get("acc", eq.get("accuracy", 0))
			equip_bonus_magic_acc += eq.get("magic_acc", eq.get("magic_accuracy", 0))
			equip_bonus_avoid += eq.get("avoid", eq.get("eva", 0))
			equip_bonus_speed += float(eq.get("speed", 0.0))
			equip_bonus_str += eq.get("str", 0)
			equip_bonus_dex += eq.get("dex", 0)
			equip_bonus_int += eq.get("int", 0)
			equip_bonus_luk += eq.get("luk", 0)
			
	# Total effective stats
	var total_str = stat_str + equip_bonus_str
	var total_dex = stat_dex + equip_bonus_dex
	var total_int = stat_int + equip_bonus_int
	var total_luk = stat_luk + equip_bonus_luk
	
	# Base level attack scaling (Every level makes you noticeably stronger!)
	var lvl_atk_bonus = player_level * 8
	
	# Update Attack Power based on Job Primary & Secondary Stat formulas (Infinitely scaling with AP & Equips!)
	match player_job_id:
		"warrior":
			weapon_atk = int((total_str * 4.2 + total_dex * 1.5) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"archer":
			weapon_atk = int((total_dex * 4.4 + total_str * 1.3) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"mage":
			magic_atk = int((total_int * 4.5 + total_luk * 1.5) * 1.7) + int(equip_bonus_magic_atk * 2.8) + (player_level * 10) + 60
			weapon_atk = int((total_str + total_dex) * 1.0) + equip_bonus_atk + 20
		"rogue":
			weapon_atk = int((total_luk * 4.6 + total_dex * 1.6) * 1.7) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 50
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		"pirate":
			weapon_atk = int((total_str * 4.2 + total_dex * 1.5) * 1.6) + int(equip_bonus_atk * 2.5) + lvl_atk_bonus + 45
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
		_:
			weapon_atk = int((total_str * 3.0 + total_dex * 1.2) * 1.2) + equip_bonus_atk + lvl_atk_bonus + 30
			magic_atk = int(total_int * 2.0) + equip_bonus_magic_atk
			
	player_speed = 250.0 + equip_bonus_speed + (50.0 if passive_buffs.get("speed_demon", false) else 0.0)
	base_crit_rate = clamp(0.15 + (float(total_luk) * 0.005) + passive_buffs.get("crit_rate_boost", 0.0), 0.15, 0.95)

# =========================================================================
# MAPLESTORY ACCURACY & HIT RATE FORMULAS (新楓之谷經典版官方命中門檻機制)
# https://bobogameguides.com/maplestory-classic/tools/accuracy/
# =========================================================================
func get_player_physical_accuracy() -> int:
	var total_dex = stat_dex + equip_bonus_dex
	var total_luk = stat_luk + equip_bonus_luk
	return int(float(total_dex) * 0.8 + float(total_luk) * 0.5) + equip_bonus_acc

func get_player_magic_accuracy() -> int:
	var total_int = stat_int + equip_bonus_int
	var total_luk = stat_luk + equip_bonus_luk
	return int(floor(float(total_int) / 10.0) + floor(float(total_luk) / 10.0)) + equip_bonus_magic_acc

func get_player_avoidability() -> int:
	var total_dex = stat_dex + equip_bonus_dex
	var total_luk = stat_luk + equip_bonus_luk
	return int(float(total_luk) * 0.5 + float(total_dex) * 0.25) + equip_bonus_avoid

func calculate_physical_accuracy_threshold(mob_level: int, mob_avoid: int) -> Dictionary:
	var D = max(0, mob_level - player_level)
	var threshold = 0
	if mob_avoid > 0:
		threshold = int(ceil((55.2 + 2.15 * float(D)) * (float(mob_avoid) / 15.0)))
	var cur_acc = get_player_physical_accuracy()
	var gap = max(0, threshold - cur_acc)
	var hit_rate = 1.0 if (threshold == 0 or cur_acc >= threshold) else clamp(float(cur_acc) / float(max(1, threshold)), 0.05, 0.99)
	return {
		"threshold": threshold,
		"current": cur_acc,
		"gap": gap,
		"diff": D,
		"hit_rate": hit_rate,
		"is_sufficient": (cur_acc >= threshold or threshold == 0)
	}

func calculate_magic_accuracy_threshold(mob_level: int, mob_avoid: int) -> Dictionary:
	var D = max(0, mob_level - player_level)
	var threshold = int(floor((float(mob_avoid) + 1.0) * (1.0 + 0.04 * float(D))))
	var cur_acc = get_player_magic_accuracy()
	var gap = max(0, threshold - cur_acc)
	var hit_rate = 1.0 if cur_acc >= threshold else clamp(float(cur_acc) / float(max(1, threshold)), 0.05, 0.99)
	return {
		"threshold": threshold,
		"current": cur_acc,
		"gap": gap,
		"diff": D,
		"hit_rate": hit_rate,
		"is_sufficient": (cur_acc >= threshold)
	}

func check_attack_hit_against_mob(mob_level: int, mob_avoid: int, is_magic: bool = false) -> bool:
	var calc = calculate_magic_accuracy_threshold(mob_level, mob_avoid) if is_magic else calculate_physical_accuracy_threshold(mob_level, mob_avoid)
	if calc.hit_rate >= 1.0:
		return true
	return randf() <= calc.hit_rate

# =========================================================================
# JOB, SP SKILL ALLOCATION & LEVELING SYSTEM
# =========================================================================
func set_player_job(job_id: String):
	if not JobDatabase.JOBS.has(job_id):
		return
	player_job_id = job_id
	player_job_data = JobDatabase.JOBS[job_id]
	
	# Initialize skill levels for this job if not already present
	var job_skills = player_job_data.get("skills", {})
	for s_key in job_skills.keys():
		if not player_skill_levels.has(s_key):
			player_skill_levels[s_key] = 1
			
	# Update Job Initial Base Attributes
	var b_stats = player_job_data.get("base_stats", {})
	stat_str = b_stats.get("str", player_job_data.get("str", 25))
	stat_dex = b_stats.get("dex", player_job_data.get("dex", 15))
	stat_int = b_stats.get("int", player_job_data.get("int", 10))
	stat_luk = b_stats.get("luk", player_job_data.get("luk", 10))
	
	player_max_hp = b_stats.get("hp", player_job_data.get("base_hp", 650)) + (player_level - 1) * 80
	player_hp = player_max_hp
	player_max_mp = b_stats.get("mp", player_job_data.get("base_mp", 150)) + (player_level - 1) * 40
	player_mp = player_max_mp
	
	recalculate_stats()
	emit_signal("player_job_changed", player_job_data)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_sp_changed", available_sp)
	emit_signal("player_stats_changed")

func equip_skill_to_slot(slot_name: String, skill_id: String):
	equipped_skill_slots[slot_name] = skill_id
	emit_signal("skill_slots_changed")
	var s_data = player_job_data.get("skills", {}).get(skill_id, {})
	var s_name = s_data.get("name", skill_id)
	var slot_display = slot_name.replace("slot_1", "快捷鍵 1 (Z)").replace("slot_2", "快捷鍵 2 (C)").replace("slot_3", "快捷鍵 3 (V)").replace("slot_4", "快捷鍵 4 (A)").replace("slot_5", "快捷鍵 5 (S)").replace("slot_6", "快捷鍵 6 (D)").replace("ultimate", "奧義鍵 (F)")
	broadcast_message("⚡ 已將【%s】配置到【%s】！" % [s_name, slot_display], Color(0.3, 0.9, 1.0))

func request_cast_skill(skill_id: String):
	emit_signal("player_cast_skill_requested", skill_id)

func get_skill_level(skill_id: String) -> int:
	return player_skill_levels.get(skill_id, 1)

func get_player_skill_stats(skill_id: String) -> Dictionary:
	var lvl = get_skill_level(skill_id)
	return JobDatabase.get_skill_stats(player_job_id, skill_id, lvl)

func allocate_sp(skill_id: String, amount: int = 1) -> bool:
	if available_sp < amount:
		return false
		
	var job_skills = player_job_data.get("skills", {})
	if not job_skills.has(skill_id):
		return false
		
	var s_data = job_skills[skill_id]
	var max_l = s_data.get("max_lvl", 20)
	var cur_l = player_skill_levels.get(skill_id, 1)
	
	if cur_l >= max_l:
		broadcast_message("⚠️ 該技能已達最高等級 Lv.%d！" % max_l, Color.SALMON)
		return false
		
	var real_add = min(amount, max_l - cur_l)
	if real_add <= 0 or available_sp < real_add:
		return false
		
	available_sp -= real_add
	player_skill_levels[skill_id] = cur_l + real_add
	
	emit_signal("player_sp_changed", available_sp)
	emit_signal("skill_points_allocated", skill_id, player_skill_levels[skill_id])
	var updated_s = get_player_skill_stats(skill_id)
	broadcast_message("✨ 【%s】提升至 Lv.%d！傷害倍率: %d%%！" % [s_data.get("name", ""), player_skill_levels[skill_id], int(updated_s.get("multiplier", 1.0) * 100.0)], Color(0.3, 1.0, 0.6))
	return true

func auto_allocate_sp():
	if available_sp <= 0:
		return
		
	var job_skills = player_job_data.get("skills", {})
	# Prioritize skill_1, skill_2, skill_3, ultimate, skill_4, skill_5, skill_6
	var priority_keys = ["skill_1", "skill_2", "skill_3", "ultimate", "skill_4", "skill_5", "skill_6"]
	
	var changed = false
	while available_sp > 0:
		var allocated_in_round = false
		for k in priority_keys:
			if job_skills.has(k):
				var max_l = job_skills[k].get("max_lvl", 20)
				var cur_l = player_skill_levels.get(k, 1)
				if cur_l < max_l and available_sp > 0:
					var to_add = min(available_sp, 1)
					available_sp -= to_add
					player_skill_levels[k] = cur_l + to_add
					allocated_in_round = true
					changed = true
					if available_sp <= 0:
						break
		if not allocated_in_round:
			break
			
	if changed:
		emit_signal("player_sp_changed", available_sp)
		broadcast_message("⚡ 智慧配點完成！已為各主動核心技能分配技能點數！", Color.GOLD)

func reset_sp():
	var job_skills = player_job_data.get("skills", {})
	var total_refund = 0
	for k in job_skills.keys():
		var cur_l = player_skill_levels.get(k, 1)
		if cur_l > 1:
			total_refund += (cur_l - 1)
			player_skill_levels[k] = 1
	available_sp += total_refund
	emit_signal("player_sp_changed", available_sp)
	broadcast_message("🔄 技能點數已重置！已全數歸還 %d 點 SP！" % total_refund, Color.CYAN)

func add_exp(amount: int):
	var boosted_exp = int(amount * exp_rate_multiplier * passive_buffs.get("exp_gain_mult", 1.0))
	player_exp += boosted_exp
	while player_exp >= player_max_exp:
		player_exp -= player_max_exp
		level_up()
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)

func level_up():
	player_level += 1
	player_max_exp = int(player_max_exp * 1.35) + 30
	player_max_hp += 80
	player_hp = player_max_hp
	player_max_mp += 40
	player_mp = player_max_mp
	
	# Grant 5 AP and 3 SP per level (Classic Maple System)
	available_ap += 5
	available_sp += 3
	
	recalculate_stats()
	emit_signal("player_exp_changed", player_exp, player_max_exp, player_level)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("player_sp_changed", available_sp)
	emit_signal("player_stats_changed")
	broadcast_message("🎉 恭喜升級！Lv.%d！獲得 5 點能力值 (AP) 與 3 點技能點數 (SP)！" % player_level, Color.GOLD)
	
	# Every 5 levels, trigger 3-Choice Roguelike Skill Draft!
	if player_level % 5 == 0:
		var cards = generate_skill_draft_cards()
		emit_signal("skill_draft_requested", cards)

# =========================================================================
# BOSS HP MANAGEMENT & REPORTING
# =========================================================================
func report_boss_hp(boss_name: String, cur_hp: int, max_hp: int):
	emit_signal("boss_hp_updated", boss_name, cur_hp, max_hp, cur_hp > 0)

func report_boss_died(boss_name: String):
	emit_signal("boss_hp_updated", boss_name, 0, 1, false)

# =========================================================================
# 1.14.6 OFFICIAL WEAPON ATTACK POWER COEFFICIENTS & DAMAGE FORMULAS
# https://bobogameguides.com/maplestory-classic/tools/attack-power/
# =========================================================================
const WEAPON_COEFFICIENTS: Dictionary = {
	"one_sword": {"name": "單手劍", "main_stat": "str", "sub_stat": "dex", "min_coeff": 4.0, "max_coeff": 4.0, "note": "揮、刺相同"},
	"one_axe": {"name": "單手斧", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.2, "max_coeff": 4.4, "note": "刺 3.2；揮 4.4"},
	"one_blunt": {"name": "單手棍", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.2, "max_coeff": 4.4, "note": "刺 3.2；揮 4.4"},
	"dagger_thief": {"name": "短劍（盜賊）", "main_stat": "luk", "sub_stat": "str_dex", "min_coeff": 3.6, "max_coeff": 3.6, "note": "盜賊公式 (STR+DEX)"},
	"dagger_other": {"name": "短劍（其他職業）", "main_stat": "str", "sub_stat": "dex", "min_coeff": 4.0, "max_coeff": 4.0, "note": "非盜賊公式"},
	"wand_staff": {"name": "短杖／長杖（物理敲擊）", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.2, "max_coeff": 4.4, "note": "只算物理敲擊"},
	"two_sword": {"name": "雙手劍", "main_stat": "str", "sub_stat": "dex", "min_coeff": 4.6, "max_coeff": 4.6, "note": "揮、刺相同"},
	"two_axe": {"name": "雙手斧", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.4, "max_coeff": 4.8, "note": "刺 3.4；揮 4.8"},
	"two_blunt": {"name": "雙手棍", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.4, "max_coeff": 4.8, "note": "刺 3.4；揮 4.8"},
	"spear": {"name": "槍", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.0, "max_coeff": 5.0, "note": "揮 3.0；刺 5.0"},
	"polearm": {"name": "矛", "main_stat": "str", "sub_stat": "dex", "min_coeff": 3.0, "max_coeff": 5.0, "note": "刺 3.0；揮 5.0"},
	"bow": {"name": "弓", "main_stat": "dex", "sub_stat": "str", "min_coeff": 3.4, "max_coeff": 3.4, "note": "弓箭手專用"},
	"crossbow": {"name": "弩", "main_stat": "dex", "sub_stat": "str", "min_coeff": 3.6, "max_coeff": 3.6, "note": "弩弓手專用"},
	"claw": {"name": "拳套", "main_stat": "luk", "sub_stat": "str_dex", "min_coeff": 3.6, "max_coeff": 3.6, "note": "兩項副屬性 (STR+DEX)"},
	"knuckle": {"name": "指虎", "main_stat": "str", "sub_stat": "dex", "min_coeff": 4.8, "max_coeff": 4.8, "note": "海盜專用"},
	"gun": {"name": "火槍", "main_stat": "dex", "sub_stat": "str", "min_coeff": 3.6, "max_coeff": 3.6, "note": "海盜專用"}
}

func get_current_equipped_weapon_class() -> String:
	var wp = equipped_items.get("weapon", null)
	if wp == null:
		return "two_sword" if player_job_id == "warrior" else ("claw" if player_job_id == "thief" else ("bow" if player_job_id in ["bowman", "archer"] else "one_sword"))
		
	var wname = wp.get("name", "").to_lower()
	var wslot = wp.get("slot", "").to_lower()
	
	if "two-handed sword" in wslot or "雙手劍" in wname:
		return "two_sword"
	elif "two-handed axe" in wslot or "雙手斧" in wname:
		return "two_axe"
	elif "two-handed blunt" in wslot or "雙手棍" in wname or "雙手槌" in wname:
		return "two_blunt"
	elif "spear" in wslot or "槍" in wname:
		return "spear"
	elif "polearm" in wslot or "矛" in wname:
		return "polearm"
	elif "bow" in wslot or "弓" in wname:
		return "bow"
	elif "crossbow" in wslot or "弩" in wname:
		return "crossbow"
	elif "claw" in wslot or "拳套" in wname or "手甲" in wname:
		return "claw"
	elif "knuckle" in wslot or "指虎" in wname:
		return "knuckle"
	elif "gun" in wslot or "火槍" in wname or "短槍" in wname:
		return "gun"
	elif "dagger" in wslot or "短刀" in wname or "短劍" in wname:
		return "dagger_thief" if player_job_id in ["thief", "rogue"] else "dagger_other"
	elif "wand" in wslot or "staff" in wslot or "杖" in wname:
		return "wand_staff"
	elif "one-handed axe" in wslot or "單手斧" in wname:
		return "one_axe"
	elif "one-handed blunt" in wslot or "單手棍" in wname or "單手槌" in wname:
		return "one_blunt"
	else:
		return "one_sword"

func calculate_weapon_attack_power_range(w_key: String, str_val: int, dex_val: int, luk_val: int, total_watk: int, mastery_pct: float) -> Dictionary:
	var w_data = WEAPON_COEFFICIENTS.get(w_key, WEAPON_COEFFICIENTS["one_sword"])
	var main_val: float = 0.0
	var sub_val: float = 0.0
	
	match w_data.main_stat:
		"str": main_val = float(str_val)
		"dex": main_val = float(dex_val)
		"luk": main_val = float(luk_val)
		
	match w_data.sub_stat:
		"str": sub_val = float(str_val)
		"dex": sub_val = float(dex_val)
		"str_dex": sub_val = float(str_val + dex_val)
		
	var mastery_modifier = 0.9 * (mastery_pct / 100.0)
	var max_atk = int(floor(((w_data.max_coeff * main_val) + sub_val) * float(total_watk) / 100.0))
	var min_atk = int(floor(((w_data.min_coeff * main_val * mastery_modifier) + sub_val) * float(total_watk) / 100.0))
	
	return {
		"min_atk": max(1, min_atk),
		"max_atk": max(1, max_atk),
		"weapon_name": w_data.name,
		"main_stat": w_data.main_stat.to_upper(),
		"sub_stat": w_data.sub_stat.to_upper(),
		"min_coeff": w_data.min_coeff,
		"max_coeff": w_data.max_coeff,
		"mastery_modifier": mastery_modifier
	}

func calculate_player_damage(skill_multiplier: float = 1.0) -> Dictionary:
	var total_str = stat_str + equip_bonus_str
	var total_dex = stat_dex + equip_bonus_dex
	var total_int = stat_int + equip_bonus_int
	var total_luk = stat_luk + equip_bonus_luk
	
	# Current Mastery: 60% with full mastery skill
	var mastery_pct = clamp((mastery + passive_buffs.get("mastery_boost", 0.0)) * 100.0, 10.0, 90.0)
	
	var is_magic_job = (player_job_id in ["magician", "mage"])
	var min_base: float = 0.0
	var max_base: float = 0.0
	
	if is_magic_job:
		var matk_val = float(magic_atk)
		var effective_m = mastery_pct / 100.0
		max_base = (((float(total_int) * 4.0 + float(total_luk)) / 100.0) * (matk_val * 1.15) + float(weapon_atk)) * 0.85
		min_base = (((float(total_int) * 4.0 * effective_m + float(total_luk)) / 100.0) * (matk_val * 1.15) + float(weapon_atk)) * 0.85
	else:
		var w_class = get_current_equipped_weapon_class()
		var total_watk = max(10, weapon_atk + equip_bonus_atk)
		var atk_calc = calculate_weapon_attack_power_range(w_class, total_str, total_dex, total_luk, total_watk, mastery_pct)
		min_base = float(atk_calc.min_atk)
		max_base = float(atk_calc.max_atk)
		
	# Level bonus base power
	var lvl_bonus = float(player_level) * 12.0
	max_base += lvl_bonus
	min_base += lvl_bonus * (mastery_pct / 100.0)
	
	var raw_rolled = randf_range(min_base, max_base)
	var final_dmg = raw_rolled * skill_multiplier * passive_buffs.get("bonus_damage_mult", 1.0)
	
	# Check Crit
	var is_crit = randf() < base_crit_rate
	if is_crit:
		var crit_mult = randf_range(1.8, 2.4) + passive_buffs.get("crit_dmg_mult", 0.0)
		final_dmg *= crit_mult
		
	return {
		"damage": max(1, int(final_dmg)),
		"is_crit": is_crit
	}

func damage_player(amount: int):
	if is_game_over:
		return
		
	var p = get_tree().get_first_node_in_group("player")
	# Check Player Dodge / Avoidability based on LUK/DEX
	var total_luk = stat_luk + equip_bonus_luk
	var total_dex = stat_dex + equip_bonus_dex
	var avoid_rate = clamp(0.08 + float(total_luk + total_dex) * 0.0008, 0.08, 0.40)
	
	if randf() < avoid_rate:
		# Player Dodged / Evaded! Spawn Purple MISS
		if is_instance_valid(p):
			var dmg_scene = load("res://scenes/skills/DamageNumber.tscn")
			if dmg_scene:
				var num = dmg_scene.instantiate()
				num.global_position = p.global_position + Vector2(randf_range(-10, 10), -45)
				num.setup(0, false, false, false, 0, true) # is_miss = true
				get_tree().current_scene.add_child.call_deferred(num)
		return
		
	var net_dmg = max(1, amount - int(equip_bonus_def * 0.4))
	player_hp = max(0, player_hp - net_dmg)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	
	# Spawn Authentic Maple Purple Player Hurt Number over player
	if is_instance_valid(p):
		p.hurt_flash = 1.0
		var dmg_scene = load("res://scenes/skills/DamageNumber.tscn")
		if dmg_scene:
			var num = dmg_scene.instantiate()
			num.global_position = p.global_position + Vector2(randf_range(-10, 10), -45)
			num.setup(net_dmg, false, true, false, 0, false) # is_player_damage = true (Purple)
			get_tree().current_scene.add_child.call_deferred(num)
	
	if player_hp <= 0:
		broadcast_message("☠ 您已陣亡！5秒後在當前地圖復活...", Color.RED)
		var t = get_tree().create_timer(3.0)
		t.timeout.connect(func():
			player_hp = player_max_hp
			emit_signal("player_hp_changed", player_hp, player_max_hp)
			broadcast_message("★ 重獲新生！HP 全滿！", Color.GREEN)
		)

func heal_player(amount: int):
	player_hp = min(player_max_hp, player_hp + amount)
	emit_signal("player_hp_changed", player_hp, player_max_hp)

func damage_goddess(amount: int):
	if is_game_over or goddess_shield_active:
		return
	goddess_hp = max(0, goddess_hp - amount)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)
	
	if goddess_hp <= 0:
		trigger_game_over(false)

func heal_goddess(amount: int):
	goddess_hp = min(goddess_max_hp, goddess_hp + amount)
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)

func trigger_game_over(is_victory: bool):
	if is_game_over:
		return
	is_game_over = true
	emit_signal("game_over_triggered", is_victory)

func broadcast_message(text: String, color: Color = Color.WHITE):
	emit_signal("message_broadcast", text, color)

func add_pet_to_inventory(pet_data: Dictionary):
	pet_inventory.append(pet_data)
	emit_signal("pet_inventory_updated")

func remove_pet_from_inventory(index: int):
	if index >= 0 and index < pet_inventory.size():
		var pet = pet_inventory[index]
		if active_pet_data.get("name", "") == pet.get("name", ""):
			dismiss_active_pet()
		pet_inventory.remove_at(index)
		var reward_meso = max(10, int(pet.get("hp", 100) * 0.05))
		meso_gold += reward_meso
		emit_signal("pet_inventory_updated")
func calculate_skill_damage(multiplier: float) -> Dictionary:
	var base_dmg = float(weapon_atk) if player_job_id != "mage" else float(magic_atk)
	var mastery_min = mastery
	var rolled_mult = randf_range(mastery_min, 1.05)
	var is_crit = randf() < base_crit_rate
	
	var final_dmg = base_dmg * multiplier * rolled_mult * passive_buffs.get("bonus_damage_mult", 1.0)
	if is_crit:
		final_dmg *= randf_range(2.0, 2.5) # 200% ~ 250% Critical Strike
		
	return {
		"damage": max(1, int(final_dmg)),
		"is_crit": is_crit
	}

func summon_pet(pet_data: Dictionary):
	active_pet_data = pet_data
	emit_signal("pet_summoned", pet_data)
	broadcast_message("召喚寵物夥伴: 【%s】出戰！" % pet_data.get("name", "寵物"), Color(0.3, 1.0, 0.5))

func dismiss_active_pet():
	if not active_pet_data.is_empty():
		var p_name = active_pet_data.get("name", "寵物")
		active_pet_data = {}
		emit_signal("pet_unsummoned")
		if is_instance_valid(active_pet_node):
			active_pet_node.queue_free()
		broadcast_message("寵物【%s】已召回休息。" % p_name, Color.WHITE)

func select_active_pet(index: int):
	if index >= 0 and index < pet_inventory.size():
		summon_pet(pet_inventory[index])

func reset_game_state():
	is_game_over = false
	current_wave = 1
	goddess_hp = goddess_max_hp
	player_hp = player_max_hp
	player_mp = player_max_mp
	emit_signal("goddess_hp_changed", goddess_hp, goddess_max_hp)
	emit_signal("player_hp_changed", player_hp, player_max_hp)
	emit_signal("player_mp_changed", player_mp, player_max_mp)
	emit_signal("wave_changed", current_wave, MAX_WAVES)

func change_map(map_id: String):
	current_map_id = map_id
	emit_signal("map_change_requested", map_id)
	if MapDatabase.MAPS.has(map_id):
		broadcast_message("傳送至: %s" % MapDatabase.MAPS[map_id].name, Color(0.4, 0.8, 1.0))


# =========================================================================
# ROGUELIKE SKILL DRAFT & CUSTOM KEYBINDINGS
# =========================================================================
func generate_skill_draft_cards() -> Array:
	var job_skills = player_job_data.get("skills", {})
	var candidates: Array = []
	
	# 1. Active Skill Unlocks & Enhancements
	for s_key in ["skill_4", "skill_5", "skill_6", "ultimate"]:
		if job_skills.has(s_key):
			var s_data = job_skills[s_key]
			var is_new = not (s_key in unlocked_skills)
			candidates.append({
				"id": s_key,
				"category": "active_skill",
				"name": ("【新技能解鎖】" if is_new else "【技能覺醒升級】") + s_data.get("name", ""),
				"rarity": "Legendary" if s_key == "ultimate" else "Epic",
				"desc": s_data.get("desc", "獲得強大職業主動技能！"),
				"icon": "⚔️" if "slash" in str(s_data) else ("🏹" if "arrow" in str(s_data) else ("⚡" if "magic" in str(s_data) else "💥")),
				"skill_key": s_key
			})
			
	# 2. Job-Specific Passives
	match player_job_id:
		"warrior":
			candidates.append({"id": "warrior_combo", "category": "passive", "name": "鬥氣狂熱 ‧ 黑暗神兵", "rarity": "Legendary", "desc": "每次攻擊累積鬥氣，最終傷害乘算提升 +45%！", "icon": "🔥", "buff": {"bonus_damage_mult": 0.45}})
			candidates.append({"id": "final_attack", "category": "passive", "name": "終極攻擊 (Final Attack)", "rarity": "Epic", "desc": "攻擊時 30% 機率額外追加 280% 巨力重斬！", "icon": "⚔️", "buff": {"final_attack_rate": 0.30}})
		"magician":
			candidates.append({"id": "magic_amp", "category": "passive", "name": "元素增幅 ‧ 魔力無限", "rarity": "Legendary", "desc": "全魔法技能傷害 +50%，消耗 MP 減少 20%！", "icon": "🔮", "buff": {"magic_atk_mult": 0.50, "mp_cost_reduction": 0.20}})
			candidates.append({"id": "magic_drain", "category": "passive", "name": "魔力吸取 ‧ 永恆治癒", "rarity": "Epic", "desc": "每次命中敵人吸收造成傷害 12% 轉化為生命與魔力！", "icon": "✨", "buff": {"life_steal": 0.12}})
		"bowman":
			candidates.append({"id": "sharp_eyes", "category": "passive", "name": "會心之眼 (Sharp Eyes)", "rarity": "Legendary", "desc": "暴擊率 +30%，暴擊傷害乘算提升 +70%！", "icon": "🎯", "buff": {"crit_rate": 0.30, "crit_dmg_mult": 0.70}})
			candidates.append({"id": "wind_walker", "category": "passive", "name": "風靈使者 ‧ 極速神箭", "rarity": "Epic", "desc": "射速提升 35%，所有技能冷卻縮減 30%！", "icon": "🍃", "buff": {"cooldown_reduction": 0.30}})
		"thief":
			candidates.append({"id": "shadow_partner_passive", "category": "passive", "name": "影之夥伴 ‧ 雙重暗殺", "rarity": "Legendary", "desc": "影分身常駐召喚！全攻擊額外造成 100% 獨立真實傷害！", "icon": "👤", "buff": {"shadow_partner_active": true}})
			candidates.append({"id": "deadly_poison", "category": "passive", "name": "致命劇毒 ‧ 刺客信條", "rarity": "Epic", "desc": "暴擊率 +25%，每次攻擊附帶劇毒持續扣血！", "icon": "🗡️", "buff": {"crit_rate": 0.25, "poison_touch": true}})
		"pirate":
			candidates.append({"id": "pirate_supercharge", "category": "passive", "name": "超負荷充能 ‧ 鋼鐵之軀", "rarity": "Legendary", "desc": "物理攻擊力 +40%，受到傷害減免 35%！", "icon": "⚓", "buff": {"watk_mult": 0.40, "damage_reduction": 0.35}})
			candidates.append({"id": "battleship_support", "category": "passive", "name": "海賊大砲 ‧ 全自動火力", "rarity": "Epic", "desc": "戰艦自動每 4 秒向周圍敵人發射 400% 重砲轟炸！", "icon": "💣", "buff": {"auto_cannon": true}})

	# 3. Global Transcendent Buffs
	candidates.append({"id": "divine_wrath", "category": "passive", "name": "天神下凡 ‧ 萬雷神罰", "rarity": "Legendary", "desc": "每 3.5 秒自動召喚全螢幕天雷轟炸所有怪物 500% 傷害！", "icon": "⚡", "buff": {"auto_lightning": true}})
	candidates.append({"id": "blood_thirst", "category": "passive", "name": "嗜血狂魔 ‧ 越戰越勇", "rarity": "Epic", "desc": "每次攻擊吸血 8% MaxHP，移動速度 +35%！", "icon": "🩸", "buff": {"life_steal": 0.08, "speed_bonus": 35.0}})
	candidates.append({"id": "wealth_frenzy", "category": "passive", "name": "黃金財富 ‧ 雙倍掉落", "rarity": "Rare", "desc": "怪物掉落楓幣與稀有裝備機率 +100%！", "icon": "💰", "buff": {"double_drops": true}})
	candidates.append({"id": "stat_titan", "category": "passive", "name": "泰坦神力 ‧ 全屬性飛升", "rarity": "Epic", "desc": "力量、敏捷、智力、幸運全體直接暴增 +80 點！", "icon": "💎", "buff": {"all_stats": 80}})
	
	candidates.shuffle()
	return candidates.slice(0, 3)

func apply_draft_card(card: Dictionary):
	var cat = card.get("category", "")
	var name = card.get("name", "覺醒技能")
	
	if cat == "active_skill":
		var s_key = card.get("skill_key", "")
		if not (s_key in unlocked_skills):
			unlocked_skills.append(s_key)
			emit_signal("active_skills_updated")
			broadcast_message("🌟 成功覺醒解鎖全新技能：%s！" % name, Color(1.0, 0.85, 0.2))
		else:
			var s_data = player_job_data.get("skills", {}).get(s_key, {})
			s_data["multiplier"] = s_data.get("multiplier", 1.0) * 1.35
			broadcast_message("⚡ %s 威力提升 +35%！" % name, Color(0.3, 1.0, 0.5))
	else:
		drafted_passives.append(card)
		var buff = card.get("buff", {})
		for k in buff.keys():
			if k == "all_stats":
				stat_str += buff[k]
				stat_dex += buff[k]
				stat_int += buff[k]
				stat_luk += buff[k]
			elif typeof(buff[k]) == TYPE_FLOAT or typeof(buff[k]) == TYPE_INT:
				passive_buffs[k] = passive_buffs.get(k, 0.0) + buff[k]
			else:
				passive_buffs[k] = buff[k]
		recalculate_stats()
		broadcast_message("✨ 成功融合覺醒天賦【%s】！" % name, Color(0.4, 0.9, 1.0))

func rebind_key(action_name: String, key_code: int):
	custom_keybindings[action_name] = key_code
	emit_signal("keybindings_changed")
	save_keybindings()

func get_action_key_name(action_name: String) -> String:
	var code = custom_keybindings.get(action_name, KEY_Z)
	return OS.get_keycode_string(code)

func save_keybindings():
	var cfg = ConfigFile.new()
	for k in custom_keybindings.keys():
		cfg.set_value("keybindings", k, custom_keybindings[k])
	cfg.save("user://keybindings.cfg")

func load_keybindings():
	var cfg = ConfigFile.new()
	var err = cfg.load("user://keybindings.cfg")
	if err == OK:
		for k in custom_keybindings.keys():
			if cfg.has_section_key("keybindings", k):
				custom_keybindings[k] = cfg.get_value("keybindings", k)
