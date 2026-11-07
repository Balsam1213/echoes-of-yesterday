class_name RecordingZone
extends Area2D
## 初始记录区(第二章,docs/13 §5.1):时间记录只能从本区域开始——
## 回声永远从初始区域出发,杜绝"走到深处起录"跳过回声旅程的漏洞。
## 玩家进入/离开时维护 PlayerController.in_recording_zone;无本区域的关卡(L1—L3)默认不受限。
## 视觉:淡青底纹(由构建脚本 setup_visual 注入)让区域在地图上可辨认。

const ZONE_COLOR := Color(0.271, 0.851, 0.949, 0.10)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## 由构建脚本调用:区域淡青底纹(矩形覆盖,纯渲染)
func setup_visual(rect_center: Vector2, rect_size: Vector2) -> void:
	var poly := Polygon2D.new()
	var half := rect_size / 2.0
	poly.polygon = PackedVector2Array([
		rect_center + Vector2(-half.x, -half.y),
		rect_center + Vector2(half.x, -half.y),
		rect_center + Vector2(half.x, half.y),
		rect_center + Vector2(-half.x, half.y),
	])
	poly.color = ZONE_COLOR
	add_child(poly)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_recording_zone = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.in_recording_zone = false
