class_name PressureSwitch
extends Area2D
## 压力开关(T2.1):echo_trigger 组实体(玩家/回声)位于触发区内即激活,全部离开后关闭。
## 信号供门体/关卡逻辑连接;激活判定基于实体清单而非计数,避免重复进出导致的漏计(docs/02 §7.1)。

signal switch_activated
signal switch_deactivated

const COLOR_OFF := Color(0.62, 0.66, 0.72, 1.0)     # 未激活:亮灰(深色地板上清晰可辨)
const COLOR_ON := Color(0.957, 0.827, 0.369, 1.0)  # 激活:#F4D35E 明亮黄

var _bodies_inside: Array[Node2D] = []

## 开关底座贴花(地面层,由关卡构建脚本注入;不参与 Y-sort,恒在角色之下)
@export var pad_sprite: Sprite2D


func _ready() -> void:
	add_to_group("mechanism")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_apply_visual(false)


func is_active() -> bool:
	return not _bodies_inside.is_empty()


func force_reset() -> void:
	## 关卡重置:清空触发清单并复位视觉(不 emit 信号;玩家随后被传送走,docs/02 §8.2)
	_bodies_inside.clear()
	_apply_visual(false)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("echo_trigger") or body in _bodies_inside:
		return
	_bodies_inside.append(body)
	if _bodies_inside.size() == 1:
		_apply_visual(true)
		switch_activated.emit()


func _on_body_exited(body: Node2D) -> void:
	var was_active := is_active()
	_bodies_inside.erase(body)
	if was_active and _bodies_inside.is_empty():
		_apply_visual(false)
		switch_deactivated.emit()


## 视觉反馈:指示变黄 + 底座下沉 2px(docs/05 §4)
## 下沉用 Sprite2D.offset(纯渲染偏移):节点 position 是贴花的唯一锚点,
## 运行时覆写 position 会因普通变量不随场景保存而把底座"飞"到错误位置(返修教训)
func _apply_visual(active: bool) -> void:
	if pad_sprite == null:
		return
	pad_sprite.modulate = COLOR_ON if active else COLOR_OFF
	pad_sprite.offset = Vector2(0, 2.0 if active else 0.0)


## 由构建脚本调用:注入地面贴花层中的底座贴图引用
func bind_pad(sprite: Sprite2D) -> void:
	pad_sprite = sprite
