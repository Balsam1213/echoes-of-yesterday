class_name Level08Manager
extends LevelManagerBase
## 第八关流程(docs/19,章末关):悖论之海 P1(E-81 判定同 E-71);异常核心 C1
## 位于区内——拨动断电(G1 落下),**断电计时归关卡层**:OFF 起 10s 自动复电
## (E-82;计时期内再拨 ON 取消计时;EnergyCore 契约零改动,L6 关卡层聚合先例);
## 时间锁为自由武装(常 arm,踩上即 10s 窗,E-84);出口门 D2 = S1 ∧ S2 ∧ TL 激活
## (当刻 AND,缺员退行重估,E-85);标准解路线不含 events(E-87)。
## 教学链:T-80 开场 / T-81 舱门 / T-82 核心;时间锁靠近文案复用 T-61。

const POWER_WINDOW := 10.0  # 断电自动复电秒数(docs/19 §4,E-82)

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)

var _power_left := 0.0  # >0 = 断电窗口计时中(E-82)
var _t81_shown := false
var _t82_shown := false

@onready var _sw1: PressureSwitch = %Switch1
@onready var _sw2: PressureSwitch = %Switch2
@onready var _lock: TimeLockSwitch = %TimeLock
@onready var _core: EnergyCore = %Core
@onready var _gate: PhaseGate = %PhaseGate
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _field: ParadoxField = %FieldSea
@onready var _lights: Array[Sprite2D] = [%Light1, %Light2, %Light3]


func _level_id() -> int:
	return 8


func _on_ready() -> void:
	_sw1.switch_activated.connect(_update_door)
	_sw1.switch_deactivated.connect(_update_door)
	_sw2.switch_activated.connect(_update_door)
	_sw2.switch_deactivated.connect(_update_door)
	_lock.switch_activated.connect(_update_door)
	_lock.switch_deactivated.connect(_update_door)
	_lock.proximity_hint_text = UIText.T61_LOCK_HINT  # 复用 L6 时间锁靠近文案
	_core.core_toggled.connect(_on_core_toggled)
	_core.player_nearby.connect(_on_core_nearby)
	_gate.player_nearby.connect(_on_gate_nearby)
	_field.paradox_triggered.connect(_on_paradox)
	_lock.arm()  # 自由时间锁:踩上即 10s 窗(基础语义,E-84;重置后重新武装)
	_core.set_on(true)  # C1 初始 ON(G1 密封)
	GameEvents.notify_requested.emit(UIText.T80_INTRO)
	_update_door()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _power_left > 0.0:
		_power_left -= delta
		if _power_left <= 0.0:
			_core.set_on(true)  # 断电窗到期自动复电(E-82)→ core_toggled 驱动 G1 复封


func _on_core_toggled(on: bool) -> void:
	_gate.set_phased(on)
	_power_left = 0.0 if on else POWER_WINDOW  # 断电窗起(E-82);复电/计时期再拨取消计时


func _update_door() -> void:
	## D2 = S1 ∧ S2 ∧ TL 激活(当刻 AND)
	var s1 := _sw1.is_active()
	var s2 := _sw2.is_active()
	var tl := _lock.is_active()
	_door.set_open(s1 and s2 and tl)
	for i in 3:
		_lights[i].modulate = LIGHT_ON if [s1, s2, tl][i] else LIGHT_OFF


func _on_paradox(echo: Node2D) -> void:
	_echo_mgr.dissolve(echo)
	_update_door()  # 消散可致 S1/S2 缺员退行(E-85)


func _on_gate_nearby() -> void:
	if not _t81_shown:
		_t81_shown = true
		GameEvents.notify_requested.emit(UIText.T81_GATE_HINT)


func _on_core_nearby() -> void:
	if not _t82_shown:
		_t82_shown = true
		GameEvents.notify_requested.emit(UIText.T82_CORE_HINT)


func _on_reset_extra() -> void:
	_sw1.force_reset()
	_sw2.force_reset()
	_lock.force_reset()
	_lock.arm()  # 重新武装自由时间锁(E-89)
	_core.force_reset()
	_gate.force_reset()
	_door.force_reset()
	_field.force_reset()
	_core.set_on(true)  # E-89:C1 复 ON(断电计时清、G1 复封)
	_power_left = 0.0
	_t81_shown = false
	_t82_shown = false
	_update_door()
