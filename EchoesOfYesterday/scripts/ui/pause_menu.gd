extends Control
## 暂停菜单(T4.6):Esc 暂停/继续;重开本关;退出游戏。
## process_mode = ALWAYS:暂停前后都要接收 Esc(docs/04 §4.3)。

func _ready() -> void:
	visible = false
	%Title.text = UIText.PAUSE_TITLE
	%BtnContinue.text = UIText.BTN_CONTINUE
	%BtnRestart.text = UIText.BTN_RESTART
	%BtnSelect.text = UIText.BTN_SELECT
	%BtnQuit.text = UIText.BTN_QUIT
	%BtnContinue.pressed.connect(_toggle)
	%BtnRestart.pressed.connect(_on_restart)
	%BtnSelect.pressed.connect(_on_select)
	%BtnQuit.pressed.connect(_on_quit)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	var tree := get_tree()
	tree.paused = not tree.paused
	visible = tree.paused


func _on_restart() -> void:
	get_tree().paused = false
	visible = false
	GameEvents.level_reset_requested.emit()


func _on_select() -> void:
	## 打开关卡选择菜单(记住来源,Esc 可返回本关)
	get_tree().paused = false
	visible = false
	LevelSelect.previous_scene = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file(LevelSelect.SELECT_SCENE)


func _on_quit() -> void:
	get_tree().quit()
