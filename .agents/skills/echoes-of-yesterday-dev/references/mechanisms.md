# mechanisms —— 机关系统

> 实现:`scripts/interaction/` + `scenes/mechanisms/`;规范:docs/02 §7。核心原则:**玩家与回声是同等触发者**(都进 `echo_trigger` 组,机关 Area 只认组不认类型)。

## 机关契约(新增任何机关必须完整实现)

| 项 | 要求 |
| --- | --- |
| 根类型 | 玩家可踩/触碰类用 `Area2D`;阻挡类用 `StaticBody2D`(+可选 Area 检测) |
| 分组 | 根节点加入 `mechanism` 组——关卡重置按组遍历调用 `force_reset()`,漏组=重置死角 |
| 碰撞 | Area:`collision_layer = 8`(trigger)、`collision_mask = 6`(player+echo);实体阻挡部分用 `StaticBody2D` + 脚印菱形 `ConvexPolygonShape2D`(docs/isometric.md) |
| 触发身份 | 检测 `body.is_in_group("echo_trigger")`,禁止 `body is PlayerController` 判型——回声必须同等生效 |
| 重置 | 必须实现 `force_reset()`:清内部状态、复位视觉;关卡重置按组遍历调用(docs/02 §8.2) |
| 反馈 | 状态变化走视觉(modulate/位移动画)+ 可选音效占位 |
| 文案 | 面向玩家的文字只经 `GameEvents.notify_requested(UIText.xxx)` |
| 信号 | 命名过去式:`switch_activated` / `switch_deactivated` / `opened` / `closed` / `player_entered` |

## 现有机关(复用而非重写)

| 机关 | 场景 | 关键接口 | 要点 |
| --- | --- | --- | --- |
| PressureSwitch | `PressureSwitch.tscn` | `switch_activated/-deactivated`、`is_active()`、`force_reset()` | 清单制激活(非计数,防漏计);激活变黄+下沉 2px |
| SecurityDoor | `SecurityDoor.tscn` | `set_open(bool)`、`is_open()`、`force_reset()` | Blocker 菱形随开关禁用;`DoorHole` 防夹(关门请求时门洞有实体则等清空);面板开 PANEL_CLOSED_Y−34 |
| TimeRecorderDevice | `TimeRecorderDevice.tscn` | proximity 56 触发 T-03(once)、`force_reset()` 重武装 | 含 Solid 脚印碰撞(实心立方体) |
| ExitArea | `ExitArea.tscn` | `player_entered`(mask=2 仅玩家) | 通关判定入口,旋转矩形覆盖多格;**单格出口须用 44×20 触发区**(128×32 会泄漏邻格——L6 北走廊事故;且实例内部子节点修改 pack() 不记录,须手搭节点) |
| TimeLockSwitch | `TimeLockSwitch.tscn` | `arm()/disarm()`、`is_active()`(=窗口开启)、`has_visitor()`、`force_reset()` | 踩上激活 10s 倒计时,到期自动释放(E-31);重踩须先离开(E-32);最后 3s 闪烁;`proximity_hint_text` 可覆写(L6 用 T-61) |
| **InterferenceField**(L4) | `InterferenceField.tscn` | `add_cell(world_pos)`(构建脚本逐格注入)、`echo_dissolved(echo)` / `player_entered(body)`、`force_reset()` | 恒定危害区:回声回放位置进入**格心判定圆 r8** 即消散(消散执行归 EchoManager,机关只发信号);玩家踏入仅触发预警;视觉=全格暗红覆格脉动;场景无形状,全部运行时注入 |
| **PulsePad**(L4) | `PulsePad.tscn` | 继承 PressureSwitch 全部;覆写 `is_active()`(=固定窗内) | 任何 echo_trigger 实体进入即激活,**0.5s 后强制释放**(停留无效、不可延长、无冷却,E-46);离开不提前释放;视觉青色系(#45D9F2 快闪),与压力开关区分 |
| **EnergyCore**(L5) | `EnergyCore.tscn` | `toggle()` / `set_on(bool)` / `is_on`、`core_toggled(on)`、`player_nearby`、`force_reset()`;入 `interactable` 组 | E 交互 toggle(PlayerController 采样 + 回声 events 重放调用,**同效**);`auto_off_seconds`(0=持续,>0 到期自动回 OFF);proximity 仅发 player_nearby(教学提示归关卡层) |
| **ToggleBarrier**(L5) | `ToggleBarrier.tscn` | `set_raised(bool)` / `is_raised`、`has_echo_on()`、`force_reset()` | 升降桥/墙:升起=脚印阻挡;**升起前格内有 echo_trigger 实体则延迟**(防夹,E-59);回声不与当下环境解算(可穿,E-51) |
| **RecordingZone**(L4—L6) | `RecordingZone.tscn` | 无接口(mask=2,自动维护 `PlayerController.in_recording_zone`) | 初始记录区:记录只能从区内开始(docs/13 §5.1);L1—L3 无区域默认不受限 |

**L5 事件链注意**:录制中的 E 交互**真实生效**(E-57)且写入当前帧 `events`;回声重放该帧时再次 `toggle()`——持续型核心会被"录制拨动+重放再拨动"抵消(E-55 历史重演),谜题设计须规避(L5 用 auto_off 化解,L6 标准解由玩家亲自拨)。

## 操作示例:新增"第二个压力开关"

1. **不新建脚本**——复用 `scenes/mechanisms/PressureSwitch.tscn`,在关卡构建脚本里再实例化一份,放到目标格位(`floor_layer.map_to_local(cell)`)。
2. **连线决定行为**:门支持多开关计数(`SecurityDoor` 内部计数)——第二开关也连 `set_open` 时,任一激活即开;需要"全部踩住才开"的与逻辑,在 LevelManager 里聚合两个开关信号后再调 `set_open`(docs/02 §7:条件组合归关卡层,机关只收最终布尔)。
3. 加入 `mechanism` 组(场景已带);确认关卡重置会覆盖到它(重置按组遍历 + `force_reset`)。
4. 若第二开关需要不同反馈文案,加 `UIText` 常量,禁止内联。
5. 跑 `tools/regression_m5.gd` + 冒烟验证新开关与回声触发(TC-03/04/13 等价用例)。

**反例(禁止)**:新建 `MySwitch.gd` 自己写 body_entered/状态/信号命名/重置逻辑——这就是"重新设计一套开关系统"。
