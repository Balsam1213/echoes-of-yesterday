extends SceneTree
## 一次性追踪:回声 1 绕行路线在何处被消散(debug 用,不入库)
## 运行:godot --path . -s tools/debug_trace_l4.gd

var _player: Node2D
var _mgr: Node
var _field_centers: Array[Vector2] = []
var _field_names: Array[String] = []


func _initialize() -> void:
	_run()


func _cw(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 32 + 32, (x + y) * 16 + 16)


func _cell_chain(from: Vector2i, to: Vector2i) -> Array:
	var pts: Array = []
	var x := from.x
	var y := from.y
	while x != to.x:
		x += signi(to.x - x)
		pts.append(_cw(x, y))
	while y != to.y:
		y += signi(to.y - y)
		pts.append(_cw(x, y))
	return pts


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _walk_to(target: Vector2, tol := 2.0) -> void:
	for i in 300:
		var d: Vector2 = target - _player.global_position
		if d.length() <= tol:
			break
		Input.action_press("move_right" if d.x > 0 else "move_left")
		Input.action_press("move_down" if d.y > 0 else "move_up")
		await physics_frame
		Input.action_release("move_right")
		Input.action_release("move_left")
		Input.action_release("move_down")
		Input.action_release("move_up")
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("move_up")


func _walk_cells(from: Vector2i, to: Vector2i) -> void:
	for p in _cell_chain(from, to):
		await _walk_to(p)


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_04.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_mgr = scene.get_node("EchoManager")
	for fname in ["FieldMain", "FieldU"]:
		var f := scene.get_node(fname)
		for cs in f.get_children():
			if cs is CollisionShape2D:
				_field_centers.append(cs.position)
				_field_names.append(fname)
	print("field shapes=", _field_centers.size())
	root.get_node("GameEvents").echo_spawned.connect(func(id: int) -> void: print("SPAWN echo=", id))
	root.get_node("GameEvents").echo_deleted.connect(func(id: int) -> void: print("DELETED echo=", id))
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))

	await _tap("record_toggle")
	await _walk_cells(Vector2i(2, 10), Vector2i(12, 10))
	await _walk_cells(Vector2i(12, 10), Vector2i(12, 4))
	await _walk_cells(Vector2i(12, 4), Vector2i(3, 4))
	await _walk_cells(Vector2i(3, 4), Vector2i(3, 2))
	await _frames(8)
	await _tap("record_toggle")
	var rec = _player.recorder.recording
	print("rec frames=", rec.frames.size())
	var min_d := 1e9
	var min_t := -1
	var min_c := ""
	for f in rec.frames:
		var p: Vector2 = f["pos"]
		for i in _field_centers.size():
			var dc: float = p.distance_to(_field_centers[i])
			if dc < min_d:
				min_d = dc
				min_t = f["t"]
				min_c = _field_names[i]
	print("min dist to field shape=", min_d, " at frame ", min_t, " (", min_c, ")")
	await _tap("play_echo")
	var last_pos := Vector2.ZERO
	for i in 620:
		var echoes = get_nodes_in_group("echo")
		if echoes.size() > 0:
			last_pos = (echoes[0] as Node2D).global_position
		if i % 40 == 0:
			print("f=%d count=%d last=%s" % [i, _mgr.echo_count(), last_pos.round()])
		await physics_frame
	quit()
