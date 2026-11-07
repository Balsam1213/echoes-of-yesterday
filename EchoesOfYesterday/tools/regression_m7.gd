extends SceneTree
## M7 回归套件:第三章新机关核心用例(docs/08 §6 第三章基线,TC-86 起)。
## 覆盖:TC-89/90 悖论双向消散(E-78)/ TC-91 多回声全消散 / TC-92 回声彼此同场不触发
## (E-73)/ TC-93 X 删除腾位(E-77)/ TC-86/87 相位门双态与回声恒穿(E-75/76)/
## TC-96 重置复位 / TC-99 断电窗自动复电(E-82)。
## 运行:godot --path . -s tools/regression_m7.gd(窗口模式,约 90 秒)

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
	await _test_paradox_directions()
	await _test_paradox_multi()
	await _test_delete_clears()
	await _test_phase_gate()
	await _test_power_window()
	print("REGRESSION M7 RESULT: ", "ALL PASS" if _fails == 0 else "%d FAILS" % _fails)
	quit(1 if _fails > 0 else 0)


## 录入悖论区的短路线((2,9)→(8,7)),回声 parks P1 内
func _record_into_p1(player: Node2D) -> void:
	await _tap("record_toggle")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(2, 10))
	await _cell_walk(player, Vector2i(2, 10), Vector2i(8, 10))
	await _cell_walk(player, Vector2i(8, 10), Vector2i(8, 6))
	await _frames(8)
	await _tap("record_toggle")  # 完成回原位(R2)


## TC-90 + TC-89(L7):悖论判定双向——回声先入区玩家后进 / 玩家先在区回声后进(E-78)
func _test_paradox_directions() -> void:
	var scene := await _load("res://scenes/levels/Level_07.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var mgr: Node = scene.get_node("EchoManager")
	var sw2: Area2D = scene.get_node("YSorted/Switch2")
	# 方向一(TC-90):回声先 parks P1 → 玩家进区 → 消散
	await _record_into_p1(player)
	await _tap("play_echo")
	for i in 500:
		if sw2.is_active():
			break  # 回声已停进 P1(S2=(8,7) 在区内)
		await physics_frame
	_check("TC-90a", mgr.echo_count() == 1 and sw2.is_active(), "echo parked inside P1, count=%d" % mgr.echo_count())
	await _cell_walk(player, Vector2i(2, 9), Vector2i(8, 9))
	await _cell_walk(player, Vector2i(8, 9), Vector2i(8, 8))
	await _cell_walk(player, Vector2i(8, 8), Vector2i(8, 7))
	await _frames(10)
	_check("TC-90b", mgr.echo_count() == 0, "player entered field with echo inside -> dissolved, count=%d" % mgr.echo_count())
	await _cell_walk(player, Vector2i(8, 7), Vector2i(2, 9))
	# 方向二(TC-89):玩家先在区内 → 回声后进区 → 消散
	await _record_into_p1(player)
	await _cell_walk(player, Vector2i(2, 9), Vector2i(8, 9))
	await _cell_walk(player, Vector2i(8, 9), Vector2i(8, 8))
	await _cell_walk(player, Vector2i(8, 8), Vector2i(8, 7))  # 玩家先站进 P1
	await _tap("play_echo")
	for i in 500:
		if mgr.echo_count() == 0:
			break  # 回声进区即消散
		await physics_frame
	_check("TC-89", mgr.echo_count() == 0, "echo entered field with player inside -> dissolved, count=%d" % mgr.echo_count())
	scene.queue_free()
	await _frames(2)


## TC-92 + TC-91(L7):回声彼此同场不触发(E-73);玩家进入 → 区内全部消散(E-71)
func _test_paradox_multi() -> void:
	var scene := await _load("res://scenes/levels/Level_07.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var mgr: Node = scene.get_node("EchoManager")
	var sw2: Area2D = scene.get_node("YSorted/Switch2")
	await _record_into_p1(player)
	await _tap("play_echo")
	await _frames(4)
	await _tap("play_echo")  # 两条回声同路线先后发射
	for i in 500:
		if sw2.is_active():
			break  # 回声已停进 P1
		await physics_frame
	await _frames(10)
	_check("TC-92a", mgr.echo_count() == 2 and sw2.is_active(), "two echoes coexist in P1 (echo-echo no trigger), count=%d" % mgr.echo_count())
	await _cell_walk(player, Vector2i(2, 9), Vector2i(8, 9))
	await _cell_walk(player, Vector2i(8, 9), Vector2i(8, 8))
	await _frames(60)  # 玩家在区外(P1 南邻)静置——不触发
	_check("TC-92b", mgr.echo_count() == 2, "player outside field, no trigger, count=%d" % mgr.echo_count())
	await _cell_walk(player, Vector2i(8, 8), Vector2i(8, 7))
	await _frames(10)
	_check("TC-91", mgr.echo_count() == 0, "player entered -> ALL echoes dissolved, count=%d" % mgr.echo_count())
	scene.queue_free()
	await _frames(2)


## TC-93(L7):X 删除腾位——删除区内回声后玩家可入区,S2 释放(E-77)
func _test_delete_clears() -> void:
	var scene := await _load("res://scenes/levels/Level_07.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var mgr: Node = scene.get_node("EchoManager")
	var sw2: Area2D = scene.get_node("YSorted/Switch2")
	await _record_into_p1(player)
	await _tap("play_echo")
	for i in 500:
		if sw2.is_active():
			break
		await physics_frame
	_check("TC-93a", mgr.echo_count() == 1 and sw2.is_active(), "echo parks S2 inside P1, count=%d" % mgr.echo_count())
	await _tap("delete_echo")
	await _frames(6)
	_check("TC-93b", mgr.echo_count() == 0 and not sw2.is_active(), "X deletes -> S2 released")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(8, 9))
	await _cell_walk(player, Vector2i(8, 9), Vector2i(8, 8))
	await _cell_walk(player, Vector2i(8, 8), Vector2i(8, 7))
	await _frames(10)
	_check("TC-93c", mgr.echo_count() == 0, "player re-enters cleared field: no dissolve, count=%d" % mgr.echo_count())
	scene.queue_free()
	await _frames(2)


## TC-86/87 + TC-96(L7):相位门双态(实体阻挡/落下通行)、回声恒穿密封门、重置复位
func _test_phase_gate() -> void:
	var scene := await _load("res://scenes/levels/Level_07.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var mgr: Node = scene.get_node("EchoManager")
	var core: Area2D = scene.get_node("YSorted/Core")
	var gate: StaticBody2D = scene.get_node("YSorted/PhaseGate")
	var sw1: Area2D = scene.get_node("YSorted/Switch1")
	_check("TC-86a", gate.call("is_phased") and core.get("is_on"), "initial: core ON -> gate sealed (manager-driven)")
	# 实体阻挡:玩家从 (11,8) 顶门,无法到达门后格 (12,7)
	await _cell_walk(player, Vector2i(2, 9), Vector2i(2, 10))
	await _cell_walk(player, Vector2i(2, 10), Vector2i(10, 10))
	await _cell_walk(player, Vector2i(10, 10), Vector2i(10, 9))
	await _cell_walk(player, Vector2i(10, 9), Vector2i(10, 8))
	await _cell_walk(player, Vector2i(10, 8), Vector2i(11, 8))
	await _walk_to(player, _cw(11, 7))
	await _frames(6)
	var past := player.global_position.distance_to(_cw(12, 7))
	_check("TC-86b", past > 16.0, "player blocked by sealed gate, dist to (12,7)=%.1f" % past)
	# 拨核心 → 门落 → 玩家可穿
	await _cell_walk(player, Vector2i(11, 8), Vector2i(10, 8))
	await _cell_walk(player, Vector2i(10, 8), Vector2i(10, 10))
	await _cell_walk(player, Vector2i(10, 10), Vector2i(6, 10))
	await _cell_walk(player, Vector2i(6, 10), Vector2i(6, 9))
	await _frames(8)
	await _tap("interact")
	await _frames(6)
	_check("TC-87a", not core.get("is_on") and not gate.call("is_phased"), "core OFF -> gate dropped")
	await _cell_walk(player, Vector2i(6, 9), Vector2i(6, 10))
	await _cell_walk(player, Vector2i(6, 10), Vector2i(2, 10))
	await _cell_walk(player, Vector2i(2, 10), Vector2i(2, 9))
	# 录「穿门进东室」路线 → 复封核心 → 回声穿**密封**门(E-75)
	await _tap("record_toggle")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(2, 10))
	await _cell_walk(player, Vector2i(2, 10), Vector2i(10, 10))
	await _cell_walk(player, Vector2i(10, 10), Vector2i(10, 9))
	await _cell_walk(player, Vector2i(10, 9), Vector2i(10, 8))
	await _cell_walk(player, Vector2i(10, 8), Vector2i(11, 8))
	await _cell_walk(player, Vector2i(11, 8), Vector2i(11, 7))
	await _cell_walk(player, Vector2i(11, 7), Vector2i(14, 7))
	await _frames(8)
	await _tap("record_toggle")
	await _cell_walk(player, Vector2i(2, 9), Vector2i(2, 10))
	await _cell_walk(player, Vector2i(2, 10), Vector2i(6, 10))
	await _cell_walk(player, Vector2i(6, 10), Vector2i(6, 9))
	await _frames(8)
	await _tap("interact")  # 复封 C1 ON
	await _frames(6)
	_check("TC-87b", gate.call("is_phased"), "core re-sealed -> gate phased again (E-76)")
	await _tap("play_echo")
	for i in 900:
		if sw1.is_active():
			break
		await physics_frame
	_check("TC-87c", sw1.is_active(), "echo passed SEALED gate and parks S1 (E-75)")
	# 重置:E-76 复位 C1 ON + 门密封 + 回声清空(TC-96)
	await _tap("reset_room")
	await _frames(10)
	_check("TC-96", core.get("is_on") and gate.call("is_phased") and mgr.echo_count() == 0 \
			and not sw1.is_active(), "reset: core ON / gate sealed / echoes cleared / S1 released")
	scene.queue_free()
	await _frames(2)


## TC-99(L8):断电窗 10s 自动复电(G1 随动复封);计时期再拨取消计时(E-82)
func _test_power_window() -> void:
	var scene := await _load("res://scenes/levels/Level_08.tscn")
	var player: Node2D = scene.get_node("YSorted/Player")
	var core: Area2D = scene.get_node("YSorted/Core")
	var gate: StaticBody2D = scene.get_node("YSorted/PhaseGate")
	await _cell_walk(player, Vector2i(2, 11), Vector2i(6, 11))
	await _cell_walk(player, Vector2i(6, 11), Vector2i(6, 9))
	await _cell_walk(player, Vector2i(6, 9), Vector2i(6, 8))
	await _cell_walk(player, Vector2i(6, 8), Vector2i(6, 4))  # 入海拨核(四邻全在区内)
	await _frames(8)
	await _tap("interact")
	await _frames(6)
	_check("TC-99a", not core.get("is_on") and not gate.call("is_phased"), "core OFF -> gate dropped, window starts")
	await _frames(620)  # 10.3s > 10s 窗
	_check("TC-99b", core.get("is_on") and gate.call("is_phased"), "auto-repower after 10s (E-82)")
	# 计时期内再拨 = 取消计时:OFF→立即 ON,等 11s 仍 ON
	await _tap("interact")
	await _frames(4)
	await _tap("interact")
	await _frames(6)
	_check("TC-99c", core.get("is_on"), "re-toggle cancels window (back ON immediately)")
	await _frames(660)
	_check("TC-99d", core.get("is_on"), "still ON after 11s (timer cancelled)")
	scene.queue_free()
	await _frames(2)
