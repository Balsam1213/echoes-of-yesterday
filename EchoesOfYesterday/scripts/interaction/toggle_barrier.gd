class_name ToggleBarrier
extends StaticBody2D
## 联动屏障(L5,docs/15):核心驱动的可升降墙/桥;升起=脚印碰撞阻挡,降下=通行。
## 由关卡层订阅 EnergyCore.core_toggled 后调 set_raised()(条件组合归关卡层,docs/02 §7)。
## 升起前检测格内 echo_trigger 实体,有则延迟至清空(防夹,E-59,模式同 SecurityDoor)。
## 回声不与当下环境解算(E-51):屏障状态不影响回声既定轨迹。

signal raised
signal lowered

const PANEL_RAISED_Y := -24.0   # 升起:墙体贴图脚印对齐(64×80 立体,docs/isometric.md)
const PANEL_LOWERED_Y := -4.0   # 降下:桥面贴地

var is_raised := true
var _raise_requested := true
var _bodies_on: Array[Node2D] = []

@onready var _blocker: CollisionShape2D = %Blocker
@onready var _wall_panel: Sprite2D = %WallPanel
@onready var _deck: Sprite2D = %Deck
@onready var _cell_zone: Area2D = %CellZone


func _ready() -> void:
	add_to_group("mechanism")
	_cell_zone.body_entered.connect(_on_zone_body_entered)
	_cell_zone.body_exited.connect(_on_zone_body_exited)
	_apply(true)


func set_raised(raised: bool) -> void:
	_raise_requested = raised
	_refresh()


func has_echo_on() -> bool:
	## 影子穿墙检测(L5 T-52):升起状态下桥格内有回声
	return is_raised and not _bodies_on.is_empty()


func force_reset() -> void:
	## 复位为升起(docs/15 §9 E-58)
	_raise_requested = true
	_bodies_on.clear()
	_refresh()


func _refresh() -> void:
	if is_raised == _raise_requested:
		return
	if not _raise_requested:
		_apply(false)  # 降下永远立即执行
	elif _bodies_on.is_empty():
		_apply(true)  # 防夹:格内有实体时保持降下,等 _on_zone_body_exited 再触发


func _on_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("echo_trigger") or body in _bodies_on:
		return
	_bodies_on.append(body)


func _on_zone_body_exited(body: Node2D) -> void:
	if not body in _bodies_on:
		return
	_bodies_on.erase(body)
	if _raise_requested and not is_raised:
		_refresh()


func _apply(to_raised: bool) -> void:
	is_raised = to_raised
	_blocker.set_deferred("disabled", not to_raised)
	_wall_panel.visible = to_raised
	_deck.visible = not to_raised
	_wall_panel.position.y = PANEL_RAISED_Y
	_deck.position.y = PANEL_LOWERED_Y
	if to_raised:
		raised.emit()
	else:
		lowered.emit()
