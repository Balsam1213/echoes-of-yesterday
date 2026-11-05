extends SceneTree
## M5 回归:TC-09 / TC-16 / TC-17 / TC-18 / TC-19 / TC-20 / TC-21。
## 运行(窗口模式,约 40 秒):godot --path . -s tools/regression_m5.gd
## 输出逐条 PASS/FAIL,结尾汇总;任何 FAIL 都须登记 logs/issues.md。

var _player: Node2D
var _switch: Area2D
var _door: StaticBody2D
var _mgr: Node
var _recorder: Node
var _fails: Array[String] = []


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _check(tc: String, cond: bool, detail := "") -> void:
	print("%s %s %s" % ["PASS" if cond else "FAIL", tc, detail])
	if not cond:
		_fails.append(tc)


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_01.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_switch = scene.get_node("YSorted/PressureSwitch")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	_recorder = _player.get_node("%TimeRecorder")
	_mgr.max_echoes = 3  # 本套件验证满额语义(TC-17 上限 3),与逐关配置无关

	# TC-09:记录满 30 秒自动结束(E-03)
	await _tap("record_toggle")
	await _frames(EchoRecording_MAX() + 30)
	var size: int = _recorder.recording.frames.size() if _recorder.recording != null else -1
	_check("TC-09", not _recorder.is_recording and size == 1800, "frames=%d" % size)

	# TC-19:记录中重置 → 未完成与已完成记录一并清除(E-01/02 §8.2)
	await _tap("record_toggle")
	await _frames(10)
	await _tap("reset_room")
	await _frames(5)
	_check("TC-19", not _recorder.is_recording and _recorder.recording == null)

	# TC-20:记录→回放→重置 ×10,无回声残留/机关状态错误/位置残留(NFR-03)
	var all_ok := true
	for i in 10:
		await _tap("record_toggle")
		await _frames(10)
		await _tap("record_toggle")
		await _tap("play_echo")
		await _frames(30)
		await _tap("reset_room")
		await _frames(5)
		var ok: bool = _mgr.echo_count() == 0 and not _switch.is_active() and not _door.is_open() \
			and _player.global_position.distance_to(Vector2(-96.0, 144.0)) < 2.0
		if not ok:
			all_ok = false
			print("  loop %d residue: echoes=%d sw=%s door=%s pos=%s" % [
				i + 1, _mgr.echo_count(), _switch.is_active(), _door.is_open(), _player.global_position])
	_check("TC-20", all_ok, "10 loops")

	# TC-17/TC-16:回声上限 3 与删除
	await _tap("record_toggle")
	await _frames(10)
	await _tap("record_toggle")
	for i in 4:
		await _tap("play_echo")
		await _frames(3)
	_check("TC-17", _mgr.echo_count() == 3)
	await _tap("delete_echo")
	await _frames(3)
	_check("TC-16", _mgr.echo_count() == 2)
	await _tap("reset_room")
	await _frames(5)

	# TC-21:暂停/继续
	var pe := InputEventAction.new()
	pe.action = &"pause"
	pe.pressed = true
	Input.parse_input_event(pe)
	await _frames(3)
	_check("TC-21a", paused)
	var pe2 := InputEventAction.new()
	pe2.action = &"pause"
	pe2.pressed = true
	Input.parse_input_event(pe2)
	await _frames(3)
	_check("TC-21b", not paused)

	# TC-47:出口开口密封(门关闭时,闭环走位不可绕行/穿越抵达出口区,防跳关)
	var leak := {"completed": false, "arrived": false}
	root.get_node("GameEvents").level_completed.connect(func(_id: int) -> void: leak.completed = true)
	var exit_pos: Vector2 = scene.get_node("YSorted/ExitArea").position
	for i in 600:
		if leak.completed or (exit_pos - _player.global_position).length() <= 24.0:
			leak.arrived = true
			break
		var d: Vector2 = exit_pos - _player.global_position
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
	_check("TC-47", not leak.completed and not leak.arrived,
		"pos=%s dist=%.0f" % [_player.global_position, _player.global_position.distance_to(exit_pos)])

	print("REGRESSION RESULT: %s (%d fails)" % ["ALL PASS" if _fails.is_empty() else "FAILURES", _fails.size()])
	quit()


## EchoRecording.MAX_FRAMES 经动态读取(-s 脚本编译期不引用游戏类,docs/03 §1)
func EchoRecording_MAX() -> int:
	var rec: RefCounted = load("res://scripts/recording/echo_recording.gd").new()
	return rec.MAX_FRAMES
