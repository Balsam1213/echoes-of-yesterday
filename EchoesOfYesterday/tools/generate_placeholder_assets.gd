extends SceneTree
## 生成占位素材(T1.1,一次性工具)。
## 运行:godot --headless --path . -s tools/generate_placeholder_assets.gd
## 产出:assets/environment/(地板/墙/测试方块)、assets/characters/(玩家三帧)。
## 色彩规范见 docs/04 §2;素材规格见 docs/04 §3。生成后需执行一次 --import。

const FLOOR_BASE := Color("394b5d")   # 建筑结构:低饱和蓝灰
const FLOOR_EDGE := Color("4a5d70")   # 地板高光边
const WALL_FACE := Color("394b5d")
const WALL_TOP := Color("46596d")
const PLAYER_BODY := Color("e5e7eb")  # 玩家角色:浅灰白
const PLAYER_DARK := Color("b9bdc4")  # 玩家暗部(腿/阴影)

func _initialize() -> void:
	_gen_floor_tile()
	_gen_wall_block()
	_gen_test_block()
	_gen_player("player_idle.png", 0)
	_gen_player("player_walk_0.png", 1)
	_gen_player("player_walk_1.png", 2)
	print("placeholder assets generated")
	quit()

func _path(res_path: String) -> String:
	return ProjectSettings.globalize_path(res_path)

## 在矩形区域内填充(闭区间)
func _fill_rect(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			img.set_pixel(x, y, color)

## 填充以 (cx, cy) 为中心的等距菱形(半宽 hw、半高 hh),scale 用于边缘圈
func _fill_diamond(img: Image, cx: float, cy: float, hw: float, hh: float, color: Color, scale: float = 1.0) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var d: float = absf(x - cx) / hw + absf(y - cy) / hh
			if d <= scale:
				img.set_pixel(x, y, color)

## 64×32 等距地板砖:蓝灰菱形 + 1px 高光边
func _gen_floor_tile() -> void:
	var img := Image.create_empty(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_diamond(img, 31.5, 15.5, 32.0, 16.0, FLOOR_EDGE, 1.06)
	_fill_diamond(img, 31.5, 15.5, 32.0, 16.0, FLOOR_BASE, 1.0)
	img.save_png(_path("res://assets/environment/floor_tile.png"))

## 64×64 墙体方块:底座菱形(下半 32px)+ 立面(上半 32px)
func _gen_wall_block() -> void:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 立面:左右各留 2px
	_fill_rect(img, 2, 2, 61, 33, WALL_FACE)
	_fill_rect(img, 2, 2, 61, 3, WALL_TOP)   # 顶部高光
	_fill_rect(img, 2, 2, 3, 33, WALL_TOP)   # 左棱高光
	_fill_rect(img, 60, 2, 61, 33, PLAYER_DARK)  # 右棱暗部
	# 底座菱形(中心 31.5, 31.5)
	_fill_diamond(img, 31.5, 31.5, 32.0, 16.0, FLOOR_EDGE, 1.06)
	_fill_diamond(img, 31.5, 31.5, 32.0, 16.0, WALL_FACE, 1.0)
	img.save_png(_path("res://assets/environment/wall_block.png"))

## 64×64 测试方块(比墙体亮一档,便于区分)
func _gen_test_block() -> void:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_rect(img, 2, 2, 61, 33, Color("4a5d70"))
	_fill_rect(img, 2, 2, 61, 3, Color("566b80"))
	_fill_rect(img, 2, 2, 3, 33, Color("566b80"))
	_fill_rect(img, 60, 2, 61, 33, PLAYER_DARK)
	_fill_diamond(img, 31.5, 31.5, 32.0, 16.0, FLOOR_EDGE, 1.06)
	_fill_diamond(img, 31.5, 31.5, 32.0, 16.0, Color("4a5d70"), 1.0)
	img.save_png(_path("res://assets/environment/test_block.png"))

## 32×48 玩家占位(脚底在帧底部):frame 0=静止,1/2=行走两帧
func _gen_player(file_name: String, frame: int) -> void:
	var img := Image.create_empty(32, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 头(椭圆)
	for y in range(3, 13):
		for x in range(10, 22):
			var dx: float = (x - 15.5) / 5.5
			var dy: float = (y - 7.5) / 4.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, PLAYER_BODY)
	# 躯干
	_fill_rect(img, 10, 13, 21, 29, PLAYER_BODY)
	_fill_rect(img, 10, 27, 21, 29, PLAYER_DARK)  # 躯干底部阴影
	# 腿:静止两腿等长;行走两帧交替抬腿
	var left_len := 14
	var right_len := 14
	if frame == 1:
		right_len = 10
	elif frame == 2:
		left_len = 10
	_fill_rect(img, 11, 30, 14, 30 + left_len, PLAYER_DARK)
	_fill_rect(img, 17, 30, 20, 30 + right_len, PLAYER_DARK)
	img.save_png(_path("res://assets/characters/" + file_name))
