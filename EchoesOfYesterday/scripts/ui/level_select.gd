class_name LevelSelect
extends Control
## 关卡选择菜单:重玩**已通关 ∪ 当前进度关**(返修 2,2026-11-08——玩到 L6 未通关时
## 1—6 均可选,回玩低关不丢进度);Esc/返回回到来源场景。
## 入口:章节末完成界面任意键(LevelManagerBase)/ 暂停菜单「关卡选择」按钮。
## 存档口径:unlocked_levels = 已通关;可选口径见 SaveManager.is_level_selectable。

const SELECT_SCENE := "res://scenes/ui/LevelSelect.tscn"
const MAX_LEVEL := 8

## 打开菜单前的场景路径(返回用;空 = 回第一关)
static var previous_scene := ""


func _ready() -> void:
	%Title.text = UIText.SELECT_TITLE
	%Hint.text = UIText.SELECT_HINT
	_build_buttons()


func _build_buttons() -> void:
	for id in range(1, MAX_LEVEL + 1):
		var btn := Button.new()
		var selectable := SaveManager.is_level_selectable(id)  # 已通关 ∪ 当前进度关(返修 2:回玩低关不丢进度)
		var completed := SaveManager.is_level_unlocked(id)
		btn.text = UIText.level_title(id) + ("(未通关)" if not completed else "")
		btn.disabled = not selectable
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
