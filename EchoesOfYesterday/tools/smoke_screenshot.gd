extends SceneTree
## 冒烟测试(T2.3):窗口模式运行机关联动测试房,模拟「踩上开关→截图 A(门开)→离开→截图 B(门关)」。
## 运行:godot --path . -s tools/smoke_screenshot.gd
## 产出:项目根 smoke_m2_open.png / smoke_m2_closed.png(验证用临时文件,不入库)。

const WAIT := 12  # 状态切换后的等待帧数


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	# 必须按物理帧计数:渲染帧率不受控(无垂直同步时可达 180fps),移动发生在 60Hz 物理帧
	for i in n:
		await physics_frame


func _shot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://" + file_name))
	print("saved ", file_name)


func _run() -> void:
	var scene: Node = (load("res://scenes/dev/dev_mechanisms.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(2)
	var player: PlayerController = scene.get_node("YSorted/Player")
	var sw: PressureSwitch = scene.get_node("YSorted/PressureSwitch")
	var door: SecurityDoor = scene.get_node("YSorted/SecurityDoor")
	print("spawn pos=", player.global_position, " switch=", sw.global_position, " door=", door.global_position)
	# 1) 向右走到压力开关上((3,4)→(4,3) 同一世界高度,右移即踩上)
	Input.action_press("move_right")
	await _frames(24)
	Input.action_release("move_right")
	await _frames(WAIT)
	print("A: pos=", player.global_position, " switch_active=", sw.is_active(), " door_open=", door.is_open())
	var panel: Sprite2D = door.get_node("%Panel")
	var light: Sprite2D = door.get_node("%Light")
	print("A: panel_pos=", panel.position, " light_mod=", light.modulate, " blocker_disabled=", door.get_node("%Blocker").disabled)
	for c in door.get_children():
		var info := str(c.get_path()).get_file() + " (" + c.get_class() + ")"
		if c is Node2D:
			info += " pos=" + str(c.position) + " global=" + str(c.global_position)
		if c is Sprite2D:
			info += " mod=" + str(c.modulate)
		print("  door child: ", info)
	await _shot("smoke_m2_open.png")
	# 2) 向下离开开关,门应关闭
	Input.action_press("move_down")
	await _frames(30)
	Input.action_release("move_down")
	await _frames(WAIT)
	print("B: pos=", player.global_position, " switch_active=", sw.is_active(), " door_open=", door.is_open())
	await _shot("smoke_m2_closed.png")
	# 3) 向右下压到底墙:玩家应被墙立方体遮挡(墙在前),验证 Y-sort 排序基准修复
	Input.action_press("move_right")
	Input.action_press("move_down")
	await _frames(30)
	Input.action_release("move_right")
	Input.action_release("move_down")
	await _frames(WAIT)
	print("C: pos=", player.global_position)
	await _shot("smoke_bottom.png")
	quit()
