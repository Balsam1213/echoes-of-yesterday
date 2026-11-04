extends SceneTree
## 构建等距测试房间 dev_grid_test.tscn(T1.1)。
## 运行:godot --headless --path . -s tools/build_dev_room.gd
## 前置:占位素材已由 generate_placeholder_assets.gd 生成并导入;Player.tscn 已存在。
## 重新运行会覆盖 scenes/dev/dev_grid_test.tscn。
## 布局:12×8 等距格(64×32);地板用 TileMapLayer;周界墙与 Y-sort 验证方块用
## Sprite2D+StaticBody2D 占位(墙体贴图进 TileMapLayer 的锚点问题留待 T4.1 验证,见 devlog)。

const ROOM_W := 12
const ROOM_H := 8
## 立起物脚印菱形(与视觉底面完全一致);碰撞体必须用它,禁止小矩形近似
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])


func _initialize() -> void:
	_run()


func _run() -> void:
	var room := Node2D.new()
	room.name = "DevGridTest"

	# --- TileSet:等距 64×32,单格地板图集 ---
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN  # 经典菱形等距;引擎默认 STACKED 不是想要的布局
	tile_set.tile_size = Vector2i(64, 32)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://assets/environment/floor_tile.png")
	atlas.texture_region_size = Vector2i(64, 32)
	atlas.create_tile(Vector2i.ZERO)
	tile_set.add_source(atlas, 0)

	# --- 地板层(背景,不参与 Y-sort) ---
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tile_set
	for x in ROOM_W:
		for y in ROOM_H:
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	room.add_child(floor_layer)

	# --- 周界墙:视觉 + 脚印菱形碰撞(一圈菱形无缝密封房间) ---
	var perimeter: Array[Vector2i] = []
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				perimeter.append(Vector2i(x, y))
	_add_wall_colliders(room, floor_layer, perimeter)

	# --- 实体层(Y-sort 生效层) ---
	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	room.add_child(ysorted)

	for cell in perimeter:
		ysorted.add_child(_make_block("wall_block.png", floor_layer.map_to_local(cell), false))

	# Y-sort 验证方块(带底座碰撞,玩家可绕行前后)
	for cell in [Vector2i(3, 2), Vector2i(6, 4), Vector2i(9, 3)]:
		ysorted.add_child(_make_block("test_block.png", floor_layer.map_to_local(cell), true))

	# --- 玩家 ---
	# 注意:工具脚本(-s)编译期不得引用游戏类(autoload 编译期不可见),一律 load() + 动态访问(docs/03 §1)
	var player: Node2D = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = floor_layer.map_to_local(Vector2i(2, 6))
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

	# 回声管理(T3.4)
	var echo_mgr: Node = load("res://scripts/level/echo_manager.gd").new()
	echo_mgr.name = "EchoManager"
	echo_mgr.debug_trajectory = true
	echo_mgr.ysorted_path = NodePath("../YSorted")
	room.add_child(echo_mgr)

	var packed := PackedScene.new()
	_assign_owner(room, room)  # pack() 只包含 owner 指向根的节点,程序化节点必须显式归属
	var err := packed.pack(room)
	if err != OK:
		push_error("pack failed: %s" % err)
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/dev/dev_grid_test.tscn")
	print("dev_grid_test.tscn saved, err=", err)
	quit()


## 只给无主(程序化创建)的节点设置 owner;子场景实例的内部节点已有 owner,
## 若一并归属会导致 pack() 展开实例、产生静态影子副本(渲染与脚本节点并存)
func _assign_owner(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child.owner == null:
			child.owner = owner
		_assign_owner(child, owner)


## 在 body 下为每个格位加一个脚印菱形碰撞体(与视觉底面完全一致)
func _add_wall_colliders(room: Node2D, floor_layer: TileMapLayer, cells: Array[Vector2i]) -> void:
	var body := StaticBody2D.new()
	body.name = "WallColliders"
	body.collision_layer = 1
	body.collision_mask = 0
	room.add_child(body)
	for cell in cells:
		var shape := ConvexPolygonShape2D.new()
		shape.points = FOOTPRINT
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = floor_layer.map_to_local(cell)
		body.add_child(cs)


## 生成一个方块(64×64 贴图,底座菱形中心对齐 pos)
func _make_block(tex_name: String, pos: Vector2, with_collision: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/environment/" + tex_name)
	sprite.position = Vector2(0, -24)  # 64×80 立体贴图:脚印菱形中心 (32,64) 对齐节点原点
	body.add_child(sprite)
	if with_collision:
		var shape := ConvexPolygonShape2D.new()
		shape.points = FOOTPRINT  # 脚印菱形,与视觉底面一致
		var cs := CollisionShape2D.new()
		cs.shape = shape
		body.add_child(cs)
	return body


## 相机边界:地板菱形外沿 + 顶部墙体高度余量
func _camera_limits(floor_layer: TileMapLayer) -> Rect2i:
	var p_top := floor_layer.map_to_local(Vector2i(0, 0))
	var p_right := floor_layer.map_to_local(Vector2i(ROOM_W - 1, 0))
	var p_bottom := floor_layer.map_to_local(Vector2i(ROOM_W - 1, ROOM_H - 1))
	var p_left := floor_layer.map_to_local(Vector2i(0, ROOM_H - 1))
	var left := int(p_left.x) - 32
	var top := int(p_top.y) - 48
	return Rect2i(left, top, int(p_right.x) + 32 - left, int(p_bottom.y) + 16 - top)
