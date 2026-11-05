extends SceneTree
## 地图泄漏探针:物理采样网格 + BFS 可达性,报告玩家(r6)可达的"房间菱形之外"区域。
## 运行:godot --path . -s tools/probe_map.gd
## 输出:每关可达外出样本数与位置(世界坐标),用于定位逃逸缺口。

const STEP := 16.0
const RADIUS := 6.0
const MARGIN := 320.0  # 采样范围:房间包围盒外扩,覆盖外圈空地

var _fails := 0


func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	for path: String in [
		"res://scenes/levels/Level_01.tscn",
		"res://scenes/levels/Level_02.tscn",
		"res://scenes/levels/Level_03.tscn",
	]:
		await _probe(path)
	print("PROBE RESULT: %d 处泄漏" % _fails)
	quit()


func _probe(path: String) -> void:
	var scene: Node = (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(3)
	var floor_layer: TileMapLayer = scene.get_node("Floor")
	var player: Node2D = scene.get_node("YSorted/Player")
	var space: PhysicsDirectSpaceState2D = scene.get_world_2d().direct_space_state

	var used: Rect2i = floor_layer.get_used_rect()
	var c00: Vector2 = floor_layer.map_to_local(used.position)
	var c10: Vector2 = floor_layer.map_to_local(used.position + Vector2i(used.size.x - 1, 0))
	var c11: Vector2 = floor_layer.map_to_local(used.position + used.size - Vector2i(1, 1))
	var c01: Vector2 = floor_layer.map_to_local(used.position + Vector2i(0, used.size.y - 1))
	var quad: PackedVector2Array = [c00, c10, c11, c01]  # 房间菱形(顶/右/底/左)

	var spawn: Vector2 = player.global_position
	var circle := CircleShape2D.new()
	circle.radius = RADIUS

	# 采样:包围盒 = 四角范围外扩 MARGIN
	var min_p: Vector2 = Vector2(
		min(min(c00.x, c01.x), min(c10.x, c11.x)) - MARGIN,
		min(min(c00.y, c01.y), min(c10.y, c11.y)) - MARGIN)
	var max_p: Vector2 = Vector2(
		max(max(c00.x, c01.x), max(c10.x, c11.x)) + MARGIN,
		max(max(c00.y, c01.y), max(c10.y, c11.y)) + MARGIN)

	var walkable := {}  # Vector2(取整) -> true
	var x := min_p.x
	while x <= max_p.x:
		var y := min_p.y
		while y <= max_p.y:
			var p := Vector2(x, y)
			var q := PhysicsShapeQueryParameters2D.new()
			q.shape = circle
			q.transform = Transform2D(0, p)
			q.collision_mask = 1
			if space.intersect_shape(q, 1).is_empty():
				walkable[p.snapped(Vector2(STEP, STEP))] = true
			y += STEP
		x += STEP

	# BFS:从出生点最近的可通行采样出发,4 邻域;记录"内→外"跨界点(泄漏入口)
	var start := spawn.snapped(Vector2(STEP, STEP))
	while not walkable.has(start):
		start += Vector2(STEP, 0)  # 兜底向右找
	var reachable := {start: true}
	var queue: Array[Vector2] = [start]
	var outside := 0
	var crossings := {}  # 格位坐标(去重);深度 > 48px 才算真泄漏(越过墙菱形 32px 凸出)
	while not queue.is_empty():
		var p: Vector2 = queue.pop_front()
		var p_depth := _quad_signed_dist(p, quad)
		for off: Vector2 in [Vector2(STEP, 0), Vector2(-STEP, 0), Vector2(0, STEP), Vector2(0, -STEP), Vector2(STEP, STEP), Vector2(STEP, -STEP), Vector2(-STEP, STEP), Vector2(-STEP, -STEP)]:
			var np: Vector2 = p + off
			var key := np.snapped(Vector2(STEP, STEP))
			if walkable.has(key) and not reachable.has(key) and not (off.x != 0 and off.y != 0 and not (walkable.has(p.snapped(Vector2(STEP, STEP)) + Vector2(off.x, 0)) and walkable.has(p.snapped(Vector2(STEP, STEP)) + Vector2(0, off.y)))):
				reachable[key] = true
				queue.push_back(key)
				var np_depth := _quad_signed_dist(np, quad)
				if np_depth > 12.0 and p_depth <= 12.0:
					crossings[floor_layer.local_to_map(np)] = np
				if np_depth > 12.0:
					outside += 1

	print("== %s ==" % path.get_file())
	print("  总可通行采样: ", walkable.size())
	print("  可达采样 %d,其中房间外(深≥12px) %d;泄漏入口 %d 处" % [reachable.size(), outside, crossings.size()])
	if not crossings.is_empty():
		_fails += 1
		for cell: Vector2i in crossings:
			print("  泄漏入口: 格位 %s 世界 %s" % [cell, crossings[cell]])

	scene.queue_free()
	await _frames(2)


## 点到房间菱形四条棱线的带符号距离(min;负=在房间内侧,正=外侧)
func _quad_signed_dist(p: Vector2, quad: PackedVector2Array) -> float:
	var n := quad.size()
	var dist := INF
	for i in n:
		var a: Vector2 = quad[i]
		var b: Vector2 = quad[(i + 1) % n]
		var edge := b - a
		var normal := Vector2(edge.y, -edge.x).normalized()  # 指向四边形外
		dist = minf(dist, (p - a).dot(normal))
	return dist
