class_name EchoController
extends CharacterBody2D
## 时间回声(T3.2/T3.3):逐物理帧重演记录数据,播完停留在末帧并保留机关触发能力(docs/02 §6)。
## 位置由记录数据直接赋值,不做物理移动解算——记录数据本身来自合法位置(02 §6)。

signal playback_finished(echo: EchoController)

static var _next_id := 1

var echo_id := 0
var recording: EchoRecording
var frame_index := 0
var playing := true

## 调试(T3.5):显示记录轨迹线,回放结束打印最大位置误差
@export var debug_trajectory := false

@onready var _sprite: AnimatedSprite2D = %Sprite

var _max_error := 0.0


func setup(rec: EchoRecording) -> void:
	recording = rec
	echo_id = EchoController._next_id
	EchoController._next_id += 1


func _ready() -> void:
	add_to_group("echo")
	add_to_group("echo_trigger")
	if debug_trajectory:
		_spawn_debug_path()


func _physics_process(_delta: float) -> void:
	if recording == null or not playing:
		return
	if frame_index >= recording.frames.size():
		_finish()
		return
	var f: Dictionary = recording.frames[frame_index]
	global_position = f["pos"]
	_sprite.play(f["anim"])
	if debug_trajectory:
		var err: float = global_position.distance_to(f["pos"])
		_max_error = maxf(_max_error, err)
	frame_index += 1


func _finish() -> void:
	playing = false
	_sprite.play("idle")
	if debug_trajectory:
		print("echo %d replay done: %d frames, max_pos_err=%.3f px" % [echo_id, recording.frames.size(), _max_error])
	playback_finished.emit(self)


## 记录轨迹调试线(T3.5):青色细线叠加记录路径
func _spawn_debug_path() -> void:
	var line := Line2D.new()
	line.name = "DebugPath"
	line.width = 1.0
	line.default_color = Color(0.271, 0.851, 0.949, 0.5)
	for f in recording.frames:
		line.add_point(f["pos"])
	add_child(line)
