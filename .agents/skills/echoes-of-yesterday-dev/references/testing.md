# testing —— 测试规范

> 工具:`tools/regression_m5.gd`(第一章回归)、`tools/regression_m6.gd`(第二章机关回归)、`tools/regression_m7.gd`(第三章机关回归)、`tools/audit_seal_l7.gd`(L7 密封审计)、`tools/smoke_screenshot.gd` + `tools/smoke_level02..08.gd`(全流程通关冒烟);用例库:docs/08 §6(TC-01~113)。
> **CI**:GitHub Actions(`.github/workflows/ci.yml`)在 push/PR 上并行跑全部 12 套件(windows-latest,窗口模式原样可用;输入模拟为引擎层,不依赖窗口焦点);`release.yml` 在 chapter* tag 上自动导出发布。本地与 CI 的判定口径完全一致。

## 何时必跑

| 改动 | 必跑 |
| --- | --- |
| 核心机制(记录/回声/机关/重置/流程) | `regression_m5.gd` + `regression_m6.gd` + 全部冒烟,全绿才算完成 |
| 第二章机关(干扰/脉冲/核心/屏障/记录区) | `regression_m6.gd` + 对应关冒烟 |
| 关卡布局/走位相关 | 对应关冒烟(剧本含门洞滑行路线) |
| UI/提示文案 | `smoke_screenshot.gd`(NOTIFY 与界面断言) |
| 任何提交前 | 确认日志无 `SCRIPT ERROR` 与 `Error calling from signal` |

## 运行(窗口模式;CLI 一律加 timeout)

```
timeout 150 godot --path EchoesOfYesterday -s tools/regression_m5.gd
timeout 150 godot --path EchoesOfYesterday -s tools/regression_m6.gd
timeout 150 godot --path EchoesOfYesterday -s tools/smoke_screenshot.gd
timeout 150 godot --path EchoesOfYesterday -s tools/smoke_level0X.gd
```
- regression_m5 覆盖 TC-09/16/17/18/19/20/21/47;regression_m6 覆盖 TC-48a/b/c、TC-49、TC-61a—d、E-54a/b、E-55、E-59a/b;
- 冒烟走完整通关剧本 + **推进断言**(`current_scene` 变化:L2→L3→…→L6→LevelSelect),状态打印含 `pos/sw/door/echoes`、`NOTIFY`(教学与提示)、`replay done: N frames, max_pos_err`(恒 0.000)。

## 编写/扩展用例的规则

1. **等待用 `await physics_frame` 计数**——渲染帧率无垂直同步时约 180fps,process 帧计数会让移动量差 3 倍(真实事故)。
2. **输入模拟两条路**:轮询类(`is_action_just_pressed`)用 `Input.action_press/release`;事件类(`_unhandled_input`)用 `Input.parse_input_event(InputEventAction/InputEventKey)`。
3. 断言打状态而非截图:位置/开关/门/回声数可打印;纯视觉(对齐、颜色)用截图 + 像素探针(`Image.load_from_file` + `get_pixel`),并**先算清相机钳位后的世界↔屏幕映射**。
4. 断言失败输出全部带上下文(位置/计数/期望值);FAIL 须登记 `logs/issues.md` 后修复。
5. `-s` 脚本编译期禁止引用游戏类:被测对象用 `scene.get_node(...)` 动态获取;新脚本先跑一次 `--import` 生成 .uid 与全局类缓存。

## 走位助手(冒烟教训,直接复用)

- **闭环 `_walk_to(target, tol=2)`**:每帧按实际位置修正方向;tol 2 防停点偏移戳入格心判定区。
- **逐格中心链 `_cell_chain(from, to)` + `_walk_cells`**:相邻格心方向恰为等距轴——屏幕 45° 对角走位会切角斜穿干扰判定区(L4 事故)。
- **持键连续走位 `_walk_chain(points)`**:长路线录制(>20 格)必须全速,逐帧 press/release 速度减半会超 30s 记录上限(L6 事故);**轴向死区 4px**(斜向分量会顶进墙棱无法滑动),到达判定与死区同口径(两轴各 ≤4,防死锁)。
- **多回声剧本"录一条发一条"**:游戏只保留最近一条记录,回声在 spawn 时快照引用(L3 先例);每条回声的发射必须紧跟各自录制(L8 教训:「录两条再发两条」两次都复放第二条路线)。
- **走位路线先查 Solid 格**(装置/核心的脚印碰撞):走位链撞实体会被守卫帧卡死、录制中断(L7 事故:x-first 链穿过 (5,9) 核心)。
- **「回声停上开关」用轮询断言**(`sw.is_active()`),固定帧等待有竞态(录制时长 ≈ 走位时长,边界漂移);开关格位与停放格位必须核对(S2 在 (8,6) 而非 (8,7),L7 事故)。
- **测试对真实存档备份/还原**(硬规则 16):开发机同时是玩家的机器,测试写入 `user://save.json` 会污染菜单解锁状态;**还原必须走统一收尾 `_finish(code)`**(成功/失败路径都走)——失败路径裸 `quit(1)` 跳过还原照样污染(L7 返修 3 事故)。
- **密封/连通性用 BFS 分区审计,不要只靠路线冒烟**:冒烟只验证「预期路线走得通」,路线外的侧绕缺口(lbuild 漏墙)只有可达性审计能发现(L7 返修 3:x10 列墙漏建,→(9,7) 绕过双门;tools/audit_seal_l7.gd 模式:格心 4 邻 BFS + 边中点/目标格心 r6 物理采样,门 Blocker 随极性实时生效,按分区矩形断言可达/不可达)。

## 已知边界

- headless `-s` + 帧等待会挂起:测试脚本一律窗口模式 + `timeout`。
- 偶发输入未达 handler(一次记录,同代码连跑三次通过):关键回调断言已可捕获;复现再深挖。
- TC-14(新玩家独立通关)、首通时长硬指标(第二章 L4≥4/L5≥5/L6≥6 分钟)与 60FPS 实测属人工验收,自动化不覆盖。
