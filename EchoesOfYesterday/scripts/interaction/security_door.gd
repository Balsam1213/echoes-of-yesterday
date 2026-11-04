class_name SecurityDoor
extends StaticBody2D
## 安全门(T2.2):set_open(true) 立即开启;关闭请求时若门洞内有实体则保持开启,清空后再关(防夹,docs/02 §7.2)。
## 单开关直连由关卡场景连线完成(T2.3);多开关与/或组合在关卡层处理,本脚本只接收最终布尔请求。

signal opened
signal closed

const LIGHT_OFF := Color(0.85, 0.36, 0.36, 1.0)  # 红:关闭(#D95D5D)
const LIGHT_ON := Color(0.42, 0.75, 0.48, 1.0)   # 绿:开启
const PANEL_CLOSED_Y := -24.0   # 64×80 立体贴图脚印 (32,64) 对齐原点的偏移
const PANEL_OPEN_LIFT := 34.0   # 开启时门体上抬高度

var _open := false
var _open_requested := false
var _bodies_in_hole: Array[Node2D] = []

@onready var _panel: Sprite2D = %Panel
@onready var _light: Sprite2D = %Light
@onready var _blocker: CollisionShape2D = %Blocker
@onready var _hole: Area2D = %DoorHole


func _ready() -> void:
	add_to_group("mechanism")
	_hole.body_entered.connect(_on_hole_body_entered)
	_hole.body_exited.connect(_on_hole_body_exited)
	_apply(false)


func is_open() -> bool:
	return _open


func force_reset() -> void:
	## 关卡重置:强制关门并清空门洞检测(docs/02 §8.2 第 2 步)
	_open_requested = false
	_bodies_in_hole.clear()
	_refresh()


func set_open(open: bool) -> void:
	_open_requested = open
	_refresh()


func _refresh() -> void:
	if _open == _open_requested:
		return
	if _open_requested:
		_apply(true)  # 开门永远立即执行
	elif _bodies_in_hole.is_empty():
		_apply(false)  # 防夹:门洞有实体时保持开启,等 _on_hole_body_exited 再触发


func _on_hole_body_entered(body: Node2D) -> void:
	if not body.is_in_group("echo_trigger") or body in _bodies_in_hole:
		return
	_bodies_in_hole.append(body)


func _on_hole_body_exited(body: Node2D) -> void:
	if not body in _bodies_in_hole:
		return
	_bodies_in_hole.erase(body)
	if not _open_requested and _open:
		_refresh()


## 状态落地:碰撞切换 + 门体上移 + 指示灯变色(占位表现,正式版换补间动画)
func _apply(open: bool) -> void:
	_open = open
	_blocker.set_deferred("disabled", open)
	_panel.position.y = (PANEL_CLOSED_Y - PANEL_OPEN_LIFT) if open else PANEL_CLOSED_Y
	_panel.modulate.a = 0.85 if open else 1.0
	_light.modulate = LIGHT_ON if open else LIGHT_OFF
	if open:
		opened.emit()
	else:
		closed.emit()
