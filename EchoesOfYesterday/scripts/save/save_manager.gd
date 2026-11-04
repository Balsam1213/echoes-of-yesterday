extends Node
## 存档(FR-014):自动保存解锁关卡进度;user://save.json(docs/02 §9)。
## demo 仅保存解锁关卡列表;不保存逐帧记录数据(02 §9)。

const SAVE_PATH := "user://save.json"

var unlocked_levels: Array[int] = []


func _ready() -> void:
	load_save()


func is_level_unlocked(id: int) -> bool:
	return id in unlocked_levels


func mark_level_completed(id: int) -> void:
	if id in unlocked_levels:
		return
	unlocked_levels.append(id)
	save()


func load_save() -> void:
	unlocked_levels.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) == TYPE_DICTIONARY and data.has("unlocked_levels"):
		for id: Variant in data["unlocked_levels"]:
			unlocked_levels.append(int(id))


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("存档写入失败:%s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify({"unlocked_levels": unlocked_levels}))
