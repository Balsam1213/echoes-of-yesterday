extends SceneTree
## 构建第一关 Level_01.tscn(T4.1)。
## 运行:godot --headless --path . -s tools/build_level_01.gd
## 布局(docs/05 §3.2):房间 12×8;出生 (2,7);记录装置 (3,5);压力开关 (5,4);
## 安全门 (5,2) 嵌在横墙 y=2 中;出口触发区 (5,0)-(7,0),出口背后一排虚拟碰撞防走出地图。
## 注意:工具脚本编译期不得引用游戏类(docs/03 §1),一律 load() + 动态访问。

const ROOM_W := 12
const ROOM_H := 8
const DOOR_CELL := Vector2i(5, 2)
const SWITCH_CELL := Vector2i(5, 4)
const DEVICE_CELL := Vector2i(3, 5)
const SPAWN_CELL := Vector2i(2, 6)  # docs/05 出生区在南端;(2,7) 是周界墙行,出生点须在其内一格
const EXIT_CELLS: Array[Vector2i] = [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_01"
	level.set_script(load("res://scripts/level/level_01_manager.gd"))
	level.next_scene = "res://scenes/levels/Level_02.tscn"  # 通关推进链(docs/10 §4)

	# --- TileSet(等距 64×32,DIAMOND_DOWN) ---
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
	level.add_child(floor_layer)

	# 地面贴花层(平底物件:开关底座等,恒在角色之下)
	var decals := Node2D.new()
	decals.name = "Decals"
	level.add_child(decals)

	# --- 墙体碰撞:周界(北缘扣除出口三格)+ 横墙;出口背后虚拟碰撞防走出地图 ---
	var wall_cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) in EXIT_CELLS:
					continue  # 出口格不设墙(由出口触发区 + 背后虚拟碰撞接管)
				wall_cells.append(Vector2i(x, y))
	for x in range(1, ROOM_W - 1):
		if Vector2i(x, 2) != DOOR_CELL:
			wall_cells.append(Vector2i(x, 2))
	for x in range(4, 9):
		wall_cells.append(Vector2i(x, -1))
	_add_wall_colliders(level, floor_layer, wall_cells)

	# --- 实体层 ---
	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	level.add_child(ysorted)

	var wall_tex: Texture2D = load("res://assets/environment/wall_block.png")

	# 周界墙视觉(北缘同样扣除出口格)
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) in EXIT_CELLS:
					continue
				ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, y))))

	# 横墙(网格行 y=2),门洞位留空
	for x in range(1, ROOM_W - 1):
		if Vector2i(x, 2) == DOOR_CELL:
			continue
		ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, 2))))

	# 机关:安全门 + 压力开关 + 时间记录装置
	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)

	var switch: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	switch.name = "PressureSwitch"
	switch.unique_name_in_owner = true
	switch.position = floor_layer.map_to_local(SWITCH_CELL)
	ysorted.add_child(switch)

	# 开关底座贴花(地面层,恒在角色之下——平底物件不参与 Y-sort)
	var sw_pad := Sprite2D.new()
	sw_pad.name = "SwitchPad"
	sw_pad.texture = load("res://assets/mechanisms/switch_pad.png")
	sw_pad.position = floor_layer.map_to_local(SWITCH_CELL)
	decals.add_child(sw_pad)
	switch.bind_pad(sw_pad, sw_pad.position)

	var device: Area2D = (load("res://scenes/mechanisms/TimeRecorderDevice.tscn") as PackedScene).instantiate()
	device.name = "TimeRecorderDevice"
	device.unique_name_in_owner = true
	device.position = floor_layer.map_to_local(DEVICE_CELL)
	ysorted.add_child(device)

	# 出口触发区:覆盖 (5,0)-(7,0) 三格,沿行方向旋转
	var exit: Area2D = (load("res://scenes/mechanisms/ExitArea.tscn") as PackedScene).instantiate()
	exit.name = "ExitArea"
	exit.unique_name_in_owner = true
	var exit_a := floor_layer.map_to_local(EXIT_CELLS[0])
	var exit_b := floor_layer.map_to_local(EXIT_CELLS[2])
	exit.position = (exit_a + exit_b) / 2.0
	exit.rotation = (exit_b - exit_a).angle()
	ysorted.add_child(exit)

	# 玩家
	var player: Node2D = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.unique_name_in_owner = true
	player.position = floor_layer.map_to_local(SPAWN_CELL)
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

	# 回声管理(第一关:上限 1,docs/10 §3)
	var echo_mgr: Node = load("res://scripts/level/echo_manager.gd").new()
	echo_mgr.name = "EchoManager"
	echo_mgr.unique_name_in_owner = true
	echo_mgr.max_echoes = 1
	echo_mgr.debug_trajectory = true
	echo_mgr.ysorted_path = NodePath("../YSorted")
	level.add_child(echo_mgr)

	# UI(HUD/暂停/通关)
	var ui: CanvasLayer = (load("res://scenes/ui/UI.tscn") as PackedScene).instantiate()
	ui.name = "UI"
	ui.unique_name_in_owner = true
	level.add_child(ui)

	_assign_owner(level, level)
	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err != OK:
		push_error("pack failed: %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_01.tscn")
	print("Level_01.tscn saved, err=", err)
	quit()


func _make_wall(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.offset = Vector2(0, -24)  # 贴图上移用 offset,Y-sort 仍按格位(docs/03 §3.9)
	return sprite


## 只给无主(程序化创建)的节点设置 owner;子场景实例内部节点已有 owner(docs/03 §1)
func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child.owner == null:
			child.owner = owner
		_assign_owner(child, owner)


func _add_wall_colliders(level: Node2D, floor_layer: TileMapLayer, cells: Array[Vector2i]) -> void:
	var body := StaticBody2D.new()
	body.name = "WallColliders"
	body.collision_layer = 1
	body.collision_mask = 0
	level.add_child(body)
	for cell in cells:
		var shape := ConvexPolygonShape2D.new()
		shape.points = FOOTPRINT
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = floor_layer.map_to_local(cell)
		body.add_child(cs)

	# 房间四角凸角封堵:角顶点的 X 形楔形缝可沿内壁滑行绕出地图(devlog 2026-11-06)
	var used: Rect2i = floor_layer.get_used_rect()
	var c00: Vector2 = floor_layer.map_to_local(used.position)
	var c10: Vector2 = floor_layer.map_to_local(used.position + Vector2i(used.size.x - 1, 0))
	var c11: Vector2 = floor_layer.map_to_local(used.position + used.size - Vector2i(1, 1))
	var c01: Vector2 = floor_layer.map_to_local(used.position + Vector2i(0, used.size.y - 1))
	for v: Vector2 in [c00 + Vector2(0, -16), c10 + Vector2(32, 0), c11 + Vector2(0, 16), c01 + Vector2(-32, 0)]:
		_add_plug(body, v, 12.0)
	for x in range(used.position.x, used.end.x):
		_add_plug(body, floor_layer.map_to_local(Vector2i(x, used.position.y)) + Vector2(32, 0))
		_add_plug(body, floor_layer.map_to_local(Vector2i(x, used.end.y - 1)) + Vector2(-32, 0))
	for y in range(used.position.y, used.end.y):
		_add_plug(body, floor_layer.map_to_local(Vector2i(used.end.x - 1, y)) + Vector2(0, 16))
		_add_plug(body, floor_layer.map_to_local(Vector2i(used.position.x, y)) + Vector2(0, -16))


## 顶点/角部封堵塞(_add_wall_colliders 调用)
func _add_plug(body: StaticBody2D, pos: Vector2, radius := 10.0) -> void:
	var plug := CircleShape2D.new()
	plug.radius = radius
	var cs := CollisionShape2D.new()
	cs.shape = plug
	cs.position = pos
	body.add_child(cs)

func _camera_limits(floor_layer: TileMapLayer) -> Rect2i:
	var p_top := floor_layer.map_to_local(Vector2i(0, 0))
	var p_right := floor_layer.map_to_local(Vector2i(ROOM_W - 1, 0))
	var p_bottom := floor_layer.map_to_local(Vector2i(ROOM_W - 1, ROOM_H - 1))
	var p_left := floor_layer.map_to_local(Vector2i(0, ROOM_H - 1))
	var left := int(p_left.x) - 32
	var top := int(p_top.y) - 48
	return Rect2i(left, top, int(p_right.x) + 32 - left, int(p_bottom.y) + 16 - top)
