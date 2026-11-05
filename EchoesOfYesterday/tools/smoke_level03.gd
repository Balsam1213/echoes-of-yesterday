extends SceneTree
## Level_03 冒烟:三回声 + 时间锁全流程(docs/12)。
## 走位采用闭环 _walk_to(每帧按实际位置修正方向,沿菱形边滑行)——消除开环帧数标定误差。
## 运行:godot --path . -s tools/smoke_level03.gd

const WAIT := 12

var _player: Node2D
var _sw_a: Area2D
var _sw_b: Area2D
var _lock: Area2D
var _door: StaticBody2D
var _mgr: Node
var _pos_a: Vector2
var _pos_b: Vector2
var _pos_c: Vector2
var _pos_exit: Vector2


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


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


## 闭环走位:同时按两轴方向,每帧按实际位置修正,直到进入容差(沿菱形边自然滑行)
func _walk_to(target: Vector2, tol := 8.0) -> void:
	for i in 600:
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


func _state(tag: String) -> void:
	print("%s pos=%s a=%s b=%s c=%s door=%s echoes=%d" % [
		tag, _player.global_position, _sw_a.is_active(), _sw_b.is_active(),
		_lock.is_active(), _door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_03.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw_a = scene.get_node("YSorted/SwitchA")
	_sw_b = scene.get_node("YSorted/SwitchB")
	_lock = scene.get_node("YSorted/TimeLock")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	print("title=", scene.get_node("UI/HUD/LevelLabel").text)
	_pos_a = scene.get_node("YSorted/SwitchA").position
	_pos_b = scene.get_node("YSorted/SwitchB").position
	_pos_c = scene.get_node("YSorted/TimeLock").position
	_pos_exit = scene.get_node("YSorted/ExitArea").position
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) A 路:走西直路到开关 A → 记录站立 → 回声 1 踩 A
	await _walk_to(_pos_a)
	_state("on_a")
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(60)
	_state("echo1_a")

	# 2) B 路:走东 L 形到开关 B → 记录 → 回声 2
	await _walk_to(_pos_b)
	_state("on_b")
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(40)
	_state("echo2_b")

	# 3) C 时间锁首次发现:走到 C → 倒计时 → 到期自动释放(T-15,E-31)
	await _walk_to(_pos_c)
	_state("on_c_first")
	await _frames(660)
	_state("c_expired")

	# 4) 录 C 路:原地记录(已在 C 上)→ 玩家走离 → Space → 回声 3 踩 C → 10s 窗口
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	var away: Vector2 = _pos_c + Vector2(0, 60)
	await _walk_to(away)
	await _tap("play_echo")
	await _frames(8)
	_state("window_open")

	# 5) 冲刺出口(时间窗内)
	await _walk_to(_pos_exit, 24.0)
	await _frames(WAIT)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))

	# 6) 按任意键重玩(章节末关)
	await _tap_key(KEY_E)
	await _frames(20)
	_state("after_replay")
	quit()
