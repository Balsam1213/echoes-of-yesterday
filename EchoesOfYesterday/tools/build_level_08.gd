extends SceneTree
## 构建 Level_08.tscn(T8-A,docs/19 §3):18×14 昨日回声——悖论之海 P1(36 格,C1 在海心)
## + 供电相位门 G1(核心 C1 断电窗)+ 时间锁 + 三重条件门;回声上限 3;章末关(next_scene 空)。
## 密封要求:海东西两侧 x5/x12 列封直通,西窄道为侦察支路;舱西墙仅 G1 一口;
## 出口行 (15,1) 两侧封死(唯一入口 = D2,门位铁律)。
## 运行:godot --headless --path . -s tools/build_level_08.gd

const ROOM_W := 18
const ROOM_H := 14
const SPAWN_CELL := Vector2i(2, 11)
const DEVICE_CELL := Vector2i(3, 10)
const CORE_CELL := Vector2i(7, 4)       # 悖论之海内部北半——拨核必须进区(E 交互四邻全在区内)
const GATE_CELL := Vector2i(13, 2)      # 核心舱西墙唯一入口
const SWITCH1_CELL := Vector2i(12, 1)   # 北横廊东端(回声 A parks,舱外)
const SWITCH2_CELL := Vector2i(6, 1)    # 北横廊西端(回声 B parks)
const LOCK_CELL := Vector2i(9, 2)       # 北横廊中段(冲刺顺路触发)
const DOOR_CELL := Vector2i(15, 2)      # 门正对出口 (15,1);出口行两侧 (14,1)(16,1) 封死
const EXIT_CELL := Vector2i(15, 1)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_08"
	level.set_script(load("res://scripts/level/level_08_manager.gd"))

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

	# 悖论之海 P1(docs/19 §3):x6..11, y3..8(36 格,单实例承载)
	# 注意:必须在 Decals **之前**加入——覆层是「地面着色」,贴花画在其上(返修 2026-11-08,同 L7)
	var field: Area2D = (load("res://scenes/mechanisms/ParadoxField.tscn") as PackedScene).instantiate()
	field.name = "FieldSea"
	field.unique_name_in_owner = true
	level.add_child(field)
	for cell: Vector2i in _rect_cells(Vector2i(6, 3), Vector2i(11, 8)):
		field.add_cell(floor_layer.map_to_local(cell))

	var decals := Node2D.new()
	decals.name = "Decals"
	level.add_child(decals)

	# 初始记录区(西南角,docs/17 §5.1;核心舱在东北——回声从记录区出发走全程,R3)
	_add_record_zone(level, floor_layer, decals, Vector2i(1, 9), Vector2i(5, 12), SPAWN_CELL)

	# 墙体:周界完整(出口 (15,1) 为内部格,背后 y0 周界兜底)+ 内部密封块
	var wall_cells := _wall_cells()
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
			if wall_cells_set.has(Vector2i(x, y)):
				ysorted.add_child(_make_wall(wall_tex, floor_layer.map_to_local(Vector2i(x, y))))

	# 相位门 G1(舱西口;联动 + 断电计时归 Level08Manager,docs/19 §4)
	var gate: StaticBody2D = (load("res://scenes/mechanisms/PhaseGate.tscn") as PackedScene).instantiate()
	gate.name = "PhaseGate"
	gate.unique_name_in_owner = true
	gate.position = floor_layer.map_to_local(GATE_CELL)
	ysorted.add_child(gate)

	# 压力开关 S1 / S2 + 底座贴花
	var sw1: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw1.name = "Switch1"
	sw1.unique_name_in_owner = true
	sw1.position = floor_layer.map_to_local(SWITCH1_CELL)
	ysorted.add_child(sw1)
	decals.add_child(_make_pad(floor_layer, SWITCH1_CELL, "Switch1Pad"))
	sw1.bind_pad(decals.get_node("Switch1Pad"))

	var sw2: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw2.name = "Switch2"
	sw2.unique_name_in_owner = true
	sw2.position = floor_layer.map_to_local(SWITCH2_CELL)
	ysorted.add_child(sw2)
	decals.add_child(_make_pad(floor_layer, SWITCH2_CELL, "Switch2Pad"))
	sw2.bind_pad(decals.get_node("Switch2Pad"))

	# 时间锁(自由武装由 Level08Manager 驱动;靠近文案覆写 T-61)
	var lock: Area2D = (load("res://scenes/mechanisms/TimeLockSwitch.tscn") as PackedScene).instantiate()
	lock.name = "TimeLock"
	lock.unique_name_in_owner = true
	lock.position = floor_layer.map_to_local(LOCK_CELL)
	ysorted.add_child(lock)
	decals.add_child(_make_pad(floor_layer, LOCK_CELL, "TimeLockPad"))
	lock.bind_pad(decals.get_node("TimeLockPad"))

	# 能量核心 C1(持续型 toggle;断电计时归关卡层,docs/19 §4)
	var core: Area2D = (load("res://scenes/mechanisms/EnergyCore.tscn") as PackedScene).instantiate()
	core.name = "Core"
	core.unique_name_in_owner = true
	core.position = floor_layer.map_to_local(CORE_CELL)
	ysorted.add_child(core)

	# 时间记录装置(复用)
	var device: Area2D = (load("res://scenes/mechanisms/TimeRecorderDevice.tscn") as PackedScene).instantiate()
	device.name = "TimeRecorderDevice"
	device.unique_name_in_owner = true
	device.position = floor_layer.map_to_local(DEVICE_CELL)
	ysorted.add_child(device)

	# 出口门(三灯:S1/S2/时间锁)
	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)
	var door_pos := floor_layer.map_to_local(DOOR_CELL)
	for i in 3:
		var light := Sprite2D.new()
		light.name = ["Light1", "Light2", "Light3"][i]
		light.unique_name_in_owner = true
		light.texture = load("res://assets/mechanisms/light_dot.png")
		light.position = door_pos + Vector2(-36 + 36 * i, -30)
		ysorted.add_child(light)

	# 出口触发区(手搭:单格 44×20,防泄漏邻格;不改 ExitArea.tscn 实例)
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
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_08.tscn")
	print("Level_08.tscn saved, err=", err)
	quit()


## 周界(完整)+ 密封块:西北 x1..3,y1..2 / x5 列 y3..8 / x12 列 y3..8(海东西封直通)/
## 东南块 x13..16, y4..8 / 舱西墙 ((13,1)(13,3),G1 居 (13,2)) / 出口行两侧 ((14,1)(16,1))
func _wall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				cells.append(Vector2i(x, y))
	for x in range(1, 4):
		for y in range(1, 3):
			cells.append(Vector2i(x, y))
	for y in range(3, 9):
		cells.append(Vector2i(5, y))
		cells.append(Vector2i(12, y))
	for x in range(13, 17):
		for y in range(4, 9):
			cells.append(Vector2i(x, y))
	cells.append(Vector2i(13, 1))
	cells.append(Vector2i(13, 3))
	cells.append(Vector2i(14, 1))
	cells.append(Vector2i(16, 1))
	return cells


func _rect_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(from.x, to.x + 1):
		for y in range(from.y, to.y + 1):
			cells.append(Vector2i(x, y))
	return cells


## 初始记录区:覆盖格位矩形 [from..to] 的世界包围盒 + 出生点标记(z_index 置顶防墙体遮挡)
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
	level.add_child(zone)
	var marker := Sprite2D.new()
	marker.name = "SpawnMarker"
	marker.texture = load("res://assets/mechanisms/light_dot.png")
	marker.scale = Vector2(3, 3)
	marker.modulate = Color(0.271, 0.851, 0.949, 0.6)
	marker.z_index = 1
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

	# 房间四角凸角封堵 + 边缘中点 plug(devlog 2026-11-06 同款)
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
