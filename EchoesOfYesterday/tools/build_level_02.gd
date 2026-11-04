extends SceneTree
## 构建 Level_02.tscn(T-D,docs/11 §3):12×8;双开关 AND 门;回声上限 2。
## 运行:godot --headless --path . -s tools/build_level_02.gd

const ROOM_W := 12
const ROOM_H := 8
const DOOR_CELL := Vector2i(6, 2)
const SWITCH_A_CELL := Vector2i(4, 4)
const SWITCH_B_CELL := Vector2i(8, 4)
const DEVICE_CELL := Vector2i(2, 5)
const SPAWN_CELL := Vector2i(2, 6)
const EXIT_CELL := Vector2i(6, 0)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_02"
	level.set_script(load("res://scripts/level/level_02_manager.gd"))
	level.next_scene = "res://scenes/levels/Level_03.tscn"  # 通关推进链(docs/10 §4)

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

	# 墙体碰撞:周界(北缘扣除出口格)+ 横墙(门洞除外)+ 出口背后虚拟格
	var wall_cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) == EXIT_CELL:
					continue
				wall_cells.append(Vector2i(x, y))
	for x in range(1, ROOM_W - 1):
		if Vector2i(x, 2) != DOOR_CELL:
			wall_cells.append(Vector2i(x, 2))
	wall_cells.append(EXIT_CELL + Vector2i(0, -1))
	_add_wall_colliders(level, floor_layer, wall_cells)

	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	level.add_child(ysorted)

	var wall_tex: Texture2D = load("res://assets/environment/wall_block.png")
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) == EXIT_CELL:
					continue
				ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, y))))
	for x in range(1, ROOM_W - 1):
		if Vector2i(x, 2) != DOOR_CELL:
			ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, 2))))

	# 机关:双开关 + 安全门 + 装置
	var sw_a: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw_a.name = "SwitchA"
	sw_a.unique_name_in_owner = true
	sw_a.position = floor_layer.map_to_local(SWITCH_A_CELL)
	ysorted.add_child(sw_a)

	var sw_b: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw_b.name = "SwitchB"
	sw_b.unique_name_in_owner = true
	sw_b.position = floor_layer.map_to_local(SWITCH_B_CELL)
	ysorted.add_child(sw_b)

	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)

	var device: Area2D = (load("res://scenes/mechanisms/TimeRecorderDevice.tscn") as PackedScene).instantiate()
	device.name = "TimeRecorderDevice"
	device.unique_name_in_owner = true
	device.position = floor_layer.map_to_local(DEVICE_CELL)
	ysorted.add_child(device)

	# 门体双指示灯(关卡层驱动,docs/11 §4)
	var door_pos := floor_layer.map_to_local(DOOR_CELL)
	var light_a := Sprite2D.new()
	light_a.name = "LightA"
	light_a.unique_name_in_owner = true
	light_a.texture = load("res://assets/mechanisms/light_dot.png")
	light_a.position = door_pos + Vector2(-34, -30)
	ysorted.add_child(light_a)
	var light_b := Sprite2D.new()
	light_b.name = "LightB"
	light_b.unique_name_in_owner = true
	light_b.texture = load("res://assets/mechanisms/light_dot.png")
	light_b.position = door_pos + Vector2(34, -30)
	ysorted.add_child(light_b)

	# 出口触发区(单格)
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

	# 回声管理(第二关:上限 2)
	var echo_mgr: Node = load("res://scripts/level/echo_manager.gd").new()
	echo_mgr.name = "EchoManager"
	echo_mgr.unique_name_in_owner = true
	echo_mgr.max_echoes = 2
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
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_02.tscn")
	print("Level_02.tscn saved, err=", err)
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


func _camera_limits(floor_layer: TileMapLayer) -> Rect2i:
	var p_top := floor_layer.map_to_local(Vector2i(0, 0))
	var p_right := floor_layer.map_to_local(Vector2i(ROOM_W - 1, 0))
	var p_bottom := floor_layer.map_to_local(Vector2i(ROOM_W - 1, ROOM_H - 1))
	var p_left := floor_layer.map_to_local(Vector2i(0, ROOM_H - 1))
	var left := int(p_left.x) - 32
	var top := int(p_top.y) - 48
	return Rect2i(left, top, int(p_right.x) + 32 - left, int(p_bottom.y) + 16 - top)
