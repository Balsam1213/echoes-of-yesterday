extends SceneTree
## Level_02 冒烟:双开关 AND 门全流程(docs/11)。
## 踩 A(T-12)→ 记录 A → 回声踩 A → 记录 B → 双回声开门 → 穿门通关 → 进入 Level_03。
## 运行:godot --path . -s tools/smoke_level02.gd

const WAIT := 12

var _player: Node2D
var _sw_a: Area2D
var _sw_b: Area2D
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
	print("%s pos=%s a=%s b=%s door=%s echoes=%d" % [
		tag, _player.global_position, _sw_a.is_active(), _sw_b.is_active(),
		_door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_02.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_sw_a = scene.get_node("YSorted/SwitchA")
	_sw_b = scene.get_node("YSorted/SwitchB")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) 走到开关 A(同排向东)→ 踩上(单灯亮 → T-12)
	await _press("move_right", 55)
	_state("on_a")

	# 2) 记录"站上 A" → 回声 1 踩住 A
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(25)
	_state("echo1_holds_a")

	# 3) 走到开关 B(南→东)→ 踩上 → 双灯齐、门开
	await _press("move_down", 26)
	await _press("move_right", 55)
	_state("on_b")

	# 4) 记录"站上 B" → 回声 2 → 双回声保持,玩家自由
	await _tap("record_toggle")
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(25)
	_state("echo2_holds_b")

	# 5) 穿门到出口(门在北墙 (6,2),出口 (6,0))
	await _press("move_up", 22)
	await _press("move_right", 8)
	await _press("move_up", 16)
	_state("north_side")
	await _press("move_up", 6)
	await _press("move_right", 14)
	await _frames(WAIT)
	_state("complete")
	print("save=", FileAccess.get_file_as_string("user://save.json"))

	# 6) 按任意键 → 应推进到 Level_03(关卡推进链;静置 1.2s 防误触延迟后)
	await _frames(90)
	await _tap_key(KEY_E)
	await _frames(20)
	print("after_key current_scene=", current_scene.name)
	quit()
