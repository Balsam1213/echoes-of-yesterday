extends SceneTree
## Level_04 冒烟:干扰场消散 + 绕行录制 + 脉冲板同振全流程(docs/14)。
## 走位采用闭环 _walk_to + **逐格中心链**(_cell_chain):相邻格心方向恰为等距轴,
## 避免屏幕 45° 对角切角斜穿干扰判定圈(冒烟教训:路线必须逐格给定)。
## 同振对齐用「记录帧定位 B 触发帧 + 延迟入场」。
## 运行:godot --path . -s tools/smoke_level04.gd

var _player: Node2D
var _sw_a: Area2D
var _pad_b: Area2D
var _pad_p: Area2D
var _door: StaticBody2D
var _mgr: Node
var _pos_a: Vector2
var _pos_b: Vector2
var _pos_p: Vector2
var _pos_exit: Vector2
var _pos_spawn: Vector2


func _initialize() -> void:
	_run()


## 格位 → 世界坐标(等距 DIAMOND_DOWN,64×32;与 map_to_local 一致)
func _cw(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 32 + 32, (x + y) * 16 + 16)


## 逐格中心链:从 from 到 to,先沿 x 轴后沿 y 轴(每步一格,方向恒为等距轴)
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


## 闭环走位:每帧按实际位置修正方向,直到进入容差(tol 2:防停点偏移戳入判定圈)
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
	print("%s pos=%s a=%s b=%s p=%s door=%s echoes=%d" % [
		tag, _player.global_position.round(), _sw_a.is_active(), _pad_b.is_active(),
		_pad_p.is_active(), _door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_04.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw_a = scene.get_node("YSorted/SwitchA")
	_pad_b = scene.get_node("YSorted/PadB")
	_pad_p = scene.get_node("YSorted/PadP")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	_pos_a = _sw_a.position
	_pos_b = _pad_b.position
	_pos_p = _pad_p.position
	_pos_exit = scene.get_node("YSorted/ExitArea").position
	_pos_spawn = _player.position
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) 贪短直穿干扰带(东行 y10 → 北上 x10 列,穿 B 与 (10,5))→ 回声消散(TC-49/E-41)
	await _tap("record_toggle")
	await _walk_cells(Vector2i(2, 10), Vector2i(10, 10))
	await _walk_cells(Vector2i(10, 10), Vector2i(10, 5))
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(300)
	_state("after_dissolve")
	if _mgr.echo_count() != 0:
		print("FAIL: echo not dissolved, count=", _mgr.echo_count())
		quit(1)
		return
	print("PASS dissolve: echoes=0")

	# 2) A 路绕行(东缺口 x12→折西 y4)→ 回声 1 常踩 A(TC-50)
	await _walk_cells(Vector2i(10, 5), Vector2i(2, 10))
	await _tap("record_toggle")
	await _walk_cells(Vector2i(2, 10), Vector2i(12, 10))
	await _walk_cells(Vector2i(12, 10), Vector2i(12, 4))
	await _walk_cells(Vector2i(12, 4), Vector2i(3, 4))
	await _walk_cells(Vector2i(3, 4), Vector2i(3, 2))
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(620)
	_state("echo1_a")
	if not _sw_a.is_active() or _mgr.echo_count() != 1:
		print("FAIL: echo1 not holding A, count=", _mgr.echo_count())
		quit(1)
		return
	print("PASS echo1_a: A held by echo")

	# 3) B 路:U 形南口进出瞬踩 B,记录并定位 B 触发帧(TC-51)
	await _tap("record_toggle")
	await _walk_cells(Vector2i(3, 2), Vector2i(12, 2))
	await _walk_cells(Vector2i(12, 2), Vector2i(12, 10))
	await _walk_cells(Vector2i(12, 10), Vector2i(10, 10))
	await _walk_cells(Vector2i(10, 10), Vector2i(10, 7))
	await _walk_cells(Vector2i(10, 7), Vector2i(10, 10))
	await _walk_cells(Vector2i(10, 10), Vector2i(12, 10))
	await _frames(8)
	await _tap("record_toggle")
	var rec = _player.recorder.recording
	var bi := 0
	var best := 1e9
	for f in rec.frames:
		var d: float = (f["pos"] as Vector2).distance_to(_pos_b)
		if d < best:
			best = d
			bi = f["t"]
	print("B crossing frame bi=", bi, " dist=", best)
	_state("b_recorded")

	# 4) 同振对齐:埋伏 (12,2) → 发射回声 2 → 掐点踩 P → 门开 1.5s(TC-52)
	await _walk_cells(Vector2i(12, 10), Vector2i(12, 2))
	await _tap("play_echo")
	await _frames(bi - 25)
	await _walk_to(_pos_p, 6.0)  # 踩上 P(0.5s 固定窗)
	_state("on_p")
	var door_opened := false
	for i in 120:
		if _door.is_open():
			door_opened = true
			break
		await physics_frame
	if not door_opened:
		print("FAIL: door not opened by sync")
		quit(1)
		return
	print("PASS sync: door opened")

	# 5) 窗口内冲入出口(TC-52/E-47)
	await _walk_to(_pos_exit, 20.0)
	await _frames(12)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))
	quit()
