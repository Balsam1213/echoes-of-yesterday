extends SceneTree
## 周界贴墙巡走:真实输入沿内壁滑行一圈,逐段检测玩家是否越出房间菱形(泄漏定位);
## 结尾走到时间锁附近截图,验证贴花可见性。
## 运行:godot --path . -s tools/smoke_perimeter.gd
## 产出:perimeter_check.png(临时,不入库)。

const DEPTH_LIMIT := 20.0  # 墙菱形最外缘约在棱线外 16px;超过 20px = 真逃逸

var _player: Node2D
var _quad: PackedVector2Array
var _leaks: Array[String] = []


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _press(action: String, frames: int) -> void:
	Input.action_press(action)
	await _frames(maxi(frames, 2))
	Input.action_release(action)


func _walk_to(target: Vector2, tol := 18.0, cap := 120) -> void:
	for i in cap:
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


func _signed_dist(p: Vector2) -> float:
	var dist := INF
	for i in _quad.size():
		var a: Vector2 = _quad[i]
		var b: Vector2 = _quad[(i + 1) % _quad.size()]
		var edge := b - a
		var normal := Vector2(edge.y, -edge.x).normalized()
		dist = minf(dist, (p - a).dot(normal))
	return dist


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_03.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	_player = scene.get_node("YSorted/Player")
	var floor_layer: TileMapLayer = scene.get_node("Floor")
	var used: Rect2i = floor_layer.get_used_rect()
	_quad = [
		floor_layer.map_to_local(used.position),
		floor_layer.map_to_local(used.position + Vector2i(used.size.x - 1, 0)),
		floor_layer.map_to_local(used.position + used.size - Vector2i(1, 1)),
		floor_layer.map_to_local(used.position + Vector2i(0, used.size.y - 1)),
	]

	# 周界格位顺时针序列:北行(x,0) → 东列(x=W-1,y↑) → 南行逆(x,W-1←) → 西列逆(0,y↓)
	var ring: Array[Vector2] = []
	for x in used.size.x:
		ring.append(floor_layer.map_to_local(Vector2i(x, 0)))
	for y in range(1, used.size.y):
		ring.append(floor_layer.map_to_local(Vector2i(used.size.x - 1, y)))
	for x in range(used.size.x - 2, -1, -1):
		ring.append(floor_layer.map_to_local(Vector2i(x, used.size.y - 1)))
	for y in range(used.size.y - 2, 0, -1):
		ring.append(floor_layer.map_to_local(Vector2i(0, y)))

	for i in ring.size():
		await _walk_to(ring[i], 18.0, 120)
		var depth := _signed_dist(_player.global_position)
		if depth > DEPTH_LIMIT:
			_leaks.append("段 %d 目标=%s pos=%s depth=%.1f" % [i, ring[i], _player.global_position, depth])
	print("PERIMETER: %s (泄漏 %d)" % ["无泄漏" if _leaks.is_empty() else "有泄漏", _leaks.size()])
	for l in _leaks:
		print("LEAK: ", l)

	# 贴花可见性截图(时间锁附近)
	var lock_pos: Vector2 = scene.get_node("YSorted/TimeLock").position
	await _walk_to(lock_pos, 40.0, 90)
	await _frames(2)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://perimeter_check.png"))
	print("saved perimeter_check.png")
	quit()
