extends SceneTree
## 一次性密封审计(用后即删):L7 分区 BFS 可达性(物理采样,门 Blocker 随极性实时生效)。
## 断言(返修 3):
##   OFF(初始):南口双门落下 → 北厅/悖论区可达;东室(密封)不可达;
##   ON(供电):南口双门密封 → 北厅/悖论区/东室内 GLES 之外均不可达;东室可达。

func _initialize() -> void:
	_run()


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _cw(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 32 + 32, (x + y) * 16 + 16)


func _standable(space: PhysicsDirectSpaceState2D, pos: Vector2) -> bool:
	var params := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	params.shape = shape
	params.transform = Transform2D(0.0, pos + Vector2(0, -6))
	params.collision_mask = 1  # world 层(墙体/门体/密封的相位门 Blocker)
	return space.intersect_shape(params, 1).is_empty()


## 以格心为节点的 4 邻 BFS(边中点 + 目标格心均需可站):密封菱形贴边即阻断
func _bfs(scene: Node, start: Vector2i, bounds: Rect2i) -> Dictionary:
	var floor_layer: TileMapLayer = scene.get_node("Floor")
	var space: PhysicsDirectSpaceState2D = scene.get_world_2d().direct_space_state
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if seen.has(n) or not bounds.has_point(n):
				continue
			var mid := (floor_layer.map_to_local(c) + floor_layer.map_to_local(n)) * 0.5
			if not _standable(space, mid):
				continue
			if not _standable(space, floor_layer.map_to_local(n)):
				continue
			seen[n] = true
			queue.append(n)
	return seen


func _zone_reachable(seen: Dictionary, zone: Rect2i) -> bool:
	for x in range(zone.position.x, zone.end.x):
		for y in range(zone.position.y, zone.end.y):
			if seen.has(Vector2i(x, y)):
				return true
	return false


func _run() -> void:
	var scene: Node = (load("res://scenes/levels/Level_07.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(3)
	var core: Area2D = scene.get_node("YSorted/Core")
	var bounds := Rect2i(1, 1, 16, 10)
	var hall := Rect2i(4, 1, 10, 3)
	var east_room := Rect2i(12, 6, 4, 3)
	var p1 := Rect2i(8, 5, 2, 3)
	var fails := 0

	# 状态 OFF(初始):南口落下 / 东门密封
	var seen := _bfs(scene, Vector2i(2, 9), bounds)
	var checks := [
		["OFF hall reachable (south gates dropped)", _zone_reachable(seen, hall), true],
		["OFF p1 reachable (crossable)", _zone_reachable(seen, p1), true],
		["OFF east_room NOT reachable (gate sealed)", _zone_reachable(seen, east_room), false],
	]
	# 状态 ON(供电):南口密封 / 东门落下
	core.call("set_on", true)
	await _frames(4)
	var seen_on := _bfs(scene, Vector2i(2, 9), bounds)
	checks.append_array([
		["ON hall NOT reachable (south gates sealed)", _zone_reachable(seen_on, hall), false],
		["ON p1 NOT reachable (only via south gates)", _zone_reachable(seen_on, p1), false],
		["ON east_room reachable (gate dropped)", _zone_reachable(seen_on, east_room), true],
	])
	for c in checks:
		var ok: bool = c[1] == c[2]
		print(("PASS " if ok else "FAIL ") + str(c[0]) + " (got %s, want %s)" % [c[1], c[2]])
		if not ok:
			fails += 1
	print("SEAL AUDIT: ", "ALL PASS" if fails == 0 else "%d FAILS" % fails)
	quit(1 if fails > 0 else 0)
