extends SceneTree
## Level_07 冒烟:相位门三门取舍 + 悖论区全流程(docs/18 §5 返修 2 + docs/17 §5.1 记录区)。
## 标准解:南口双门密封(核心 OFF)→ 东室门落下录 E1 守 S1(发)→ 拨核心供电
## (南口落下 + 东门密封,取舍)→ 录 E2 停 S2(区内)→ 玩家穿区北上 → 北侧发射 E2 → 冲门。
## 运行:godot --path . -s tools/smoke_level07.gd

var _player: Node2D
var _sw1: Area2D
var _sw2: Area2D
var _core: Area2D
var _gate_east: StaticBody2D
var _gate_s1: StaticBody2D
var _gate_s2: StaticBody2D
var _door: StaticBody2D
var _mgr: Node
var _pos_exit: Vector2
var _notifies: Array[String] = []


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


## 持键连续走位(全速):长路线录制用(逐帧 press/release 速度减半,超 30s 记录上限)
func _walk_chain(points: Array) -> void:
	var idx := 0
	var guard := 0
	while idx < points.size() and guard < 4000:
		guard += 1
		var d: Vector2 = (points[idx] as Vector2) - _player.global_position
		if absf(d.x) <= 4.0 and absf(d.y) <= 4.0:
			idx += 1
			Input.action_release("move_right")
			Input.action_release("move_left")
			Input.action_release("move_down")
			Input.action_release("move_up")
			await physics_frame
			continue
		if absf(d.x) > 4.0:
			Input.action_press("move_right" if d.x > 0 else "move_left")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
		if absf(d.y) > 4.0:
			Input.action_press("move_down" if d.y > 0 else "move_up")
		else:
			Input.action_release("move_down")
			Input.action_release("move_up")
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("move_up")


func _chain(points: Array) -> void:
	await _walk_chain(points)


func _state(tag: String) -> void:
	print("%s pos=%s s1=%s s2=%s core=%s s_gates=%s/%s e_gate=%s door=%s echoes=%d" % [
		tag, _player.global_position.round(), _sw1.is_active(), _sw2.is_active(),
		_core.get("is_on"), _gate_s1.call("is_phased"), _gate_s2.call("is_phased"),
		_gate_east.call("is_phased"), _door.is_open(), _mgr.echo_count()])


func _notify_seen(key: String) -> bool:
	for t in _notifies:
		if t.contains(key):
			return true
	return false


func _run() -> void:
	var save_backup := ""
	if FileAccess.file_exists("user://save.json"):
		save_backup = FileAccess.get_file_as_string("user://save.json")  # 备份真实存档,收尾还原(防测试污染开发机)
	DirAccess.remove_absolute("user://save.json")  # 存档隔离:通关断言只认本轮
	var scene: Node = (load("res://scenes/levels/Level_07.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw1 = scene.get_node("YSorted/Switch1")
	_sw2 = scene.get_node("YSorted/Switch2")
	_core = scene.get_node("YSorted/Core")
	_gate_east = scene.get_node("YSorted/GateEast")
	_gate_s1 = scene.get_node("YSorted/GateSouth1")
	_gate_s2 = scene.get_node("YSorted/GateSouth2")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	_pos_exit = scene.get_node("YSorted/ExitArea").position
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void:
		_notifies.append(t)
		print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")
	if _core.get("is_on") or not _gate_s1.call("is_phased") or not _gate_s2.call("is_phased") \
			or _gate_east.call("is_phased"):
		print("FAIL: initial state should be core OFF / south pair sealed / east gate dropped")
		quit(1)
		return

	# 1) 南口相位门教学:实体被挡(T-71);断电态东室门落下可进(TC-86)
	await _walk_cells(Vector2i(2, 9), Vector2i(2, 10))
	await _walk_cells(Vector2i(2, 10), Vector2i(8, 10))
	await _walk_cells(Vector2i(8, 10), Vector2i(8, 9))
	await _walk_to(_cw(8, 8))
	await _frames(6)
	if not _notify_seen("相位封锁"):
		print("FAIL: T-71 gate hint not shown near sealed gate")
		quit(1)
		return
	var blocked := _player.global_position.distance_to(_cw(8, 7))
	if blocked <= 16.0:
		print("FAIL: player should be blocked by sealed south gate, dist to (8,7)=%.1f" % blocked)
		quit(1)
		return
	print("PASS south_gate_sealed: T-71 shown, entity blocked")

	# 2) 东室侦察(断电态门落下):直达 S1(15,6)——实体不可穿密封门、门落可穿双态可见
	await _chain(_cell_chain(Vector2i(8, 9), Vector2i(8, 10)) \
			+ _cell_chain(Vector2i(8, 10), Vector2i(12, 10)) \
			+ _cell_chain(Vector2i(12, 10), Vector2i(12, 9)) \
			+ _cell_chain(Vector2i(12, 9), Vector2i(12, 8)) \
			+ _cell_chain(Vector2i(12, 8), Vector2i(12, 7)) \
			+ _cell_chain(Vector2i(12, 7), Vector2i(15, 7)) \
			+ _cell_chain(Vector2i(15, 7), Vector2i(15, 6)))
	await _frames(6)
	_state("east_room")
	var at_s1 := _player.global_position.distance_to(_cw(15, 6))
	if at_s1 > 8.0:
		print("FAIL: player should reach S1 through dropped east gate, dist=%.1f" % at_s1)
		quit(1)
		return
	print("PASS east_gate_dropped: player reached S1")

	# 3) 悖论初体验(凹室):录进凹室 → 回放 → 跟进 → 消散 + T-72(TC-88)
	await _chain(_cell_chain(Vector2i(15, 6), Vector2i(15, 7)) \
			+ _cell_chain(Vector2i(15, 7), Vector2i(12, 7)) \
			+ _cell_chain(Vector2i(12, 7), Vector2i(12, 8)) \
			+ _cell_chain(Vector2i(12, 8), Vector2i(12, 9)) \
			+ _cell_chain(Vector2i(12, 9), Vector2i(12, 10)) \
			+ _cell_chain(Vector2i(12, 10), Vector2i(2, 10)) \
			+ _cell_chain(Vector2i(2, 10), Vector2i(2, 9)))
	await _tap("record_toggle")
	await _chain(_cell_chain(Vector2i(2, 9), Vector2i(2, 10)) \
			+ _cell_chain(Vector2i(2, 10), Vector2i(6, 10)) \
			+ _cell_chain(Vector2i(6, 10), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 8)) \
			+ _cell_chain(Vector2i(6, 8), Vector2i(7, 8)))
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _walk_cells(Vector2i(2, 9), Vector2i(6, 9))
	await _walk_cells(Vector2i(6, 9), Vector2i(6, 8))
	await _walk_cells(Vector2i(6, 8), Vector2i(7, 8))
	for i in 500:
		if _mgr.echo_count() == 0:
			break  # 玩家与回声先后进区(先后皆可)→ 消散(E-78 双向)
		await physics_frame
	_state("sandbox_paradox")
	if _mgr.echo_count() != 0 or not _notify_seen("只能有一个你"):
		print("FAIL: sandbox paradox dissolve/T-72, count=", _mgr.echo_count())
		quit(1)
		return
	print("PASS sandbox_paradox: echo dissolved + T-72")

	# 4) 录 E1(断电态穿东门)→ 回记录区 → 发射 → 守 S1(TC-94 前半)
	await _walk_cells(Vector2i(7, 8), Vector2i(6, 8))
	await _walk_cells(Vector2i(6, 8), Vector2i(6, 9))
	await _walk_cells(Vector2i(6, 9), Vector2i(6, 10))
	await _walk_cells(Vector2i(6, 10), Vector2i(2, 10))
	await _walk_cells(Vector2i(2, 10), Vector2i(2, 9))
	await _tap("record_toggle")
	await _chain(_cell_chain(Vector2i(2, 9), Vector2i(2, 10)) \
			+ _cell_chain(Vector2i(2, 10), Vector2i(12, 10)) \
			+ _cell_chain(Vector2i(12, 10), Vector2i(12, 9)) \
			+ _cell_chain(Vector2i(12, 9), Vector2i(12, 8)) \
			+ _cell_chain(Vector2i(12, 8), Vector2i(12, 7)) \
			+ _cell_chain(Vector2i(12, 7), Vector2i(15, 7)) \
			+ _cell_chain(Vector2i(15, 7), Vector2i(15, 6)))
	await _frames(8)
	await _tap("record_toggle")
	_state("e1_recorded")
	await _tap("play_echo")
	for i in 900:
		if _sw1.is_active():
			break
		await physics_frame
	_state("e1_parked")
	if not _sw1.is_active():
		print("FAIL: echo1 never parked S1")
		quit(1)
		return
	print("PASS echo1_parked: parks S1 via dropped east gate")

	# 5) 拨核心供电:南口双门落下 + 东门密封(取舍,TC-87)
	await _walk_cells(Vector2i(2, 9), Vector2i(2, 10))
	await _walk_cells(Vector2i(2, 10), Vector2i(6, 10))
	await _walk_cells(Vector2i(6, 10), Vector2i(6, 9))
	await _frames(8)
	await _tap("interact")
	await _frames(6)
	_state("core_on")
	if not _core.get("is_on") or _gate_s1.call("is_phased") or _gate_s2.call("is_phased") \
			or not _gate_east.call("is_phased"):
		print("FAIL: core ON should drop south pair AND seal east gate")
		quit(1)
		return
	print("PASS core_tradeoff: south pair dropped + east gate sealed")

	# 6) 录 E2(穿落下的南门,空区北上 → 停 S2 区内)
	await _walk_cells(Vector2i(6, 9), Vector2i(6, 10))
	await _walk_cells(Vector2i(6, 10), Vector2i(2, 10))
	await _walk_cells(Vector2i(2, 10), Vector2i(2, 9))
	await _tap("record_toggle")
	await _chain(_cell_chain(Vector2i(2, 9), Vector2i(2, 10)) \
			+ _cell_chain(Vector2i(2, 10), Vector2i(8, 10)) \
			+ _cell_chain(Vector2i(8, 10), Vector2i(8, 9)) \
			+ _cell_chain(Vector2i(8, 9), Vector2i(8, 8)) \
			+ _cell_chain(Vector2i(8, 8), Vector2i(8, 7)) \
			+ _cell_chain(Vector2i(8, 7), Vector2i(8, 6)))
	await _frames(8)
	await _tap("record_toggle")
	_state("e2_recorded")

	# 7) 玩家穿区北上(P1 空,合法)→ 北侧发射 E2(先过去,再让过去发生)
	await _chain(_cell_chain(Vector2i(2, 9), Vector2i(2, 10)) \
			+ _cell_chain(Vector2i(2, 10), Vector2i(8, 10)) \
			+ _cell_chain(Vector2i(8, 10), Vector2i(8, 9)) \
			+ _cell_chain(Vector2i(8, 9), Vector2i(8, 8)) \
			+ _cell_chain(Vector2i(8, 8), Vector2i(8, 7)) \
			+ _cell_chain(Vector2i(8, 7), Vector2i(8, 6)) \
			+ _cell_chain(Vector2i(8, 6), Vector2i(8, 5)) \
			+ _cell_chain(Vector2i(8, 5), Vector2i(8, 4)) \
			+ _cell_chain(Vector2i(8, 4), Vector2i(8, 3)))
	_state("north_side")
	await _tap("play_echo")
	for i in 900:
		if _sw2.is_active():
			break
		await physics_frame
	_state("e2_parked")
	if not _sw2.is_active():
		print("FAIL: echo2 never parked S2 (north-fire)")
		quit(1)
		return
	if not _door.is_open():
		print("FAIL: door should open at S1 && S2")
		quit(1)
		return
	print("PASS north_fire: echo2 crossed field from north launch, door open")

	# 8) 冲门 → 通关(TC-97)
	await _walk_cells(Vector2i(8, 3), Vector2i(8, 1))
	await _frames(12)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))

	# 9) 推进链:L7 → Level_08(next_scene)
	await _frames(80)
	await _tap_key(KEY_E)
	await _frames(20)
	var nxt := String(current_scene.name) if current_scene != null else "<null>"
	print("after_key current_scene=", nxt)
	if nxt != "Level_08":
		print("FAIL: expected advance to Level_08, got ", nxt)
		quit(1)
		return
	print("PASS advance_l8: L7 -> L8")
	if save_backup != "":
		var fb := FileAccess.open("user://save.json", FileAccess.WRITE)
		fb.store_string(save_backup)
		fb.close()
	quit()


func _tap_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)
