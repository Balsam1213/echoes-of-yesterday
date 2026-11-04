class_name Level01Manager
extends LevelManagerBase
## 第一关流程:开关→门接线、教学 T-02(踩上后离开)/装置 T-03(docs/05、docs/11 前置)。

var _switch_seen := false
var _hint02_shown := false

@onready var _switch: PressureSwitch = %PressureSwitch
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _device: TimeRecorderDevice = %TimeRecorderDevice


func _level_id() -> int:
	return 1


func _on_ready() -> void:
	_switch.switch_activated.connect(_on_switch_activated)
	_switch.switch_deactivated.connect(_on_switch_deactivated)
	# 开关→门直连(T2.3 契约;多条件聚合见 Level02/03)
	_switch.switch_activated.connect(_door.set_open.bind(true))
	_switch.switch_deactivated.connect(_door.set_open.bind(false))


func _on_reset_extra() -> void:
	_switch.force_reset()
	_door.force_reset()
	_device.force_reset()
	_switch_seen = false
	_hint02_shown = false


func _on_switch_activated() -> void:
	_switch_seen = true


func _on_switch_deactivated() -> void:
	## 首次"踩上后离开"→ T-02(教学阶段 2,docs/05 §5)
	if _switch_seen and not _hint02_shown and _state == State.PLAY:
		_hint02_shown = true
		GameEvents.notify_requested.emit(UIText.T02_CANNOT_PASS)
