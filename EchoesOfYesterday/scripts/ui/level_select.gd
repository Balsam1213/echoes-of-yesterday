class_name LevelSelect
extends Control
## 关卡选择菜单(用户验收新增):重玩任意**已通关**关卡;Esc/返回回到来源场景。
## 入口:章节末完成界面任意键(LevelManagerBase)/ 暂停菜单「关卡选择」按钮。
## 未解锁关卡灰置显示,提供进度反馈(docs/08 存档口径:unlocked_levels = 已通关)。

const SELECT_SCENE := "res://scenes/ui/LevelSelect.tscn"
const MAX_LEVEL := 6

## 打开菜单前的场景路径(返回用;空 = 回第一关)
static var previous_scene := ""


func _ready() -> void:
	%Title.text = UIText.SELECT_TITLE
	%Hint.text = UIText.SELECT_HINT
	_build_buttons()


func _build_buttons() -> void:
	for id in range(1, MAX_LEVEL + 1):
		var btn := Button.new()
		var unlocked := SaveManager.is_level_unlocked(id)
		btn.text = UIText.level_title(id) + ("(未通关)" if not unlocked else "")
		btn.disabled = not unlocked
		btn.pressed.connect(_on_level_pressed.bind(id))
		%Buttons.add_child(btn)


func _on_level_pressed(id: int) -> void:
	_go("res://scenes/levels/Level_%02d.tscn" % id)


func _go(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _unhandled_input(event: InputEvent) -> void:
	## Esc 返回来源场景(未设置则回第一关)
	if event.is_action_pressed("pause"):
		_go(previous_scene if previous_scene != "" else "res://scenes/levels/Level_01.tscn")
		get_viewport().set_input_as_handled()
