extends SceneTree
## M6 回归套件:第二章新机关核心用例(docs/08 §6 第二章基线,TC-48 起)。
## 覆盖:TC-48 脉冲板固定窗 / TC-49 消散 / TC-61 events 采集与重放 / E-55 重复回放翻转 /
##       E-54 核心自动失效 / E-59 屏障防夹。
## 运行:godot --path . -s tools/regression_m6.gd(窗口模式,约 60 秒)

var _results: Array[String] = []
var _fails := 0


func _initialize() -> void:
	_run()


func _cw(x: int, y: int) -> Vector2:
	return Vector2((x - y) * 32 + 32, (x + y) * 16 + 16)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)


func _walk_to(player: Node2D, target: Vector2, tol := 2.0) -> void:
	for i in 300:
		var d: Vector2 = target - player.global_position
		if d.length() <= tol:
			break
		Input.action_press("move_right" if d.x > 0 else "move_left")
		Input.action_press("move_down" if d.y > 0 else "move_up")
		await physics_frame
		Input.action_release("move_right")
		Input.action_release("move_left")
		Input.action_release("move_down")
		Input.action_release("move_up")
	Input.action_release("move_right")
	Input.action_release("move_left")
	Input.action_release("move_down")
	Input.action_release("move_up")


func _cell_walk(player: Node2D, from: Vector2i, to: Vector2i) -> void:
	var x := from.x
	var y := from.y
	while x != to.x or y != to.y:
		if x != to.x:
			x += signi(to.x - x)
		elif y != to.y:
			y += signi(to.y - y)
		await _walk_to(player, _cw(x, y))


func _check(id: String, ok: bool, ctx := "") -> void:
	if ok:
		print("PASS ", id, " ", ctx)
	else:
		_fails += 1
		print("FAIL ", id, " ", ctx)


func _load(path: String) -> Node:
	var scene: Node = (load(path) as PackedScene).instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(2)
	return scene


func _run() -> void:
	await _test_pulse_pad()
	await _test_dissolve()
	await _test_events()
	await _test_core_auto_off()
	await _test_barrier_guard()
	print("REGRESSION M6 RESULT: ", "ALL PASS" if _fails == 0 else "%d FAILS" % _fails)
	quit(1 if _fails > 0 else 0)


## TC-48(L4):脉冲板 0.5s 固定窗——踩上激活,持续踩住到期也释放(E-46)
func _test_pulse_pad() -> void:
	var scene := await _load("res://scenes/levels/Level_04.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var pad_b: Area2D = scene.get_node("YSorted/PadB")
	await _cell_walk(player, Vector2i(2, 10), Vector2i(10, 9))
	await _cell_walk(player, Vector2i(10, 9), Vector2i(10, 7))
	await _frames(6)
	_check("TC-48a", pad_b.is_active(), "stepping on pad activates")
	await _frames(40)  # 持续踩住 > 0.5s
	_check("TC-48b", not pad_b.is_active(), "fixed window expires despite standing (E-46)")
	# 走开再踩:无冷却,重新激活
	await _cell_walk(player, Vector2i(10, 7), Vector2i(10, 9))
	await _cell_walk(player, Vector2i(10, 9), Vector2i(10, 7))
	await _frames(6)
	_check("TC-48c", pad_b.is_active(), "re-trigger no cooldown (E-46)")
	scene.queue_free()
	await _frames(2)


## TC-49(L4):贪短记录穿干扰带 → 回声消散,计数 1→0(E-41/42)
func _test_dissolve() -> void:
	var scene := await _load("res://scenes/levels/Level_04.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var mgr: Node = scene.get_node("EchoManager")
	await _tap("record_toggle")
	await _cell_walk(player, Vector2i(2, 10), Vector2i(10, 10))
	await _cell_walk(player, Vector2i(10, 10), Vector2i(10, 5))
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(300)
	_check("TC-49", mgr.echo_count() == 0, "echo dissolved in field, count=%d" % mgr.echo_count())
	scene.queue_free()
	await _frames(2)


## TC-61 + E-55(L5):E 交互写入 events,回声重放执行;重复回放 toggle 翻转
func _test_events() -> void:
	var scene := await _load("res://scenes/levels/Level_05.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var core1: Area2D = scene.get_node("YSorted/Core1")
	var mgr: Node = scene.get_node("EchoManager")
	# 录一段"靠近核心 1 + 按 E"的记录(核心 1 初始 OFF)
	await _cell_walk(player, Vector2i(2, 9), Vector2i(3, 5))
	await _frames(8)
	await _tap("record_toggle")
	await _frames(10)
	await _tap("interact")
	await _frames(10)
	await _tap("record_toggle")
	var rec = player.recorder.recording
	var events := 0
	for f in rec.frames:
		events += (f["events"] as Array).size()
	_check("TC-61a", events == 1, "recording holds 1 interact event, got %d" % events)
	_check("TC-61b", core1.get("is_on"), "real toggle during recording took effect (E-57)")
	# 手动拨回 OFF,再让回声重放同一段历史
	await _tap("interact")
	await _frames(6)
	_check("TC-61c", not core1.get("is_on"), "core1 manually back off before replay")
	await _tap("play_echo")
	await _frames(40)
	_check("TC-61d", core1.get("is_on"), "echo replay toggled core1 ON (E-52)")
	# E-55:重复回放同一条记录 = 历史重演,toggle 翻转
	await _tap("play_echo")
	await _frames(40)
	_check("E-55", not core1.get("is_on"), "second replay flips core1 OFF (history repeats)")
	if mgr.echo_count() != 2:
		print("   note: echo count=", mgr.echo_count())
	scene.queue_free()
	await _frames(2)


## E-54(L5):核心 2 auto_off=8s,到期自动回 OFF
func _test_core_auto_off() -> void:
	var scene := await _load("res://scenes/levels/Level_05.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var core1: Area2D = scene.get_node("YSorted/Core1")
	var core2: Area2D = scene.get_node("YSorted/Core2")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(3, 5))
	await _frames(8)
	await _tap("interact")  # 核心 1 ON → 桥降(否则过不去)
	await _frames(6)
	await _cell_walk(player, Vector2i(3, 5), Vector2i(7, 1))
	await _cell_walk(player, Vector2i(7, 1), Vector2i(9, 1))
	await _cell_walk(player, Vector2i(9, 1), Vector2i(9, 8))
	await _cell_walk(player, Vector2i(9, 8), Vector2i(9, 2))
	await _cell_walk(player, Vector2i(9, 2), Vector2i(13, 2))
	await _cell_walk(player, Vector2i(13, 2), Vector2i(13, 8))
	await _frames(8)
	await _tap("interact")
	await _frames(6)
	_check("E-54a", core2.get("is_on"), "core2 on after E")
	await _frames(540)  # 9s > 8s
	_check("E-54b", not core2.get("is_on"), "core2 auto-off after 8s")
	scene.queue_free()
	await _frames(2)


## E-59(L5):屏障升起前格内有实体 → 延迟至清空(防夹)
## 编排:回声站在桥格上,玩家去核心 1 旁关核心 → 升桥被回声阻挡 → X 删除回声后升桥
func _test_barrier_guard() -> void:
	var scene := await _load("res://scenes/levels/Level_05.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var core1: Area2D = scene.get_node("YSorted/Core1")
	var bridge: StaticBody2D = scene.get_node("YSorted/Bridge")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(3, 5))
	await _frames(8)
	await _tap("interact")  # 核心 1 ON → 桥降
	await _frames(6)
	# 录"走上桥格"→ 回声站上桥
	await _tap("record_toggle")
	await _cell_walk(player, Vector2i(3, 5), Vector2i(7, 1))
	await _cell_walk(player, Vector2i(7, 1), Vector2i(8, 1))
	await _frames(8)
	await _tap("record_toggle")
	await _tap("play_echo")
	await _frames(80)  # 回声走上桥并驻留
	# 玩家走回核心 1 旁关核心(桥升请求被回声阻挡)
	await _cell_walk(player, Vector2i(8, 1), Vector2i(7, 1))
	await _cell_walk(player, Vector2i(7, 1), Vector2i(3, 5))
	await _frames(8)
	await _tap("interact")  # 核心 1 OFF
	await _frames(6)
	_check("E-59a", not bridge.get("is_raised"), "bridge stays lowered while echo occupies cell")
	await _tap("delete_echo")  # X 删除回声 → 格清空 → 升桥
	await _frames(12)
	_check("E-59b", bridge.get("is_raised"), "bridge raises after cell cleared")
	scene.queue_free()
	await _frames(2)
