class_name EchoManager
extends Node
## 回声管理(T3.4):Space 以最近一条已完成记录生成回声,上限 3,X 删除最新。
## 挂在关卡场景,不写死关卡内容(NFR-04);重置时由关卡流程调用 clear_all()(T4.4 接入)。

const MAX_ECHOES := 3
const ECHO_SCENE := preload("res://scenes/echo/Echo.tscn")

@export var debug_trajectory := false
## 回声放入的容器(应为开启 y_sort 的实体层);为空时用父节点的 YSorted 子节点
@export var ysorted_path: NodePath

var _echoes: Array[EchoController] = []
var _debug_lines: Dictionary = {}  # echo_id -> Line2D(轨迹调试线,世界空间)
var _player: PlayerController
var _spawn_parent: Node2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_spawn_parent = get_node_or_null(ysorted_path) if not ysorted_path.is_empty() else get_parent().get_node_or_null("YSorted")


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("play_echo"):
		_spawn()
	elif Input.is_action_just_pressed("delete_echo"):
		_delete_latest()


func echo_count() -> int:
	return _echoes.size()


func clear_all() -> void:
	## 重置房间时清空全部回声与调试线(docs/02 §8.2 第 1 步)
	for echo in _echoes:
		echo.queue_free()
	_echoes.clear()
	for line in _debug_lines.values():
		line.queue_free()
	_debug_lines.clear()


func _spawn() -> void:
	if _player == null or _spawn_parent == null:
		return
	if _player.recorder.is_recording:
		return  # 记录未结束按 Space:忽略(E-02)
	var rec := _player.recorder.recording
	if rec == null or rec.frames.is_empty():
		GameEvents.notify_requested.emit("没有可播放的记录。按 R 先记录一段行动。")
		return
	if _echoes.size() >= MAX_ECHOES:
		GameEvents.notify_requested.emit("回声数量已达上限(3)。按 X 可删除回声。")  # T-06
		return
	var echo: EchoController = ECHO_SCENE.instantiate()
	echo.setup(rec)
	echo.debug_trajectory = debug_trajectory
	_spawn_parent.add_child(echo)
	echo.global_position = rec.start_position()
	echo.playback_finished.connect(_on_playback_finished)
	_echoes.append(echo)
	if debug_trajectory:
		_spawn_debug_line(echo, rec)
	GameEvents.echo_spawned.emit(echo.echo_id)


func _delete_latest() -> void:
	if _echoes.is_empty():
		return
	var echo: EchoController = _echoes.pop_back()
	_remove_debug_line(echo.echo_id)
	GameEvents.echo_deleted.emit(echo.echo_id)
	echo.queue_free()


func _on_playback_finished(echo: EchoController) -> void:
	_remove_debug_line(echo.echo_id)  # 回放结束,轨迹比对完成,调试线即时移除
	# 回声本体停留在末帧,继续保留机关触发能力(docs/02 §6)


## 轨迹调试线(T3.5):画在房间根(世界空间),与记录轨迹逐点重合;禁止挂到回声下(会随回声漂移)
func _spawn_debug_line(echo: EchoController, rec: EchoRecording) -> void:
	var line := Line2D.new()
	line.name = "EchoDebugPath%d" % echo.echo_id
	line.width = 1.0
	line.default_color = Color(0.271, 0.851, 0.949, 0.5)
	for f in rec.frames:
		line.add_point(f["pos"])
	get_parent().add_child(line)
	_debug_lines[echo.echo_id] = line


func _remove_debug_line(echo_id: int) -> void:
	if _debug_lines.has(echo_id):
		_debug_lines[echo_id].queue_free()
		_debug_lines.erase(echo_id)
