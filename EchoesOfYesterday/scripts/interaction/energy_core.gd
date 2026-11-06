class_name EnergyCore
extends Area2D
## 能量核心(L5,docs/15):echo_trigger 实体在交互范围内按 E 启动/关闭;
## auto_off_seconds > 0 时到期自动回 OFF(「重复的实验」,E-54)。
## 玩家与回声触发完全同效(E-53):玩家经 PlayerController E 交互调用 toggle(),
## 回声经记录 events 重放调用 toggle()——本机关不区分触发者。
## 视觉为占位表现:机身方块 + 指示灯,ON 亮黄 / OFF 暗灰。

signal core_toggled(on: bool)
signal player_nearby  # 首次靠近(教学提示钩子,force_reset 重武装)

const COLOR_ON := Color(0.957, 0.827, 0.369, 1.0)   # ON:#F4D35E
const COLOR_OFF := Color(0.35, 0.38, 0.42, 1.0)     # OFF:暗灰
const BLINK_FROM := 3.0

## 到期自动回 OFF 的秒数;0 = 持续(不自动熄灭)
@export var auto_off_seconds := 0.0

var is_on := false
var _remaining := 0.0
var _hint_shown := false

@onready var _proximity: Area2D = %Proximity
@onready var _body_sprite: Sprite2D = %Body
@onready var _core_light: Sprite2D = %CoreLight


func _ready() -> void:
	add_to_group("mechanism")
	add_to_group("interactable")
	_proximity.body_entered.connect(_on_proximity_entered)
	_apply_visual()


func is_interactable() -> bool:
	return true


## 玩家(E)与回声(events 重放)统一入口;重复设置同态不重复广播(E-55 语义)
func toggle() -> void:
	set_on(not is_on)


func set_on(on: bool) -> void:
	if is_on == on:
		return
	is_on = on
	if is_on and auto_off_seconds > 0.0:
		_remaining = auto_off_seconds
		GameEvents.notify_requested.emit(UIText.T53_TRIAL % int(ceil(auto_off_seconds)))
	_apply_visual()
	core_toggled.emit(is_on)


func force_reset() -> void:
	is_on = false
	_remaining = 0.0
	_hint_shown = false
	_apply_visual()


func _on_proximity_entered(body: Node2D) -> void:
	## 首次靠近即教学(T-51 由关卡层发,本机关只广播事实)
	if body.is_in_group("player") and not _hint_shown:
		_hint_shown = true
		player_nearby.emit()


func _apply_visual() -> void:
	_body_sprite.modulate = COLOR_ON if is_on else COLOR_OFF
	_core_light.modulate = COLOR_ON if is_on else COLOR_OFF


func _physics_process(delta: float) -> void:
	if not is_on or auto_off_seconds <= 0.0:
		return
	_remaining -= delta
	if _remaining <= BLINK_FROM:
		var lit := fmod(_remaining, 0.5) < 0.25
		_body_sprite.modulate = COLOR_ON if lit else COLOR_OFF
		_core_light.modulate = COLOR_ON if lit else COLOR_OFF
	if _remaining <= 0.0:
		set_on(false)  # 到期自动回 OFF(E-54):门条件经 core_toggled 当刻重估
