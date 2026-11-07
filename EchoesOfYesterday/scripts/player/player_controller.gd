class_name PlayerController
extends CharacterBody2D
## 玩家控制器(T1.2—T1.4):八向移动、朝向、动画状态、跟随镜头。
## 移动为屏幕空间八向自由移动,不做格子吸附(docs/02 §3)。
## 本节点的 position / direction / anim_state 是记录系统(TimeRecorder)的采样来源(docs/02 §5.2),
## 因此输入轮询与状态更新必须保持在 _physics_process(60Hz)内。

const INTERACT_DURATION := 0.4  # 交互动作持续时间(秒)
const INTERACT_RANGE := 56.0    # E 交互作用半径(与机关 proximity 一致,docs/15 §4)

## 有效交互事件(docs/15 §4):E 命中交互物时发出,TimeRecorder 据此写入记录帧 events 字段
signal interacted(target: Node2D)

@export var move_speed: float = 140.0
## 关卡边界(像素,世界坐标);size 为 ZERO 表示不限制。由关卡场景或构建工具设置。
@export var camera_limit_rect: Rect2i = Rect2i()

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _camera: Camera2D = %Camera
@onready var recorder: TimeRecorder = %TimeRecorder

## 朝向:最后一次非零移动方向,单位向量(记录字段 direction)
var direction: Vector2 = Vector2.DOWN
## 动画状态:idle / walk / interact(记录字段 animation_state,合法值见 docs/03 §3.6)
var anim_state: String = "idle"
## 是否处于初始记录区内(RecordingZone 维护;默认 true——L1—L3 无记录区,不受限)
var in_recording_zone := true

var _interact_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")
	add_to_group("echo_trigger")  # 机关触发身份:压力开关/门洞检测均识别此组(docs/03 §4)
	_apply_camera_limits()
	_sprite.play(anim_state)


func _physics_process(delta: float) -> void:
	if _interact_timer > 0.0:
		_interact_timer -= delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()
	if input_dir != Vector2.ZERO:
		direction = input_dir.normalized()

	if Input.is_action_just_pressed("interact"):
		_interact_timer = INTERACT_DURATION
		_try_interact()

	_update_anim_state(input_dir)
	_sprite.play(anim_state)


## 动画状态机:idle / walk / interact(interact 进行中优先)
func _update_anim_state(input_dir: Vector2) -> void:
	if _interact_timer > 0.0:
		anim_state = "interact"
	elif input_dir != Vector2.ZERO:
		anim_state = "walk"
	else:
		anim_state = "idle"


## E 交互:命中交互范围内最近的交互物(interactable 组,须实现 toggle());
## 未命中则只播交互动画、不发事件(E-56 空挥)。交互物真实状态在本帧改变(E-57)。
func _try_interact() -> void:
	var best: Node2D = null
	var best_dist := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		var n := node as Node2D
		if n == null:
			continue
		var dist := global_position.distance_to(n.global_position)
		if dist < best_dist:
			best_dist = dist
			best = n
	if best != null and best.has_method("toggle"):
		best.call("toggle")
		interacted.emit(best)


## 关卡重置:回出生点并复位全部运动/动画状态(docs/02 §8.2 第 3 步)
func reset_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	direction = Vector2.DOWN
	_interact_timer = 0.0
	anim_state = "idle"
	_sprite.play("idle")


func _apply_camera_limits() -> void:
	if camera_limit_rect.size == Vector2i.ZERO:
		return
	_camera.limit_left = camera_limit_rect.position.x
	_camera.limit_top = camera_limit_rect.position.y
	_camera.limit_right = camera_limit_rect.position.x + camera_limit_rect.size.x
	_camera.limit_bottom = camera_limit_rect.position.y + camera_limit_rect.size.y
