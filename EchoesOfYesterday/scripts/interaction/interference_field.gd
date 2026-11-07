class_name InterferenceField
extends Area2D
## 时间干扰装置(L4,docs/14):恒定危害区,回声进入当帧消散(E-41)。
## 只作用于 echo 组(碰撞掩码仅 echo 层,E-45);玩家与机关实体不受影响。
## 消散执行归 EchoManager(关卡层接线 echo_dissolved → EchoManager.dissolve),
## 机关不直接 free 回声,避免破坏管理器清单(docs/02 §7:机关只广播,处理归关卡层)。
## 场景本身不含形状/贴花:由构建脚本 add_cell() 逐格注入(单实例承载整片场)。

signal echo_dissolved(echo: Node2D)
signal player_entered(body: Node2D)  # 玩家踏入(免疫伤害,仅教学预警钩子,T-41)

const FIELD_COLOR := Color(0.851, 0.365, 0.365, 0.34)  # #D95D5D 半透明覆格
## 判定圈半径(格中心):等距车道与邻格场心的最小间隙 ~28.6px(回声圆心 reach ≈19px),
## r8 留 ≥11px 确定裕量——贴行车道绝不误伤;穿越格心的回声必触发(docs/14 E-41 判定口径)
const TRIGGER_RADIUS := 8.0
## 视觉:全格红覆格(用户验收反馈,可读性优先——整格铺红明确"此路危险")
static var FOOTPRINT := PackedVector2Array([Vector2(0, -16), Vector2(32, 0), Vector2(0, 16), Vector2(-32, 0)])

var _visuals: Array[Polygon2D] = []


func _ready() -> void:
	add_to_group("mechanism")
	body_entered.connect(_on_body_entered)


## 由构建脚本调用:一格干扰场(格心判定圆 + 地面暗红覆格,纯渲染不走 Y-sort)
func add_cell(world_pos: Vector2) -> void:
	var shape := CircleShape2D.new()
	shape.radius = TRIGGER_RADIUS
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
	## 干扰场恒定存在、无状态可复位(E-48);保留空实现以满足 mechanism 组遍历契约
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("echo"):
		echo_dissolved.emit(body)
	elif body.is_in_group("player"):
		player_entered.emit(body)


func _physics_process(_delta: float) -> void:
	## 视觉脉动(纯表现,不影响判定);Time.get_ticks_msec 仅用于外观
	var pulse := 0.30 + 0.12 * sin(Time.get_ticks_msec() / 400.0)
	for v in _visuals:
		v.color.a = pulse
