class_name RecordingZone
extends Area2D
## 初始记录区(第二章,docs/13 §5.1):时间记录只能从本区域开始——
## 回声永远从初始区域出发,杜绝"走到深处起录"跳过回声旅程的漏洞。
## 玩家进入/离开时维护 PlayerController.in_recording_zone;无本区域的关卡(L1—L3)默认不受限。

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_recording_zone = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_recording_zone = false
