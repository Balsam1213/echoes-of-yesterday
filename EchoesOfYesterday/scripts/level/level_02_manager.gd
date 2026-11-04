class_name Level02Manager
extends LevelManagerBase
## 第二关流程:双开关 AND 门聚合、教学 T-10/T-12/T-13(docs/11)。
## 条件聚合归关卡层(docs/02 §7):开关只广播状态,门只收最终布尔。

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)   # 指示灯亮:黄
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)     # 指示灯灭:蓝灰

var _hint12_shown := false
var _t13_shown := false

@onready var _sw_a: PressureSwitch = %SwitchA
@onready var _sw_b: PressureSwitch = %SwitchB
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _light_a: Sprite2D = %LightA
@onready var _light_b: Sprite2D = %LightB


func _level_id() -> int:
	return 2


func _on_ready() -> void:
	for sw: PressureSwitch in [_sw_a, _sw_b]:
		sw.switch_activated.connect(_on_switch_changed)
		sw.switch_deactivated.connect(_on_switch_changed)
	GameEvents.echo_count_changed.connect(_on_echo_count_changed)
	GameEvents.notify_requested.emit(UIText.T10_INTRO)
	_update_door()


func _on_reset_extra() -> void:
	_sw_a.force_reset()
	_sw_b.force_reset()
	_door.force_reset()
	_hint12_shown = false
	_t13_shown = false
	_update_door()


## AND 聚合:双开关全激活才开门;指示灯随各自开关状态(docs/11 §4)
func _on_switch_changed() -> void:
	_update_door()
	if _state == State.PLAY and not _hint12_shown \
			and (_sw_a.is_active() or _sw_b.is_active()) \
			and not (_sw_a.is_active() and _sw_b.is_active()):
		_hint12_shown = true
		GameEvents.notify_requested.emit(UIText.T12_TWO_LOCKS)


func _update_door() -> void:
	var both := _sw_a.is_active() and _sw_b.is_active()
	_door.set_open(both)
	_light_a.modulate = LIGHT_ON if _sw_a.is_active() else LIGHT_OFF
	_light_b.modulate = LIGHT_ON if _sw_b.is_active() else LIGHT_OFF


func _on_echo_count_changed(count: int, _cap: int) -> void:
	if count >= 2 and not _t13_shown and _state == State.PLAY:
		_t13_shown = true
		GameEvents.notify_requested.emit(UIText.T13_TWO_ECHOES)
