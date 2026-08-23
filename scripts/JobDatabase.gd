# JobDatabase.gd
extends Node

const JOBS = {
	"warrior": {
		"id": "warrior",
		"name": "劍士 (Warrior)",
		"title": "狂戰士 ‧ 聖騎士",
		"desc": "擁有極高的生命值與強大的近戰爆發力，手持巨劍劈砍敵群！",
		"primary_stat": "STR",
		"base_stats": {
			"str": 25,
			"dex": 12,
			"int": 4,
			"luk": 4,
			"hp": 750,
			"mp": 120,
			"watk": 42,
			"matk": 5,
			"mastery": 0.60,
			"crit_rate": 0.15
		},
		"growth": {
			"hp": 75,
			"mp": 15,
			"str": 4,
			"dex": 1,
			"int": 0,
			"luk": 0,
			"watk": 5
		},
		"weapon_name": "英雄雙手劍",
		"color": Color(0.9, 0.25, 0.2),
		"skills": {
			"basic": {"name": "巨劍揮擊", "multiplier": 1.1, "hits": 1, "mp": 0, "type": "melee"},
			"skill_1": {"name": "魔靈斬 (Power Strike)", "multiplier": 2.8, "hits": 1, "mp": 10, "type": "melee_heavy", "cd": 0.8, "desc": "凝聚全力斬擊，造成 280% 單體巨額傷害！"},
			"skill_2": {"name": "劍氣斬 (Slash Blast)", "multiplier": 1.4, "hits": 2, "mp": 18, "type": "aoe_slash", "cd": 1.2, "desc": "揮出半月劍氣橫掃周圍敵群，造成 2 段範圍傷害！"},
			"skill_3": {"name": "鬥氣爆發 ‧ 聖十字審判", "multiplier": 4.2, "hits": 3, "mp": 45, "type": "ultimate_shockwave", "cd": 5.0, "desc": "鬥氣全開轟出聖光震波，造成 3 段 420% 毀滅傷害！"}
		}
	},
	"magician": {
		"id": "magician",
		"name": "魔法師 (Magician)",
		"title": "大魔導士 ‧ 主教",
		"desc": "掌握元素與神聖力量，具備超大範圍魔法轟炸與治癒能力！",
		"primary_stat": "INT",
		"base_stats": {
			"str": 4,
			"dex": 4,
			"int": 25,
			"luk": 12,
			"hp": 420,
			"mp": 650,
			"watk": 10,
			"matk": 55,
			"mastery": 0.65,
			"crit_rate": 0.20
		},
		"growth": {
			"hp": 35,
			"mp": 60,
			"str": 0,
			"dex": 0,
			"int": 4,
			"luk": 1,
			"matk": 6
		},
		"weapon_name": "元素大魔杖",
		"color": Color(0.3, 0.6, 1.0),
		"skills": {
			"basic": {"name": "魔力彈 (Energy Bolt)", "multiplier": 1.2, "hits": 1, "mp": 0, "type": "magic_bolt"},
			"skill_1": {"name": "魔力之爪 (Magic Claw)", "multiplier": 1.5, "hits": 2, "mp": 15, "type": "magic_claw", "cd": 0.8, "desc": "召喚兩道奧術光爪撕裂敵人，造成 2 段魔法打擊！"},
			"skill_2": {"name": "狂雷風暴 (Thunder Bolt)", "multiplier": 1.6, "hits": 2, "mp": 25, "type": "lightning_storm", "cd": 1.5, "desc": "在全周圍降下密集落雷，連鎖轟炸多個目標！"},
			"skill_3": {"name": "終極奧義 ‧ 天怒 (Genesis)", "multiplier": 6.5, "hits": 4, "mp": 60, "type": "screen_genesis", "cd": 5.5, "desc": "降下全屏神聖光雨審判，造成 4 段 650% 超絕傷害！"}
		}
	},
	"bowman": {
		"id": "bowman",
		"name": "弓箭手 (Bowman)",
		"title": "箭神 ‧ 神射手",
		"desc": "超長射程與超高暴擊率，以狂風般的箭雨瞬間射穿敵人！",
		"primary_stat": "DEX",
		"base_stats": {
			"str": 10,
			"dex": 26,
			"int": 4,
			"luk": 5,
			"hp": 520,
			"mp": 280,
			"watk": 40,
			"matk": 5,
			"mastery": 0.70,
			"crit_rate": 0.35
		},
		"growth": {
			"hp": 48,
			"mp": 22,
			"str": 1,
			"dex": 4,
			"int": 0,
			"luk": 0,
			"watk": 5
		},
		"weapon_name": "精靈長弓",
		"color": Color(0.2, 0.9, 0.4),
		"skills": {
			"basic": {"name": "精準箭矢", "multiplier": 1.15, "hits": 1, "mp": 0, "type": "arrow_single"},
			"skill_1": {"name": "二連矢 (Double Shot)", "multiplier": 1.45, "hits": 2, "mp": 12, "type": "arrow_double", "cd": 0.7, "desc": "迅捷射出兩支強烈箭矢，造成 2 段精準狙擊！"},
			"skill_2": {"name": "箭雨 (Arrow Rain)", "multiplier": 1.3, "hits": 3, "mp": 22, "type": "arrow_rain", "cd": 1.4, "desc": "向天發射箭矢如暴雨般落下，造成 3 段廣域傷害！"},
			"skill_3": {"name": "暴風神射 ‧ 四連殺 (Strafe)", "multiplier": 1.8, "hits": 4, "mp": 35, "type": "arrow_hurricane", "cd": 4.0, "desc": "如疾風般連續射出 4 支毀滅連弩箭矢！"}
		}
	},
	"thief": {
		"id": "thief",
		"name": "盜賊 (Thief)",
		"title": "夜使者 ‧ 暗影神偷",
		"desc": "極致的靈敏度與高段數爆發，以飛鏢與影分身斬殺敵首！",
		"primary_stat": "LUK",
		"base_stats": {
			"str": 5,
			"dex": 12,
			"int": 4,
			"luk": 26,
			"hp": 480,
			"mp": 300,
			"watk": 38,
			"matk": 5,
			"mastery": 0.60,
			"crit_rate": 0.30
		},
		"growth": {
			"hp": 45,
			"mp": 24,
			"str": 0,
			"dex": 1,
			"int": 0,
			"luk": 4,
			"watk": 5
		},
		"weapon_name": "日月標 & 拳套",
		"color": Color(0.8, 0.3, 0.9),
		"skills": {
			"basic": {"name": "手裏劍投擲", "multiplier": 1.1, "hits": 1, "mp": 0, "type": "shuriken"},
			"skill_1": {"name": "雙飛斬 (Lucky Seven)", "multiplier": 1.7, "hits": 2, "mp": 12, "type": "lucky_seven", "cd": 0.6, "desc": "經典雙飛投擲兩枚金鏢，受 LUK 加成極大爆發！"},
			"skill_2": {"name": "影分身 (Shadow Partner)", "multiplier": 1.6, "hits": 3, "mp": 20, "type": "shadow_slash", "cd": 1.2, "desc": "召喚影子殘像協同突刺，造成 3 段暗影傷害！"},
			"skill_3": {"name": "迴旋斬 ‧ 六連擊 (Savage Blow)", "multiplier": 1.25, "hits": 6, "mp": 40, "type": "savage_blow", "cd": 3.8, "desc": "以令人目眩的極速在瞬間斬出 6 段連擊！"}
		}
	},
	"pirate": {
		"id": "pirate",
		"name": "海盜 (Pirate)",
		"title": "拳霸 ‧ 槍神",
		"desc": "結合體術拳法與重火器射擊，攻守兼備無所畏懼！",
		"primary_stat": "STR/DEX",
		"base_stats": {
			"str": 18,
			"dex": 18,
			"int": 4,
			"luk": 4,
			"hp": 620,
			"mp": 260,
			"watk": 40,
			"matk": 5,
			"mastery": 0.65,
			"crit_rate": 0.20
		},
		"growth": {
			"hp": 60,
			"mp": 20,
			"str": 2,
			"dex": 2,
			"int": 0,
			"luk": 0,
			"watk": 5
		},
		"weapon_name": "重金屬火槍 & 指虎",
		"color": Color(0.95, 0.6, 0.1),
		"skills": {
			"basic": {"name": "直拳重擊", "multiplier": 1.15, "hits": 1, "mp": 0, "type": "pirate_fist"},
			"skill_1": {"name": "雙連彈 (Double Fire)", "multiplier": 1.5, "hits": 2, "mp": 10, "type": "pirate_bullet", "cd": 0.7, "desc": "拔槍連續射出兩發烈焰子彈！"},
			"skill_2": {"name": "昇龍拳 (Somersault Kick)", "multiplier": 1.4, "hits": 2, "mp": 18, "type": "pirate_kick", "cd": 1.2, "desc": "騰空旋風踢擊退周遭 360 度所有近身敵人！"},
			"skill_3": {"name": "瘋狂轟炸 ‧ 龍之審判 (Dragon Strike)", "multiplier": 2.2, "hits": 4, "mp": 45, "type": "pirate_artillery", "cd": 4.5, "desc": "召喚巨龍狂轟濫炸，造成 4 段巨型烈焰爆炸！"}
		}
	}
}

static func get_job(job_id: String) -> Dictionary:
	if JOBS.has(job_id):
		return JOBS[job_id]
	return JOBS["warrior"]
