class_name LevelManagerBase
extends Node2D
## 关卡流程基类:INTRO→PLAY→COMPLETE 状态机、通关冻结、重玩/下一关推进(docs/10 §4)。
## 子类定制点:_level_id()(存档与文案)、_on_ready()(接线与开场提示)、_on_reset_extra()(机关 force_reset 与教学状态复位)。
## 接线规则:机关↔门/指示灯的信号连接由子类在本场景内完成;条件组合归关卡层(docs/02 §7)。

@export var next_scene := ""  # 通关后进入的场景路径;空 = 原地重玩(章节末关)

enum State { INTRO, PLAY, COMPLETE }

var _state := State.INTRO
var _spawn_position := Vector2.ZERO

@onready var _player: PlayerController = %Player
@onready var _exit: ExitArea = %ExitArea
@onready var _echo_mgr: EchoManager = %EchoManager


func _ready() -> void:
	get_tree().paused = false  # 防御:编辑器调试器暂停残留会让关卡以冻结态启动(黑屏/相机悬空)
	_spawn_position = _player.global_position
	_exit.player_entered.connect(_on_exit_entered)
	GameEvents.advance_requested.connect(_on_advance_requested)
	GameEvents.level_reset_requested.connect(_on_level_reset_requested)
	_on_ready()
	_state = State.PLAY


func _physics_process(_delta: float) -> void:
	if _state == State.PLAY and Input.is_action_just_pressed("reset_room"):
		reset_room()


## 子类覆盖:关卡编号(存档与完成文案选择)
func _level_id() -> int:
	return 0


## 子类覆盖:接线与开场提示(在 _state 置 PLAY 前调用)
func _on_ready() -> void:
	pass


## 子类覆盖:重置时的机关 force_reset 与教学状态复位
func _on_reset_extra() -> void:
	pass


## Backspace 全量复位(docs/02 §8.2 四步;顺序勿变)
func reset_room() -> void:
	_echo_mgr.clear_all()
	_player.recorder.clear_all()
	_on_reset_extra()
	_player.reset_to(_spawn_position)
	_state = State.PLAY


func _on_exit_entered() -> void:
	if _state != State.PLAY:
		return
	if _player.recorder.is_recording:
		_player.recorder.discard_buffer()  # E-09:通关时静默取消记录
	_state = State.COMPLETE
	get_tree().paused = true  # 冻结世界:防移动键误触,保证看清完成界面
	GameEvents.level_completed.emit(_level_id())
	SaveManager.mark_level_completed(_level_id())


func _on_advance_requested() -> void:
	## 完成界面任意键:重置并推进到下一关(末关 next_scene 为空 → 原地重玩)
	reset_room()
	get_tree().paused = false
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)
	else:
		_state = State.PLAY


func _on_level_reset_requested() -> void:
	## 暂停菜单"重新开始本关":仅重置当前关,不推进
	reset_room()
	get_tree().paused = false
	_state = State.PLAY
