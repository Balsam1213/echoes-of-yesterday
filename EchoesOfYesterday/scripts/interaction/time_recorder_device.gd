class_name TimeRecorderDevice
extends Area2D
## 时间记录装置(T4.2):玩家首次靠近时提示记录功能(T-03);重置时重新武装(纯提示,无需终端交互)。

var _hint_shown := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _hint_shown:
		_hint_shown = true
		GameEvents.notify_requested.emit(UIText.T03_DEVICE)


func force_reset() -> void:
	_hint_shown = false

