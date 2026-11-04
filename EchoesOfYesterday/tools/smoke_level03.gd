extends SceneTree
## Level_03 冒烟:三回声 + 时间锁全流程(docs/12)。
## A 路记录→回声1;B 路记录→回声2;踩 C 发现时间锁(T-15);录 C 路→回声3 踩 C
## → 10s 窗口冲刺出门 → 通关(章节完)→ 任意键重玩。
## 运行:godot --path . -s tools/smoke_level03.gd

const WAIT := 12

var _player: Node2D
var _sw_a: Area2D
var _sw_b: Area2D
var _lock: Area2D
var _door: StaticBody2D
var _mgr: Node


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _press(action: String, frames: int) -> void:
	Input.action_press(action)
	await _frames(maxi(frames, 2))
	Input.action_release(action)


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
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) A 路(西直路):左 41f → 上 49f → 踩 A → 记录 → 回声 1
	await _press("move_left", 41)
	await _press("move_up", 49)
	_state("on_a")
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(60)
	_state("echo1_a")

	# 2) B 路(东 L 形):东行(沿 (5,4) 短墙滑行)→ 南下(绕 (9,5)/(9,6))→ 踩 B → 记录 → 回声 2
	await _press("move_right", 70)
	await _press("move_down", 55)
	await _press("move_right", 30)
	await _press("move_down", 20)
	_state("near_b")
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(40)
	_state("echo2_b")

	# 3) 走到时间锁 C → 首次发现(倒计时到期 T-15)
	await _press("move_left", 55)
	await _press("move_up", 60)
	_state("on_c_first")
	await _frames(660)
	_state("c_expired")

	# 4) 录 C 路(离开→折回):下 55f → R → 上 55f → R → 玩家下 6f → Space → 回声 3 踩 C → 窗口
	await _press("move_down", 55)
	await _tap("record_toggle")
	await _press("move_up", 55)
	await _tap("record_toggle")
	await _press("move_down", 6)
	await _tap("play_echo")
	await _frames(8)
	_state("window_open")
	# 5) 冲刺:东北 → 穿门 → 出口
	await _press("move_up", 30)
	await _press("move_right", 40)
	await _press("move_up", 20)
	await _press("move_right", 15)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))

	# 6) 按任意键重玩(章节末关)
	await _tap_key(KEY_E)
	await _frames(20)
	_state("after_replay")
	quit()
