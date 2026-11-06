extends SceneTree
## Level_05 冒烟:能量核心 + events 采集/重放 + 桥联动 + 双回声时序编排全流程(docs/15)。
## 运行:godot --path . -s tools/smoke_level05.gd

var _player: Node2D
var _sw_a: Area2D
var _core1: Area2D
var _core2: Area2D
var _bridge: StaticBody2D
var _door: StaticBody2D
var _mgr: Node
var _pos_a: Vector2
var _pos_exit: Vector2


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


func _state(tag: String) -> void:
	print("%s pos=%s a=%s c1=%s c2=%s bridge_raised=%s door=%s echoes=%d" % [
		tag, _player.global_position.round(), _sw_a.is_active(), _core1.get("is_on"),
		_core2.get("is_on"), _bridge.get("is_raised"), _door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_05.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw_a = scene.get_node("YSorted/SwitchA")
	_core1 = scene.get_node("YSorted/Core1")
	_core2 = scene.get_node("YSorted/Core2")
	_bridge = scene.get_node("YSorted/Bridge")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	_pos_a = _sw_a.position
	_pos_exit = scene.get_node("YSorted/ExitArea").position
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")
	if not _bridge.get("is_raised"):
		print("FAIL: bridge should start raised")
		quit(1)
		return

	# 1) 靠近核心 1(T-51)→ E 拨 ON → 桥降(TC-58)
	await _walk_cells(Vector2i(2, 9), Vector2i(3, 5))
	await _frames(8)
	await _tap("interact")
	await _frames(8)
	_state("core1_on")
	if not _core1.get("is_on") or _bridge.get("is_raised"):
		print("FAIL: core1 toggle / bridge lower")
		quit(1)
		return
	print("PASS core1_on: bridge lowered")

	# 2) 过桥进机房
	await _walk_cells(Vector2i(3, 5), Vector2i(7, 1))
	await _walk_cells(Vector2i(7, 1), Vector2i(9, 1))
	await _walk_cells(Vector2i(9, 1), Vector2i(9, 8))
	_state("in_machine_room")

	# 3) 录 R1:机房西侧 → 过桥 → 前厅 → 停 A(TC-62)
	await _tap("record_toggle")
	await _walk_cells(Vector2i(9, 8), Vector2i(9, 1))
	await _walk_cells(Vector2i(9, 1), Vector2i(2, 1))
	await _walk_cells(Vector2i(2, 1), Vector2i(2, 2))
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")  # 回声 1 先发(慢:过桥 + 走前厅)
	_state("echo1_launched")

	# 4) 回前厅方向?不——玩家折返机房(桥仍降),录 R2:北上 → 绕 F1 北缺口 → 南下 → E 拨核心 2 → 折返
	await _walk_cells(Vector2i(2, 2), Vector2i(2, 1))
	await _walk_cells(Vector2i(2, 1), Vector2i(9, 1))
	await _walk_cells(Vector2i(9, 1), Vector2i(9, 8))
	await _tap("record_toggle")
	await _walk_cells(Vector2i(9, 8), Vector2i(9, 2))
	await _walk_cells(Vector2i(9, 2), Vector2i(13, 2))
	await _walk_cells(Vector2i(13, 2), Vector2i(13, 8))
	await _frames(8)
	await _tap("interact")  # 录制中的真实交互(E-57):核心 2 ON + 事件写入
	await _frames(8)
	await _walk_cells(Vector2i(13, 8), Vector2i(12, 9))
	await _tap("record_toggle")
	var rec = _player.recorder.recording
	var event_count := 0
	for f in rec.frames:
		event_count += (f["events"] as Array).size()
	print("R2 frames=", rec.frames.size(), " events=", event_count)
	if event_count != 1:
		print("FAIL: R2 should contain exactly 1 interact event, got ", event_count)
		quit(1)
		return
	print("PASS r2_event: 1 interact recorded")
	_state("r2_recorded")

	# 5) 等 A 就位 → 发射回声 2 → 途中 E 拨核心 2 → 窗口开启 → 门开(TC-61/63)
	for i in 600:
		if _sw_a.is_active():
			break
		await physics_frame
	if not _sw_a.is_active():
		print("FAIL: echo1 never reached A")
		quit(1)
		return
	print("PASS echo1_a: A held")
	await _tap("play_echo")
	await _frames(320)  # 回声 2 途中(约 220 帧处拨核)
	_state("echo2_mid")
	if not _core2.get("is_on") or not _door.is_open():
		print("FAIL: core2 not on or door closed after echo2 event")
		quit(1)
		return
	print("PASS sync: core2 on, door open")

	# 6) 8s 窗口内冲门(TC-69)
	await _walk_cells(Vector2i(12, 9), Vector2i(12, 2))
	await _walk_cells(Vector2i(12, 2), Vector2i(13, 2))
	await _walk_to(_pos_exit, 20.0)
	await _frames(12)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))
	quit()
