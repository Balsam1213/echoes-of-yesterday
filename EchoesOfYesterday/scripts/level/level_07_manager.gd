class_name Level07Manager
extends LevelManagerBase
## 第七关流程(docs/18,返修 3 修订):能量核心 C1 统一驱动三扇相位门——
## **断电(OFF,初始)= 南口双门落下(可自由北上)+ 东室门密封(S1 仅回声可达);
## 供电(ON)= 南口双门密封 + 东门落下**。东室默认回声专属,录 E1 须临时供电
## (东室入口在南侧贴条,不经南口,双向均无被困风险);南口经 x10 列墙封死侧绕,
## 密封态下南区→北厅仅南口一条路(且被双门把守)——核心是不可绕过的取舍机关。
## 出口门 D2 = S1 ∧ S2(当刻 AND,缺员退行当刻重估,E-79);
## 悖论区消散接线(E-71/72):玩家 ∧ 回声同场 → 区内全部回声消散。
## 教学链:T-70 开场 / T-71 相位门 / T-72 悖论触发 / T-73 凹室 / T-74 主区 / T-51 核心(复用)。

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)

var _t71_shown := false
var _t72_shown := false
var _t73_shown := false
var _t74_shown := false
var _t51_shown := false

@onready var _sw1: PressureSwitch = %Switch1
@onready var _sw2: PressureSwitch = %Switch2
@onready var _core: EnergyCore = %Core
@onready var _gate_east: PhaseGate = %GateEast
@onready var _gate_south1: PhaseGate = %GateSouth1
@onready var _gate_south2: PhaseGate = %GateSouth2
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _field_main: ParadoxField = %FieldMain
@onready var _field_sandbox: ParadoxField = %FieldSandbox
@onready var _lights: Array[Sprite2D] = [%Light1, %Light2]


func _level_id() -> int:
	return 7


func _on_ready() -> void:
	_sw1.switch_activated.connect(_update_door)
	_sw1.switch_deactivated.connect(_update_door)
	_sw2.switch_activated.connect(_update_door)
	_sw2.switch_deactivated.connect(_update_door)
	_core.core_toggled.connect(_on_core_toggled)
	_core.player_nearby.connect(_on_core_nearby)
	for gate: PhaseGate in [_gate_east, _gate_south1, _gate_south2]:
		gate.player_nearby.connect(_on_gate_nearby)
	_field_main.player_entered.connect(_on_main_entered)
	_field_sandbox.player_entered.connect(_on_sandbox_entered)
	_field_main.paradox_triggered.connect(_on_paradox)
	_field_sandbox.paradox_triggered.connect(_on_paradox)
	_sync_gates()  # C1 初始 OFF:南口双门密封、东室门落下(EnergyCore 默认态,无需驱动)
	GameEvents.notify_requested.emit(UIText.T70_INTRO)
	_update_door()


func _on_core_toggled(_on: bool) -> void:
	_sync_gates()


## 相位门统一极性(返修 3,交换):**断电(OFF,初始)= 南口双门落下 + 东门密封**;
## 供电(ON)= 南口双门密封 + 东门落下。默认可自由北上探索,东室默认回声专属;
## 录 E1 须临时供电(东室入口在南侧贴条,不经南口,双向均无被困风险)
func _sync_gates() -> void:
	var on := _core.is_on
	_gate_south1.set_phased(on)
	_gate_south2.set_phased(on)
	_gate_east.set_phased(not on)


func _update_door() -> void:
	## D2 = S1 ∧ S2(当刻 AND)
	var s1 := _sw1.is_active()
	var s2 := _sw2.is_active()
	_door.set_open(s1 and s2)
	for i in 2:
		_lights[i].modulate = LIGHT_ON if [s1, s2][i] else LIGHT_OFF


func _on_paradox(echo: Node2D) -> void:
	_echo_mgr.dissolve(echo)
	if not _t72_shown:
		_t72_shown = true
		GameEvents.notify_requested.emit(UIText.T72_PARADOX)
	_update_door()  # 消散可致 S1/S2 缺员退行(E-79)


func _on_gate_nearby() -> void:
	if not _t71_shown:
		_t71_shown = true
		GameEvents.notify_requested.emit(UIText.T71_GATE_HINT)


func _on_core_nearby() -> void:
	if not _t51_shown:
		_t51_shown = true
		GameEvents.notify_requested.emit(UIText.T51_CORE_HINT)  # 复用 L5 核心提示


func _on_main_entered(_body: Node2D) -> void:
	if not _t74_shown:
		_t74_shown = true
		GameEvents.notify_requested.emit(UIText.T74_FIELD_HINT)


func _on_sandbox_entered(_body: Node2D) -> void:
	if not _t73_shown:
		_t73_shown = true
		GameEvents.notify_requested.emit(UIText.T73_SANDBOX_HINT)


func _on_reset_extra() -> void:
	_sw1.force_reset()
	_sw2.force_reset()
	_core.force_reset()
	_gate_east.force_reset()
	_gate_south1.force_reset()
	_gate_south2.force_reset()
	_door.force_reset()
	_field_main.force_reset()
	_field_sandbox.force_reset()
	_sync_gates()  # E-76:重置复位 C1 OFF 初始态(南落东封)
	_t71_shown = false
	_t72_shown = false
	_t73_shown = false
	_t74_shown = false
	_t51_shown = false
	_update_door()
