# MonsterDatabaseFull.gd
extends Node

const FULL_DATABASE = {
	# [生態 1: 楓葉草原 Lv.1~10] - 綠地與平原
	1: {"name": "綠水靈", "type": "Slime", "hp": 150, "atk": 15, "speed": 60, "ai": "hop", "scale": 1.0, "color": Color(0.2, 0.9, 0.2), "exp": 20, "meso": 15},
	2: {"name": "藍寶", "type": "Snail", "hp": 220, "atk": 18, "speed": 35, "ai": "crawl", "scale": 0.8, "color": Color(0.2, 0.5, 0.9), "exp": 28, "meso": 20},
	3: {"name": "紅寶", "type": "Snail", "hp": 310, "atk": 25, "speed": 40, "ai": "crawl", "scale": 0.9, "color": Color(0.9, 0.2, 0.2), "exp": 38, "meso": 28},
	4: {"name": "花菇菇", "type": "Mushroom", "hp": 420, "atk": 32, "speed": 55, "ai": "patrol", "scale": 1.0, "color": Color(0.9, 0.6, 0.2), "exp": 50, "meso": 35},
	5: {"name": "綠菇菇", "type": "Mushroom", "hp": 550, "atk": 40, "speed": 65, "ai": "patrol", "scale": 1.1, "color": Color(0.4, 0.8, 0.3), "exp": 65, "meso": 45},
	6: {"name": "藍水靈", "type": "Slime", "hp": 680, "atk": 48, "speed": 70, "ai": "hop", "scale": 1.0, "color": Color(0.1, 0.6, 1.0), "exp": 80, "meso": 55},
	7: {"name": "木妖", "type": "Wood", "hp": 850, "atk": 58, "speed": 45, "ai": "patrol", "scale": 1.2, "color": Color(0.5, 0.35, 0.2), "exp": 100, "meso": 70},
	8: {"name": "黑木妖", "type": "Wood", "hp": 1020, "atk": 68, "speed": 50, "ai": "patrol", "scale": 1.25, "color": Color(0.2, 0.2, 0.2), "exp": 120, "meso": 85},
	9: {"name": "漂漂豬", "type": "Beast", "hp": 1250, "atk": 80, "speed": 110, "ai": "charge", "scale": 1.0, "color": Color(1.0, 0.7, 0.8), "exp": 150, "meso": 105},
	10: {"name": "【Boss】菇菇王", "type": "Boss", "hp": 8000, "atk": 180, "speed": 40, "ai": "boss_stomp", "scale": 2.5, "color": Color(1.0, 0.4, 0.1), "exp": 1000, "meso": 800},

	# [生態 2: 勇士岩地與密林 Lv.11~20]
	11: {"name": "黑肥肥", "type": "Beast", "hp": 1500, "atk": 95, "speed": 120, "ai": "charge", "scale": 1.1, "color": Color(0.3, 0.3, 0.3), "exp": 180, "meso": 130},
	12: {"name": "刺菇菇", "type": "Undead", "hp": 1800, "atk": 110, "speed": 60, "ai": "patrol", "scale": 1.0, "color": Color(0.8, 0.7, 0.6), "exp": 220, "meso": 160},
	13: {"name": "殭屍菇菇", "type": "Undead", "hp": 2200, "atk": 130, "speed": 55, "ai": "patrol", "scale": 1.1, "color": Color(0.6, 0.8, 0.7), "exp": 270, "meso": 200},
	14: {"name": "蝙蝠", "type": "Fly", "hp": 1700, "atk": 145, "speed": 130, "ai": "fly_swoop", "scale": 0.8, "color": Color(0.4, 0.1, 0.5), "exp": 310, "meso": 230},
	15: {"name": "黑斧木妖", "type": "Wood", "hp": 2700, "atk": 160, "speed": 55, "ai": "melee_slash", "scale": 1.3, "color": Color(0.3, 0.2, 0.1), "exp": 360, "meso": 270},
	16: {"name": "黑角幼龍", "type": "Dragon", "hp": 3200, "atk": 185, "speed": 75, "ai": "patrol", "scale": 0.9, "color": Color(0.2, 0.4, 0.2), "exp": 420, "meso": 320},
	17: {"name": "火肥肥", "type": "Beast", "hp": 3800, "atk": 210, "speed": 125, "ai": "charge_burn", "scale": 1.1, "color": Color(0.9, 0.3, 0.1), "exp": 490, "meso": 380},
	18: {"name": "幼魔精靈", "type": "Fairy", "hp": 3400, "atk": 230, "speed": 90, "ai": "ranged_magic", "scale": 0.8, "color": Color(0.7, 0.2, 0.9), "exp": 560, "meso": 440},
	19: {"name": "石巨人", "type": "Golem", "hp": 5500, "atk": 260, "speed": 35, "ai": "heavy_smash", "scale": 1.8, "color": Color(0.6, 0.6, 0.6), "exp": 680, "meso": 550},
	20: {"name": "【Boss】巨型石巨人", "type": "Boss", "hp": 25000, "atk": 420, "speed": 30, "ai": "boss_quake", "scale": 3.2, "color": Color(0.4, 0.4, 0.4), "exp": 3500, "meso": 2500},

	# [生態 3: 廢棄都市與地下鐵道 Lv.21~30]
	21: {"name": "小幽靈", "type": "Ghost", "hp": 4500, "atk": 290, "speed": 80, "ai": "phase_through", "scale": 0.9, "color": Color(0.9, 0.9, 1.0), "exp": 750, "meso": 620},
	22: {"name": "大幽靈", "type": "Ghost", "hp": 5800, "atk": 330, "speed": 85, "ai": "phase_through", "scale": 1.2, "color": Color(0.8, 0.8, 0.95), "exp": 880, "meso": 720},
	23: {"name": "青蛇", "type": "Reptile", "hp": 5100, "atk": 310, "speed": 100, "ai": "poison_bite", "scale": 1.0, "color": Color(0.1, 0.7, 0.3), "exp": 960, "meso": 800},
	24: {"name": "紅蛇", "type": "Reptile", "hp": 6200, "atk": 360, "speed": 105, "ai": "poison_bite", "scale": 1.0, "color": Color(0.8, 0.1, 0.2), "exp": 1100, "meso": 920},
	25: {"name": "風獨眼獸", "type": "Eye", "hp": 7000, "atk": 390, "speed": 90, "ai": "jump_bite", "scale": 1.1, "color": Color(0.3, 0.8, 0.4), "exp": 1250, "meso": 1050},
	26: {"name": "黑洞眼獸", "type": "Eye", "hp": 8200, "atk": 430, "speed": 95, "ai": "jump_bite", "scale": 1.15, "color": Color(0.2, 0.2, 0.3), "exp": 1420, "meso": 1200},
	27: {"name": "泥人怪", "type": "Mud", "hp": 9800, "atk": 470, "speed": 45, "ai": "slow_aura", "scale": 1.4, "color": Color(0.4, 0.3, 0.2), "exp": 1600, "meso": 1380},
	28: {"name": "黑泥人怪", "type": "Mud", "hp": 11500, "atk": 520, "speed": 45, "ai": "slow_aura", "scale": 1.5, "color": Color(0.15, 0.15, 0.15), "exp": 1850, "meso": 1580},
	29: {"name": "蝙蝠魔幼體", "type": "Demon", "hp": 13000, "atk": 580, "speed": 110, "ai": "fly_shoot", "scale": 1.0, "color": Color(0.5, 0.0, 0.2), "exp": 2100, "meso": 1800},
	30: {"name": "【Boss】沼澤巨鱷", "type": "Boss", "hp": 65000, "atk": 850, "speed": 50, "ai": "boss_tail_whip", "scale": 3.0, "color": Color(0.2, 0.4, 0.2), "exp": 8000, "meso": 6000},

	# [生態 4: 奇幻村詛咒寺院 Lv.31~40]
	31: {"name": "冰獨角獸", "type": "Beast", "hp": 14000, "atk": 620, "speed": 100, "ai": "charge_freeze", "scale": 1.2, "color": Color(0.5, 0.8, 1.0), "exp": 2400, "meso": 2000},
	32: {"name": "火獨角獸", "type": "Beast", "hp": 15500, "atk": 670, "speed": 100, "ai": "charge_burn", "scale": 1.2, "color": Color(1.0, 0.3, 0.2), "exp": 2700, "meso": 2250},
	33: {"name": "黃金巨人", "type": "Golem", "hp": 18000, "atk": 730, "speed": 40, "ai": "heavy_smash", "scale": 1.9, "color": Color(0.9, 0.8, 0.2), "exp": 3100, "meso": 2550},
	34: {"name": "鋼鐵巨偶", "type": "Golem", "hp": 21000, "atk": 790, "speed": 35, "ai": "armor_up", "scale": 2.0, "color": Color(0.4, 0.5, 0.6), "exp": 3500, "meso": 2900},
	35: {"name": "食人花", "type": "Plant", "hp": 19500, "atk": 840, "speed": 0, "ai": "turret_spit", "scale": 1.3, "color": Color(0.7, 0.1, 0.4), "exp": 3900, "meso": 3200},
	36: {"name": "黑食人花", "type": "Plant", "hp": 23000, "atk": 910, "speed": 0, "ai": "turret_poison", "scale": 1.4, "color": Color(0.2, 0.1, 0.3), "exp": 4400, "meso": 3600},
	37: {"name": "骷髏犬", "type": "Undead", "hp": 25500, "atk": 980, "speed": 130, "ai": "pack_rush", "scale": 1.0, "color": Color(0.9, 0.9, 0.8), "exp": 4900, "meso": 4000},
	38: {"name": "地獄獵犬", "type": "Undead", "hp": 29000, "atk": 1060, "speed": 135, "ai": "pack_rush_fire", "scale": 1.15, "color": Color(0.4, 0.1, 0.1), "exp": 5500, "meso": 4500},
	39: {"name": "巫妖信徒", "type": "Mage", "hp": 32000, "atk": 1150, "speed": 60, "ai": "curse_spell", "scale": 1.0, "color": Color(0.3, 0.1, 0.4), "exp": 6200, "meso": 5000},
	40: {"name": "【Boss】地獄巴洛古", "type": "Boss", "hp": 150000, "atk": 1800, "speed": 85, "ai": "boss_meteor", "scale": 3.5, "color": Color(0.6, 0.0, 0.1), "exp": 20000, "meso": 15000},

	# [生態 5: 冰原雪域峭壁 Lv.41~50]
	41: {"name": "雪吉拉", "type": "Beast", "hp": 36000, "atk": 1250, "speed": 65, "ai": "heavy_punch", "scale": 1.6, "color": Color(0.95, 0.95, 1.0), "exp": 7000, "meso": 5700},
	42: {"name": "黑雪吉拉", "type": "Beast", "hp": 41000, "atk": 1360, "speed": 70, "ai": "heavy_punch", "scale": 1.65, "color": Color(0.2, 0.2, 0.25), "exp": 7900, "meso": 6400},
	43: {"name": "企鵝王", "type": "Bird", "hp": 38000, "atk": 1300, "speed": 80, "ai": "slide_dash", "scale": 1.0, "color": Color(0.1, 0.3, 0.5), "exp": 8800, "meso": 7100},
	44: {"name": "雪吉拉戰車", "type": "Beast", "hp": 52000, "atk": 1500, "speed": 60, "ai": "split_on_death", "scale": 2.0, "color": Color(0.85, 0.9, 1.0), "exp": 10000, "meso": 8000},
	45: {"name": "白狼", "type": "Beast", "hp": 45000, "atk": 1420, "speed": 130, "ai": "howl_buff", "scale": 1.2, "color": Color(0.9, 0.95, 0.95), "exp": 11200, "meso": 9000},
	46: {"name": "白狼人", "type": "Beast", "hp": 56000, "atk": 1600, "speed": 110, "ai": "double_claw", "scale": 1.5, "color": Color(0.8, 0.85, 0.9), "exp": 12500, "meso": 10000},
	47: {"name": "狼人", "type": "Beast", "hp": 62000, "atk": 1720, "speed": 115, "ai": "double_claw", "scale": 1.5, "color": Color(0.3, 0.25, 0.2), "exp": 14000, "meso": 11200},
	48: {"name": "冰石巨偶", "type": "Golem", "hp": 70000, "atk": 1850, "speed": 40, "ai": "freeze_slam", "scale": 2.1, "color": Color(0.6, 0.85, 1.0), "exp": 15800, "meso": 12500},
	49: {"name": "寒冰幽靈", "type": "Ghost", "hp": 65000, "atk": 1950, "speed": 85, "ai": "ranged_ice_shard", "scale": 1.1, "color": Color(0.7, 0.9, 1.0), "exp": 17800, "meso": 14000},
	50: {"name": "【Boss】雪毛怪人", "type": "Boss", "hp": 320000, "atk": 2800, "speed": 60, "ai": "boss_blizzard", "scale": 4.0, "color": Color(0.9, 0.95, 1.0), "exp": 50000, "meso": 35000},

	# [生態 6: 玩具城時光鐘塔 Lv.51~60]
	51: {"name": "發條熊", "type": "Toy", "hp": 76000, "atk": 2100, "speed": 75, "ai": "wind_up_strike", "scale": 1.3, "color": Color(0.8, 0.5, 0.2), "exp": 20000, "meso": 16000},
	52: {"name": "積木泥人", "type": "Toy", "hp": 83000, "atk": 2250, "speed": 60, "ai": "block_scatter", "scale": 1.2, "color": Color(0.9, 0.8, 0.1), "exp": 22500, "meso": 18000},
	53: {"name": "玩具鴨", "type": "Toy", "hp": 79000, "atk": 2180, "speed": 95, "ai": "quack_laser", "scale": 0.9, "color": Color(1.0, 0.9, 0.0), "exp": 25000, "meso": 20000},
	54: {"name": "機器章魚", "type": "Mech", "hp": 91000, "atk": 2400, "speed": 80, "ai": "tentacle_whip", "scale": 1.2, "color": Color(0.5, 0.2, 0.6), "exp": 28000, "meso": 22500},
	55: {"name": "幽靈發條熊", "type": "ToyGhost", "hp": 98000, "atk": 2550, "speed": 85, "ai": "soul_drain", "scale": 1.35, "color": Color(0.3, 0.6, 0.7), "exp": 31500, "meso": 25000},
	56: {"name": "小丑怪", "type": "Toy", "hp": 105000, "atk": 2700, "speed": 110, "ai": "box_trap", "scale": 1.1, "color": Color(0.9, 0.2, 0.5), "exp": 35000, "meso": 28000},
	57: {"name": "幽靈小丑", "type": "ToyGhost", "hp": 115000, "atk": 2880, "speed": 115, "ai": "box_trap_explode", "scale": 1.15, "color": Color(0.4, 0.1, 0.6), "exp": 39000, "meso": 31000},
	58: {"name": "發條騎兵", "type": "Toy", "hp": 128000, "atk": 3050, "speed": 100, "ai": "lance_charge", "scale": 1.4, "color": Color(0.7, 0.7, 0.8), "exp": 43500, "meso": 35000},
	59: {"name": "時間魔偶", "type": "Mech", "hp": 142000, "atk": 3250, "speed": 50, "ai": "time_slow_field", "scale": 1.7, "color": Color(0.8, 0.6, 0.3), "exp": 48500, "meso": 39000},
	60: {"name": "【Boss】拉圖斯", "type": "Boss", "hp": 680000, "atk": 4500, "speed": 70, "ai": "boss_time_warp", "scale": 3.8, "color": Color(0.2, 0.7, 0.9), "exp": 120000, "meso": 80000},

	# [生態 7: 深海沉船與珊瑚礁 Lv.61~70]
	61: {"name": "毒河豚", "type": "Aqua", "hp": 155000, "atk": 3500, "speed": 70, "ai": "puff_spikes", "scale": 1.1, "color": Color(0.3, 0.8, 0.6), "exp": 54000, "meso": 43000},
	62: {"name": "海馬騎士", "type": "Aqua", "hp": 168000, "atk": 3720, "speed": 90, "ai": "water_spear", "scale": 1.2, "color": Color(0.2, 0.6, 0.8), "exp": 60000, "meso": 48000},
	63: {"name": "電鰻", "type": "Aqua", "hp": 182000, "atk": 3950, "speed": 105, "ai": "lightning_surge", "scale": 1.0, "color": Color(0.9, 0.9, 0.3), "exp": 67000, "meso": 53000},
	64: {"name": "寄居蟹巨怪", "type": "Aqua", "hp": 205000, "atk": 4200, "speed": 40, "ai": "shell_defend", "scale": 1.8, "color": Color(0.7, 0.4, 0.3), "exp": 75000, "meso": 59000},
	65: {"name": "深海章魚", "type": "Aqua", "hp": 220000, "atk": 4450, "speed": 85, "ai": "ink_blind", "scale": 1.5, "color": Color(0.4, 0.1, 0.3), "exp": 84000, "meso": 66000},
	66: {"name": "尖牙鯊魚", "type": "Aqua", "hp": 245000, "atk": 4750, "speed": 130, "ai": "shark_charge", "scale": 1.6, "color": Color(0.3, 0.4, 0.6), "exp": 94000, "meso": 74000},
	67: {"name": "深海巨烏賊", "type": "Aqua", "hp": 270000, "atk": 5050, "speed": 75, "ai": "whirlpool_pull", "scale": 2.2, "color": Color(0.6, 0.1, 0.2), "exp": 105000, "meso": 83000},
	68: {"name": "幽靈船水手", "type": "UndeadAqua", "hp": 295000, "atk": 5380, "speed": 90, "ai": "cutlass_combo", "scale": 1.2, "color": Color(0.5, 0.7, 0.6), "exp": 118000, "meso": 93000},
	69: {"name": "幽靈船長", "type": "UndeadAqua", "hp": 330000, "atk": 5750, "speed": 95, "ai": "cannon_volley", "scale": 1.5, "color": Color(0.2, 0.5, 0.4), "exp": 132000, "meso": 104000},
	70: {"name": "【Boss】深海海龍王", "type": "Boss", "hp": 1200000, "atk": 7500, "speed": 80, "ai": "boss_tidal_wave", "scale": 4.5, "color": Color(0.1, 0.3, 0.8), "exp": 300000, "meso": 200000},

	# [生態 8: 神木村龍之巢穴 Lv.71~80]
	71: {"name": "綠角幼龍", "type": "Dragon", "hp": 360000, "atk": 6150, "speed": 90, "ai": "fire_breath", "scale": 1.3, "color": Color(0.3, 0.7, 0.3), "exp": 148000, "meso": 116000},
	72: {"name": "赤角幼龍", "type": "Dragon", "hp": 395000, "atk": 6550, "speed": 95, "ai": "fire_breath", "scale": 1.35, "color": Color(0.8, 0.2, 0.2), "exp": 165000, "meso": 130000},
	73: {"name": "短刃蜥蜴戰士", "type": "Dragonkin", "hp": 435000, "atk": 7000, "speed": 115, "ai": "blade_frenzy", "scale": 1.4, "color": Color(0.5, 0.6, 0.3), "exp": 184000, "meso": 145000},
	74: {"name": "雙刃蜥蜴戰士", "type": "Dragonkin", "hp": 480000, "atk": 7500, "speed": 120, "ai": "blade_frenzy", "scale": 1.45, "color": Color(0.4, 0.5, 0.2), "exp": 205000, "meso": 162000},
	75: {"name": "長槍龍騎兵", "type": "Dragonkin", "hp": 530000, "atk": 8050, "speed": 105, "ai": "spear_thrust", "scale": 1.6, "color": Color(0.6, 0.4, 0.2), "exp": 228000, "meso": 180000},
	76: {"name": "火焰半人馬", "type": "Centaur", "hp": 585000, "atk": 8600, "speed": 135, "ai": "trample_fire", "scale": 1.7, "color": Color(0.9, 0.3, 0.0), "exp": 255000, "meso": 200000},
	77: {"name": "寒冰半人馬", "type": "Centaur", "hp": 645000, "atk": 9200, "speed": 135, "ai": "trample_ice", "scale": 1.7, "color": Color(0.2, 0.6, 0.95), "exp": 285000, "meso": 225000},
	78: {"name": "暗黑半人馬", "type": "Centaur", "hp": 710000, "atk": 9850, "speed": 140, "ai": "trample_dark", "scale": 1.75, "color": Color(0.2, 0.1, 0.3), "exp": 320000, "meso": 250000},
	79: {"name": "骨骸飛龍", "type": "UndeadDragon", "hp": 790000, "atk": 10600, "speed": 120, "ai": "bone_breath", "scale": 2.2, "color": Color(0.85, 0.85, 0.8), "exp": 360000, "meso": 280000},
	80: {"name": "【Boss】九尾狐妖 / 赤龍王", "type": "Boss", "hp": 2500000, "atk": 14000, "speed": 90, "ai": "boss_flame_pillar", "scale": 4.2, "color": Color(1.0, 0.2, 0.0), "exp": 750000, "meso": 500000},

	# [生態 9: 崩壞神殿門扉 Lv.81~90]
	81: {"name": "神殿侍衛", "type": "Temple", "hp": 880000, "atk": 11500, "speed": 85, "ai": "shield_bash", "scale": 1.5, "color": Color(0.8, 0.8, 0.9), "exp": 410000, "meso": 320000},
	82: {"name": "神殿禁衛軍", "type": "Temple", "hp": 980000, "atk": 12400, "speed": 90, "ai": "spear_guard", "scale": 1.6, "color": Color(0.7, 0.7, 0.85), "exp": 465000, "meso": 365000},
	83: {"name": "悔恨的神官", "type": "Temple", "hp": 1090000, "atk": 13400, "speed": 75, "ai": "ranged_holy_smite", "scale": 1.3, "color": Color(0.3, 0.5, 0.8), "exp": 525000, "meso": 415000},
	84: {"name": "忘卻的神官", "type": "Temple", "hp": 1210000, "atk": 14500, "speed": 75, "ai": "silence_debuff", "scale": 1.3, "color": Color(0.8, 0.3, 0.3), "exp": 595000, "meso": 470000},
	85: {"name": "燃燒神殿守衛", "type": "Temple", "hp": 1340000, "atk": 15700, "speed": 100, "ai": "cleave_burn", "scale": 1.8, "color": Color(0.9, 0.4, 0.1), "exp": 675000, "meso": 530000},
	86: {"name": "多多 (神殿水牛)", "type": "TempleBeast", "hp": 1500000, "atk": 17000, "speed": 110, "ai": "unstoppable_rush", "scale": 2.5, "color": Color(0.2, 0.4, 0.7), "exp": 765000, "meso": 600000},
	87: {"name": "利里諾斯 (鏡像騎士)", "type": "Temple", "hp": 1680000, "atk": 18400, "speed": 105, "ai": "damage_reflect", "scale": 2.0, "color": Color(0.8, 0.9, 1.0), "exp": 870000, "meso": 680000},
	88: {"name": "雷卡 (神殿獅王)", "type": "TempleBeast", "hp": 1880000, "atk": 19900, "speed": 125, "ai": "roar_stun_all", "scale": 2.6, "color": Color(0.9, 0.7, 0.2), "exp": 990000, "meso": 770000},
	89: {"name": "殘缺虛空魔眼", "type": "Void", "hp": 2100000, "atk": 21500, "speed": 95, "ai": "void_laser", "scale": 1.7, "color": Color(0.4, 0.0, 0.6), "exp": 1130000, "meso": 880000},
	90: {"name": "【Boss】闇黑龍王 (左/右頭)", "type": "Boss", "hp": 5000000, "atk": 28000, "speed": 0, "ai": "boss_dragon_roar", "scale": 5.0, "color": Color(0.3, 0.1, 0.4), "exp": 2500000, "meso": 1800000},

	# [生態 10: 時間神殿極點與滅世終章 Lv.91~100]
	91: {"name": "虛空撕裂者", "type": "Void", "hp": 2400000, "atk": 23500, "speed": 140, "ai": "blink_slash", "scale": 1.4, "color": Color(0.1, 0.0, 0.2), "exp": 1300000, "meso": 1000000},
	92: {"name": "終焉守門人", "type": "Void", "hp": 2750000, "atk": 25700, "speed": 70, "ai": "gravity_well", "scale": 2.3, "color": Color(0.2, 0.2, 0.2), "exp": 1500000, "meso": 1150000},
	93: {"name": "混亂賢者", "type": "Chaos", "hp": 3150000, "atk": 28000, "speed": 80, "ai": "invert_controls", "scale": 1.5, "color": Color(0.6, 0.1, 0.5), "exp": 1750000, "meso": 1350000},
	94: {"name": "時間追獵者", "type": "Time", "hp": 3600000, "atk": 30500, "speed": 160, "ai": "fast_flank", "scale": 1.3, "color": Color(0.1, 0.8, 0.8), "exp": 2050000, "meso": 1600000},
	95: {"name": "滅世巨神偶", "type": "Golem", "hp": 4200000, "atk": 33500, "speed": 40, "ai": "cataclysm_slam", "scale": 3.0, "color": Color(0.7, 0.1, 0.1), "exp": 2400000, "meso": 1900000},
	96: {"name": "深淵支配者", "type": "Demon", "hp": 4900000, "atk": 37000, "speed": 110, "ai": "summon_minions", "scale": 2.4, "color": Color(0.3, 0.0, 0.1), "exp": 2850000, "meso": 2250000},
	97: {"name": "【Boss】混沌巴洛古", "type": "Boss", "hp": 8500000, "atk": 45000, "speed": 100, "ai": "boss_hellfire", "scale": 4.5, "color": Color(0.8, 0.0, 0.0), "exp": 6000000, "meso": 4500000},
	98: {"name": "【Boss】混沌闇黑龍王 (主體)", "type": "Boss", "hp": 15000000, "atk": 60000, "speed": 0, "ai": "boss_dragon_apocalypse", "scale": 5.5, "color": Color(0.2, 0.0, 0.3), "exp": 12000000, "meso": 8000000},
	99: {"name": "【Boss】神殿守護神像群", "type": "Boss", "hp": 25000000, "atk": 75000, "speed": 0, "ai": "boss_statue_barrage", "scale": 6.0, "color": Color(0.9, 0.85, 0.7), "exp": 25000000, "meso": 15000000},
	100: {"name": "【Final Boss】真‧皮卡啾 (滅世本體)", "type": "FinalBoss", "hp": 50000000, "atk": 100000, "speed": 110, "ai": "boss_pink_bean_chaos", "scale": 4.0, "color": Color(1.0, 0.4, 0.7), "exp": 50000000, "meso": 30000000}
}

# 取得第 1~50 波攻城敵怪配置
static func get_wave_data(wave: int) -> Dictionary:
	var count = int(8 + (wave * 1.5)) # 隨波次增加怪物數量
	var normal_mob_id = clampi((wave * 2) - 1, 1, 96)
	var result = {"count": count, "monster_id": normal_mob_id}
	
	# 每 5 波派出對應生態的 BOSS
	if wave % 5 == 0:
		var boss_index = (wave / 5) * 10
		result["boss_id"] = clampi(boss_index, 10, 100)
	return result

static func get_monster(id: int) -> Dictionary:
	if FULL_DATABASE.has(id):
		var data = FULL_DATABASE[id].duplicate()
		data["id"] = id
		return data
	return {"id": id, "name": "Monster", "type": "Slime", "hp": 100, "atk": 10, "speed": 50, "ai": "patrol", "scale": 1.0, "color": Color.GREEN, "exp": 20, "meso": 15}

static func get_biome_monsters(biome_idx: int) -> Array:
	var start_id = (biome_idx - 1) * 10 + 1
	var end_id = biome_idx * 10
	var list = []
	for id in range(start_id, end_id + 1):
		if FULL_DATABASE.has(id):
			var data = FULL_DATABASE[id].duplicate()
			data["id"] = id
			list.append(data)
	return list
