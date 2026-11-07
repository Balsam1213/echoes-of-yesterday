class_name PhaseGate
extends StaticBody2D
## 相位门(L7,docs/18):实验室相位封锁——实体玩家不可过,时间回声可穿
## (回声逐帧赋位回放无视当下环境,docs/02 §6;E-51 显性化为可读规则)。
## 机关本体无智能:对外仅 set_phased(bool)(True=密封/False=落下),联动由
## 关卡层订阅 core_toggled 驱动(L5 ToggleBarrier 接线先例,docs/18 §4 决策记录);
## 无需新碰撞层——密封/落下只切换本门 Blocker,回声恒可穿(E-75)。

signal phase_dropped          # 密封 → 落下(E-76)
signal player_nearby          # 首次贴近(教学提示钩子 T-71,force_reset 重武装)

const GATE_COLOR_UP := Color(0.608, 0.42, 0.851, 0.72)    # 密封:紫半透明屏障
const GATE_COLOR_DOWN := Color(0.608, 0.42, 0.851, 0.10)  # 落下:残影

var _phased := true
var _hint_shown := false

@onready var _blocker: CollisionShape2D = %Blocker
@onready var _panel: Sprite2D = %Panel
@onready var _proximity: Area2D = %Proximity


func _ready() -> void:
	add_to_group("mechanism")
	_proximity.body_entered.connect(_on_proximity_entered)
	_apply()


func is_phased() -> bool:
	return _phased


func set_phased(phased: bool) -> void:
	if _phased == phased:
		return
	_phased = phased
	_apply()
	if not phased:
		phase_dropped.emit()


func force_reset() -> void:
	## 关卡重置:复位为密封初始态并重武装教学(E-76);核心复封由关卡层随后驱动
	_phased = true
	_hint_shown = false
	_apply()


func _on_proximity_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _hint_shown:
		_hint_shown = true
		player_nearby.emit()


## 状态落地:Blocker 切换 + 屏障透明度(set_deferred 防物理回调中改形状,SecurityDoor 同款)
func _apply() -> void:
	_blocker.set_deferred("disabled", not _phased)
	_panel.modulate = GATE_COLOR_UP if _phased else GATE_COLOR_DOWN
