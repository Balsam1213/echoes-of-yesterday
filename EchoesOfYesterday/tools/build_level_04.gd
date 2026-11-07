extends SceneTree
## 构建 Level_04.tscn(T4-A,docs/14 §3):16×12;干扰带 F1 + U 形 F2;脉冲板同振 + 三灯 AND 门;回声上限 3。
## 运行:godot --headless --path . -s tools/build_level_04.gd

const ROOM_W := 16
const ROOM_H := 12
const SPAWN_CELL := Vector2i(2, 10)
const DEVICE_CELL := Vector2i(3, 8)
const SWITCH_A_CELL := Vector2i(3, 2)
const PAD_B_CELL := Vector2i(10, 7)
const PAD_P_CELL := Vector2i(13, 2)
const DOOR_CELL := Vector2i(13, 1)
const EXIT_CELL := Vector2i(13, 0)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_04"
	level.set_script(load("res://scripts/level/level_04_manager.gd"))
	level.next_scene = "res://scenes/levels/Level_05.tscn"

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

	# 地面贴花层(平底物件:开关/脉冲板底座,恒在角色之下)
	var decals := Node2D.new()
	decals.name = "Decals"
	level.add_child(decals)

	# 初始记录区(西南角,docs/13 §5.1:记录只能在此开始)
	_add_record_zone(level, floor_layer, decals, Vector2i(0, 9), Vector2i(3, 11), SPAWN_CELL)

	# 干扰场(恒定危害区;置于 Decals 之后、YSorted 之前:覆格在角色之下)
	var field_main: Area2D = (load("res://scenes/mechanisms/InterferenceField.tscn") as PackedScene).instantiate()
	field_main.name = "FieldMain"
	field_main.unique_name_in_owner = true
	level.add_child(field_main)
	for x in 12:
		field_main.add_cell(floor_layer.map_to_local(Vector2i(x, 5)))  # F1:x0..11,y5

	var field_u: Area2D = (load("res://scenes/mechanisms/InterferenceField.tscn") as PackedScene).instantiate()
	field_u.name = "FieldU"
	field_u.unique_name_in_owner = true
	level.add_child(field_u)
	for cell: Vector2i in [Vector2i(9, 6), Vector2i(10, 6), Vector2i(11, 6), Vector2i(9, 7), Vector2i(11, 7), Vector2i(9, 8), Vector2i(11, 8)]:
		field_u.add_cell(floor_layer.map_to_local(cell))  # F2:U 形围 B,南口 (10,8)

	# 墙体:周界(北缘扣除出口格)+ 出口背后虚拟格(本关无内墙,区域由干扰场划分)
	var wall_cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				if Vector2i(x, 0) == EXIT_CELL:
					continue
				wall_cells.append(Vector2i(x, y))
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

	# 压力开关 A + 底座贴花
	var sw_a: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw_a.name = "SwitchA"
	sw_a.unique_name_in_owner = true
	sw_a.position = floor_layer.map_to_local(SWITCH_A_CELL)
	ysorted.add_child(sw_a)
	ysorted.get_parent().get_node("Decals").add_child(_make_pad(floor_layer, SWITCH_A_CELL, "SwitchAPad"))
	sw_a.bind_pad(ysorted.get_parent().get_node("Decals/SwitchAPad"))

	# 脉冲板 B / P + 底座贴花
	var pad_b: Area2D = (load("res://scenes/mechanisms/PulsePad.tscn") as PackedScene).instantiate()
	pad_b.name = "PadB"
	pad_b.unique_name_in_owner = true
	pad_b.position = floor_layer.map_to_local(PAD_B_CELL)
	ysorted.add_child(pad_b)
	ysorted.get_parent().get_node("Decals").add_child(_make_pad(floor_layer, PAD_B_CELL, "PadBPad"))
	pad_b.bind_pad(ysorted.get_parent().get_node("Decals/PadBPad"))

	var pad_p: Area2D = (load("res://scenes/mechanisms/PulsePad.tscn") as PackedScene).instantiate()
	pad_p.name = "PadP"
	pad_p.unique_name_in_owner = true
	pad_p.position = floor_layer.map_to_local(PAD_P_CELL)
	ysorted.add_child(pad_p)
	ysorted.get_parent().get_node("Decals").add_child(_make_pad(floor_layer, PAD_P_CELL, "PadPPad"))
	pad_p.bind_pad(ysorted.get_parent().get_node("Decals/PadPPad"))

	# 时间记录装置(复用)
	var device: Area2D = (load("res://scenes/mechanisms/TimeRecorderDevice.tscn") as PackedScene).instantiate()
	device.name = "TimeRecorderDevice"
	device.unique_name_in_owner = true
	device.position = floor_layer.map_to_local(DEVICE_CELL)
	ysorted.add_child(device)

	# 出口门(三灯:A/B/P,关卡层驱动)
	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)
	var door_pos := floor_layer.map_to_local(DOOR_CELL)
	for i in 3:
		var light := Sprite2D.new()
		light.name = ["LightA", "LightB", "LightP"][i]
		light.unique_name_in_owner = true
		light.texture = load("res://assets/mechanisms/light_dot.png")
		light.position = door_pos + Vector2(-36 + 36 * i, -30)
		ysorted.add_child(light)

	# 出口触发区(手搭:单格 44×20,防泄漏邻格;实例内部子节点的修改 pack() 不记录)
	var exit := Area2D.new()
	exit.name = "ExitArea"
	exit.unique_name_in_owner = true
	exit.collision_layer = 8
	exit.collision_mask = 2
	exit.set_script(load("res://scripts/interaction/exit_area.gd"))
	var exit_zone := RectangleShape2D.new()
	exit_zone.size = Vector2(44, 20)
	var exit_cs := CollisionShape2D.new()
	exit_cs.name = "Zone"
	exit_cs.shape = exit_zone
	exit.add_child(exit_cs)
	exit.position = floor_layer.map_to_local(EXIT_CELL)
	ysorted.add_child(exit)

	# 玩家
	var player: Node2D = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.unique_name_in_owner = true
	player.position = floor_layer.map_to_local(SPAWN_CELL)
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

	# 回声管理(上限 3)
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
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_04.tscn")
	print("Level_04.tscn saved, err=", err)
	quit()


## 初始记录区:覆盖格位矩形 [from..to] 的世界包围盒(含各格菱形外沿)+ 淡青底纹 + 出生点标记
func _add_record_zone(level: Node2D, floor_layer: TileMapLayer, decals: Node2D, from: Vector2i, to: Vector2i, spawn_cell: Vector2i) -> void:
	var zone: Area2D = (load("res://scenes/mechanisms/RecordingZone.tscn") as PackedScene).instantiate()
	zone.name = "RecordingZone"
	zone.unique_name_in_owner = true
	var min_cx := (minf(from.x, to.x) - maxf(from.y, to.y)) * 32 + 32
	var max_cx := (maxf(from.x, to.x) - minf(from.y, to.y)) * 32 + 32
	var min_cy := (minf(from.x, to.x) + minf(from.y, to.y)) * 16 + 16
	var max_cy := (maxf(from.x, to.x) + maxf(from.y, to.y)) * 16 + 16
	var center := Vector2((min_cx + max_cx) / 2.0, (min_cy + max_cy) / 2.0)
	var size := Vector2(max_cx - min_cx + 64, max_cy - min_cy + 32)
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	zone.add_child(cs)
	zone.position = center
	zone.setup_visual(center, size)
	level.add_child(zone)
	# 出生点标记:淡青圆点贴花,方便玩家辨认记录起点(用户验收)
	var marker := Sprite2D.new()
	marker.name = "SpawnMarker"
	marker.texture = load("res://assets/mechanisms/light_dot.png")
	marker.scale = Vector2(3, 3)
	marker.modulate = Color(0.271, 0.851, 0.949, 0.6)
	marker.position = floor_layer.map_to_local(spawn_cell)
	decals.add_child(marker)


func _make_pad(floor_layer: TileMapLayer, cell: Vector2i, pad_name: String) -> Sprite2D:
	var pad := Sprite2D.new()
	pad.name = pad_name
	pad.texture = load("res://assets/mechanisms/switch_pad.png")
	pad.position = floor_layer.map_to_local(cell)
	return pad


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
