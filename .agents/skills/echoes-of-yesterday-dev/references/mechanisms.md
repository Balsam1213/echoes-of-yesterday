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

## 现有四机关(复用而非重写)

| 机关 | 场景 | 关键接口 | 要点 |
| --- | --- | --- | --- |
| PressureSwitch | `PressureSwitch.tscn` | `switch_activated/-deactivated`、`is_active()`、`force_reset()` | 清单制激活(非计数,防漏计);激活变黄+下沉 2px |
| SecurityDoor | `SecurityDoor.tscn` | `set_open(bool)`、`is_open()`、`force_reset()` | Blocker 菱形随开关禁用;`DoorHole` 防夹(关门请求时门洞有实体则等清空);面板开 PANEL_CLOSED_Y−34 |
| TimeRecorderDevice | `TimeRecorderDevice.tscn` | proximity 56 触发 T-03(once)、`force_reset()` 重武装 | 含 Solid 脚印碰撞(实心立方体) |
| ExitArea | `ExitArea.tscn` | `player_entered`(mask=2 仅玩家) | 通关判定入口,旋转矩形覆盖多格 |

## 操作示例:新增"第二个压力开关"

1. **不新建脚本**——复用 `scenes/mechanisms/PressureSwitch.tscn`,在关卡构建脚本里再实例化一份,放到目标格位(`floor_layer.map_to_local(cell)`)。
2. **连线决定行为**:门支持多开关计数(`SecurityDoor` 内部计数)——第二开关也连 `set_open` 时,任一激活即开;需要"全部踩住才开"的与逻辑,在 LevelManager 里聚合两个开关信号后再调 `set_open`(docs/02 §7:条件组合归关卡层,机关只收最终布尔)。
3. 加入 `mechanism` 组(场景已带);确认关卡重置会覆盖到它(重置按组遍历 + `force_reset`)。
4. 若第二开关需要不同反馈文案,加 `UIText` 常量,禁止内联。
5. 跑 `tools/regression_m5.gd` + 冒烟验证新开关与回声触发(TC-03/04/13 等价用例)。

**反例(禁止)**:新建 `MySwitch.gd` 自己写 body_entered/状态/信号命名/重置逻辑——这就是"重新设计一套开关系统"。
