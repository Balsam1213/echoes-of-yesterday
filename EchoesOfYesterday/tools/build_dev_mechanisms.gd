extends SceneTree
## 构建机关联动测试房 dev_mechanisms.tscn(T2.3)。
## 运行:godot --headless --path . -s tools/build_dev_mechanisms.gd
## 布局:8×6 等距房;横向(网格行 y=2)墙体带门洞,压力开关(5,4),玩家出生 (3,4)。
## 联线:switch_activated → door.set_open(true);switch_deactivated → door.set_open(false)。
## 验证点:踩开关开门(TC-03/05)、离开关门(TC-04/06)、门洞防夹(TC-07)。

const ROOM_W := 8
const ROOM_H := 6
const DOOR_CELL := Vector2i(3, 2)
const SWITCH_CELL := Vector2i(4, 3)
const SPAWN_CELL := Vector2i(3, 4)


func _initialize() -> void:
	_run()


func _run() -> void:
	var room := Node2D.new()
	room.name = "DevMechanisms"
	room.set_script(load("res://scripts/level/dev_mechanisms_room.gd"))  # 运行时连线(pack 不保存连接)

	# --- TileSet(与 dev_grid_test 同参:等距 64×32,DIAMOND_DOWN) ---
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = Vector2i(64, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/environment/floor_tile.png")
	atlas.texture_region_size = Vector2i(64, 32)
	atlas.create_tile(Vector2i.ZERO)
	tile_set.add_source(atlas, 0)

	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tile_set
	for x in ROOM_W:
		for y in ROOM_H:
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	room.add_child(floor_layer)

	_add_boundary(room, floor_layer)

	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	room.add_child(ysorted)

	var wall_tex: Texture2D = load("res://assets/environment/wall_block.png")

	# 周界墙
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, y))))

	# 横墙(网格行 y=2),门洞位留空
	for x in range(1, ROOM_W - 1):
		if Vector2i(x, 2) == DOOR_CELL:
			continue
		ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, 2))))

	# 机关:压力开关 + 安全门,信号直连
	var switch: PressureSwitch = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	switch.name = "PressureSwitch"
	switch.unique_name_in_owner = true
	switch.position = floor_layer.map_to_local(SWITCH_CELL)
	ysorted.add_child(switch)

	var door: SecurityDoor = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)

	# 玩家
	var player: PlayerController = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = floor_layer.map_to_local(SPAWN_CELL)
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

	_assign_owner(room, room)  # pack() 只包含 owner 指向根的节点
	var packed := PackedScene.new()
	var err := packed.pack(room)
	if err != OK:
		push_error("pack failed: %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/dev/dev_mechanisms.tscn")
	print("dev_mechanisms.tscn saved, err=", err)
	quit()


func _make_wall(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	return sprite


func _assign_owner(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_assign_owner(child, owner)


func _add_boundary(room: Node2D, floor_layer: TileMapLayer) -> void:
	var p_top := floor_layer.map_to_local(Vector2i(0, 0))
	var p_right := floor_layer.map_to_local(Vector2i(ROOM_W - 1, 0))
	var p_bottom := floor_layer.map_to_local(Vector2i(ROOM_W - 1, ROOM_H - 1))
	var p_left := floor_layer.map_to_local(Vector2i(0, ROOM_H - 1))
	var verts: Array[Vector2] = [
		p_top + Vector2(0, -16),
		p_right + Vector2(32, 0),
		p_bottom + Vector2(0, 16),
		p_left + Vector2(-32, 0),
	]
	var center: Vector2 = (verts[0] + verts[1] + verts[2] + verts[3]) / 4.0

	var body := StaticBody2D.new()
	body.name = "Boundary"
	body.collision_layer = 1
	body.collision_mask = 0
	room.add_child(body)
	for i in 4:
		var a: Vector2 = verts[i]
		var b: Vector2 = verts[(i + 1) % 4]
		var dir: Vector2 = (b - a).normalized()
		var normal: Vector2 = dir.orthogonal()
		if (center - (a + b) / 2.0).dot(normal) < 0.0:
			normal = -normal
		var shape := RectangleShape2D.new()
		shape.size = Vector2(a.distance_to(b) + 32.0, 14.0)
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = (a + b) / 2.0 + normal * 12.0  # 内移 12px,防边界穿模(见 devlog 2026-11-04 M1)
		cs.rotation = dir.angle()
		body.add_child(cs)


func _camera_limits(floor_layer: TileMapLayer) -> Rect2i:
	var p_top := floor_layer.map_to_local(Vector2i(0, 0))
	var p_right := floor_layer.map_to_local(Vector2i(ROOM_W - 1, 0))
	var p_bottom := floor_layer.map_to_local(Vector2i(ROOM_W - 1, ROOM_H - 1))
	var p_left := floor_layer.map_to_local(Vector2i(0, ROOM_H - 1))
	var left := int(p_left.x) - 32
	var top := int(p_top.y) - 48
	return Rect2i(left, top, int(p_right.x) + 32 - left, int(p_bottom.y) + 16 - top)
