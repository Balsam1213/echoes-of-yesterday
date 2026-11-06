class_name Level04Manager
extends LevelManagerBase
## 第四关流程(docs/14):出口门 = A ∧ 同振(B∧P),同振触发后维持 1.5 秒(E-47);
## 三灯驱动(A/B/P);干扰场消散接线(消散执行归 EchoManager,T-42 首次提示);
## 教学链 T-40 开场 / T-41 靠近干扰场(由场实例 proximity 触发,见下)/ T-43 脉冲板。

const SYNC_HOLD := 1.5   # 同振窗口维持秒数(E-47)
const T44_DELAY := 3.0   # 回声首次经过 B 后,门仍未开的提示延迟

const LIGHT_ON := Color(0.957, 0.827, 0.369, 1.0)
const LIGHT_OFF := Color(0.35, 0.38, 0.42, 1.0)

var _sync_timer := 0.0
var _t41_shown := false
var _t42_shown := false
var _t44_timer := -1.0   # <0 未武装;>=0 倒计时中
var _t44_shown := false

@onready var _sw_a: PressureSwitch = %SwitchA
@onready var _pad_b: PulsePad = %PadB
@onready var _pad_p: PulsePad = %PadP
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _fields: Array[Node] = [%FieldMain, %FieldU]
@onready var _lights: Array[Sprite2D] = [%LightA, %LightB, %LightP]


func _level_id() -> int:
	return 4


func _on_ready() -> void:
	_sw_a.switch_activated.connect(_update_door)
	_sw_a.switch_deactivated.connect(_update_door)
	_pad_b.switch_activated.connect(_on_pad_b_triggered)
	_pad_b.switch_deactivated.connect(_update_door)
	_pad_p.switch_activated.connect(_update_door)
	_pad_p.switch_deactivated.connect(_update_door)
	for f in _fields:
		f.echo_dissolved.connect(_on_echo_dissolved)
		f.player_entered.connect(_on_field_player_entered)
	GameEvents.notify_requested.emit(UIText.T40_INTRO)
	_update_door()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _sync_timer > 0.0:
		_sync_timer -= delta
		if _sync_timer <= 0.0:
			_sync_timer = 0.0
			_update_door()
	if _t44_timer >= 0.0:
		_t44_timer -= delta
		if _t44_timer < 0.0 and not _door.is_open() and not _t44_shown:
			_t44_shown = true
			GameEvents.notify_requested.emit(UIText.T44_SYNC_HINT)


func _on_pad_b_triggered() -> void:
	_update_door()
	if _t44_timer < 0.0 and not _t44_shown:
		_t44_timer = T44_DELAY  # 首次经过 B:武装 T-44(门 3 秒内未开则提示)


func _update_door() -> void:
	## 同振判定:B∧P 同帧激活且 A 就位 → 开门;同振期间持续刷新窗口,
	## 结束时刻 = 最后同振帧 + 1.5s(E-47);A 缺席时同振不开门(三灯反馈"缺 A")
	var a := _sw_a.is_active()
	var b := _pad_b.is_active()
	var p := _pad_p.is_active()
	if a and b and p:
		_sync_timer = SYNC_HOLD
	_door.set_open(a and _sync_timer > 0.0)
	for i in 3:
		_lights[i].modulate = LIGHT_ON if [a, b, p][i] else LIGHT_OFF


func _on_echo_dissolved(echo: Node2D) -> void:
	_echo_mgr.dissolve(echo)
	if not _t42_shown:
		_t42_shown = true
		GameEvents.notify_requested.emit(UIText.T42_DISSOLVED)
	_update_door()  # 消散的回声可能正压着机关,状态当刻重估(E-43)


## 玩家(免疫干扰,不受场伤害)首次走进任一场范围 → T-41 预警
func _on_field_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _t41_shown:
		_t41_shown = true
		GameEvents.notify_requested.emit(UIText.T41_FIELD_WARN)


func _on_reset_extra() -> void:
	_sw_a.force_reset()
	_pad_b.force_reset()
	_pad_p.force_reset()
	_door.force_reset()
	_sync_timer = 0.0
	_t41_shown = false
	_t42_shown = false
	_t44_timer = -1.0
	_t44_shown = false
	_update_door()
