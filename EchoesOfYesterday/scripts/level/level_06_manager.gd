class_name Level06Manager
extends LevelManagerBase
## 第六关流程(docs/16,章末关):序列门 A→B→C——激活第 i 号时第 1..i-1 号须全部
## 处于激活态,乱序 = 无效 + 底座闪红 + T-62(温和版,前序保持,E-61);
## 出口门 = A ∧ B(合法)∧ C(合法)∧ 核心;时间锁 C 沿用 L3 模式(A∧B 咬合时武装)。
## 合法性以「激活事件时刻」判定;失活即失格,再次激活重新按序检查(E-62)。

const FLASH_TIME := 0.5   # 乱序闪红时长

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)
const LIGHT_RED := Color(0.85, 0.36, 0.36, 1.0)

var _b_legal := false
var _c_legal := false
var _t62_shown := false
var _flash_left := 0.0
var _flash_pad: Sprite2D = null

@onready var _sw_a: PressureSwitch = %SwitchA
@onready var _sw_b: PressureSwitch = %SwitchB
@onready var _lock: TimeLockSwitch = %TimeLock
@onready var _core: EnergyCore = %Core
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _fields: Array[Node] = [%Field0, %Field1, %Field2, %Field3]
@onready var _lights: Array[Sprite2D] = [%LightA, %LightB, %LightC, %LightD]


func _level_id() -> int:
	return 6


func _on_ready() -> void:
	_sw_a.switch_activated.connect(_update_door)
	_sw_a.switch_deactivated.connect(_update_door)
	_sw_b.switch_activated.connect(_on_b_activated)
	_sw_b.switch_deactivated.connect(_on_b_deactivated)
	_lock.switch_activated.connect(_on_c_activated)
	_lock.switch_deactivated.connect(_on_c_deactivated)
	_core.core_toggled.connect(_on_core_toggled)
	for f in _fields:
		f.echo_dissolved.connect(_on_echo_dissolved)
	GameEvents.notify_requested.emit(UIText.T60_INTRO)
	_update_door()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0 and _flash_pad != null:
			_flash_pad.modulate = PressureSwitch.COLOR_OFF
			_flash_pad = null
	## C 被踩住但未武装(A∧B 未咬合)→ 乱序反馈(E-61;武装下启动即合法,不走此分支)
	if not _t62_shown and not _lock.is_active() and _lock.has_visitor() \
			and not (_sw_a.is_active() and _b_legal and _sw_b.is_active()):
		_t62_shown = true
		_flash(_lock.pad_sprite)
		GameEvents.notify_requested.emit(UIText.T62_ORDER_WRONG)


func _on_b_activated() -> void:
	if _sw_a.is_active():
		_b_legal = true
	else:
		_b_legal = false
		_flash(_sw_b.pad_sprite)
		if not _t62_shown:
			_t62_shown = true
			GameEvents.notify_requested.emit(UIText.T62_ORDER_WRONG)
	_update_door()


func _on_b_deactivated() -> void:
	_b_legal = false  # 失活即失格,再次激活重新按序检查(E-62)
	_update_door()


func _on_c_activated() -> void:
	_c_legal = true  # C 仅在 A∧B 咬合时被武装(见 _update_door),武装下启动即合法
	_update_door()


func _on_c_deactivated() -> void:
	_c_legal = false
	_update_door()


func _on_core_toggled(_on: bool) -> void:
	_update_door()


func _update_door() -> void:
	## 门 = A ∧ B(合法)∧ C(合法)∧ 核心;时间锁武装沿用 L3 模式:A∧B 咬合瞬间 arm()
	var a := _sw_a.is_active()
	var b := _b_legal and _sw_b.is_active()
	if a and b:
		_lock.arm()
	else:
		_lock.disarm()
	var c := _c_legal and _lock.is_active()
	var d := _core.is_on
	_door.set_open(a and b and c and d)
	for i in 4:
		_lights[i].modulate = LIGHT_ON if [a, b, c, d][i] else LIGHT_OFF


func _flash(pad: Sprite2D) -> void:
	_flash_pad = pad
	_flash_left = FLASH_TIME
	if pad != null:
		pad.modulate = LIGHT_RED


func _on_echo_dissolved(echo: Node2D) -> void:
	_echo_mgr.dissolve(echo)
	_update_door()  # 消散可致 A/B 缺员退行(E-65)


func _on_reset_extra() -> void:
	_sw_a.force_reset()
	_sw_b.force_reset()
	_lock.force_reset()
	_core.force_reset()
	_door.force_reset()
	_b_legal = false
	_c_legal = false
	_t62_shown = false
	_flash_left = 0.0
	_flash_pad = null
	_update_door()
