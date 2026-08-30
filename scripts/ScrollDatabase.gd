# ScrollDatabase.gd
# 楓之谷經典版官方卷軸資料庫（收錄 93 種官方怪物掉落卷軸與完整衝裝機制）
# 資料來源：https://bobogameguides.com/maplestory-classic/scrolls/
extends Node

var SCROLLS: Dictionary = {}
var MONSTER_SCROLL_DROP_MAP: Dictionary = {}

func _init():
	_init_scrolls()
	_init_monster_drop_map()

func _init_scrolls():
	SCROLLS = {
		"2040402": {
			"id": "2040402",
			"name": "上衣防禦卷軸10%",
			"target_slot": "top",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 15},
			"mobs": ["木妖", "紅寶王", "樹妖王", "礦山殭屍", "黑利堤", "喵怪仙人", "地獄巴洛古", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040400": {
			"id": "2040400",
			"name": "上衣防禦卷軸100%",
			"target_slot": "top",
			"rate": 100,
			"is_cursed": false,
			"stats": {"def": 5},
			"mobs": ["穆魯帕"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040401": {
			"id": "2040401",
			"name": "上衣防禦卷軸60%",
			"target_slot": "top",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 10},
			"mobs": ["紅寶王", "黃金海馬", "禿鷹", "鼬鼠鬧鐘", "咕咕鐘", "蜈蚣大王", "蘑菇王", "變身小鬼怪", "黑龍", "骨骸魚", "怨靈女巫", "藍翼龍", "艾利傑", "海怒斯", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043002": {
			"id": "2043002",
			"name": "單手劍攻擊卷軸10%",
			"target_slot": "one-handed sword",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["三眼章魚", "狐蒙", "沙漠毒蠍", "紅獨角獅", "巨居蟹", "黑暗萊西", "巨人維京", "地獄巴洛古", "赤翼龍"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043001": {
			"id": "2043001",
			"name": "單手劍攻擊卷軸60%",
			"target_slot": "one-handed sword",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "str": 1},
			"mobs": ["黃色戰鬥機", "樹妖王", "蜈蚣大王", "鱷魚克洛克", "殭屍蘑菇王", "綠色鬼怪", "巴洛古", "尖鼻鯊魚", "噴火龍", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043102": {
			"id": "2043102",
			"name": "單手斧攻擊卷軸10%",
			"target_slot": "one-handed axe",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 2},
			"mobs": ["綠菇菇", "鼬鼠", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043101": {
			"id": "2043101",
			"name": "單手斧攻擊卷軸60%",
			"target_slot": "one-handed axe",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "str": 1},
			"mobs": ["樹妖王", "蜈蚣大王", "葛雷金剛", "殭屍蘑菇王", "月牙牛魔王", "肯德熊", "喵怪仙人", "巴洛古", "噴火龍", "藍色蘑菇王", "金勾海賊王", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043202": {
			"id": "2043202",
			"name": "單手棍攻擊卷軸10%",
			"target_slot": "one-handed blunt weapon",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 2},
			"mobs": ["斧木妖", "玩具鴨", "獨眼蝙蝠", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043201": {
			"id": "2043201",
			"name": "單手棍攻擊卷軸60%",
			"target_slot": "one-handed blunt weapon",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "str": 1},
			"mobs": ["紅寶王", "樹妖王", "青螃蟹", "咕咕鐘", "蜈蚣大王", "殭屍蘑菇王", "巴洛古", "噴火龍", "金勾海賊王", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040502": {
			"id": "2040502",
			"name": "套服敏捷卷軸10%",
			"target_slot": "overall",
			"rate": 10,
			"is_cursed": false,
			"stats": {"dex": 5, "speed": 2},
			"mobs": ["紅寶", "樹妖王", "紅色機器人", "咕咕鐘", "百烈", "地獄巴洛古", "格瑞芬多", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040500": {
			"id": "2040500",
			"name": "套服敏捷卷軸100%",
			"target_slot": "overall",
			"rate": 100,
			"is_cursed": false,
			"stats": {"dex": 1, "speed": 2},
			"mobs": ["穆魯君"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040501": {
			"id": "2040501",
			"name": "套服敏捷卷軸60%",
			"target_slot": "overall",
			"rate": 60,
			"is_cursed": false,
			"stats": {"dex": 3, "speed": 2},
			"mobs": ["發芽木妖", "仙人掌", "紅寶王", "花鯰魚", "仙人長老", "蜈蚣大王", "蘑菇王", "變身小鬼怪", "沼澤巨鱷", "九尾妖狐", "骨骸魚", "雙刀龍戰士", "忘卻的守護隊長", "雪毛怪人", "奇美拉", "海怒斯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040505": {
			"id": "2040505",
			"name": "套服防禦卷軸10%",
			"target_slot": "overall",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 20},
			"mobs": ["黑暗萊西", "地獄巴洛古", "格瑞芬多", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040504": {
			"id": "2040504",
			"name": "套服防禦卷軸60%",
			"target_slot": "overall",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 15},
			"mobs": ["仙人長老", "總理大神", "強化鋼鐵穆太", "積木泥人王", "紅花蛇", "日光精靈", "訓練用木頭人", "殭屍猴王", "蜈蚣大王", "蘑菇王", "黃色鬼怪", "喵怪仙人", "奇美拉", "海怒斯", "法郎肯洛伊德"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048005": {
			"id": "2048005",
			"name": "寵物跳躍力卷軸10%",
			"target_slot": "weapon",
			"rate": 10,
			"is_cursed": false,
			"stats": {},
			"mobs": ["紅螃蟹", "肯德熊"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048003": {
			"id": "2048003",
			"name": "寵物跳躍力卷軸100%",
			"target_slot": "weapon",
			"rate": 100,
			"is_cursed": false,
			"stats": {},
			"mobs": ["青蛇"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048004": {
			"id": "2048004",
			"name": "寵物跳躍力卷軸60%",
			"target_slot": "weapon",
			"rate": 60,
			"is_cursed": false,
			"stats": {},
			"mobs": ["蝙蝠", "長牙海豹", "黑豪豬", "殭屍蘑菇王", "暗黑半人馬"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048002": {
			"id": "2048002",
			"name": "寵物速度卷軸10%",
			"target_slot": "weapon",
			"rate": 10,
			"is_cursed": false,
			"stats": {},
			"mobs": ["小幽靈", "機器章魚王", "沼澤巨鱷"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048000": {
			"id": "2048000",
			"name": "寵物速度卷軸100%",
			"target_slot": "weapon",
			"rate": 100,
			"is_cursed": false,
			"stats": {},
			"mobs": ["穆魯穆魯", "綠菇菇"],
			"icon": "res://assets/items/scroll.png"
		},
		"2048001": {
			"id": "2048001",
			"name": "寵物速度卷軸60%",
			"target_slot": "weapon",
			"rate": 60,
			"is_cursed": false,
			"stats": {},
			"mobs": ["發芽木妖", "藍水靈", "圍巾蜥蜴", "巨居蟹", "殭屍蘑菇王", "刺鰭魚"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040739": {
			"id": "2040739",
			"name": "巴洛古的鞋子強化卷軸5%",
			"target_slot": "shoes",
			"rate": 5,
			"is_cursed": false,
			"stats": {},
			"mobs": ["巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044502": {
			"id": "2044502",
			"name": "弓攻擊卷軸10%",
			"target_slot": "bow",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "dex": 3},
			"mobs": ["黑妖苗", "風獨眼獸", "咕咕鐘", "沼澤巨鱷", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044501": {
			"id": "2044501",
			"name": "弓攻擊卷軸60%",
			"target_slot": "bow",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "dex": 1},
			"mobs": ["耳罩蜥蜴", "沙漠地鼠", "幼黃獨角獅", "發條貓熊", "發條楓葉鼠", "長牙海豹", "黑豪豬", "石巨人", "蜈蚣大王", "殭屍蘑菇王", "肯德熊", "九尾妖狐", "巴洛古", "噴火龍", "悔恨的守護隊長", "萊伊卡", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044602": {
			"id": "2044602",
			"name": "弩攻擊卷軸10%",
			"target_slot": "crossbow",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "dex": 3},
			"mobs": ["公砂兔", "小雪球", "小虎", "強化鋰礦穆太", "機器人堤安", "訓練用稻草人", "邪惡侏儒怪", "哈摩斯庫拉", "哈維", "黑暗冥鐘", "維京", "地獄巴洛古", "化石龍", "忘卻的守護兵"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044601": {
			"id": "2044601",
			"name": "弩攻擊卷軸60%",
			"target_slot": "crossbow",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "dex": 1},
			"mobs": ["花鯰魚", "仙人長老", "總理大神", "石巨人", "巨居蟹", "殭屍猴王", "蜈蚣大王", "沼澤巨鱷", "殭屍蘑菇王", "哈門庫魯", "黑格里芬", "肯德熊", "喵怪仙人", "巴洛古", "暗黑三角龍", "噴火龍", "忘卻的祭司", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040805": {
			"id": "2040805",
			"name": "手套攻擊卷軸10%",
			"target_slot": "gloves",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 3},
			"mobs": ["烏龜", "火蚌殼", "火石球", "肯德熊", "火焰半人馬", "地獄巴洛古", "噴火龍", "化石龍"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040804": {
			"id": "2040804",
			"name": "手套攻擊卷軸60%",
			"target_slot": "gloves",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2},
			"mobs": ["火蚌殼", "進化妖魔", "馬堤安", "培利堤安", "小雪球", "小虎", "奈歐洛伊德", "梅花鹿", "混種石巨人", "巨居蟹", "咕咕鐘", "蜈蚣大王", "蘑菇王", "沼澤巨鱷", "葛雷金剛", "幽魂發條熊", "骷髏士官", "九尾妖狐", "致命烏賊怪", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040802": {
			"id": "2040802",
			"name": "手套敏捷卷軸10%",
			"target_slot": "gloves",
			"rate": 10,
			"is_cursed": false,
			"stats": {"dex": 3, "accuracy": 2},
			"mobs": ["黑木妖", "葛雷隊長", "巨居蟹", "冥鐘", "地獄巴洛古", "達納托斯", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040801": {
			"id": "2040801",
			"name": "手套敏捷卷軸60%",
			"target_slot": "gloves",
			"rate": 60,
			"is_cursed": false,
			"stats": {"dex": 2, "accuracy": 2},
			"mobs": ["發芽木妖", "樹妖王", "仙人長老", "蒙面河豚", "總理大神", "毒河豚", "殭屍猴王", "蜈蚣大王", "蘑菇王", "橡木甲蟲", "喵怪仙人", "致命烏賊怪", "雪毛怪人", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041014": {
			"id": "2041014",
			"name": "披風力量卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"str": 3},
			"mobs": ["黑食人花", "獨眼蝙蝠", "木乃伊犬", "石蟲", "惡魔綿羊"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041012": {
			"id": "2041012",
			"name": "披風力量卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"str": 1},
			"mobs": ["星光精靈", "紅獨角獅"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041013": {
			"id": "2041013",
			"name": "披風力量卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"str": 2},
			"mobs": ["烏龜", "巨居蟹", "咕咕鐘", "特貝爾芬", "鯊魚", "化石龍長老", "奇美拉", "拉圖斯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041023": {
			"id": "2041023",
			"name": "披風幸運卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"luk": 3},
			"mobs": ["機器章魚", "虎傑", "藍獨角獅", "深山人蔘", "雪吉拉戰車", "幼龍保護者"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041021": {
			"id": "2041021",
			"name": "披風幸運卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"luk": 1},
			"mobs": ["肥肥", "地獄獵犬"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041022": {
			"id": "2041022",
			"name": "披風幸運卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"luk": 2},
			"mobs": ["巨居蟹", "幽魂發條熊隊長", "貝爾芬", "黑吉拉", "肯德熊", "煉獄獵犬", "藍色雙角龍", "幽魂女巫", "尖鼻鯊魚", "忘卻的神官", "奇美拉", "拉圖斯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041020": {
			"id": "2041020",
			"name": "披風敏捷卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"dex": 3},
			"mobs": ["雪吉拉戰車", "艾利傑"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041018": {
			"id": "2041018",
			"name": "披風敏捷卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"dex": 1},
			"mobs": ["穆魯菲亞", "綠水靈", "禿鷹", "鼬鼠"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041019": {
			"id": "2041019",
			"name": "披風敏捷卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"dex": 2},
			"mobs": ["鋼鐵穆太", "短牙海豹", "野狼", "艾利傑", "奇美拉", "拉圖斯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041017": {
			"id": "2041017",
			"name": "披風智力卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"int": 3},
			"mobs": ["粉紅發條熊", "樹妖王", "總理大神", "小獵犬", "日光精靈", "黃獨角獅", "殭屍猴王", "九尾妖狐", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041015": {
			"id": "2041015",
			"name": "披風智力卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"int": 1},
			"mobs": ["藍水靈"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041016": {
			"id": "2041016",
			"name": "披風智力卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"int": 2},
			"mobs": ["紅寶王", "木面怪人", "石球", "樹妖王", "總理大神", "冰石球", "殭屍猴王", "咕咕鐘", "葛雷金剛", "怨靈發條熊", "九尾妖狐", "雪毛怪人", "奇美拉", "拉圖斯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041008": {
			"id": "2041008",
			"name": "披風生命卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"hp": 50},
			"mobs": ["木妖", "火蚌殼", "沼澤巨鱷", "變種侏儒怪", "侏儒怪", "忘卻的守護兵", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041006": {
			"id": "2041006",
			"name": "披風生命卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"hp": 10},
			"mobs": ["藍寶"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041007": {
			"id": "2041007",
			"name": "披風生命卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"hp": 30},
			"mobs": ["菇菇仔", "仙人長老", "火蚌殼", "綠色鬼怪", "艾利傑", "奇美拉"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041005": {
			"id": "2041005",
			"name": "披風防禦卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 15},
			"mobs": ["石球", "星光精靈", "葛雷族人", "雪吉拉戰車", "喵怪仙人", "哈摩斯庫拉", "哈維"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041004": {
			"id": "2041004",
			"name": "披風防禦卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 10},
			"mobs": ["穆魯穆魯", "藍水靈", "獨角尼莫", "樹妖王", "仙人長老", "蜈蚣大王", "蘑菇王", "黑龍", "化石龍長老"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041011": {
			"id": "2041011",
			"name": "披風魔力卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"mp": 50},
			"mobs": ["食人花"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041009": {
			"id": "2041009",
			"name": "披風魔力卷軸100%",
			"target_slot": "cape",
			"rate": 100,
			"is_cursed": false,
			"stats": {"mp": 10},
			"mobs": ["紅寶", "怨靈發條熊隊長"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041010": {
			"id": "2041010",
			"name": "披風魔力卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"mp": 30},
			"mobs": ["猴子", "樹妖王", "火精靈", "肯德熊", "九尾妖狐", "喵怪仙人", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041002": {
			"id": "2041002",
			"name": "披風魔防卷軸10%",
			"target_slot": "cape",
			"rate": 10,
			"is_cursed": false,
			"stats": {"mdef": 15},
			"mobs": ["成年仙人掌", "蝙蝠", "鱷魚", "總理大神", "巨居蟹", "殭屍猴王", "咕咕鐘", "金屬甲蟲"],
			"icon": "res://assets/items/scroll.png"
		},
		"2041001": {
			"id": "2041001",
			"name": "披風魔防卷軸60%",
			"target_slot": "cape",
			"rate": 60,
			"is_cursed": false,
			"stats": {"mdef": 10},
			"mobs": ["嫩寶", "樹妖王", "木馬士兵", "食人花", "蜈蚣大王", "蘑菇王", "小丑柏非", "沼澤巨鱷", "黑龍", "百烈", "肯德熊", "鯊魚", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044702": {
			"id": "2044702",
			"name": "拳套攻擊卷軸10%",
			"target_slot": "claw",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "luk": 3},
			"mobs": ["沼澤巨鱷", "雪吉拉戰車", "九尾妖狐", "邪惡綿羊", "怨靈女巫", "地獄巴洛古", "幼年龍", "回憶守護兵"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044701": {
			"id": "2044701",
			"name": "拳套攻擊卷軸60%",
			"target_slot": "claw",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "luk": 1},
			"mobs": ["沙漠矮人", "方塊水靈", "紅砂矮人", "幼紅獨角獅", "叛徒菇菇仔", "毒菇", "總理大神", "鼬鼠鬧鐘", "骷髏士兵", "巨居蟹", "殭屍猴王", "蜈蚣大王", "沼澤巨鱷", "殭屍蘑菇王", "D．洛伊", "刺鰭魚", "狼人", "巴洛古", "獨角迅猛龍", "噴火龍", "萊伊卡", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044802": {
			"id": "2044802",
			"name": "指虎攻擊卷軸10%",
			"target_slot": "knuckle",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["發芽木妖", "黃蜘蛛", "鱷魚", "紅螃蟹", "總理大神", "砂巨人", "黑曜石巨人", "殭屍猴王", "猿人肥肥", "鱷魚克洛克", "邪惡侏儒怪", "九尾妖狐", "黑吉拉戰車", "維京", "地獄巴洛古", "雙刀龍戰士", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044801": {
			"id": "2044801",
			"name": "指虎攻擊卷軸60%",
			"target_slot": "knuckle",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "str": 1},
			"mobs": ["狐蒙", "紅寶王", "蝙蝠", "仙人長老", "長牙海豹", "黑鱷魚", "咕咕鐘", "小丑瑞奇", "殭屍蘑菇王", "哈門庫魯", "肯德熊", "巴洛古", "邪惡綿羊", "進化迅猛龍", "噴火龍", "化石龍長老", "萊伊卡"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044302": {
			"id": "2044302",
			"name": "槍攻擊卷軸10%",
			"target_slot": "spear",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["殭屍菇菇", "獨角尼莫", "總理大神", "殭屍猴王", "喵怪仙人", "地獄巴洛古", "艾利傑"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044301": {
			"id": "2044301",
			"name": "槍攻擊卷軸60%",
			"target_slot": "spear",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 3, "str": 1},
			"mobs": ["石面怪人", "積木泥人王", "骷髏犬", "咕咕鐘", "蜈蚣大王", "葛雷金剛", "殭屍蘑菇王", "地獄獵犬", "怨靈發條熊隊長", "巴洛古", "黑翼龍", "噴火龍", "悔恨的守護兵", "艾利傑", "萊伊卡", "藍色蘑菇王", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044902": {
			"id": "2044902",
			"name": "火槍攻擊卷軸10%",
			"target_slot": "gun",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "dex": 3},
			"mobs": ["紅寶王", "風獨眼獸", "積木泥人王", "強化鋰礦穆太", "咕咕鐘", "船員克魯", "幽魂發條熊", "喵怪仙人", "哈摩斯庫拉", "藍色雙角龍", "地獄巴洛古", "鯊魚", "化石龍"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044901": {
			"id": "2044901",
			"name": "火槍攻擊卷軸60%",
			"target_slot": "gun",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "dex": 1},
			"mobs": ["小仙人掌", "妖魔", "兔子鼓手", "總理大神", "梅卡堤安", "虎傑", "殭屍猴王", "葛雷金剛", "殭屍蘑菇王", "黑格里芬", "刺鰭魚", "雪吉拉戰車", "九尾妖狐", "巴洛古", "赤翼龍", "噴火龍", "幼龍保護者", "回憶守護隊長", "萊伊卡"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040902": {
			"id": "2040902",
			"name": "盾牌防禦卷軸10%",
			"target_slot": "shield",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 20, "hp": 20},
			"mobs": ["緞帶肥肥", "沙漠蛇", "青蛇", "星光精靈", "特威德", "泥人領導者", "巨居蟹", "橡木甲蟲", "九尾妖狐", "白狼人", "巨人維京", "地獄巴洛古", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040900": {
			"id": "2040900",
			"name": "盾牌防禦卷軸100%",
			"target_slot": "shield",
			"rate": 100,
			"is_cursed": false,
			"stats": {"def": 5, "hp": 10},
			"mobs": ["黃蜘蛛", "綠海馬"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040901": {
			"id": "2040901",
			"name": "盾牌防禦卷軸60%",
			"target_slot": "shield",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 12, "hp": 10},
			"mobs": ["木面怪人", "樹妖王", "總理大神", "積木泥人", "毒河豚", "豪豬", "小虎", "強化鋰礦穆太", "奈歐洛伊德", "訓練用稻草人", "梅花鹿", "白狼", "混種石巨人", "殭屍猴王", "蜈蚣大王", "蘑菇王", "肯德熊", "暗黑半人馬", "進化迅猛龍", "鯊魚", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044402": {
			"id": "2044402",
			"name": "矛攻擊卷軸10%",
			"target_slot": "polearm",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["火獨眼獸", "地獄巴洛古", "黑翼龍", "艾利傑"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044400": {
			"id": "2044400",
			"name": "矛攻擊卷軸100%",
			"target_slot": "polearm",
			"rate": 100,
			"is_cursed": false,
			"stats": {"atk": 1, "str": 1},
			"mobs": ["穆魯君"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044401": {
			"id": "2044401",
			"name": "矛攻擊卷軸60%",
			"target_slot": "polearm",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 3, "str": 1},
			"mobs": ["白色發條鼠", "砂巨人", "蜈蚣大王", "沼澤巨鱷", "葛雷金剛", "殭屍蘑菇王", "變種侏儒怪", "多立百烈", "巴洛古", "噴火龍", "回憶的神官", "艾利傑", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043302": {
			"id": "2043302",
			"name": "短劍攻擊卷軸10%",
			"target_slot": "dagger",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "luk": 3},
			"mobs": ["藍水靈", "紅寶王", "藍色機器人", "賽伊迪", "船員克魯", "地獄巴洛古", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043301": {
			"id": "2043301",
			"name": "短劍攻擊卷軸60%",
			"target_slot": "dagger",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 2, "luk": 1},
			"mobs": ["紅螃蟹", "粉紅色戰鬥機", "蜈蚣大王", "沼澤巨鱷", "葛雷金剛", "幽魂發條熊隊長", "殭屍蘑菇王", "肯德熊", "九尾妖狐", "巴洛古", "血腥哈維", "短刃龍戰士", "噴火龍", "化石龍", "回憶的祭司", "艾利傑", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043702": {
			"id": "2043702",
			"name": "短杖魔力卷軸10%",
			"target_slot": "wand",
			"rate": 10,
			"is_cursed": false,
			"stats": {"matk": 5, "int": 3},
			"mobs": ["紅寶王", "妖魔", "總理大神", "殭屍猴王", "九尾妖狐", "地獄巴洛古", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043701": {
			"id": "2043701",
			"name": "短杖魔力卷軸60%",
			"target_slot": "wand",
			"rate": 60,
			"is_cursed": false,
			"stats": {"matk": 2, "int": 1},
			"mobs": ["狐蒙", "沙漠毒蠍", "紅寶王", "幼藍獨角獅", "三尾狐", "功夫熊", "黑色小雪球", "骷髏士兵", "咕咕鐘", "蜈蚣大王", "小丑柏非", "蟠猴", "魔龍", "殭屍蘑菇王", "D．洛伊", "狼人", "邪惡侏儒怪", "巴洛古", "寒冰半人馬", "噴火龍", "忘卻的守護隊長", "艾利傑", "雪毛怪人", "萊伊卡", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040302": {
			"id": "2040302",
			"name": "耳環智力卷軸10%",
			"target_slot": "earrings",
			"rate": 10,
			"is_cursed": false,
			"stats": {"int": 3, "matk": 5},
			"mobs": ["紅寶王", "黑妖苗三兄弟", "機器章魚王", "藍色戰鬥機", "粉紅小海豹", "火蚌殼", "咕咕鐘", "D．洛伊", "狼人", "黃色鬼怪", "冥鐘", "地獄巴洛古", "雙刀龍戰士", "黑翼龍", "格瑞芬多", "悔恨的守護兵", "艾利傑"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040301": {
			"id": "2040301",
			"name": "耳環智力卷軸60%",
			"target_slot": "earrings",
			"rate": 60,
			"is_cursed": false,
			"stats": {"int": 2, "matk": 3},
			"mobs": ["紅寶王", "石面怪人", "總理大神", "火蚌殼", "殭屍猴王", "蜈蚣大王", "蘑菇王", "鱷魚克洛克", "喵仙", "小丑瑞奇", "骷髏指揮官", "九尾妖狐", "尖鼻鯊魚", "艾利傑", "奇美拉"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040602": {
			"id": "2040602",
			"name": "褲、裙防禦卷軸10%",
			"target_slot": "bottom",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 15},
			"mobs": ["綠水靈", "樹妖王", "藍色機器人", "九尾妖狐", "獨角迅猛龍", "地獄巴洛古", "通道守門人", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040601": {
			"id": "2040601",
			"name": "褲、裙防禦卷軸60%",
			"target_slot": "bottom",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 10},
			"mobs": ["母砂兔", "紅寶王", "紅蜘蛛", "活跳蝦", "蜈蚣大王", "蘑菇王", "怨靈發條熊", "藍色鬼怪", "喵怪仙人", "烏賊怪", "雪毛怪人", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043802": {
			"id": "2043802",
			"name": "長杖魔力卷軸10%",
			"target_slot": "staff",
			"rate": 10,
			"is_cursed": false,
			"stats": {"matk": 5, "int": 3},
			"mobs": ["妖魔隊長", "梅卡堤安", "咕咕鐘", "幽魂發條熊", "骷髏士官", "邪惡綿羊", "地獄巴洛古", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2043801": {
			"id": "2043801",
			"name": "長杖魔力卷軸60%",
			"target_slot": "staff",
			"rate": 60,
			"is_cursed": false,
			"stats": {"matk": 3, "int": 1},
			"mobs": ["紅寶王", "石面怪人", "仙人長老", "總理大神", "葛雷元老", "三尾狐", "功夫熊", "骷髏士兵", "殭屍猴王", "蜈蚣大王", "小丑柏非", "殭屍蘑菇王", "雪吉拉戰車", "肯德熊", "九尾妖狐", "巴洛古", "黑吉拉戰車", "藍色雙角龍", "進化迅猛龍", "噴火龍", "幼龍保護者", "忘卻的神官", "雪毛怪人", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044002": {
			"id": "2044002",
			"name": "雙手劍攻擊卷軸10%",
			"target_slot": "two-handed sword",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["沙漠蛇", "藍菇菇", "樹妖王", "強化鋼鐵穆太", "積木泥人王", "紅花蛇", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044001": {
			"id": "2044001",
			"name": "雙手劍攻擊卷軸60%",
			"target_slot": "two-handed sword",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 3, "str": 1},
			"mobs": ["紅寶王", "仙人長老", "鋼之黑肥肥", "黃獨角獅", "蜈蚣大王", "沼澤巨鱷", "殭屍蘑菇王", "特貝爾芬", "喵怪仙人", "巴洛古", "黑吉拉戰車", "惡魔綿羊", "煉獄獵犬", "幽魂女巫", "藍翼龍", "噴火龍", "忘卻的祭司", "藍色蘑菇王", "法郎肯洛伊德", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044102": {
			"id": "2044102",
			"name": "雙手斧攻擊卷軸10%",
			"target_slot": "two-handed axe",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["小仙人掌", "刺菇菇", "鋰礦穆太", "妖魔隊長", "罈壺", "小石球", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044101": {
			"id": "2044101",
			"name": "雙手斧攻擊卷軸60%",
			"target_slot": "two-handed axe",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 3, "str": 1},
			"mobs": ["總理大神", "殭屍猴王", "蜈蚣大王", "殭屍蘑菇王", "金屬甲蟲", "長槍牛魔王", "雪吉拉戰車", "侏儒怪", "肯德熊", "巴洛古", "暗黑三角龍", "噴火龍", "悔恨的守護隊長", "金勾海賊王", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044202": {
			"id": "2044202",
			"name": "雙手棍攻擊卷軸10%",
			"target_slot": "two-handed blunt weapon",
			"rate": 10,
			"is_cursed": false,
			"stats": {"atk": 5, "str": 3},
			"mobs": ["黑斧木妖", "海膽", "地獄巴洛古"],
			"icon": "res://assets/items/scroll.png"
		},
		"2044201": {
			"id": "2044201",
			"name": "雙手棍攻擊卷軸60%",
			"target_slot": "two-handed blunt weapon",
			"rate": 60,
			"is_cursed": false,
			"stats": {"atk": 3, "str": 1},
			"mobs": ["仙人長老", "妖魔", "黑食人花", "木乃伊犬", "虎傑", "書靈", "黑曜石巨人", "咕咕鐘", "蜈蚣大王", "殭屍蘑菇王", "巴洛古", "噴火龍", "化石龍長老", "忘卻的守護兵", "藍色蘑菇王", "金勾海賊王", "超強型毒石巨人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040702": {
			"id": "2040702",
			"name": "鞋子敏捷卷軸10%",
			"target_slot": "shoes",
			"rate": 10,
			"is_cursed": false,
			"stats": {"dex": 3, "speed": 1},
			"mobs": ["肥肥", "巨居蟹", "沼澤巨鱷", "喵怪仙人", "地獄巴洛古", "達納托斯", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040701": {
			"id": "2040701",
			"name": "鞋子敏捷卷軸60%",
			"target_slot": "shoes",
			"rate": 60,
			"is_cursed": false,
			"stats": {"dex": 2, "speed": 1},
			"mobs": ["泡泡魚", "褐色發條熊", "樹妖王", "蒙面河豚", "中毒的豬", "蜈蚣大王", "蘑菇王", "藍色鬼怪", "九尾妖狐", "喵怪仙人", "烏賊怪", "赤翼龍", "悔恨的守護兵", "雪毛怪人"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040705": {
			"id": "2040705",
			"name": "鞋子跳躍卷軸10%",
			"target_slot": "shoes",
			"rate": 10,
			"is_cursed": false,
			"stats": {"jump": 3, "dex": 1},
			"mobs": ["菇菇寶貝", "小仙人掌", "火蚌殼", "月光精靈", "骷髏犬", "月妙", "青花蛇", "利堤", "大副凱丁", "萊西", "肯德熊", "地獄巴洛古", "通道守門人", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040703": {
			"id": "2040703",
			"name": "鞋子跳躍卷軸100%",
			"target_slot": "shoes",
			"rate": 100,
			"is_cursed": false,
			"stats": {"jump": 1, "dex": 1},
			"mobs": ["黑色發條鼠", "火焰半人馬"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040704": {
			"id": "2040704",
			"name": "鞋子跳躍卷軸60%",
			"target_slot": "shoes",
			"rate": 60,
			"is_cursed": false,
			"stats": {"jump": 2, "dex": 1},
			"mobs": ["火蚌殼", "河豚", "巨居蟹", "咕咕鐘", "蜈蚣大王", "蘑菇王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040708": {
			"id": "2040708",
			"name": "鞋子速度卷軸10%",
			"target_slot": "shoes",
			"rate": 10,
			"is_cursed": false,
			"stats": {"speed": 3},
			"mobs": ["地獄巴洛古", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040707": {
			"id": "2040707",
			"name": "鞋子速度卷軸60%",
			"target_slot": "shoes",
			"rate": 60,
			"is_cursed": false,
			"stats": {"speed": 2},
			"mobs": ["總理大神", "葛雷士兵", "巨居蟹", "殭屍猴王", "蜈蚣大王", "蘑菇王", "葛雷金剛", "喵怪仙人", "血腥哈維", "幼龍保護者", "回憶的神官", "艾利傑", "法郎肯洛伊德"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040005": {
			"id": "2040005",
			"name": "頭盔生命卷軸10%",
			"target_slot": "hat",
			"rate": 10,
			"is_cursed": false,
			"stats": {"hp": 50},
			"mobs": ["小幽靈", "肯德熊", "地獄巴洛古", "格瑞芬多"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040003": {
			"id": "2040003",
			"name": "頭盔生命卷軸100%",
			"target_slot": "hat",
			"rate": 100,
			"is_cursed": false,
			"stats": {"hp": 10},
			"mobs": ["穆魯"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040004": {
			"id": "2040004",
			"name": "頭盔生命卷軸60%",
			"target_slot": "hat",
			"rate": 60,
			"is_cursed": false,
			"stats": {"hp": 30},
			"mobs": ["仙人長老", "紅色機器人", "苔蘚蝸牛", "巨居蟹", "蜈蚣大王", "蘑菇王", "變身小鬼怪", "沼澤巨鱷", "喵怪仙人", "寒冰半人馬", "幼年龍", "法郎肯洛伊德"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040002": {
			"id": "2040002",
			"name": "頭盔防禦卷軸10%",
			"target_slot": "hat",
			"rate": 10,
			"is_cursed": false,
			"stats": {"def": 15},
			"mobs": ["嫩寶", "紅寶王", "大副凱丁", "萊西", "地獄巴洛古", "格瑞芬多", "艾利傑", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
		"2040001": {
			"id": "2040001",
			"name": "頭盔防禦卷軸60%",
			"target_slot": "hat",
			"rate": 60,
			"is_cursed": false,
			"stats": {"def": 10},
			"mobs": ["紅寶王", "黃金海馬", "鋰礦穆太", "冰獨眼獸", "河豚", "松鼠", "罈壺", "蜈蚣大王", "蘑菇王", "黑龍", "短刃龍戰士", "藍翼龍", "艾利傑", "金勾海賊王"],
			"icon": "res://assets/items/scroll.png"
		},
	}

func _init_monster_drop_map():
	MONSTER_SCROLL_DROP_MAP.clear()
	for scroll_id in SCROLLS.keys():
		var scroll = SCROLLS[scroll_id]
		var mob_list = scroll.get("mobs", [])
		for mob_name in mob_list:
			if not MONSTER_SCROLL_DROP_MAP.has(mob_name):
				MONSTER_SCROLL_DROP_MAP[mob_name] = []
			MONSTER_SCROLL_DROP_MAP[mob_name].append(scroll_id)

func get_scroll(scroll_id: String) -> Dictionary:
	return SCROLLS.get(scroll_id, {})

func get_scroll_by_name(scroll_name: String) -> Dictionary:
	for scroll in SCROLLS.values():
		if scroll.name == scroll_name:
			return scroll
	return {}

func get_scrolls_for_monster(mob_name: String) -> Array:
	var scroll_ids = MONSTER_SCROLL_DROP_MAP.get(mob_name, [])
	var result = []
	for sid in scroll_ids:
		if SCROLLS.has(sid):
			result.append(SCROLLS[sid])
	return result

func is_scroll_compatible_with_equip(scroll_data: Dictionary, equip_data: Dictionary) -> bool:
	var t_slot = scroll_data.get("target_slot", "")
	var eq_slot = equip_data.get("slot", "")
	if t_slot.is_empty() or eq_slot.is_empty():
		return false
	if t_slot == eq_slot:
		return true
	if t_slot == "weapon":
		var weapon_slots = ["weapon", "one-handed sword", "two-handed sword", "one-handed axe", "two-handed axe", "one-handed blunt weapon", "two-handed blunt weapon", "dagger", "bow", "crossbow", "claw", "spear", "polearm", "wand", "staff", "knuckle", "gun"]
		return eq_slot in weapon_slots
	if t_slot == "armor":
		return eq_slot in ["hat", "top", "bottom", "overall", "shoes", "gloves", "cape", "shield"]
	return false