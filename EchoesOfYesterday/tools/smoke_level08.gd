extends SceneTree
## Level_08 冒烟:悖论之海 + 断电窗冲刺全流程(docs/19 §5 + 录一条发一条——
## 记录只保留最近一条,发射必须紧跟各自录制)。
## 标准解:西窄道侦察 → 录 E-A 穿海守 S1(发)→ 录 E-B 穿海守 S2(发)→
## 玩家进区拨核(断电窗起)→ 穿海北缘 → 踩 TL → 过落下的 G1 → 三重门 → 出口。
## 运行:godot --path . -s tools/smoke_level08.gd

var _player: Node2D
var _sw1: Area2D
var _sw2: Area2D
var _lock: Area2D
var _core: Area2D
var _gate: StaticBody2D
var _door: StaticBody2D
var _mgr: Node
var _notifies: Array[String] = []
var save_backup := ""  # 真实存档备份(_finish 统一还原;成功/失败路径都要走)


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
	print("%s pos=%s s1=%s s2=%s tl=%s core=%s gate_phased=%s door=%s echoes=%d" % [
		tag, _player.global_position.round(), _sw1.is_active(), _sw2.is_active(),
		_lock.is_active(), _core.get("is_on"), _gate.call("is_phased"), _door.is_open(), _mgr.echo_count()])


func _notify_seen(key: String) -> bool:
	for t in _notifies:
		if t.contains(key):
			return true
	return false


func _run() -> void:
	if FileAccess.file_exists("user://save.json"):
		save_backup = FileAccess.get_file_as_string("user://save.json")  # 备份真实存档,收尾还原(防测试污染开发机,返修 2026-11-08)
	DirAccess.remove_absolute("user://save.json")  # 存档隔离:通关断言只认本轮
	var scene: Node = (load("res://scenes/levels/Level_08.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw1 = scene.get_node("YSorted/Switch1")
	_sw2 = scene.get_node("YSorted/Switch2")
	_lock = scene.get_node("YSorted/TimeLock")
	_core = scene.get_node("YSorted/Core")
	_gate = scene.get_node("YSorted/PhaseGate")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void:
		_notifies.append(t)
		print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")
	if not _core.get("is_on") or not _gate.call("is_phased") or _door.is_open():
		print("FAIL: initial state should be core ON + gate sealed + door closed")
		_finish(1)
		return

	# 1) 西窄道侦察支路(TC-98):可达横廊与舱门外;G1 密封阻挡 + T-81
	await _chain(_cell_chain(Vector2i(2, 11), Vector2i(2, 9)) \
			+ _cell_chain(Vector2i(2, 9), Vector2i(2, 3)) \
			+ _cell_chain(Vector2i(2, 3), Vector2i(4, 3)) \
			+ _cell_chain(Vector2i(4, 3), Vector2i(4, 2)) \
			+ _cell_chain(Vector2i(4, 2), Vector2i(6, 2)) \
			+ _cell_chain(Vector2i(6, 2), Vector2i(12, 2)) \
			+ _cell_chain(Vector2i(12, 2), Vector2i(13, 2)))
	await _walk_to(_cw(13, 2))
	await _frames(6)
	_state("gate_recon")
	if not _notify_seen("核心舱"):
		print("FAIL: T-81 gate hint not shown near sealed gate")
		_finish(1)
		return
	var stuck := _player.global_position.distance_to(_cw(14, 2))
	if stuck <= 16.0:
		print("FAIL: player should be blocked by sealed G1, dist to (14,2)=%.1f" % stuck)
		_finish(1)
		return
	print("PASS recon: west corridor reachable, G1 blocks entity (T-81)")

	# 2) 核心侦察:入海到 C1 旁(T-82;无回声在场,合法)
	await _chain(_cell_chain(Vector2i(13, 2), Vector2i(12, 2)) \
			+ _cell_chain(Vector2i(12, 2), Vector2i(6, 2)) \
			+ _cell_chain(Vector2i(6, 2), Vector2i(4, 2)) \
			+ _cell_chain(Vector2i(4, 2), Vector2i(4, 3)) \
			+ _cell_chain(Vector2i(4, 3), Vector2i(2, 3)) \
			+ _cell_chain(Vector2i(2, 3), Vector2i(2, 9)) \
			+ _cell_chain(Vector2i(2, 9), Vector2i(2, 11)))
	await _chain(_cell_chain(Vector2i(2, 11), Vector2i(6, 11)) \
			+ _cell_chain(Vector2i(6, 11), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 8)) \
			+ _cell_chain(Vector2i(6, 8), Vector2i(6, 4)))
	await _frames(8)
	if not _notify_seen("异常核心"):
		print("FAIL: T-82 core hint not shown in sea")
		_finish(1)
		return
	print("PASS core_recon: T-82 shown, C1 reachable only inside sea")
	await _chain(_cell_chain(Vector2i(6, 4), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 11)) \
			+ _cell_chain(Vector2i(6, 11), Vector2i(2, 11)))

	# 3) 录 E-A → 立即发射(录一条发一条):穿海守 S1(TC-101)
	await _tap("record_toggle")
	await _chain(_cell_chain(Vector2i(2, 11), Vector2i(6, 11)) \
			+ _cell_chain(Vector2i(6, 11), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 8)) \
			+ _cell_chain(Vector2i(6, 8), Vector2i(6, 3)) \
			+ _cell_chain(Vector2i(6, 3), Vector2i(6, 2)) \
			+ _cell_chain(Vector2i(6, 2), Vector2i(6, 1)) \
			+ _cell_chain(Vector2i(6, 1), Vector2i(12, 1)))
	await _frames(8)
	await _tap("record_toggle")
	_state("ea_recorded")
	await _tap("play_echo")
	for i in 900:
		if _sw1.is_active():
			break
		await physics_frame
	_state("ea_parked")
	if not _sw1.is_active():
		print("FAIL: echo A never parked S1")
		_finish(1)
		return
	print("PASS echo_a: crossed sea, parks S1")

	# 4) 录 E-B → 发射:穿海守 S2(TC-102;此时海面无回声,玩家录制合法)
	await _tap("record_toggle")
	await _chain(_cell_chain(Vector2i(2, 11), Vector2i(6, 11)) \
			+ _cell_chain(Vector2i(6, 11), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 8)) \
			+ _cell_chain(Vector2i(6, 8), Vector2i(6, 3)) \
			+ _cell_chain(Vector2i(6, 3), Vector2i(6, 2)) \
			+ _cell_chain(Vector2i(6, 2), Vector2i(6, 1)))
	await _frames(8)
	await _tap("record_toggle")
	_state("eb_recorded")
	await _tap("play_echo")
	for i in 900:
		if _sw2.is_active():
			break
		await physics_frame
	_state("eb_parked")
	if not _sw2.is_active():
		print("FAIL: echo B never parked S2")
		_finish(1)
		return
	print("PASS echo_b: crossed sea, parks S2 (sea now clear)")

	# 5) 断电冲刺(TC-105):入海拨核(10s 窗)→ 北缘 → TL(10s 窗)→ 过 G1 → 三重门 → 出口
	await _chain(_cell_chain(Vector2i(2, 11), Vector2i(6, 11)) \
			+ _cell_chain(Vector2i(6, 11), Vector2i(6, 9)) \
			+ _cell_chain(Vector2i(6, 9), Vector2i(6, 8)) \
			+ _cell_chain(Vector2i(6, 8), Vector2i(6, 7)) \
			+ _cell_chain(Vector2i(6, 7), Vector2i(6, 6)) \
			+ _cell_chain(Vector2i(6, 6), Vector2i(6, 5)) \
			+ _cell_chain(Vector2i(6, 5), Vector2i(6, 4)))
	await _frames(8)
	await _tap("interact")  # 拨核:断电窗起(E-82),G1 落下
	await _frames(6)
	_state("core_off")
	if _core.get("is_on") or _gate.call("is_phased"):
		print("FAIL: core toggle should drop G1")
		_finish(1)
		return
	await _chain(_cell_chain(Vector2i(6, 4), Vector2i(6, 3)) \
			+ _cell_chain(Vector2i(6, 3), Vector2i(6, 2)) \
			+ _cell_chain(Vector2i(6, 2), Vector2i(9, 2)) \
			+ _cell_chain(Vector2i(9, 2), Vector2i(12, 2)) \
			+ _cell_chain(Vector2i(12, 2), Vector2i(13, 2)) \
			+ _cell_chain(Vector2i(13, 2), Vector2i(15, 2)) \
			+ _cell_chain(Vector2i(15, 2), Vector2i(15, 1)))
	await _frames(12)
	_state("complete")
	if not _lock.is_active() and not _door.is_open():
		print("note: TL window state at exit=", _lock.is_active(), " door=", _door.is_open())
	print("save=", FileAccess.get_file_as_string("user://save.json"))

	# 6) 章末通关 → 任意键打开关卡选择(8 关全显,TC-113)
	await _frames(80)
	await _tap_key(KEY_E)
	await _frames(20)
	var nxt := String(current_scene.name) if current_scene != null else "<null>"
	print("after_key current_scene=", nxt)
	if nxt != "LevelSelect":
		print("FAIL: expected LevelSelect menu, got ", nxt)
		_finish(1)
		return
	var btns: Node = current_scene.get_node("%Buttons")
	if btns == null or btns.get_child_count() != 8:
		print("FAIL: menu should list 8 levels, got ", btns.get_child_count() if btns else -1)
		_finish(1)
		return
	print("PASS advance_select: chapter end -> LevelSelect with 8 levels")
	_finish(0)


## 统一收尾:无论成功/失败路径都还原真实存档(返修 3 教训:失败路径 quit(1) 跳过还原会污染开发机)
func _finish(code: int) -> void:
	if save_backup != "":
		var fb := FileAccess.open("user://save.json", FileAccess.WRITE)
		fb.store_string(save_backup)
		fb.close()
	quit(code)


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
