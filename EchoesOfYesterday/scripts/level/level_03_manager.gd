class_name Level03Manager
extends LevelManagerBase
## 第三关流程:三条件 AND(双压力开关 + 时间锁)、三灯驱动、章节末关(docs/12)。
## 时间锁到期自动释放(E-31)→ is_active 变 false → 本管理器聚合后关门。

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)

@onready var _sw_a: PressureSwitch = %SwitchA
@onready var _sw_b: PressureSwitch = %SwitchB
@onready var _lock: TimeLockSwitch = %TimeLock
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _lights: Array[Sprite2D] = [%LightA, %LightB, %LightC]


func _level_id() -> int:
	return 3


func _on_ready() -> void:
	for sw: PressureSwitch in [_sw_a, _sw_b, _lock]:
		sw.switch_activated.connect(_update_door)
		sw.switch_deactivated.connect(_update_door)
	_update_door()


func _on_reset_extra() -> void:
	_sw_a.force_reset()
	_sw_b.force_reset()
	_lock.force_reset()
	_door.force_reset()
	_update_door()


## 三条件 AND:A + B + 时间锁全激活才开门;三灯随各自状态
func _update_door() -> void:
	var states := [_sw_a.is_active(), _sw_b.is_active(), _lock.is_active()]
	_door.set_open(states[0] and states[1] and states[2])
	for i in 3:
		_lights[i].modulate = LIGHT_ON if states[i] else LIGHT_OFF
