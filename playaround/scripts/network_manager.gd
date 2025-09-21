extends Node

var pending_spawns: Array = []   # store spawns until root is ready
var players_root: Node = null
var players := {} # peer_id -> player node
var player_scene: PackedScene = preload("res://scenes/myplayer.tscn")
var isSinglePlayer := false

func singleplayer():
	print("Singleplayer Starting...")
	_spawn_player(1)

func register_players_root(root: Node):
	players_root = root
	print("✅ NetworkManager now has players_root: ", root)
	#push_warning("✅ NetworkManager now has players_root:", root)
	print("pending spawns: " , pending_spawns)
	spawn_pending_players()

func spawn_pending_players():
	for id in pending_spawns:
		_spawn_player(id)
		print("this func ran for %s" % id)
		pending_spawns.pop_front()


func _ready():
	# Cache the Players root
	#push_warning("func ran now")
	if players_root:
		print("✅ Registered Players root:", players_root)
	#else:
		#push_warning("⚠️ Players root not found at startup, will retry on player connect")
		
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

# --- HOSTING / JOINING ---
func host_game(port: int = 9000):
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	print("✅ Hosting on port", port)
	#single_player_or_multiplayer_auth_check()
	if players_root:
		_spawn_player(multiplayer.get_unique_id())
		print("🔗 Peer connected:", multiplayer.get_unique_id())
	else:
		push_warning("⚠️ players_root is null, queuing spawn for %s" % multiplayer.get_unique_id())
		pending_spawns.append(multiplayer.get_unique_id())
	

func join_game(ip: String, port: int = 9000):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error == OK:
		get_tree().get_multiplayer().set_multiplayer_peer(peer)
	else:
		push_error("Failed to connect")
	#single_player_or_multiplayer_auth_check()
	print("✅ Joining", ip, ":", port)

func freePlayersarray():
	players.clear()

# --- PLAYER SPAWNING ---
func _spawn_player(peer_id: int):
	if players_root == null:
		push_warning("⚠️ players_root is null, cannot spawn player for ", peer_id ," and ", players_root)
		pending_spawns.push_back(peer_id)
		return

	if players.has(peer_id):
		print("⚠️ Player ", peer_id, " already exists")
		return
	
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	
	players_root.add_child(player, true)
	
	# --- Get random spawn point ---
	var spawn_points = get_tree().current_scene.get_node("SpawnPoints").get_children()
	if spawn_points.size() > 0:
		randomize()  # ensures different results each run
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		player.global_transform.origin = spawn_point.global_transform.origin
	else:
		print("⚠️ No spawn points found, defaulting to origin")
	
	player.set_multiplayer_authority(peer_id)
	players[peer_id] = player
	print("✅ Spawned player", peer_id)
	push_warning("✅ Spawned player", peer_id)



func _on_peer_connected(id: int):
	if players_root:
		_spawn_player(id)
		print("🔗 Peer connected:", id)
	else:
		push_warning("⚠️ players_root is null, queuing spawn for %s" % id)
		pending_spawns.push_back(id)
		spawn_pending_players()

#disconnects from the server
func disconnectPeer():
	# disconnect safely
	if get_tree().get_multiplayer().has_multiplayer_peer():
		var peer = get_tree().get_multiplayer().multiplayer_peer
		if peer != null:
			peer.close()

#host kicks the player
func kick_player(peer_id: int):
	var peer = get_tree().get_multiplayer().get_multiplayer_peer()
	if peer and peer.has_method("disconnect_peer"):
		peer.disconnect_peer(peer_id)
		_on_peer_disconnected(peer_id)

func _on_peer_disconnected(id: int):
	print("❌ Peer disconnected:", id)
	push_warning("❌ Peer disconnected:", id)
	if players.has(id):
		var player = players[id]
		if is_instance_valid(player):
			player.queue_free()
		players.erase(id)   # remove reference

func _on_connected_to_server():
	print("✅ Connected to server, spawning self")
	_spawn_player(multiplayer.get_unique_id())

func _on_connection_failed():
	push_error("❌ Connection failed")

func local_ip_finder():
	var local_ip := ""
	var ips = IP.get_local_addresses()
	for ip in ips:
		# skip loopback (127.x.x.x) and IPv6 (::1 etc.)
		if ip.begins_with("127.") or ip.find(":") != -1:
			continue
		# Typical private network ranges: 192.168.x.x, 10.x.x.x, 172.16–31.x.x
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			local_ip = ip
			break
	return local_ip

# --- INPUT SYNC ---
func send_input(input_dir: Vector2):
	rpc("rpc_set_input", multiplayer.get_unique_id(), input_dir)

@rpc("unreliable", "any_peer")
func rpc_set_input(peer_id: int, new_input: Vector2):
	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		players[peer_id].apply_network_input(new_input)

# --- TRANSFORM SYNC ---
func broadcast_transform(player: Node,body: Node):
	rpc("rpc_set_transform", multiplayer.get_unique_id(), player.global_transform, body.global_transform)

@rpc("unreliable", "any_peer")
func rpc_set_transform(peer_id: int, player_transform: Transform3D,body_transform: Transform3D):
	if players.has(peer_id) and is_instance_valid(players[peer_id]):
		var p = players[peer_id]
		if not p.is_multiplayer_authority():
			p.global_transform = player_transform
			p.get_node("Body").global_transform = body_transform

###############DAMAGE##############

@rpc("any_peer","reliable","call_local")
func request_damage(target_name: String, amount: int) -> void:
	if not multiplayer.is_server():
		return  # only server decides

	if players.has(int(target_name)):
		var target = players[int(target_name)]
		if target:
			target.take_damage(amount)

@rpc("any_peer")
func request_full_state(sender_id: int):
	if multiplayer.is_server():
		for pid in players.keys():
			var p = players[pid]
			rpc_id(sender_id, "sync_health", pid, p.get_health())


@rpc("any_peer", "reliable","call_local")
func report_hit(target_id: int,damage: int):
	if not multiplayer.is_server():
		return
	
	if players.has(target_id): # network manager dict
		var player = players[target_id]
		player.apply_damage(damage)
		player.rpc("sync_health",target_id,player.health)
