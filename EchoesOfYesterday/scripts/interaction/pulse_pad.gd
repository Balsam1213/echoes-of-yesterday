class_name PulsePad
extends PressureSwitch
## 脉冲板(L4,docs/14):任何 echo_trigger 实体进入即激活,0.5 秒后强制释放——
## 停留无效、不可延长、两次触发之间无冷却(E-46)。
## 覆写进入/离开语义:离开不提前释放,只有计时到期才释放(固定窗,docs/14 §4)。

const PULSE_SECONDS := 0.5

## 视觉与压力开关区分(docs/14 §4):青色系——待机青灰、激活亮青(#45D9F2,与回声同色系:
## 脉冲板只认"经过",恰是回声运动的位置标记);压力开关保持暖灰/明黄
const PULSE_COLOR_OFF := Color(0.45, 0.58, 0.66, 1.0)
const PULSE_COLOR_ON := Color(0.271, 0.851, 0.949, 1.0)

var _pulse_left := 0.0


func is_active() -> bool:
	return _pulse_left > 0.0


func force_reset() -> void:
	super.force_reset()
	_pulse_left = 0.0


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("echo_trigger"):
		return
	if _pulse_left <= 0.0:
		_pulse_left = PULSE_SECONDS
		_apply_visual(true)
		switch_activated.emit()
	# 激活期内重复进入不刷新窗口(E-46)


func _on_body_exited(_body: Node2D) -> void:
	pass  # 固定窗:提前离开不释放,到期统一释放(E-46)


## 覆写配色:青色系(区别压力开关的黄/灰,docs/04 色彩语义)
func _apply_visual(active: bool) -> void:
	if pad_sprite == null:
		return
	pad_sprite.modulate = PULSE_COLOR_ON if active else PULSE_COLOR_OFF
	pad_sprite.offset = Vector2(0, 2.0 if active else 0.0)


func _physics_process(delta: float) -> void:
	if _pulse_left <= 0.0:
		return
	_pulse_left -= delta
	if pad_sprite != null:
		# 激活期快闪(周期 0.25s),与基类常亮区分
		pad_sprite.modulate = PULSE_COLOR_ON if fmod(_pulse_left, 0.25) < 0.125 else PULSE_COLOR_OFF
	if _pulse_left <= 0.0:
		_pulse_left = 0.0
		_apply_visual(false)
		switch_deactivated.emit()
