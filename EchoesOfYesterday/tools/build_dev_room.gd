extends SceneTree
## 构建等距测试房间 dev_grid_test.tscn(T1.1)。
## 运行:godot --headless --path . -s tools/build_dev_room.gd
## 前置:占位素材已由 generate_placeholder_assets.gd 生成并导入;Player.tscn 已存在。
## 重新运行会覆盖 scenes/dev/dev_grid_test.tscn。
## 布局:12×8 等距格(64×32);地板用 TileMapLayer;周界墙与 Y-sort 验证方块用
## Sprite2D+StaticBody2D 占位(墙体贴图进 TileMapLayer 的锚点问题留待 T4.1 验证,见 devlog)。

const ROOM_W := 12
const ROOM_H := 8


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

	# --- 边界碰撞:沿房间菱形四条边的静态墙体(world 层) ---
	_add_boundary(room, floor_layer)

	# --- 实体层(Y-sort 生效层) ---
	var ysorted := Node2D.new()
	ysorted.name = "YSorted"
	ysorted.y_sort_enabled = true
	room.add_child(ysorted)

	# 周界墙占位视觉(仅外观,碰撞由 Boundary 承担)
	for x in ROOM_W:
		for y in ROOM_H:
			if x == 0 or y == 0 or x == ROOM_W - 1 or y == ROOM_H - 1:
				ysorted.add_child(_make_block("wall_block.png", floor_layer.map_to_local(Vector2i(x, y)), false))

	# Y-sort 验证方块(带底座碰撞,玩家可绕行前后)
	for cell in [Vector2i(3, 2), Vector2i(6, 4), Vector2i(9, 3)]:
		ysorted.add_child(_make_block("test_block.png", floor_layer.map_to_local(cell), true))

	# --- 玩家 ---
	var player: PlayerController = (load("res://scenes/player/Player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = floor_layer.map_to_local(Vector2i(2, 6))
	player.camera_limit_rect = _camera_limits(floor_layer)
	ysorted.add_child(player)

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


## 递归设置 owner,使子树全部归属场景根(否则 pack() 会丢弃)
func _assign_owner(node: Node, owner: Node) -> void:
	node.owner = owner
	for child in node.get_children():
		_assign_owner(child, owner)


## 房间四个角格中心 → 外沿顶点 → 四条边各生成一个旋转矩形碰撞体
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
		cs.position = (a + b) / 2.0 + normal * 7.0  # 向房间内侧推半厚度,外沿贴齐菱形边
		cs.rotation = dir.angle()
		body.add_child(cs)


## 生成一个方块(64×64 贴图,底座菱形中心对齐 pos)
func _make_block(tex_name: String, pos: Vector2, with_collision: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/environment/" + tex_name)
	body.add_child(sprite)
	if with_collision:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(48.0, 14.0)  # 覆盖底座菱形
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
