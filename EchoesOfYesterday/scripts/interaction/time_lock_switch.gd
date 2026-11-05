class_name TimeLockSwitch
extends PressureSwitch
## 时间锁(L3 新机关,docs/12 §4):踩上即激活并启动倒计时,到期**无论是否被踩住都自动释放**(E-31);
## 重新激活必须先离开再进入(E-32);最后 3 秒闪烁;到期首次播报教学 T-15(force_reset 重武装)。

@export var hold_seconds := 10.0

const BLINK_FROM := 3.0

var _counting := false
var _remaining := 0.0
var _t17_sent := false
var _t15_sent := false
var _hint31_shown := false

@onready var _proximity: Area2D = %Proximity


func _ready() -> void:
	super._ready()
	_proximity.body_entered.connect(_on_proximity_entered)


func _on_proximity_entered(body: Node2D) -> void:
	## 首次靠近即教学(T-31):时间锁的规则必须在踩下去之前讲清楚
	if body.is_in_group("player") and not _hint31_shown:
		_hint31_shown = true
		GameEvents.notify_requested.emit(UIText.T31_LOCK_HINT)


func _physics_process(delta: float) -> void:
	if not _counting:
		return
	_remaining -= delta
	if _remaining <= BLINK_FROM:
		# 最后 3 秒闪烁(T-17 一次)
		_pad.modulate = COLOR_ON if fmod(_remaining, 0.5) < 0.25 else COLOR_OFF
		if not _t17_sent:
			_t17_sent = true
			GameEvents.notify_requested.emit(UIText.T17_COUNTDOWN)
	if _remaining <= 0.0:
		_expire()


func force_reset() -> void:
	## 关卡重置:清倒计时、清触发清单、重新武装 T-15/T-31(docs/12 E-35)
	super()
	_counting = false
	_remaining = 0.0
	_t17_sent = false
	_t15_sent = false
	_hint31_shown = false


func _on_body_entered(body: Node2D) -> void:
	super(body)
	# 进入触发激活:启动/重启倒计时(T-16);离开再进入即重触发(E-32)
	if is_active() and not _counting:
		_remaining = hold_seconds
		_counting = true
		_t17_sent = false
		GameEvents.notify_requested.emit(UIText.T16_LOCK % int(ceil(hold_seconds)))


func _on_body_exited(body: Node2D) -> void:
	super(body)
	# 压力语义:全部离开立即释放并停止倒计时(E-31)
	if not is_active() and _counting:
		_stop_counting()


## 到期自动释放:清触发清单(不看脚下,E-31)+ 停止计数 + 广播失效
func _expire() -> void:
	_counting = false
	var was_active := is_active()
	_bodies_inside.clear()
	_apply_visual(false)
	if not _t15_sent:
		_t15_sent = true
		GameEvents.notify_requested.emit(UIText.T15_EXPIRED)
	if was_active:
		switch_deactivated.emit()


func _stop_counting() -> void:
	_counting = false
	_remaining = 0.0
