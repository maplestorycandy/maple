# MapDatabase.gd
extends Node

const MAPS = {
	"henesys_field": {
		"name": "【主城】楓葉草原 & 女神要塞",
		"biome_idx": 1,
		"bg_top_color": Color(0.4, 0.7, 1.0),
		"bg_bottom_color": Color(0.7, 0.9, 0.5),
		"ground_color": Color(0.35, 0.75, 0.25),
		"platform_color": Color(0.55, 0.35, 0.18),
		"description": "中央女神庇護所，50波怪物在此集結進攻！",
		"is_sanctuary": true,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [1, 2, 3, 4, 5, 6, 7, 8, 9]
	},
	"perion_highlands": {
		"name": "【野圖 2】勇士部落 - 狂風岩地",
		"biome_idx": 2,
		"bg_top_color": Color(0.85, 0.55, 0.35),
		"bg_bottom_color": Color(0.95, 0.75, 0.5),
		"ground_color": Color(0.7, 0.45, 0.25),
		"platform_color": Color(0.5, 0.3, 0.15),
		"description": "險峻紅岩與木妖盤據的高原！",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [11, 12, 13, 14, 15, 16, 17, 18, 19]
	},
	"ellinia_forest": {
		"name": "【野圖 3】魔法密林 - 巨木樹洞",
		"biome_idx": 1,
		"bg_top_color": Color(0.15, 0.35, 0.25),
		"bg_bottom_color": Color(0.3, 0.6, 0.4),
		"ground_color": Color(0.2, 0.5, 0.2),
		"platform_color": Color(0.35, 0.25, 0.15),
		"description": "古木參天，幽暗中潛藏著各類菇菇與魔靈。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [4, 5, 6, 7, 8, 12, 13, 18]
	},
	"kerning_subway": {
		"name": "【野圖 4】廢棄都市 - 霓虹地下鐵道",
		"biome_idx": 3,
		"bg_top_color": Color(0.08, 0.08, 0.12),
		"bg_bottom_color": Color(0.18, 0.15, 0.22),
		"ground_color": Color(0.25, 0.25, 0.28),
		"platform_color": Color(0.4, 0.35, 0.3),
		"description": "廢棄下水道與鐵軌，大幽靈與鱷魚遊蕩。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [21, 22, 23, 24, 25, 26, 27, 28, 29]
	},
	"sleepywood_temple": {
		"name": "【野圖 5】奇幻村 - 詛咒寺院迷宮",
		"biome_idx": 4,
		"bg_top_color": Color(0.12, 0.05, 0.15),
		"bg_bottom_color": Color(0.3, 0.1, 0.2),
		"ground_color": Color(0.2, 0.15, 0.2),
		"platform_color": Color(0.35, 0.2, 0.3),
		"description": "地獄犬與地獄巴洛古棲息的深層古廟。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [31, 32, 33, 34, 35, 36, 37, 38, 39]
	},
	"elnath_snowfield": {
		"name": "【野圖 6】冰原雪域 - 萬年峭壁",
		"biome_idx": 5,
		"bg_top_color": Color(0.5, 0.7, 0.9),
		"bg_bottom_color": Color(0.85, 0.92, 1.0),
		"ground_color": Color(0.8, 0.9, 0.95),
		"platform_color": Color(0.6, 0.75, 0.85),
		"description": "雪花紛飛的寒冬之地，雪吉拉與狼人縱橫。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [41, 42, 43, 44, 45, 46, 47, 48, 49]
	},
	"ludibrium_clocktower": {
		"name": "【野圖 7】玩具城 - 時光之塔底層",
		"biome_idx": 6,
		"bg_top_color": Color(0.2, 0.1, 0.4),
		"bg_bottom_color": Color(0.4, 0.2, 0.55),
		"ground_color": Color(0.8, 0.3, 0.2),
		"platform_color": Color(0.2, 0.6, 0.7),
		"description": "積木與發條機械組成的時鐘異度空間。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [51, 52, 53, 54, 55, 56, 57, 58, 59]
	},
	"aqua_road": {
		"name": "【野圖 8】水世界 - 深海藍洞珊瑚礁",
		"biome_idx": 7,
		"bg_top_color": Color(0.02, 0.1, 0.25),
		"bg_bottom_color": Color(0.05, 0.3, 0.5),
		"ground_color": Color(0.15, 0.4, 0.45),
		"platform_color": Color(0.2, 0.5, 0.6),
		"description": "蔚藍深海，幽靈船長與凶猛鯊魚在深處遊弋。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [61, 62, 63, 64, 65, 66, 67, 68, 69]
	},
	"leafre_dragon_nest": {
		"name": "【野圖 9】神木村 - 龍之主巢穴",
		"biome_idx": 8,
		"bg_top_color": Color(0.3, 0.15, 0.05),
		"bg_bottom_color": Color(0.6, 0.35, 0.1),
		"ground_color": Color(0.4, 0.3, 0.2),
		"platform_color": Color(0.6, 0.45, 0.25),
		"description": "強悍龍族與半人馬一族的古老領地。",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [71, 72, 73, 74, 75, 76, 77, 78, 79]
	},
	"temple_of_time": {
		"name": "【野圖 10】時間神殿 - 滅世終焉空間",
		"biome_idx": 10,
		"bg_top_color": Color(0.05, 0.0, 0.1),
		"bg_bottom_color": Color(0.2, 0.05, 0.3),
		"ground_color": Color(0.3, 0.25, 0.4),
		"platform_color": Color(0.45, 0.35, 0.6),
		"description": "神殿極點與滅世空間，混沌之神皮卡啾等待著勇者！",
		"is_sanctuary": false,
		"world_rect": Rect2(-1800, -800, 3600, 1600),
		"wild_mob_ids": [81, 83, 85, 87, 89, 91, 93, 95, 96]
	}
}

func get_map_list() -> Array:
	var list = []
	for key in MAPS.keys():
		var m = MAPS[key].duplicate()
		m["id"] = key
		list.append(m)
	return list
