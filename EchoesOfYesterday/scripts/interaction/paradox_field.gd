class_name ParadoxField
extends Area2D
## 悖论区(L7,docs/18):时间异常的具象化——同一时刻只能有一个「你」。
## 玩家与回声同时在区内 → 区内全部回声消散(E-71);玩家无伤原地继续(温和失败)。
## 分组识别(player/echo 组),不判型(机关契约);消散执行归 EchoManager
## (关卡层接线 paradox_triggered → EchoManager.dissolve,机关只广播,docs/02 §7)。
## 回声彼此同场不触发(E-73:同为「过去」);布局约束:记录起点不在区内(R5)。
## 场景本身不含形状/贴花:由构建脚本 add_cell() 逐格注入(单实例承载整片场)。

signal paradox_triggered(echo: Node2D)  # 每个被判定消散的回声各发一次(一次可多个)
signal player_entered(body: Node2D)     # 玩家踏入(教学预警钩子 T-74;区内无回声则无事发生)

const FIELD_COLOR := Color(0.608, 0.42, 0.851, 0.34)  # 紫系覆格(#9B6BD9 族,与干扰场暗红区分)
const FLASH_COLOR := Color(0.95, 0.93, 1.0, 0.6)      # 触发瞬间区内闪白
const FLASH_TIME := 0.35

## 视觉:全格紫覆格(口径同干扰场——整格铺色明确「此处勿与回声同场」)
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])

var _players: Array[Node2D] = []
var _echoes: Array[Node2D] = []
var _visuals: Array[Polygon2D] = []
var _flash_left := 0.0


func _ready() -> void:
	add_to_group("mechanism")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 由构建脚本调用:一格悖论区(整格菱形判定 + 紫色覆格,纯渲染不走 Y-sort)
func add_cell(world_pos: Vector2) -> void:
	var shape := ConvexPolygonShape2D.new()
	shape.points = FOOTPRINT
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = world_pos
	add_child(cs)
	var poly := Polygon2D.new()
	poly.polygon = FOOTPRINT
	poly.position = world_pos
	poly.color = FIELD_COLOR
	add_child(poly)
	_visuals.append(poly)


func force_reset() -> void:
	## 关卡重置:清双清单与闪白(E-74);覆格恒在、无相位态
	_players.clear()
	_echoes.clear()
	_flash_left = 0.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_players.append(body)
		player_entered.emit(body)
	elif body.is_in_group("echo"):
		_echoes.append(body)
	_check_paradox()


func _on_body_exited(body: Node2D) -> void:
	_players.erase(body)
	_echoes.erase(body)


## 在场判定(E-71):玩家 ∧ 回声同时在区 → 区内全部回声消散(双向,先后无关)
func _check_paradox() -> void:
	if _players.is_empty() or _echoes.is_empty():
		return
	_flash_left = FLASH_TIME
	for echo in _echoes:
		paradox_triggered.emit(echo)
	_echoes.clear()  # 消散回声的 body_exited 延迟至释放,显式清单防悬引用


func _physics_process(delta: float) -> void:
	## 视觉脉动(纯表现,不影响判定);触发瞬间整片闪白(E-71)
	if _flash_left > 0.0:
		_flash_left -= delta
	for v in _visuals:
		if _flash_left > 0.0:
			v.color = FLASH_COLOR
		else:
			v.color = FIELD_COLOR
			v.color.a = 0.30 + 0.12 * sin(Time.get_ticks_msec() / 400.0)
