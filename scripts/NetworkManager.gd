# NetworkManager.gd
extends Node

signal player_connected(peer_id: int, player_info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected()
signal connection_succeeded()
signal connection_failed()
signal chat_message_received(sender_name: String, message: String, color: Color)

const DEFAULT_PORT: int = 8910
const MAX_PLAYERS: int = 8

var peer: MultiplayerPeer = null
var is_multiplayer_active: bool = false
var is_host: bool = false
var local_player_name: String = "勇者"

# Dict of peer_id -> player_info
var players: Dictionary = {}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_web_client() -> bool:
	return OS.has_feature("web")

func host_game(port: int = DEFAULT_PORT, player_name: String = "房主勇者") -> Error:
	if is_web_client():
		# Browser sandbox cannot listen on raw TCP/UDP server ports directly without WebRTC
		Global.broadcast_message("【提示】網頁端作為房主需透過專用中繼伺服器或 WebSocket 連線！", Color.ORANGE)
	
	# Create Universal WebSocket / ENet server
	var ws_peer = WebSocketMultiplayerPeer.new()
	var err = ws_peer.create_server(port)
	if err == OK:
		peer = ws_peer
	else:
		# Fallback to ENet if WebSocket port is busy
		var enet_peer = ENetMultiplayerPeer.new()
		err = enet_peer.create_server(port, MAX_PLAYERS)
		peer = enet_peer
		
	if err != OK:
		Global.broadcast_message("創建房間失敗: 錯誤碼 %d (請檢查 Port %d 是否被佔用)" % [err, port], Color.RED)
		return err
		
	multiplayer.multiplayer_peer = peer
	is_multiplayer_active = true
	is_host = true
	local_player_name = player_name
	
	players[1] = {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	}
	
	Global.broadcast_message("★ 多人伺服器已建立！(支援 Web / PC 跨端連線) Port: %d ★" % port, Color(0.2, 1.0, 0.4))
	return OK

func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT, player_name: String = "冒險者") -> Error:
	var clean_addr = address.strip_edges()
	var target_url = clean_addr
	
	# Auto-format WebSocket URL for browser & desktop compatibility
	if not target_url.begins_with("ws://") and not target_url.begins_with("wss://"):
		if target_url.contains(":"):
			target_url = "ws://" + target_url
		else:
			target_url = "ws://" + target_url + ":" + str(port)
			
	var ws_peer = WebSocketMultiplayerPeer.new()
	var err = ws_peer.create_client(target_url)
	
	# If on desktop and ws fails, try ENet
	if err != OK and not is_web_client():
		var enet_peer = ENetMultiplayerPeer.new()
		var host_ip = clean_addr.replace("ws://", "").replace("wss://", "").split(":")[0]
		err = enet_peer.create_client(host_ip, port)
		peer = enet_peer
	else:
		peer = ws_peer
		
	if err != OK:
		Global.broadcast_message("連線失敗: 錯誤碼 %d" % err, Color.RED)
		return err
		
	multiplayer.multiplayer_peer = peer
	is_multiplayer_active = true
	is_host = false
	local_player_name = player_name
	
	Global.broadcast_message("正在連線至: %s ..." % target_url, Color(0.4, 0.8, 1.0))
	return OK

func leave_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_multiplayer_active = false
	is_host = false
	players.clear()
	Global.broadcast_message("已退出多人連線房間", Color.GRAY)

func _on_peer_connected(id: int):
	Global.broadcast_message("玩家 [ID: %d] 加入了冒險隊伍！" % id, Color(0.3, 1.0, 0.5))
	rpc_id(id, "register_player", multiplayer.get_unique_id(), {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	})

func _on_peer_disconnected(id: int):
	var p_name = players.get(id, {}).get("name", "玩家 %d" % id)
	Global.broadcast_message("玩家 [%s] 離開了隊伍" % p_name, Color(1.0, 0.4, 0.4))
	players.erase(id)
	emit_signal("player_disconnected", id)

func _on_connected_to_server():
	Global.broadcast_message("✔ 成功連線進入房主世界！", Color(0.2, 1.0, 0.4))
	emit_signal("connection_succeeded")
	rpc("register_player", multiplayer.get_unique_id(), {
		"name": local_player_name,
		"job_id": Global.player_job_id,
		"level": Global.player_level,
		"hp": Global.player_hp,
		"max_hp": Global.player_max_hp
	})

func _on_connection_failed():
	Global.broadcast_message("連線失敗！請檢查伺服器位址或網路狀態！", Color.RED)
	emit_signal("connection_failed")
	leave_game()

func _on_server_disconnected():
	Global.broadcast_message("與房主伺服器中斷連線！", Color.RED)
	emit_signal("server_disconnected")
	leave_game()

@rpc("any_peer", "call_local", "reliable")
func register_player(peer_id: int, info: Dictionary):
	players[peer_id] = info
	emit_signal("player_connected", peer_id, info)

@rpc("any_peer", "call_local", "reliable")
func broadcast_chat(sender_name: String, message: String, col_code: String = "yellow"):
	var col = Color.YELLOW
	match col_code:
		"cyan": col = Color(0.2, 0.9, 1.0)
		"green": col = Color(0.2, 1.0, 0.4)
		"gold": col = Color.GOLD
		"red": col = Color(1.0, 0.3, 0.3)
	emit_signal("chat_message_received", sender_name, message, col)
	Global.broadcast_message("[%s]: %s" % [sender_name, message], col)
