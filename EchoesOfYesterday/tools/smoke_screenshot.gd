extends SceneTree
## M3 冒烟:核心闭环验证。
## 场景:玩家走到开关东侧 → R 记录"走回开关" → 走离开关 → Space 生成回声
##   → 回声重演并踩住开关(门保持开)→ 玩家穿门到北侧 → 上限/删除测试。
## 运行:godot --path . -s tools/smoke_screenshot.gd
## 产出:项目根 smoke_m3_echo.png / smoke_m3_through.png(临时,不入库)。

const WAIT := 12

# 工具脚本(-s)编译期不得引用游戏类(autoload 编译期不可见),一律动态访问(docs/03 §1)
var _player: Node2D
var _switch: Area2D
var _door: StaticBody2D
var _mgr: Node


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	# 必须按物理帧计数(渲染帧率不受控,docs/devlog 2026-11-04 M2)
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


func _shot(file_name: String) -> void:
	await physics_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://" + file_name))
	print("saved ", file_name)


func _state(tag: String) -> void:
	print("%s pos=%s sw=%s door=%s echoes=%d" % [
		tag, _player.global_position, _switch.is_active(), _door.is_open(), _mgr.echo_count()])


func _run() -> void:
	var scene: Node = (load("res://scenes/dev/dev_mechanisms.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	_switch = scene.get_node("YSorted/PressureSwitch")
	_door = scene.get_node("YSorted/SecurityDoor")
	_mgr = scene.get_node("EchoManager")
	root.get_node("GameEvents").notify_requested.connect(func(t: String) -> void: print("NOTIFY: ", t))
	_state("spawn")

	# 1) 走到开关东侧(记录起点,不在开关上)
	await _press("move_right", 40)
	_state("start_pos")
	# 2) R 开始 → 向左走回开关上 → R 结束(记录内容:走向开关)
	await _tap("record_toggle")
	await _press("move_left", 16)
	await _tap("record_toggle")
	_state("recorded")
	# 3) 玩家走离开关,Space 生成回声 → 回声重演走上开关并踩住(TC-11/13)
	await _press("move_left", 15)
	await _tap("play_echo")
	await _frames(45)
	_state("echo_on_pad")
	await _shot("smoke_m3_echo.png")
	# 4) 玩家经门洞走到北侧(门被回声保持打开,TC-05)
	await _press("move_right", 14)
	await _press("move_up", 26)
	await _press("move_right", 10)
	_state("through_door")
	await _shot("smoke_m3_through.png")
	# 5) 回声上限与删除(TC-16/17):再生成 2 个 → 第 4 个超限提示 → X 删除
	await _tap("play_echo")
	await _frames(5)
	await _tap("play_echo")
	await _frames(5)
	_state("capped_3")
	await _tap("play_echo")
	await _frames(5)
	_state("over_cap")
	await _tap("delete_echo")
	await _frames(5)
	_state("after_delete")
	quit()
