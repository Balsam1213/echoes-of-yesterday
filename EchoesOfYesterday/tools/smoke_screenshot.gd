extends SceneTree
## M4 冒烟:第一关全流程。
## 教学(T-03/T-02/T-05)→ 记录/回声协作 → 穿门 → 通关(存档+T-07)→ 任意键重玩 → 重置 → 暂停。
## 运行:godot --path . -s tools/smoke_screenshot.gd
## 产出:smoke_m4_replaying.png / smoke_m4_complete.png(临时,不入库)。

const WAIT := 12

var _player: Node2D
var _switch: Area2D
var _door: StaticBody2D
var _mgr: Node
var _level: Node


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


func _tap_action_event(action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func _shot(file_name: String) -> void:
	await physics_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://" + file_name))
	print("saved ", file_name)


func _state(tag: String) -> void:
	print("%s pos=%s sw=%s door=%s echoes=%d paused=%s" % [
		tag, _player.global_position, _switch.is_active(), _door.is_open(),
		_mgr.echo_count(), paused])


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_01.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene  # 使 change_scene_to_file 在 -s 模式可用(关卡推进链验证)
	await _frames(2)
	_level = scene
	_player = scene.get_node("YSorted/Player")
	_switch = scene.get_node("YSorted/PressureSwitch")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	root.get_node("GameEvents").level_completed.connect(func(id: int) -> void: print("LEVEL_COMPLETED id=", id))
	_state("spawn")

	# 1) 向东南:经过记录装置(T-03)→ 踩上开关(TC-03)→ 走离开关(T-02)
	await _press("move_down", 4)
	await _press("move_right", 40)
	_state("near_device")
	await _press("move_right", 30)
	_state("on_pad")
	await _press("move_right", 20)
	_state("off_pad")

	# 2) R 记录"走回开关" → 玩家离开 → Space 回声踩住(TC-08~13)
	await _tap("record_toggle")
	await _press("move_left", 30)
	await _tap("record_toggle")
	await _press("move_left", 12)
	await _tap("play_echo")
	await _frames(8)
	await _shot("smoke_m4_replaying.png")
	await _frames(40)
	_state("echo_holds")

	# 3) 穿门(TC-05)→ 抵达出口 → 通关(存档 + T-07,TC-14/15)
	await _press("move_right", 26)
	await _press("move_down", 8)
	await _press("move_right", 14)
	await _press("move_up", 26)
	await _press("move_right", 10)
	_state("north_side")
	await _press("move_up", 6)
	await _press("move_right", 24)
	await _frames(WAIT)
	_state("complete")
	await _shot("smoke_m4_complete.png")
	print("save_exists=", FileAccess.file_exists("user://save.json"),
		" content=", FileAccess.get_file_as_string("user://save.json") if FileAccess.file_exists("user://save.json") else "")

	# 4) 按任意键继续(FR-011 推进链):冻结 1.2s 后接受按键 → 切换到 Level_02
	await _frames(90)
	_state("complete_settled")
	await _tap_key(KEY_E)
	await _frames(20)
	print("after_key current_scene=", current_scene.name)
	quit()
