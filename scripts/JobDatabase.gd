# JobDatabase.gd
# 楓之谷全職業技能資料庫 (全職業 6 大主動技 + 全螢幕終極奧義 + 覺醒被動)
extends Node

const JOBS = {
	"warrior": {
		"id": "warrior",
		"name": "劍士 (Warrior)",
		"title": "狂戰士 ‧ 英雄 ‧ 聖騎士",
		"desc": "擁有極高的生命值與強大的近戰爆發力，手持巨劍劈砍敵群！",
		"primary_stat": "STR",
		"base_stats": {
			"str": 30, "dex": 15, "int": 4, "luk": 4,
			"hp": 950, "mp": 160, "watk": 55, "matk": 5,
			"mastery": 0.65, "crit_rate": 0.20
		},
		"growth": {
			"hp": 90, "mp": 20, "str": 4, "dex": 1, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "英雄雙手巨劍",
		"color": Color(1.0, 0.3, 0.2),
		"skills": {
			"basic": {"name": "巨劍揮擊", "multiplier": 1.2, "hits": 1, "mp": 0, "type": "melee"},
			"skill_1": {"name": "魔靈斬 (Power Strike)", "multiplier": 3.0, "hits": 1, "mp": 10, "type": "melee_heavy", "cd": 0.6, "desc": "凝聚全力斬擊，造成 300% 單體巨額傷害！"},
			"skill_2": {"name": "劍氣斬 (Slash Blast)", "multiplier": 1.6, "hits": 2, "mp": 16, "type": "aoe_slash", "cd": 1.0, "desc": "揮出半月劍氣橫掃周圍敵群，造成 2 段範圍傷害！"},
			"skill_3": {"name": "突進連斬 (Rush & Brandish)", "multiplier": 2.2, "hits": 3, "mp": 25, "type": "rush_slash", "cd": 2.0, "desc": "向前狂奔推擠敵群並連續揮出 3 段重擊！"},
			"skill_4": {"name": "黑暗神兵 (Dark Force)", "multiplier": 2.6, "hits": 4, "mp": 35, "type": "dark_force", "cd": 3.0, "desc": "釋放暗黑龍魂連續撕裂 4 次敵群，附帶 10% 吸血！"},
			"skill_5": {"name": "龍之咆哮 (Dragon Roar)", "multiplier": 3.2, "hits": 3, "mp": 45, "type": "dragon_roar", "cd": 4.5, "desc": "仰天怒吼震碎全圖，對全螢幕所有怪物造成 3 段重創！"},
			"skill_6": {"name": "聖十字審判 (Brandish Light)", "multiplier": 3.8, "hits": 4, "mp": 55, "type": "holy_slash", "cd": 5.0, "desc": "召喚聖光十字雙重審判，造成 4 段 380% 聖光傷害！"},
			"ultimate": {"name": "【終極奧義】諸神黃昏 ‧ 天崩地裂", "multiplier": 7.5, "hits": 6, "mp": 80, "type": "ultimate_screen", "cd": 10.0, "desc": "化身戰神撕裂空間，對全螢幕造成 6 段 750% 毀滅巨響！"}
		}
	},
	"magician": {
		"id": "magician",
		"name": "魔法師 (Magician)",
		"title": "大魔導士 ‧ 主教 ‧ 聖通靈師",
		"desc": "掌握元素與神聖力量，具備超大範圍魔法轟炸與治癒能力！",
		"primary_stat": "INT",
		"base_stats": {
			"str": 4, "dex": 4, "int": 32, "luk": 14,
			"hp": 550, "mp": 850, "watk": 12, "matk": 70,
			"mastery": 0.70, "crit_rate": 0.25
		},
		"growth": {
			"hp": 45, "mp": 80, "str": 0, "dex": 0, "int": 5, "luk": 1, "matk": 8
		},
		"weapon_name": "元素大魔杖",
		"color": Color(0.3, 0.7, 1.0),
		"skills": {
			"basic": {"name": "魔力彈 (Energy Bolt)", "multiplier": 1.25, "hits": 1, "mp": 0, "type": "magic_bolt"},
			"skill_1": {"name": "魔力之爪 (Magic Claw)", "multiplier": 1.65, "hits": 2, "mp": 12, "type": "magic_claw", "cd": 0.6, "desc": "召喚兩道奧術光爪撕裂敵人，造成 2 段魔法打擊！"},
			"skill_2": {"name": "狂雷連鎖 (Chain Lightning)", "multiplier": 1.8, "hits": 3, "mp": 22, "type": "lightning_storm", "cd": 1.2, "desc": "在周圍引爆高壓閃電，連鎖穿梭轟炸多個目標！"},
			"skill_3": {"name": "冰風暴 (Ice Strike)", "multiplier": 2.4, "hits": 3, "mp": 30, "type": "ice_strike", "cd": 2.0, "desc": "召喚萬丈冰柱從地底刺出，冰封並重創範圍敵群！"},
			"skill_4": {"name": "滅世隕石 (Meteor)", "multiplier": 3.4, "hits": 3, "mp": 45, "type": "meteor", "cd": 3.5, "desc": "從虛空中召喚巨大熾熱隕石撞擊地面，引發全圖火海！"},
			"skill_5": {"name": "暴風雪 (Blizzard)", "multiplier": 3.5, "hits": 4, "mp": 55, "type": "blizzard", "cd": 4.5, "desc": "極寒暴風雪籠罩全場，降下無數銳利冰錐連續打擊！"},
			"skill_6": {"name": "天使之箭 (Angel Ray)", "multiplier": 4.2, "hits": 4, "mp": 60, "type": "angel_ray", "cd": 5.0, "desc": "召喚熾天使神聖聖光射線貫穿敵群，同時治癒自身！"},
			"ultimate": {"name": "【終極奧義】神聖創世紀 (Genesis)", "multiplier": 8.0, "hits": 6, "mp": 90, "type": "ultimate_screen", "cd": 10.0, "desc": "天降神聖萬丈聖光之柱，對全屏怪物施以 6 段 800% 神罰！"}
		}
	},
	"bowman": {
		"id": "bowman",
		"name": "弓箭手 (Bowman)",
		"title": "箭神 ‧ 神射手 ‧ 風靈使者",
		"desc": "超長射程與超高暴擊率，以狂風般的箭雨瞬間射穿敵人！",
		"primary_stat": "DEX",
		"base_stats": {
			"str": 12, "dex": 32, "int": 4, "luk": 6,
			"hp": 680, "mp": 380, "watk": 52, "matk": 5,
			"mastery": 0.75, "crit_rate": 0.40
		},
		"growth": {
			"hp": 60, "mp": 30, "str": 1, "dex": 4, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "精靈神風長弓",
		"color": Color(0.2, 0.95, 0.4),
		"skills": {
			"basic": {"name": "精準箭矢", "multiplier": 1.2, "hits": 1, "mp": 0, "type": "arrow_single"},
			"skill_1": {"name": "二連矢 (Double Shot)", "multiplier": 1.6, "hits": 2, "mp": 10, "type": "arrow_double", "cd": 0.5, "desc": "迅捷射出兩支強烈箭矢，造成 2 段精準狙擊！"},
			"skill_2": {"name": "漫天箭雨 (Arrow Rain)", "multiplier": 1.5, "hits": 3, "mp": 20, "type": "arrow_rain", "cd": 1.0, "desc": "向天發射箭矢如暴雨般落下，造成 3 段廣域轟炸！"},
			"skill_3": {"name": "炸彈箭 (Arrow Bomb)", "multiplier": 2.5, "hits": 2, "mp": 26, "type": "arrow_bomb", "cd": 1.8, "desc": "發射附帶火藥的爆破箭矢，命中時引發劇烈範圍爆炸！"},
			"skill_4": {"name": "貫穿之箭 (Piercing Arrow)", "multiplier": 3.0, "hits": 4, "mp": 38, "type": "piercing_arrow", "cd": 3.0, "desc": "蓄力射出貫穿全直線所有敵人的旋風巨箭！"},
			"skill_5": {"name": "召喚烈火鳳凰 (Phoenix Strike)", "multiplier": 3.6, "hits": 3, "mp": 50, "type": "phoenix", "cd": 4.5, "desc": "召喚火鳳凰自九天俯衝撲殺敵群，引發烈火焚燒！"},
			"skill_6": {"name": "暴風神射 (Hurricane)", "multiplier": 1.4, "hits": 8, "mp": 55, "type": "hurricane", "cd": 5.0, "desc": "如加特林機槍般狂風掃射！瞬間轟出 8 支致命疾風箭！"},
			"ultimate": {"name": "【終極奧義】神箭萬丈 ‧ 滅世神風", "multiplier": 7.8, "hits": 8, "mp": 85, "type": "ultimate_screen", "cd": 10.0, "desc": "射出金色神風貫穿天際，引發 8 段 780% 全屏毀滅箭雨！"}
		}
	},
	"thief": {
		"id": "thief",
		"name": "盜賊 (Thief)",
		"title": "夜使者 ‧ 暗影神偷 ‧ 影武者",
		"desc": "極致的靈敏度與高段數爆發，以飛鏢與影分身斬殺敵首！",
		"primary_stat": "LUK",
		"base_stats": {
			"str": 6, "dex": 14, "int": 4, "luk": 32,
			"hp": 650, "mp": 400, "watk": 50, "matk": 5,
			"mastery": 0.70, "crit_rate": 0.35
		},
		"growth": {
			"hp": 55, "mp": 32, "str": 0, "dex": 1, "int": 0, "luk": 4, "watk": 6
		},
		"weapon_name": "無影金標 & 拳套",
		"color": Color(0.85, 0.35, 1.0),
		"skills": {
			"basic": {"name": "手裏劍投擲", "multiplier": 1.15, "hits": 1, "mp": 0, "type": "shuriken"},
			"skill_1": {"name": "雙飛斬 (Lucky Seven)", "multiplier": 1.8, "hits": 2, "mp": 10, "type": "lucky_seven", "cd": 0.5, "desc": "經典雙飛投擲兩枚金鏢，受 LUK 巨額加成！"},
			"skill_2": {"name": "落葉斬 (Assaulter)", "multiplier": 2.2, "hits": 3, "mp": 18, "type": "assaulter", "cd": 1.0, "desc": "化作殘影瞬間穿透怪物身軀，造成 3 段突襲刺殺！"},
			"skill_3": {"name": "迴旋斬 ‧ 六連擊 (Savage Blow)", "multiplier": 1.35, "hits": 6, "mp": 28, "type": "savage_blow", "cd": 1.8, "desc": "以令人目眩的極速在瞬間斬出 6 段暗影匕首連擊！"},
			"skill_4": {"name": "楓葉狂刀 (Band of Thieves)", "multiplier": 2.8, "hits": 4, "mp": 38, "type": "band_thieves", "cd": 3.0, "desc": "召喚盜賊兄弟會幻影齊聚斬殺，造成 4 段範圍絞殺！"},
			"skill_5": {"name": "三連投擲 (Triple Throw)", "multiplier": 2.4, "hits": 5, "mp": 48, "type": "triple_throw", "cd": 4.0, "desc": "影分身協同投擲出 5 枚強化劇毒手裏劍！"},
			"skill_6": {"name": "暗影分身斬 (Shadow Partner)", "multiplier": 3.2, "hits": 6, "mp": 55, "type": "shadow_partner", "cd": 5.0, "desc": "本體與影分身同步施展絕殺，狂暴斬出 6 段 320% 傷害！"},
			"ultimate": {"name": "【終極奧義】百鬼夜行 ‧ 影之奧義", "multiplier": 8.2, "hits": 8, "mp": 85, "type": "ultimate_screen", "cd": 10.0, "desc": "全螢幕暗夜黑幕降臨，無數影分身穿梭爆發 8 段 820% 刺殺！"}
		}
	},
	"pirate": {
		"id": "pirate",
		"name": "海盜 (Pirate)",
		"title": "拳霸 ‧ 槍神 ‧ 重砲指揮官",
		"desc": "結合體術拳法與重火器射擊，攻守兼備無所畏懼！",
		"primary_stat": "STR/DEX",
		"base_stats": {
			"str": 22, "dex": 22, "int": 4, "luk": 4,
			"hp": 820, "mp": 350, "watk": 54, "matk": 5,
			"mastery": 0.70, "crit_rate": 0.25
		},
		"growth": {
			"hp": 75, "mp": 28, "str": 2, "dex": 2, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "重金屬火槍 & 指虎",
		"color": Color(1.0, 0.65, 0.1),
		"skills": {
			"basic": {"name": "直拳重擊", "multiplier": 1.2, "hits": 1, "mp": 0, "type": "pirate_fist"},
			"skill_1": {"name": "雙連彈 (Double Fire)", "multiplier": 1.6, "hits": 2, "mp": 10, "type": "pirate_bullet", "cd": 0.5, "desc": "拔槍連續射出兩發烈焰子彈！"},
			"skill_2": {"name": "昇龍拳 (Somersault Kick)", "multiplier": 1.6, "hits": 3, "mp": 18, "type": "pirate_kick", "cd": 1.0, "desc": "騰空旋風踢擊退周遭 360 度所有近身敵人！"},
			"skill_3": {"name": "能量爆發 (Energy Blast)", "multiplier": 2.4, "hits": 3, "mp": 28, "type": "energy_blast", "cd": 1.8, "desc": "聚集全身鬥氣轟出超巨型雷射衝擊波！"},
			"skill_4": {"name": "迅雷不及掩耳 (Rapid Fire)", "multiplier": 1.5, "hits": 6, "mp": 40, "type": "rapid_fire", "cd": 3.0, "desc": "雙槍加特林瘋狂掃射，傾瀉 6 發爆裂燃燒彈！"},
			"skill_5": {"name": "戰艦重砲轟擊 (Battleship Cannon)", "multiplier": 3.6, "hits": 4, "mp": 50, "type": "battleship", "cd": 4.2, "desc": "召喚海盜戰艦巨砲齊發，引發毀滅性連環重砲轟炸！"},
			"skill_6": {"name": "降龍十八掌 ‧ 閃連殺 (Dragon Strike)", "multiplier": 2.8, "hits": 6, "mp": 60, "type": "dragon_strike", "cd": 5.0, "desc": "召喚金龍之魂附體，以狂暴體術連續轟出 6 段超重擊！"},
			"ultimate": {"name": "【終極奧義】海賊艦隊 ‧ 全彈發射", "multiplier": 8.0, "hits": 8, "mp": 85, "type": "ultimate_screen", "cd": 10.0, "desc": "海賊艦隊全體出動向全螢幕傾瀉無盡砲火，造成 8 段 800% 浩劫！"}
		}
	}
}

static func get_job(job_id: String) -> Dictionary:
	if JOBS.has(job_id):
		return JOBS[job_id]
	return JOBS["warrior"]
