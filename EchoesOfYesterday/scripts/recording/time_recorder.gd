class_name TimeRecorder
extends Node
## 行动记录器(T3.1):R 开始/结束,60Hz 逐物理帧采样,满 30 秒自动结束(docs/02 §5)。
## 采样在 _physics_process 内进行——回放一致性的根基(NFR-02)。
## 作为 Player 子节点存在;仅保留最近一条已完成记录(02 §5.3,多记录为第 3 关需求)。

var recording: EchoRecording = null  # 最近一条已完成记录
var is_recording := false

var _buffer: EchoRecording = null
var _player: PlayerController


func _ready() -> void:
	_player = get_parent() as PlayerController


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("record_toggle"):
		if is_recording:
			_stop()
		else:
			_start()
		return
	if is_recording:
		_sample()


func discard_buffer() -> void:
	## 丢弃未完成记录(通关静默取消时调用,E-09);不影响已完成记录
	if is_recording:
		is_recording = false
		_buffer = null


func clear_all() -> void:
	## 关卡重置:未完成与已完成记录一并清除(docs/02 §8.2 第 1 步)
	is_recording = false
	_buffer = null
	recording = null


func _start() -> void:
	_buffer = EchoRecording.new()
	is_recording = true
	GameEvents.recording_started.emit()


func _stop() -> void:
	is_recording = false
	recording = _buffer
	_buffer = null
	GameEvents.recording_stopped.emit(recording.duration())


func _sample() -> void:
	if _buffer.frames.size() >= EchoRecording.MAX_FRAMES:
		_stop()  # 满 30 秒自动结束(E-03)
		return
	# TODO(recording): 交互事件由 InteractionManager 在 M4+ 填充(02 §5.2 events 字段)
	_buffer.frames.append({
		"t": _buffer.frames.size(),
		"pos": _player.global_position,
		"dir": _player.direction,
		"anim": _player.anim_state,
		"events": [],
	})
