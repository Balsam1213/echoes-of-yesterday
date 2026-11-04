class_name Level01Manager
extends Node2D
## 第一关流程控制(T4.1/T4.4/T4.7):状态机 INTRO→PLAY→COMPLETE、教学提示、重置、通关判定(docs/05)。
## 文案一律经 UIText;跨场景通信一律经 GameEvents。

enum State { INTRO, PLAY, COMPLETE }

var _state := State.INTRO
var _switch_seen := false
var _hint02_shown := false
var _spawn_position := Vector2.ZERO

@onready var _player: PlayerController = %Player
@onready var _switch: PressureSwitch = %PressureSwitch
@onready var _door: SecurityDoor = %SecurityDoor
@onready var _exit: ExitArea = %ExitArea
@onready var _device: TimeRecorderDevice = %TimeRecorderDevice
@onready var _echo_mgr: EchoManager = %EchoManager


func _ready() -> void:
	_spawn_position = _player.global_position
	_switch.switch_activated.connect(_on_switch_activated)
	_switch.switch_deactivated.connect(_on_switch_deactivated)
	# 开关→门直连(T2.3):踩住开门、离开关门;多条件门由后续关卡在此扩展
	_switch.switch_activated.connect(_door.set_open.bind(true))
	_switch.switch_deactivated.connect(_door.set_open.bind(false))
	_exit.player_entered.connect(_on_exit_entered)
	GameEvents.restart_requested.connect(_on_restart_requested)
	_state = State.PLAY  # INTRO 提示即 T-01 常驻键位(HUD 常驻),无额外演出


func _physics_process(_delta: float) -> void:
	if _state == State.PLAY and Input.is_action_just_pressed("reset_room"):
		reset_room()


## Backspace 全量复位(docs/02 §8.2 四步):回声与记录 → 机关 → 玩家 → 教学/UI
func reset_room() -> void:
	_echo_mgr.clear_all()
	_player.recorder.discard_buffer()
	_switch.force_reset()
	_door.force_reset()
	_device.force_reset()
	_player.reset_to(_spawn_position)
	_switch_seen = false
	_hint02_shown = false


func _on_switch_activated() -> void:
	_switch_seen = true


func _on_switch_deactivated() -> void:
	## 首次"踩上后离开"→ T-02(教学阶段 2,docs/05 §5)
	if _switch_seen and not _hint02_shown and _state == State.PLAY:
		_hint02_shown = true
		GameEvents.notify_requested.emit(UIText.T02_CANNOT_PASS)


func _on_exit_entered() -> void:
	if _state != State.PLAY:
		return
	if _player.recorder.is_recording:
		_player.recorder.discard_buffer()  # E-09 预留:通关时静默取消记录
	_state = State.COMPLETE
	get_tree().paused = true  # 冻结世界:玩家进门时可能仍按着移动键,冻结保证看清通关界面
	GameEvents.level_completed.emit(1)
	SaveManager.mark_level_completed(1)


func _on_restart_requested() -> void:
	## 通关界面按任意键 / 暂停菜单"重新开始本关" 共用;解除冻结并全量复位
	reset_room()
	get_tree().paused = false
	_state = State.PLAY
