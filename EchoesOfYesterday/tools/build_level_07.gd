extends SceneTree
## 构建 Level_07.tscn(T7-A,docs/18 §3):18×12 相位回廊——相位门 ×3(南口双门 + 东室门,
## 核心 C1 统一驱动:断电 = 南落东封(初始),供电 = 南封东落,返修 3 交换)+ 悖论区 P1(主)/
## P2(教学凹室)+ 双开关 AND 门;回声上限 3。
## 密封要求:西储块/东块封死绕行,P1 横贯回廊为南北唯一通路(南口由双相位门把守,
## x10 列墙 y4..8 封死东缘侧绕——返修 3),y2 行除门格外全墙(出口行唯一入口 = 门)。
## 运行:godot --headless --path . -s tools/build_level_07.gd

const ROOM_W := 18
const ROOM_H := 12
const SPAWN_CELL := Vector2i(2, 9)
const DEVICE_CELL := Vector2i(3, 8)
const CORE_CELL := Vector2i(5, 9)
const GATE_EAST_CELL := Vector2i(12, 9)   # 东室南墙唯一入口(凹形口袋 (12,10) 是唯一接近格)
const GATE_S1_CELL := Vector2i(8, 8)      # 南口双相位门(回廊 2 宽 = 两个口,双门同时密封/落下)
const GATE_S2_CELL := Vector2i(9, 8)
const SWITCH1_CELL := Vector2i(15, 6)     # 东室西北角——遮挡锥全空(返修 2:(14,7) 被南墙立方体完全盖住)
const SWITCH2_CELL := Vector2i(8, 6)      # 主悖论区 P1 内部(谜题之眼,docs/18 §3)
const DOOR_CELL := Vector2i(8, 2)         # 门正对出口 (8,1);y2 行其余全墙封死侧向绕行
const EXIT_CELL := Vector2i(8, 1)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var level := Node2D.new()
	level.name = "Level_07"
	level.set_script(load("res://scripts/level/level_07_manager.gd"))
	level.next_scene = "res://scenes/levels/Level_08.tscn"  # 漏设 = 过关原地重玩(L4/L5 返修教训)

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

	# 悖论区 ×2(docs/18 §3):P2 教学凹室(主路径外)/ P1 主区(横贯回廊 6 格)
	# 注意:必须在 Decals **之前**加入——覆层是「地面着色」,开关底座/出生标记等
	# 贴花要画在其上(返修 2026-11-08:P1 内 S2 底座曾被紫覆层盖住看不见)
	var field_defs := {
		"FieldSandbox": [Vector2i(6, 8), Vector2i(7, 8)],
		"FieldMain": _rect_cells(Vector2i(8, 5), Vector2i(9, 7)),
	}
	for fname: String in field_defs:
		var field: Area2D = (load("res://scenes/mechanisms/ParadoxField.tscn") as PackedScene).instantiate()
		field.name = fname
		field.unique_name_in_owner = true
		level.add_child(field)
		for cell: Vector2i in field_defs[fname]:
			field.add_cell(floor_layer.map_to_local(cell))

	var decals := Node2D.new()
	decals.name = "Decals"
	level.add_child(decals)

	# 初始记录区(南区西段,docs/17 §5.1:记录只能在此开始;R5:悖论区不覆盖记录区)
	_add_record_zone(level, floor_layer, decals, Vector2i(1, 8), Vector2i(3, 10), SPAWN_CELL)

	# 墙体:周界完整(出口 (8,1) 为内部格,背后 y0 周界兜底)+ 内部密封块
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

	# 相位门 ×3(返修 2:南口双门 + 东室门;联动极性由 Level07Manager 统一驱动——
	# C1 供电 = 南口双门落下 + 东门密封,断电反之)
	for g in [["GateSouth1", GATE_S1_CELL], ["GateSouth2", GATE_S2_CELL], ["GateEast", GATE_EAST_CELL]]:
		var gate: StaticBody2D = (load("res://scenes/mechanisms/PhaseGate.tscn") as PackedScene).instantiate()
		gate.name = g[0]
		gate.unique_name_in_owner = true
		gate.position = floor_layer.map_to_local(g[1])
		ysorted.add_child(gate)

	# 压力开关 S1(东室内)/ S2(P1 内)+ 底座
	# 底座挂 YSorted(不再进 Decals):正确参与 Y-sort 遮挡——贴花层恒在墙体精灵之下,
	# 室内开关会被墙立方体完全盖住(返修 2:S1 (14,7) 不可见)
	var sw1: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw1.name = "Switch1"
	sw1.unique_name_in_owner = true
	sw1.position = floor_layer.map_to_local(SWITCH1_CELL)
	ysorted.add_child(sw1)
	var pad1 := _make_pad(floor_layer, SWITCH1_CELL, "Switch1Pad")
	ysorted.add_child(pad1)
	sw1.bind_pad(pad1)

	var sw2: Area2D = (load("res://scenes/mechanisms/PressureSwitch.tscn") as PackedScene).instantiate()
	sw2.name = "Switch2"
	sw2.unique_name_in_owner = true
	sw2.position = floor_layer.map_to_local(SWITCH2_CELL)
	ysorted.add_child(sw2)
	var pad2 := _make_pad(floor_layer, SWITCH2_CELL, "Switch2Pad")
	ysorted.add_child(pad2)
	sw2.bind_pad(pad2)

	# 能量核心 C1(持续型;初始 ON 由 Level07Manager 驱动,docs/18 §4)
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

	# 出口门(双灯:S1/S2)
	var door: StaticBody2D = (load("res://scenes/mechanisms/SecurityDoor.tscn") as PackedScene).instantiate()
	door.name = "SecurityDoor"
	door.unique_name_in_owner = true
	door.position = floor_layer.map_to_local(DOOR_CELL)
	ysorted.add_child(door)
	var door_pos := floor_layer.map_to_local(DOOR_CELL)
	for i in 2:
		var light := Sprite2D.new()
		light.name = ["Light1", "Light2"][i]
		light.unique_name_in_owner = true
		light.texture = load("res://assets/mechanisms/light_dot.png")
		light.position = door_pos + Vector2(-18 + 36 * i, -30)
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
	err = ResourceSaver.save(packed, "res://scenes/levels/Level_07.tscn")
	print("Level_07.tscn saved, err=", err)
	quit()


## 周界(完整)+ 密封块:西储 x1..7,y4..7 / 东块 x14..16,y1..5 / y4 行 x10..13 +
## x10 列 y5..8(回廊东墙,返修 3:缺此列则 (10,8)→(9,7) 绕过南口双门直穿悖论区)/
## y2 行(除门格)/ 东室墙(x11 y6..8 西墙、y5 x11..13 北墙、y9 x11..16 南墙——门洞 (12,9))
func _wall_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				cells.append(Vector2i(x, y))
	for x in range(1, 8):
		for y in range(4, 8):
			cells.append(Vector2i(x, y))
	for x in range(14, 17):
		for y in range(1, 6):
			cells.append(Vector2i(x, y))
	for x in range(10, 14):
		cells.append(Vector2i(x, 4))
	for y in range(5, 9):
		cells.append(Vector2i(10, y))
	for x in range(1, 14):
		if x != DOOR_CELL.x:
			cells.append(Vector2i(x, 2))
	for y in range(6, 9):
		cells.append(Vector2i(11, y))
	for x in range(11, 14):
		cells.append(Vector2i(x, 5))
	for x in range(11, 17):
		if x != GATE_EAST_CELL.x:
			cells.append(Vector2i(x, 9))
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
