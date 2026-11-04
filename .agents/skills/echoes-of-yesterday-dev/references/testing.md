# testing —— 测试规范

> 工具:`tools/regression_m5.gd`(回归套件)、`tools/smoke_screenshot.gd`(全流程通关+截图);用例库:docs/08(TC-01~24)。

## 何时必跑

| 改动 | 必跑 |
| --- | --- |
| 核心机制(记录/回声/机关/重置/流程) | `regression_m5.gd` **和** `smoke_screenshot.gd`,两者全绿才算完成 |
| 关卡布局/走位相关 | `smoke_screenshot.gd`(剧本含门洞滑行路线) |
| UI/提示文案 | `smoke_screenshot.gd`(NOTIFY 与界面断言) |
| 任何提交前 | 确认日志无 `SCRIPT ERROR` 与 `Error calling from signal` |

## 运行(窗口模式;CLI 一律加 timeout)

```
timeout 150 godot --path EchoesOfYesterday -s tools/regression_m5.gd
timeout 150 godot --path EchoesOfYesterday -s tools/smoke_screenshot.gd
```
- regression 覆盖 TC-09/16/17/18/19/20/21,输出逐条 `PASS/FAIL` + `REGRESSION RESULT`;
- smoke 走完整通关剧本,状态打印含 `pos/sw/door/echoes/paused`、`NOTIFY`(教学与提示)、`replay done: N frames, max_pos_err`(恒 0.000)、`save_exists`。

## 编写/扩展用例的规则

1. **等待用 `await physics_frame` 计数**——渲染帧率无垂直同步时约 180fps,process 帧计数会让移动量差 3 倍(真实事故)。
2. **输入模拟两条路**:轮询类(`is_action_just_pressed`)用 `Input.action_press/release`;事件类(`_unhandled_input`)用 `Input.parse_input_event(InputEventAction/InputEventKey)`。
3. 断言打状态而非截图:位置/开关/门/回声数可打印;纯视觉(对齐、颜色)用截图 + 像素探针(`Image.load_from_file` + `get_pixel`),并**先算清相机钳位后的世界↔屏幕映射**。
4. 断言失败输出全部带上下文(位置/计数/期望值);FAIL 须登记 `logs/issues.md` 后修复。
5. `-s` 脚本编译期禁止引用游戏类:被测对象用 `scene.get_node(...)` 动态获取;新脚本先跑一次 `--import` 生成 .uid 与全局类缓存。

## 已知边界

- headless `-s` + 帧等待会挂起:测试脚本一律窗口模式 + `timeout`。
- 偶发输入未达 handler(一次记录,同代码连跑三次通过):关键回调断言已可捕获;复现再深挖。
- TC-14(新玩家独立通关)与 60FPS 实测属人工验收,自动化不覆盖。
