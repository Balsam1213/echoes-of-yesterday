extends SceneTree
## 构建 Level_03.tscn(T-E,docs/12 §3):14×10;三翼三路线;时间锁 + 三灯 AND 门;回声上限 3。
## 运行:godot --headless --path . -s tools/build_level_03.gd

const ROOM_W := 14
const ROOM_H := 10
const DOOR_CELL := Vector2i(7, 1)
const SWITCH_A_CELL := Vector2i(2, 6)
const SWITCH_B_CELL := Vector2i(11, 4)
const LOCK_CELL := Vector2i(6, 3)
const SPAWN_CELL := Vector2i(7, 8)
const EXIT_CELL := Vector2i(7, 0)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_03"
	level.set_script(load("res://scripts/level/level_03_manager.gd"))

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

	# 墙体:周界(北缘扣除出口格)+ 门侧翼 + 路线造型短墙 + 出口背后虚拟格
	var wall_cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) == EXIT_CELL:
					continue
				wall_cells.append(Vector2i(x, y))
	for cell: Vector2i in [Vector2i(6, 1), Vector2i(8, 1), Vector2i(9, 5), Vector2i(9, 6), Vector2i(5, 4)]:
		wall_cells.append(cell)
	for dx in [-1, 0, 1]:
		wall_cells.append(EXIT_CELL + Vector2i(dx, -1))
	_add_wall_colliders(level, floor_layer, wall_cells)

	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	level.add_child(ysorted)

	var wall_tex: Texture2D = load("res://assets/environment/wall_block.png")
	var wall_cells_set := {}
	for cell in wall_cells:
		wall_cells_set[cell] = true
	for x in ROOM_W:
		for y in ROOM_H:
			var c := Vector2i(x, y)
			if wall_cells_set.has(c) and not (y == -1):
				ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(c)))

	# 机关:双压力开关 + 时间锁 + 安全门(三灯);底座贴花入地面层
	var sw_a: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw_a.name = "SwitchA"
	sw_a.unique_name_in_owner = true
	sw_a.position = floor_layer.map_to_local(SWITCH_A_CELL)
	ysorted.add_child(sw_a)

	var sw_a_pad := Sprite2D.new()
	sw_a_pad.name = "SwitchAPad"
	sw_a_pad.texture = load("res://assets/mechanisms/switch_pad.png")
	sw_a_pad.position = floor_layer.map_to_local(SWITCH_A_CELL)
	decals.add_child(sw_a_pad)
	sw_a.bind_pad(sw_a_pad)

	var sw_b: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw_b.name = "SwitchB"
	sw_b.unique_name_in_owner = true
	sw_b.position = floor_layer.map_to_local(SWITCH_B_CELL)
	ysorted.add_child(sw_b)

	var sw_b_pad := Sprite2D.new()
	sw_b_pad.name = "SwitchBPad"
	sw_b_pad.texture = load("res://assets/mechanisms/switch_pad.png")
	sw_b_pad.position = floor_layer.map_to_local(SWITCH_B_CELL)
	decals.add_child(sw_b_pad)
	sw_b.bind_pad(sw_b_pad)

	var lock: Area2D = (load("res://scenes/mechanisms/TimeLockSwitch.tscn") as PackedScene).instantiate()
	lock.name = "TimeLock"
	lock.unique_name_in_owner = true
	lock.position = floor_layer.map_to_local(LOCK_CELL)
	ysorted.add_child(lock)

	var lock_pad := Sprite2D.new()
	lock_pad.name = "TimeLockPad"
	lock_pad.texture = load("res://assets/mechanisms/switch_pad.png")
	lock_pad.position = floor_layer.map_to_local(LOCK_CELL)
	decals.add_child(lock_pad)
	lock.bind_pad(lock_pad)

	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)

	# 三指示灯(关卡层驱动)
	var door_pos := floor_layer.map_to_local(DOOR_CELL)
	for i in 3:
		var light := Sprite2D.new()
		light.name = ["LightA", "LightB", "LightC"][i]
		light.unique_name_in_owner = true
		light.texture = load("res://assets/mechanisms/light_dot.png")
		light.position = door_pos + Vector2(-36 + 36 * i, -30)
		ysorted.add_child(light)

	# 出口触发区
	var exit: Area2D = (load("res://scenes/mechanisms/ExitArea.tscn") as PackedScene).instantiate()
	exit.name = "ExitArea"
	exit.unique_name_in_owner = true
	exit.position = floor_layer.map_to_local(EXIT_CELL)
	ysorted.add_child(exit)

	# 玩家
	var player: Node2D = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.unique_name_in_owner = true
	player.position = floor_layer.map_to_local(SPAWN_CELL)
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

	# 回声管理(第三关:上限 3)
	var echo_mgr: Node = load("res://scripts/level/echo_manager.gd").new()
	echo_mgr.name = "EchoManager"
	echo_mgr.unique_name_in_owner = true
	echo_mgr.max_echoes = 3
	echo_mgr.debug_trajectory = true
	echo_mgr.ysorted_path = NodePath("../YSorted")
	level.add_child(echo_mgr)

	# UI
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
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_03.tscn")
	print("Level_03.tscn saved, err=", err)
	quit()


func _make_wall(tex: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.offset = Vector2(0, -24)
	return sprite


## 只给无主节点设置 owner(docs/03 §1:防影子副本)
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
func _add_plug(body: StaticBody2D, pos: Vector2, radius := 14.0) -> void:
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
