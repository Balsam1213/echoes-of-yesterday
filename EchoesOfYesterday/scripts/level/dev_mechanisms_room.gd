extends Node2D
## dev_mechanisms 测试房装配(T2.3):运行时连接压力开关与安全门。
## PackedScene.pack() 不保存程序化建立的信号连接,故连线由本脚本在 _ready 完成;
## Level_01 的正式连线将由 LevelManager 以同样方式承载(docs/02 §8)。

@onready var _switch: PressureSwitch = %PressureSwitch
@onready var _door: SecurityDoor = %SecurityDoor


func _ready() -> void:
	_switch.switch_activated.connect(_door.set_open.bind(true))
	_switch.switch_deactivated.connect(_door.set_open.bind(false))
