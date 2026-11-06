class_name PulsePad
extends PressureSwitch
## 脉冲板(L4,docs/14):任何 echo_trigger 实体进入即激活,0.5 秒后强制释放——
## 停留无效、不可延长、两次触发之间无冷却(E-46)。
## 覆写进入/离开语义:离开不提前释放,只有计时到期才释放(固定窗,docs/14 §4)。

const PULSE_SECONDS := 0.5

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


func _physics_process(delta: float) -> void:
	if _pulse_left <= 0.0:
		return
	_pulse_left -= delta
	if pad_sprite != null:
		# 激活期快闪(周期 0.25s),与基类常亮区分
		pad_sprite.modulate = COLOR_ON if fmod(_pulse_left, 0.25) < 0.125 else COLOR_OFF
	if _pulse_left <= 0.0:
		_pulse_left = 0.0
		_apply_visual(false)
		switch_deactivated.emit()
