extends CanvasLayer
## HUD/教学提示/通关界面(T4.5/T4.7/T4.3 展示层)。文案唯一来源 ui_text.gd(docs/05 §6)。
## 状态来源:GameEvents 总线;本层不直接引用关卡节点。

const RECORD_MAX := 30.0

var _recording := false
var _record_elapsed := 0.0
var _playback_total := 0.0
var _playback_elapsed := 0.0
var _hint_timer := 0.0
var _complete := false

@onready var _level_label: Label = %LevelLabel
@onready var _echo_label: Label = %EchoLabel
@onready var _key_hints: Label = %KeyHints
@onready var _timeline: ProgressBar = %Timeline
@onready var _hint_label: Label = %HintLabel
@onready var _complete_overlay: Control = %CompleteOverlay


func _ready() -> void:
	_level_label.text = UIText.LEVEL_TITLE
	_key_hints.text = UIText.T01_KEYS
	_echo_label.text = UIText.echo_count_text(0)
	%CompleteText.text = UIText.T07_COMPLETE
	%CompleteTitle.text = UIText.T07_TITLE
	%ReplayHint.text = UIText.T07_REPLAY
	_timeline.max_value = RECORD_MAX
	_timeline.show_percentage = false
	_set_timeline_state("idle")
	_hint_label.visible = false
	_complete_overlay.visible = false
	GameEvents.recording_started.connect(_on_recording_started)
	GameEvents.recording_stopped.connect(_on_recording_stopped)
	GameEvents.echo_spawned.connect(_on_echo_changed)
	GameEvents.echo_deleted.connect(_on_echo_changed)
	GameEvents.echo_count_changed.connect(_on_echo_count_changed)
	GameEvents.notify_requested.connect(show_hint)
	GameEvents.echo_playback_started.connect(_on_playback_started)
	GameEvents.echo_playback_stopped.connect(_on_playback_stopped)
	GameEvents.level_completed.connect(_on_level_completed)
	GameEvents.restart_requested.connect(_on_restart)


func _process(delta: float) -> void:
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			_hint_label.visible = false
	if _recording:
		_record_elapsed = minf(_record_elapsed + delta, RECORD_MAX)
		_timeline.value = _record_elapsed
	elif _playback_total > 0.0:
		_playback_elapsed += delta
		_timeline.value = maxf(_playback_total - _playback_elapsed, 0.0)


func show_hint(text: String) -> void:
	_hint_label.text = text
	_hint_label.visible = true
	_hint_timer = UIText.HINT_SECONDS


func _unhandled_input(event: InputEvent) -> void:
	if _complete and event is InputEventKey and event.pressed:
		_complete = false
		GameEvents.restart_requested.emit()
		get_viewport().set_input_as_handled()


func _set_timeline_state(state: String) -> void:
	match state:
		"recording":
			_timeline.modulate = Color(0.957, 0.827, 0.369, 1.0)  # 黄:填充
		"playback":
			_timeline.modulate = Color(0.271, 0.851, 0.949, 1.0)  # 青:回放
		_:
			_timeline.modulate = Color(1, 1, 1, 0.25)  # 暗:普通


func _on_recording_started() -> void:
	_recording = true
	_record_elapsed = 0.0
	_set_timeline_state("recording")


func _on_recording_stopped(duration: float) -> void:
	_recording = false
	_timeline.value = 0.0
	_set_timeline_state("idle")
	if duration > 0.0:
		show_hint(UIText.T05_RECORDED)


func _on_echo_changed(_id: int) -> void:
	pass  # 计数经 echo_count_changed 更新


func _on_echo_count_changed(count: int) -> void:
	_echo_label.text = UIText.echo_count_text(count)


func _on_playback_started(duration: float) -> void:
	_playback_total = duration
	_playback_elapsed = 0.0
	_timeline.max_value = duration
	_timeline.value = duration
	_set_timeline_state("playback")


func _on_playback_stopped() -> void:
	_playback_total = 0.0
	_timeline.value = 0.0
	_set_timeline_state("idle")


func _on_level_completed(_level_id: int) -> void:
	_complete = true
	_complete_overlay.visible = true


func _on_restart() -> void:
	_complete = false
	_complete_overlay.visible = false
	_hint_label.visible = false
	_echo_label.text = UIText.echo_count_text(0)
	_timeline.value = 0.0
	_set_timeline_state("idle")
