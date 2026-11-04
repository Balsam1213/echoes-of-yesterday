class_name ExitArea
extends Area2D
## 出口触发区(T4.3):仅玩家(mask=2)进入时通关(docs/05 §4)。

signal player_entered


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit()
