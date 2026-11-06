class_name Level05Manager
extends LevelManagerBase
## 第五关流程(docs/15):出口门 = A ∧ 核心2;核心1 驱动北桥(ON=降/OFF=升);
## 影子穿墙检测(T-52,桥升起而回声位于桥格);E 交互教学(T-51 共享一次);
## 教学链 T-50 开场 / T-53 由核心本体在 auto_off 启动时发出。

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)

var _t51_shown := false
var _t52_shown := false

@onready var _sw_a: PressureSwitch = %SwitchA
@onready var _core1: EnergyCore = %Core1
@onready var _core2: EnergyCore = %Core2
@onready var _bridge: ToggleBarrier = %Bridge
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _field: InterferenceField = %FieldM
@onready var _lights: Array[Sprite2D] = [%LightA, %LightC]


func _level_id() -> int:
	return 5


func _on_ready() -> void:
	_sw_a.switch_activated.connect(_update_door)
	_sw_a.switch_deactivated.connect(_update_door)
	_core2.core_toggled.connect(_on_core2_toggled)
	_core1.core_toggled.connect(_on_core1_toggled)
	for core: EnergyCore in [_core1, _core2]:
		core.player_nearby.connect(_on_core_nearby)
	_field.echo_dissolved.connect(_on_echo_dissolved)
	GameEvents.notify_requested.emit(UIText.T50_INTRO)
	_update_door()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	## 影子穿墙(T-52,once):桥升起而回声位于桥格(E-51 的可见化时刻)
	if not _t52_shown and _bridge.has_echo_on():
		_t52_shown = true
		GameEvents.notify_requested.emit(UIText.T52_SHADOW_WALL)


func _on_core1_toggled(on: bool) -> void:
	_bridge.set_raised(not on)  # 核心1 ON = 桥降(通行);OFF = 桥升(阻挡)


func _on_core2_toggled(_on: bool) -> void:
	_update_door()


func _on_core_nearby() -> void:
	if not _t51_shown:
		_t51_shown = true
		GameEvents.notify_requested.emit(UIText.T51_CORE_HINT)


func _update_door() -> void:
	## 门 = A(回声常踩)∧ 核心2 ON(8s 窗)——双回声时序编排的目标状态
	var a := _sw_a.is_active()
	var c := _core2.is_on
	_door.set_open(a and c)
	for i in 2:
		_lights[i].modulate = LIGHT_ON if [a, c][i] else LIGHT_OFF


func _on_echo_dissolved(echo: Node2D) -> void:
	_echo_mgr.dissolve(echo)
	_update_door()


func _on_reset_extra() -> void:
	_sw_a.force_reset()
	_core1.force_reset()
	_core2.force_reset()
	_bridge.force_reset()
	_door.force_reset()
	_t51_shown = false
	_t52_shown = false
	_update_door()
