class_name TimeLockSwitch
extends PressureSwitch
## 时间锁(L3,docs/12):双开关咬合(A+B)时由关卡层 `arm()` 武装;
## 武装后踩上即启动 10s 倒计时,**到期无论是否被踩住都自动释放**(E-31);
## 重触发 = 离开再进入(武装期间,E-32)或重新武装;重置清全部状态(E-35)。
## 注意:本机关覆写进入/离开语义,**不要调用基类的激活处理**(窗口不看脚下)。

@export var hold_seconds := 10.0

const BLINK_FROM := 3.0

var _armed := false
var _counting := false
var _remaining := 0.0
var _expired_occupied := false  # 到期时仍有人踩住:阻断 arm() 立即重启,直到离开(E-32)
var _t17_sent := false
var _t15_sent := false
var _hint31_shown := false

@onready var _proximity: Area2D = %Proximity


func _ready() -> void:
	super._ready()
	_proximity.body_entered.connect(_on_proximity_entered)


func _on_proximity_entered(body: Node2D) -> void:
	## 首次靠近即教学(T-31):规则必须在踩下去之前讲清楚
	if body.is_in_group("player") and not _hint31_shown:
		_hint31_shown = true
		GameEvents.notify_requested.emit(UIText.T31_LOCK_HINT)


func _on_body_entered(body: Node2D) -> void:
	_bodies_inside.append(body)
	_try_start()


func _on_body_exited(body: Node2D) -> void:
	_bodies_inside.erase(body)  # 离开不影响窗口——到期才释放(E-31)
	if _bodies_inside.is_empty():
		_expired_occupied = false


## 时间锁"激活" = 窗口开启中(与是否有人踩无关,E-31);门条件据此判定
func is_active() -> bool:
	return _counting


## 关卡层调用:A+B 咬合时武装;若此刻已有人踩住则立即开始倒计时
func arm() -> void:
	_armed = true
	_try_start()


## 解除武装(A 或 B 松开)
func disarm() -> void:
	_armed = false


func force_reset() -> void:
	_bodies_inside.clear()
	_armed = false
	_counting = false
	_remaining = 0.0
	_expired_occupied = false
	_t17_sent = false
	_t15_sent = false
	_hint31_shown = false
	_apply_visual(false)


func _try_start() -> void:
	if _armed and not _counting and not _expired_occupied and not _bodies_inside.is_empty():
		_counting = true
		_remaining = hold_seconds
		_t17_sent = false
		_apply_visual(true)
		switch_activated.emit()  # 窗口状态变化通知关卡层(门聚合依赖)
		GameEvents.notify_requested.emit(UIText.T16_LOCK % int(ceil(hold_seconds)))


func _expire() -> void:
	_counting = false
	_apply_visual(false)
	_expired_occupied = not _bodies_inside.is_empty()
	switch_deactivated.emit()  # 窗口关闭通知关卡层
	if not _t15_sent:
		_t15_sent = true
	GameEvents.notify_requested.emit(UIText.T15_EXPIRED)


func _physics_process(delta: float) -> void:
	if not _counting:
		return
	_remaining -= delta
	if _remaining <= BLINK_FROM:
		_pad.modulate = COLOR_ON if fmod(_remaining, 0.5) < 0.25 else COLOR_OFF
		if not _t17_sent:
			_t17_sent = true
			GameEvents.notify_requested.emit(UIText.T17_COUNTDOWN)
	if _remaining <= 0.0:
		_expire()
