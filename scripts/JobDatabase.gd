# JobDatabase.gd
# 楓之谷經典版全職業技能資料庫 (初心者 + 劍士/法師/弓箭手/盜賊/海盜 一二轉經典技能與數值逐級成長)
# 參考波波攻略島技能總覽 https://bobogameguides.com/maplestory-classic/guides/skills-overview.html
extends Node

const JOBS = {
	"beginner": {
		"id": "beginner",
		"name": "初心者 (Beginner)",
		"title": "冒險家起源",
		"desc": "初心未改的冒險者，能投擲蝸牛殼、疾走奔馳與恢復體力！",
		"primary_stat": "STR",
		"base_stats": {
			"str": 12, "dex": 12, "int": 10, "luk": 10,
			"hp": 300, "mp": 80, "watk": 20, "matk": 10,
			"mastery": 0.55, "crit_rate": 0.10
		},
		"growth": {
			"hp": 50, "mp": 20, "str": 2, "dex": 1, "int": 1, "luk": 1, "watk": 4
		},
		"weapon_name": "初心木棒",
		"color": Color(0.8, 0.8, 0.8),
		"skills": {
			"basic": {
				"id": "basic", "name": "初心者揮擊", "tier": 0, "max_lvl": 1,
				"base_mult": 1.0, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "melee", "icon": "🗡️", "desc": "以手中的簡易武器揮擊目標。"
			},
			"skill_1": {
				"id": "skill_1", "name": "蝸牛投擲術 (Three Snails)", "tier": 1, "max_lvl": 3,
				"base_mult": 1.5, "lvl_mult": 0.5, "base_mp": 3, "lvl_mp": 2, "hits": 1, "cd": 0.5,
				"type": "snail_throw", "icon": "🐌", "desc": "消耗蝸牛殼投擲向遠距離敵人，造成固定與倍率真實傷害！"
			},
			"skill_2": {
				"id": "skill_2", "name": "疾風狂奔 (Nimble Feet)", "tier": 1, "max_lvl": 3,
				"base_mult": 1.3, "lvl_mult": 0.3, "base_mp": 5, "lvl_mp": 3, "hits": 2, "cd": 1.2,
				"type": "dash_strike", "icon": "👟", "desc": "短暫爆發移動速度並向前衝撞敵群！"
			},
			"skill_3": {
				"id": "skill_3", "name": "治癒之光 (Recovery)", "tier": 1, "max_lvl": 3,
				"base_mult": 1.8, "lvl_mult": 0.4, "base_mp": 10, "lvl_mp": 4, "hits": 1, "cd": 3.0,
				"type": "heal_aura", "icon": "💖", "desc": "引導生命能量，短時間內持續恢復自身與周遭生命！"
			},
			"skill_4": {
				"id": "skill_4", "name": "初心狂暴重擊", "tier": 1, "max_lvl": 10,
				"base_mult": 2.2, "lvl_mult": 0.15, "base_mp": 15, "lvl_mp": 2, "hits": 3, "cd": 2.0,
				"type": "melee_heavy", "icon": "🔨", "desc": "發揮初心者無窮潛力，猛力向下重擊引發震波！"
			},
			"skill_5": {
				"id": "skill_5", "name": "初心者之怒", "tier": 2, "max_lvl": 10,
				"base_mult": 3.0, "lvl_mult": 0.2, "base_mp": 25, "lvl_mp": 3, "hits": 4, "cd": 4.0,
				"type": "aoe_slash", "icon": "⚡", "desc": "釋放未經雕琢的冒險之魂，狂暴橫掃周圍敵群！"
			},
			"skill_6": {
				"id": "skill_6", "name": "冒險之魂審判", "tier": 2, "max_lvl": 10,
				"base_mult": 4.0, "lvl_mult": 0.25, "base_mp": 40, "lvl_mp": 4, "hits": 5, "cd": 5.0,
				"type": "ultimate_screen", "icon": "🌟", "desc": "召喚楓之谷群星的庇佑，對畫面敵群造成神聖制裁！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】初心覺醒 ‧ 楓之榮耀", "tier": 3, "max_lvl": 10,
				"base_mult": 6.5, "lvl_mult": 0.35, "base_mp": 60, "lvl_mp": 5, "hits": 6, "cd": 10.0,
				"type": "ultimate_screen", "icon": "🍁", "desc": "楓之谷初心神力全開！召喚楓葉風暴與神聖流星摧毀全場！"
			}
		}
	},
	"warrior": {
		"id": "warrior",
		"name": "劍士 (Warrior)",
		"title": "狂戰士 ‧ 見習騎士 ‧ 槍騎兵",
		"desc": "擁有極高的生命值與強大的近戰爆發力，手持巨劍與長槍劈砍敵群！",
		"primary_stat": "STR",
		"base_stats": {
			"str": 35, "dex": 15, "int": 4, "luk": 4,
			"hp": 950, "mp": 160, "watk": 58, "matk": 5,
			"mastery": 0.65, "crit_rate": 0.20
		},
		"growth": {
			"hp": 95, "mp": 20, "str": 4, "dex": 1, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "英雄雙手巨劍",
		"color": Color(1.0, 0.3, 0.2),
		"skills": {
			"basic": {
				"id": "basic", "name": "巨劍揮擊", "tier": 0, "max_lvl": 1,
				"base_mult": 1.2, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "melee", "icon": "🗡️", "desc": "揮舞巨劍劈砍前方目標。"
			},
			"skill_1": {
				"id": "skill_1", "name": "魔靈斬 (Power Strike)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.8, "lvl_mult": 0.11, "base_mp": 6, "lvl_mp": 0.5, "hits": 1, "cd": 0.5,
				"type": "melee_heavy", "icon": "💥", "desc": "凝聚全身氣力斬向單一敵人，滿級造成高達 400% 爆發巨額傷害！"
			},
			"skill_2": {
				"id": "skill_2", "name": "劍氣斬 (Slash Blast)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.3, "lvl_mult": 0.08, "base_mp": 10, "lvl_mp": 0.6, "hits": 2, "cd": 0.9,
				"type": "aoe_slash", "icon": "⚔️", "desc": "揮出半月劍氣橫掃周圍敵群，造成 2 段大範圍實體波及傷害！"
			},
			"skill_3": {
				"id": "skill_3", "name": "突進連斬 (Rush & Brandish)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.6, "lvl_mult": 0.10, "base_mp": 18, "lvl_mp": 0.8, "hits": 3, "cd": 1.8,
				"type": "rush_slash", "icon": "🛡️", "desc": "向前推擠敵群並連續揮出 3 段重擊，擊退霸體敵人！"
			},
			"skill_4": {
				"id": "skill_4", "name": "黑暗神兵 (Dark Force)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.0, "lvl_mult": 0.12, "base_mp": 28, "lvl_mp": 1.0, "hits": 4, "cd": 2.5,
				"type": "dark_force", "icon": "🐉", "desc": "釋放暗黑龍魂撕裂 4 次周圍敵群，附帶 10% 吸血回復！"
			},
			"skill_5": {
				"id": "skill_5", "name": "龍之咆哮 (Dragon Roar)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.4, "lvl_mult": 0.14, "base_mp": 38, "lvl_mp": 1.2, "hits": 3, "cd": 4.0,
				"type": "dragon_roar", "icon": "🐲", "desc": "仰天怒吼震碎全圖，對全螢幕所有怪物造成 3 段巨型衝擊波！"
			},
			"skill_6": {
				"id": "skill_6", "name": "聖十字審判 (Brandish Light)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.8, "lvl_mult": 0.16, "base_mp": 45, "lvl_mp": 1.5, "hits": 4, "cd": 4.5,
				"type": "holy_slash", "icon": "✝️", "desc": "召喚聖光十字雙重審判，對敵群造成 4 段 450%+ 聖光致命斬殺！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】諸神黃昏 ‧ 天崩地裂", "tier": 3, "max_lvl": 10,
				"base_mult": 5.5, "lvl_mult": 0.35, "base_mp": 70, "lvl_mp": 3.0, "hits": 6, "cd": 10.0,
				"type": "ultimate_screen", "icon": "🔥", "desc": "化身狂戰神撕裂空間，對全螢幕造成 6 段毀天滅地戰神巨響！"
			}
		}
	},
	"magician": {
		"id": "magician",
		"name": "魔法師 (Magician)",
		"title": "大魔導士 ‧ 主教 ‧ 聖靈祭司",
		"desc": "掌控元素冰火雷電與神聖創世紀，具備超大範圍魔法轟炸與生命治癒！",
		"primary_stat": "INT",
		"base_stats": {
			"str": 4, "dex": 4, "int": 38, "luk": 14,
			"hp": 560, "mp": 900, "watk": 12, "matk": 75,
			"mastery": 0.70, "crit_rate": 0.25
		},
		"growth": {
			"hp": 45, "mp": 85, "str": 0, "dex": 0, "int": 5, "luk": 1, "matk": 8
		},
		"weapon_name": "元素大魔杖",
		"color": Color(0.3, 0.7, 1.0),
		"skills": {
			"basic": {
				"id": "basic", "name": "魔力彈 (Energy Bolt)", "tier": 0, "max_lvl": 1,
				"base_mult": 1.25, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "magic_bolt", "icon": "🔮", "desc": "凝聚奧術能量發射一枚魔法光彈。"
			},
			"skill_1": {
				"id": "skill_1", "name": "魔力之爪 (Magic Claw)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.4, "lvl_mult": 0.09, "base_mp": 8, "lvl_mp": 0.5, "hits": 2, "cd": 0.5,
				"type": "magic_claw", "icon": "⚡", "desc": "召喚兩道金色奧術光爪撕裂敵人，造成 2 段無視防禦魔法打擊！"
			},
			"skill_2": {
				"id": "skill_2", "name": "狂雷連鎖 (Chain Lightning)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.5, "lvl_mult": 0.10, "base_mp": 16, "lvl_mp": 0.8, "hits": 3, "cd": 1.0,
				"type": "lightning_storm", "icon": "🌩️", "desc": "引爆高壓閃電並在周圍怪物間連鎖穿梭，造成 3 段電擊！"
			},
			"skill_3": {
				"id": "skill_3", "name": "冰風暴 (Ice Strike)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.9, "lvl_mult": 0.11, "base_mp": 24, "lvl_mp": 0.9, "hits": 3, "cd": 1.8,
				"type": "ice_strike", "icon": "❄️", "desc": "召喚萬丈極寒冰柱從地底刺出，冰封並重創範圍敵群！"
			},
			"skill_4": {
				"id": "skill_4", "name": "滅世隕石 (Meteor)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.5, "lvl_mult": 0.14, "base_mp": 36, "lvl_mp": 1.2, "hits": 3, "cd": 3.2,
				"type": "meteor", "icon": "☄️", "desc": "從虛空中召喚巨大熾熱隕石砸擊地面，引發全圖熾熱火海！"
			},
			"skill_5": {
				"id": "skill_5", "name": "暴風雪 (Blizzard)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.6, "lvl_mult": 0.15, "base_mp": 44, "lvl_mp": 1.4, "hits": 4, "cd": 4.0,
				"type": "blizzard", "icon": "🌨️", "desc": "極寒暴風雪籠罩全場，降下無數銳利冰錐連續打擊！"
			},
			"skill_6": {
				"id": "skill_6", "name": "天使之箭 (Angel Ray)", "tier": 2, "max_lvl": 20,
				"base_mult": 3.0, "lvl_mult": 0.18, "base_mp": 50, "lvl_mp": 1.5, "hits": 4, "cd": 4.5,
				"type": "angel_ray", "icon": "👼", "desc": "召喚熾天使神聖聖光射線貫穿敵群，同時治癒自身！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】神聖創世紀 (Genesis)", "tier": 3, "max_lvl": 10,
				"base_mult": 6.0, "lvl_mult": 0.40, "base_mp": 80, "lvl_mp": 3.5, "hits": 6, "cd": 10.0,
				"type": "ultimate_screen", "icon": "✨", "desc": "天降萬丈聖光神聖光柱，對全螢幕怪物施以 6 段神聖審判！"
			}
		}
	},
	"bowman": {
		"id": "bowman",
		"name": "弓箭手 (Bowman)",
		"title": "箭神 ‧ 神射手 ‧ 風靈使者",
		"desc": "超長射程與超高暴擊率，以狂風般的疾風箭雨瞬間射穿敵人！",
		"primary_stat": "DEX",
		"base_stats": {
			"str": 12, "dex": 38, "int": 4, "luk": 6,
			"hp": 680, "mp": 380, "watk": 54, "matk": 5,
			"mastery": 0.75, "crit_rate": 0.40
		},
		"growth": {
			"hp": 62, "mp": 30, "str": 1, "dex": 4, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "精靈神風長弓",
		"color": Color(0.2, 0.95, 0.4),
		"skills": {
			"basic": {
				"id": "basic", "name": "精準箭矢", "tier": 0, "max_lvl": 1,
				"base_mult": 1.2, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "arrow_single", "icon": "🏹", "desc": "搭弓射出一發精準箭矢。"
			},
			"skill_1": {
				"id": "skill_1", "name": "二連矢 (Double Shot)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.3, "lvl_mult": 0.08, "base_mp": 8, "lvl_mp": 0.5, "hits": 2, "cd": 0.4,
				"type": "arrow_double", "icon": "🎯", "desc": "迅捷射出兩支強烈箭矢，造成 2 段精準狙擊！"
			},
			"skill_2": {
				"id": "skill_2", "name": "漫天箭雨 (Arrow Rain)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.3, "lvl_mult": 0.09, "base_mp": 16, "lvl_mp": 0.7, "hits": 3, "cd": 0.9,
				"type": "arrow_rain", "icon": "🌧️", "desc": "向天發射箭矢如暴雨般落下，造成 3 段廣域轟炸！"
			},
			"skill_3": {
				"id": "skill_3", "name": "炸彈箭 (Arrow Bomb)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.8, "lvl_mult": 0.11, "base_mp": 20, "lvl_mp": 0.8, "hits": 2, "cd": 1.5,
				"type": "arrow_bomb", "icon": "💣", "desc": "發射附帶火藥的爆破箭矢，命中時引發劇烈範圍爆炸！"
			},
			"skill_4": {
				"id": "skill_4", "name": "貫穿之箭 (Piercing Arrow)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.2, "lvl_mult": 0.13, "base_mp": 30, "lvl_mp": 1.0, "hits": 4, "cd": 2.5,
				"type": "piercing_arrow", "icon": "🌪️", "desc": "蓄力射出貫穿全直線所有敵人的旋風巨箭！"
			},
			"skill_5": {
				"id": "skill_5", "name": "召喚烈火鳳凰 (Phoenix Strike)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.6, "lvl_mult": 0.15, "base_mp": 40, "lvl_mp": 1.2, "hits": 3, "cd": 4.0,
				"type": "phoenix", "icon": "🦅", "desc": "召喚火鳳凰自九天俯衝撲殺敵群，引發烈火焚燒！"
			},
			"skill_6": {
				"id": "skill_6", "name": "暴風神射 (Hurricane)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.1, "lvl_mult": 0.06, "base_mp": 45, "lvl_mp": 1.4, "hits": 8, "cd": 4.5,
				"type": "hurricane", "icon": "💨", "desc": "如加特林機槍般狂風掃射！瞬間轟出 8 支致命疾風箭！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】神箭萬丈 ‧ 滅世神風", "tier": 3, "max_lvl": 10,
				"base_mult": 5.8, "lvl_mult": 0.38, "base_mp": 75, "lvl_mp": 3.0, "hits": 8, "cd": 10.0,
				"type": "ultimate_screen", "icon": "🌠", "desc": "射出金色神風貫穿天際，引發 8 段全屏毀滅箭雨！"
			}
		}
	},
	"thief": {
		"id": "thief",
		"name": "盜賊 (Thief)",
		"title": "夜使者 ‧ 暗影神偷 ‧ 影武者",
		"desc": "極致的靈敏度與高段數爆發，以飛鏢與影分身斬殺敵首！",
		"primary_stat": "LUK",
		"base_stats": {
			"str": 6, "dex": 14, "int": 4, "luk": 38,
			"hp": 650, "mp": 400, "watk": 53, "matk": 5,
			"mastery": 0.70, "crit_rate": 0.35
		},
		"growth": {
			"hp": 58, "mp": 32, "str": 0, "dex": 1, "int": 0, "luk": 4, "watk": 6
		},
		"weapon_name": "無影金標 & 拳套",
		"color": Color(0.85, 0.35, 1.0),
		"skills": {
			"basic": {
				"id": "basic", "name": "手裏劍投擲", "tier": 0, "max_lvl": 1,
				"base_mult": 1.15, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "shuriken", "icon": "🗡️", "desc": "投擲手裏劍攻擊目標。"
			},
			"skill_1": {
				"id": "skill_1", "name": "雙飛斬 (Lucky Seven)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.5, "lvl_mult": 0.09, "base_mp": 8, "lvl_mp": 0.5, "hits": 2, "cd": 0.4,
				"type": "lucky_seven", "icon": "🥷", "desc": "經典雙飛投擲兩枚金鏢，受 LUK 幸運巨額加成！"
			},
			"skill_2": {
				"id": "skill_2", "name": "落葉斬 (Assaulter)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.6, "lvl_mult": 0.10, "base_mp": 15, "lvl_mp": 0.7, "hits": 3, "cd": 0.9,
				"type": "assaulter", "icon": "🍂", "desc": "化作殘影瞬間穿透怪物身軀，造成 3 段突襲刺殺！"
			},
			"skill_3": {
				"id": "skill_3", "name": "迴旋斬 ‧ 六連擊 (Savage Blow)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.1, "lvl_mult": 0.06, "base_mp": 22, "lvl_mp": 0.9, "hits": 6, "cd": 1.5,
				"type": "savage_blow", "icon": "🔪", "desc": "以令人目眩的極速在瞬間斬出 6 段暗影匕首連擊！"
			},
			"skill_4": {
				"id": "skill_4", "name": "楓葉狂刀 (Band of Thieves)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.1, "lvl_mult": 0.12, "base_mp": 32, "lvl_mp": 1.0, "hits": 4, "cd": 2.5,
				"type": "band_thieves", "icon": "👥", "desc": "召喚盜賊兄弟會幻影齊聚斬殺，造成 4 段範圍絞殺！"
			},
			"skill_5": {
				"id": "skill_5", "name": "三連投擲 (Triple Throw)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.8, "lvl_mult": 0.11, "base_mp": 40, "lvl_mp": 1.2, "hits": 5, "cd": 3.5,
				"type": "triple_throw", "icon": "⭐", "desc": "影分身協同投擲出 5 枚強化劇毒手裏劍！"
			},
			"skill_6": {
				"id": "skill_6", "name": "暗影分身斬 (Shadow Partner)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.4, "lvl_mult": 0.14, "base_mp": 48, "lvl_mp": 1.4, "hits": 6, "cd": 4.5,
				"type": "shadow_partner", "icon": "👤", "desc": "本體與影分身同步施展絕殺，狂暴斬出 6 段暗影傷害！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】百鬼夜行 ‧ 影之奧義", "tier": 3, "max_lvl": 10,
				"base_mult": 6.2, "lvl_mult": 0.40, "base_mp": 75, "lvl_mp": 3.0, "hits": 8, "cd": 10.0,
				"type": "ultimate_screen", "icon": "🌑", "desc": "全螢幕暗夜黑幕降臨，無數影分身穿梭爆發 8 段刺殺！"
			}
		}
	},
	"pirate": {
		"id": "pirate",
		"name": "海盜 (Pirate)",
		"title": "拳霸 ‧ 槍神 ‧ 重砲指揮官",
		"desc": "結合體術格鬥拳法與重火器射擊，攻守兼備無所畏懼！",
		"primary_stat": "STR/DEX",
		"base_stats": {
			"str": 25, "dex": 25, "int": 4, "luk": 4,
			"hp": 830, "mp": 350, "watk": 55, "matk": 5,
			"mastery": 0.70, "crit_rate": 0.25
		},
		"growth": {
			"hp": 78, "mp": 28, "str": 2, "dex": 2, "int": 0, "luk": 0, "watk": 6
		},
		"weapon_name": "重金屬火槍 & 指虎",
		"color": Color(1.0, 0.65, 0.1),
		"skills": {
			"basic": {
				"id": "basic", "name": "直拳重擊", "tier": 0, "max_lvl": 1,
				"base_mult": 1.2, "lvl_mult": 0.0, "base_mp": 0, "lvl_mp": 0, "hits": 1, "cd": 0.0,
				"type": "pirate_fist", "icon": "👊", "desc": "向前轟出直拳。"
			},
			"skill_1": {
				"id": "skill_1", "name": "雙連彈 (Double Fire)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.3, "lvl_mult": 0.08, "base_mp": 8, "lvl_mp": 0.5, "hits": 2, "cd": 0.4,
				"type": "pirate_bullet", "icon": "🔫", "desc": "拔槍連續射出兩發烈焰子彈！"
			},
			"skill_2": {
				"id": "skill_2", "name": "昇龍拳 (Somersault Kick)", "tier": 1, "max_lvl": 20,
				"base_mult": 1.4, "lvl_mult": 0.09, "base_mp": 14, "lvl_mp": 0.6, "hits": 3, "cd": 0.9,
				"type": "pirate_kick", "icon": "🌪️", "desc": "騰空旋風踢擊退周遭 360 度所有近身敵人！"
			},
			"skill_3": {
				"id": "skill_3", "name": "能量爆發 (Energy Blast)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.9, "lvl_mult": 0.11, "base_mp": 22, "lvl_mp": 0.8, "hits": 3, "cd": 1.6,
				"type": "energy_blast", "icon": "⚡", "desc": "聚集全身鬥氣轟出超巨型雷射衝擊波！"
			},
			"skill_4": {
				"id": "skill_4", "name": "迅雷不及掩耳 (Rapid Fire)", "tier": 2, "max_lvl": 20,
				"base_mult": 1.2, "lvl_mult": 0.07, "base_mp": 32, "lvl_mp": 1.0, "hits": 6, "cd": 2.5,
				"type": "rapid_fire", "icon": "🔥", "desc": "雙槍加特林瘋狂掃射，傾瀉 6 發爆裂燃燒彈！"
			},
			"skill_5": {
				"id": "skill_5", "name": "戰艦重砲轟擊 (Battleship Cannon)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.7, "lvl_mult": 0.15, "base_mp": 42, "lvl_mp": 1.2, "hits": 4, "cd": 3.8,
				"type": "battleship", "icon": "🚢", "desc": "召喚海盜戰艦巨砲齊發，引發毀滅性連環重砲轟炸！"
			},
			"skill_6": {
				"id": "skill_6", "name": "降龍十八掌 ‧ 閃連殺 (Dragon Strike)", "tier": 2, "max_lvl": 20,
				"base_mult": 2.2, "lvl_mult": 0.13, "base_mp": 50, "lvl_mp": 1.4, "hits": 6, "cd": 4.5,
				"type": "dragon_strike", "icon": "🐉", "desc": "召喚金龍之魂附體，以狂暴體術連續轟出 6 段超重擊！"
			},
			"ultimate": {
				"id": "ultimate", "name": "【終極奧義】海賊艦隊 ‧ 全彈發射", "tier": 3, "max_lvl": 10,
				"base_mult": 6.0, "lvl_mult": 0.40, "base_mp": 75, "lvl_mp": 3.0, "hits": 8, "cd": 10.0,
				"type": "ultimate_screen", "icon": "💣", "desc": "海賊艦隊全體出動向全螢幕傾瀉無盡砲火，造成 8 段浩劫！"
			}
		}
	}
}

static func get_job(job_id: String) -> Dictionary:
	if JOBS.has(job_id):
		return JOBS[job_id]
	return JOBS["warrior"]

static func get_skill_stats(job_id: String, skill_id: String, skill_lvl: int) -> Dictionary:
	var job = get_job(job_id)
	var skills = job.get("skills", {})
	if not skills.has(skill_id):
		return {}
		
	var s = skills[skill_id].duplicate()
	var lvl = clamp(skill_lvl, 1, s.get("max_lvl", 20))
	var base_mult = s.get("base_mult", 1.0)
	var lvl_mult = s.get("lvl_mult", 0.1)
	var base_mp = s.get("base_mp", 10)
	var lvl_mp = s.get("lvl_mp", 1.0)
	
	s["current_level"] = lvl
	s["multiplier"] = base_mult + (lvl - 1) * lvl_mult
	s["mp"] = int(base_mp + (lvl - 1) * lvl_mp)
	return s
