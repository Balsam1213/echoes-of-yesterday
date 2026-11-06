class_name EchoManager
extends Node
## 回声管理(T3.4):Space 以最近一条已完成记录生成回声,上限 3,X 删除最新。
## 挂在关卡场景,不写死关卡内容(NFR-04);重置时由关卡流程调用 clear_all()(T4.4 接入)。

const ECHO_SCENE := preload("res://scenes/echo/Echo.tscn")

## 回声上限逐关配置(docs/10 §4):L1=1、L2=2、L3=3,由关卡构建脚本设置
@export var max_echoes := 3
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
	GameEvents.echo_count_changed.emit(0, max_echoes)


func _spawn() -> void:
	if _player == null or _spawn_parent == null:
		return
	if _player.recorder.is_recording:
		return  # 记录未结束按 Space:忽略(E-02)
	var rec := _player.recorder.recording
	if rec == null or rec.frames.is_empty():
		GameEvents.notify_requested.emit(UIText.T_NO_RECORDING)
		return
	if _echoes.size() >= max_echoes:
		GameEvents.notify_requested.emit(UIText.T06_CAP % max_echoes)
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
	GameEvents.echo_count_changed.emit(_echoes.size(), max_echoes)
	GameEvents.echo_playback_started.emit(rec.duration())


func _delete_latest() -> void:
	if _echoes.is_empty():
		return
	var echo: EchoController = _echoes.pop_back()
	_remove_debug_line(echo.echo_id)
	GameEvents.echo_deleted.emit(echo.echo_id)
	GameEvents.echo_count_changed.emit(_echoes.size(), max_echoes)
	echo.queue_free()


## 干扰场消散(L4,docs/14 E-42):与 X 删除同路径的正式注销——计数、信号、残影同步。
## 回声当帧停止回放与触发(E-41),本体做 0.3s 碎裂渐隐后释放。
func dissolve(echo: Node2D) -> void:
	var ec := echo as EchoController
	if ec == null or not _echoes.has(ec):
		return  # 非回声 / 已注销(重复信号)幂等返回
	_echoes.erase(ec)
	ec.playing = false
	ec.set_physics_process(false)
	ec.remove_from_group("echo_trigger")  # 当帧失去机关触发能力(E-41)
	_remove_debug_line(ec.echo_id)
	GameEvents.echo_deleted.emit(ec.echo_id)
	GameEvents.echo_count_changed.emit(_echoes.size(), max_echoes)
	var tween := ec.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ec, "modulate:a", 0.0, 0.3)
	tween.tween_property(ec, "scale", Vector2(1.4, 1.4), 0.3)
	tween.chain().tween_callback(ec.queue_free)


func _on_playback_finished(echo: EchoController) -> void:
	## 轨迹残影(docs/13 支柱 4):回放结束不再删除轨迹线,降透明度保留供玩家复盘;
	## 删除/消散/重置时才清理。回声本体停留在末帧,继续保留机关触发能力(docs/02 §6)
	if _debug_lines.has(echo.echo_id):
		(_debug_lines[echo.echo_id] as Line2D).modulate.a = 0.25
	GameEvents.echo_playback_stopped.emit()


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
