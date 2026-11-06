extends SceneTree
## Level_06 冒烟:序列门(A→B→C 乱序拒绝)+ 三区调度 + 时间锁冲刺全流程(docs/16)。
## 标准解:回声 1 守 A、回声 2 守 B、回声 3 踩 C,玩家亲自拨核心后 ambush 冲刺。
## 运行:godot --path . -s tools/smoke_level06.gd

var _player: Node2D
var _sw_a: Area2D
var _sw_b: Area2D
var _lock: Area2D
var _core: Area2D
var _door: StaticBody2D
var _mgr: Node
var _light_b: Sprite2D
var _light_off := Color(0.35, 0.38, 0.42, 1.0)
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
	print("%s pos=%s a=%s b=%s c=%s core=%s door=%s echoes=%d" % [
		tag, _player.global_position.round(), _sw_a.is_active(), _sw_b.is_active(),
		_lock.is_active(), _core.get("is_on"), _door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_06.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw_a = scene.get_node("YSorted/SwitchA")
	_sw_b = scene.get_node("YSorted/SwitchB")
	_lock = scene.get_node("YSorted/TimeLock")
	_core = scene.get_node("YSorted/Core")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	_light_b = scene.get_node("YSorted/LightB")
	_pos_exit = scene.get_node("YSorted/ExitArea").position
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) 乱序教学:先踩 B(A 未激活)→ 物理激活但灯不亮 + T-62(TC-70/E-61)
	await _walk_cells(Vector2i(2, 11), Vector2i(8, 3))
	await _frames(20)
	_state("on_b_illegal")
	if _light_b.modulate != _light_off:
		print("FAIL: light B should be OFF (sequence rejected), got ", _light_b.modulate)
		quit(1)
		return
	print("PASS illegal_b: sequence rejected, light off")

	# 2) 录 R1(B→A)→ 立即发射回声 1(游戏只保留最近一条记录:录一条发一条,L3 先例)
	await _tap("record_toggle")
	await _walk_cells(Vector2i(8, 3), Vector2i(8, 1))
	await _walk_cells(Vector2i(8, 1), Vector2i(2, 1))
	await _walk_cells(Vector2i(2, 1), Vector2i(2, 3))
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	_state("echo1_launched")

	# 3) 录 R2(A→B)→ 等回声 1 就位(A 先激活,序列合法,E-61)→ 发射回声 2
	await _tap("record_toggle")
	await _walk_cells(Vector2i(2, 3), Vector2i(2, 1))
	await _walk_cells(Vector2i(2, 1), Vector2i(8, 1))
	await _walk_cells(Vector2i(8, 1), Vector2i(8, 3))
	await _frames(8)
	await _tap("record_toggle")
	for i in 600:
		if _sw_a.is_active():
			break
		await physics_frame
	if not _sw_a.is_active():
		print("FAIL: echo1 never reached A")
		quit(1)
		return
	print("PASS echo1_a")
	await _tap("play_echo")
	for i in 600:
		if _sw_b.is_active():
			break
		await physics_frame
	if not _sw_b.is_active():
		print("FAIL: echo2 never reached B")
		quit(1)
		return
	print("PASS echo2_b")
	_state("ab_held")

	# 4) 走东区,录 R3:x12 窄道北上 → 踩 C(末帧)
	await _walk_cells(Vector2i(8, 3), Vector2i(12, 8))
	await _tap("record_toggle")
	await _walk_cells(Vector2i(12, 8), Vector2i(12, 2))
	await _walk_cells(Vector2i(12, 2), Vector2i(14, 2))
	await _walk_cells(Vector2i(14, 2), Vector2i(15, 3))
	await _frames(8)
	await _tap("record_toggle")
	_state("r3_recorded")

	# 5) 玩家亲自拨核心(持续 ON,TC-74 修订:标准解由玩家执行)
	await _walk_cells(Vector2i(15, 3), Vector2i(15, 10))
	await _frames(8)
	await _tap("interact")
	await _frames(8)
	if not _core.get("is_on"):
		print("FAIL: core not on after interact")
		quit(1)
		return
	print("PASS core_on")

	# 6) 埋伏 (12,2) → 发射回声 3 → 等 C 窗口(TC-80)
	await _walk_cells(Vector2i(15, 10), Vector2i(12, 10))
	await _walk_cells(Vector2i(12, 10), Vector2i(12, 2))
	_state("ambush")
	await _tap("play_echo")
	var c_opened := false
	for i in 600:
		if _lock.is_active():
			c_opened = true
			break
		await physics_frame
	if not c_opened:
		print("FAIL: echo3 never triggered time lock C")
		quit(1)
		return
	print("PASS echo3_c: window open")
	_state("window_open")

	# 7) 10s 窗口内经 x12 窄道冲门(TC-76)
	await _walk_cells(Vector2i(12, 2), Vector2i(9, 2))
	await _walk_cells(Vector2i(9, 2), Vector2i(9, 0))
	await _frames(12)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))
	quit()
