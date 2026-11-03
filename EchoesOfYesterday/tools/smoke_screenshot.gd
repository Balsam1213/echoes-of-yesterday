extends SceneTree
## 冒烟测试(T1.1—T1.4):窗口模式运行测试房间约 1 秒,模拟向右移动后截图。
## 运行:godot --path . -s tools/smoke_screenshot.gd
## 产出:项目根 smoke_m1.png(验证用临时文件,不入库)。

func _initialize() -> void:
	_run()


func _run() -> void:
	var scene: Node = (load("res://scenes/dev/dev_grid_test.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	# 等场景就绪后向右走约 0.75 秒,再停住 0.15 秒截图
	await process_frame
	await process_frame
	Input.action_press("move_right")
	for i in 45:
		await process_frame
	Input.action_release("move_right")
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://smoke_m1.png"))
	print("smoke screenshot saved")
	quit()
