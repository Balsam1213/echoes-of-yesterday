extends SceneTree
## 生成占位素材(T1.1,一次性工具)。
## 运行:godot --headless --path . -s tools/generate_placeholder_assets.gd
## 产出:assets/environment/(地板/墙/测试方块)、assets/characters/(玩家三帧)。
## 色彩规范见 docs/04 §2;素材规格见 docs/04 §3。生成后需执行一次 --import。

const FLOOR_BASE := Color("394b5d")   # 建筑结构:低饱和蓝灰
const FLOOR_EDGE := Color("4a5d70")   # 地板高光边
const PLAYER_BODY := Color("e5e7eb")  # 玩家角色:浅灰白
const PLAYER_DARK := Color("b9bdc4")  # 玩家暗部(腿/阴影)

func _initialize() -> void:
	_gen_floor_tile()
	_gen_iso_cube("wall_block.png", 40.0, Color("4a5d70"), Color("394b5d"), Color("2a3a49"))
	_gen_iso_cube("test_block.png", 28.0, Color("566b80"), Color("4a5d70"), Color("36485a"))
	_gen_switch_pad()
	_gen_iso_cube("door_block.png", 40.0, Color("3a546b"), Color("2f4457"), Color("22333f"))
	_gen_light_dot()
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

## 64×80 等距立方体(真 2.5D):顶面菱形 + 左右两个 2:1 斜面。
## 底面脚印菱形中心在 (32,64)——精灵按 centered 摆放时需上移 24px 使脚印对齐节点原点。
## h=立方体高度;左面受光、右面背光(光来自左上)。
func _gen_iso_cube(file_name: String, h: float, col_top: Color, col_l: Color, col_r: Color) -> void:
	var img := Image.create_empty(64, 80, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# 左面:x∈[0,32],上沿 (64-h)+0.5x,下沿 64+0.5x
	for y in 80:
		for x in range(0, 33):
			if y >= (64.0 - h) + 0.5 * x and y <= 64.0 + 0.5 * x:
				img.set_pixel(x, y, col_l)
	# 右面:x∈[32,64],上沿 (96-h)-0.5x,下沿 96-0.5x
	for y in 80:
		for x in range(32, 64):
			if y >= (96.0 - h) - 0.5 * x and y <= 96.0 - 0.5 * x:
				img.set_pixel(x, y, col_r)
	# 顶面:脚印菱形上移 h,外圈 1px 描边
	_fill_diamond(img, 32.0, 64.0 - h, 32.0, 16.0, col_top.lightened(0.25), 1.06)
	_fill_diamond(img, 32.0, 64.0 - h, 32.0, 16.0, col_top, 1.0)
	var dir := "res://assets/mechanisms/" if file_name == "door_block.png" else "res://assets/environment/"
	img.save_png(_path(dir + file_name))

## 64×32 压力开关底座:浅色菱形(供 modulate 染色:灰=关闭,黄=激活)+ 内环细节
func _gen_switch_pad() -> void:
	var img := Image.create_empty(64, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_diamond(img, 31.5, 15.5, 32.0, 16.0, Color("394b5d"), 1.06)  # 深色描边
	_fill_diamond(img, 31.5, 15.5, 32.0, 16.0, Color("e2e5ea"), 1.0)   # 浅色面(染色基底)
	_fill_diamond(img, 31.5, 15.5, 18.0, 9.0, Color("c3c7cd"), 1.0)    # 内环
	_fill_diamond(img, 31.5, 15.5, 8.0, 4.0, Color("aeb3ba"), 1.0)     # 中心
	img.save_png(_path("res://assets/mechanisms/switch_pad.png"))

## 6×6 白色圆点(指示灯,运行时 modulate 红/绿)
func _gen_light_dot() -> void:
	var img := Image.create_empty(6, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 6:
		for x in 6:
			var dx: float = x - 2.5
			var dy: float = y - 2.5
			if dx * dx + dy * dy <= 6.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	img.save_png(_path("res://assets/mechanisms/light_dot.png"))

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
