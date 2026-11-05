---
name: echoes-of-yesterday-dev
description: >
  Use for EVERY Godot development task in the Echoes of Yesterday (《昨日回声》) repo —
  writing or editing any .gd script, .tscn scene, level, mechanism, echo/recording logic,
  UI, or test; adding content such as "第二个压力开关" or new levels; and touching project
  layout, isometric rules, or collision. Enforces this project's architecture, interface
  contracts, isometric conventions, and testing requirements so new work reuses existing
  systems instead of reinventing them.
---

# 《昨日回声》开发规范(echoes-of-yesterday-dev)

Godot 4.x 等距像素解谜游戏,核心机制:**时间记录(R)→ 回声回放(空格)→ 自我协作**。
当前进度:第一章(第 1—3 关)完成——回声上限逐关 1/2/3,含时间锁新机关与关卡推进链。
仓库布局:`docs/`(上位文档 00—12)、`logs/`(devlog/changelog/issues)、`EchoesOfYesterday/`(Godot 工程)、`tools/`(构建与测试脚本)。

本技能是**操作入口**;`docs/00—12` 是上位文档,冲突时以 docs 为准(docs/00 §2.4)。

## 硬规则 Top 10(每条都有一次返修教训,违反即返修)

1. **记录与回放只由 60Hz 物理帧驱动**(`_physics_process`):显示帧率不受控,驱动错误破坏复现一致性(NFR-02)。
2. **等距 TileSet 必须显式 `tile_layout = TILE_LAYOUT_DIAMOND_DOWN`**:引擎默认 STACKED,坐标数学会全错。
3. **立起物贴图偏移用 `Sprite2D.offset`,禁止烘进 `position`**:position 是 Y-sort 与逻辑的唯一锚点,烘进去墙会"躺倒穿模"。
4. **立起物碰撞 = 脚印菱形** `ConvexPolygonShape2D`,points `(0,-16, 32,0, 0,16, -32,0)`:小矩形近似会导致"踩进方块才被挡"。
5. **构建脚本的 owner 只赋无主节点**(`child.owner == null` 才赋):给实例子场景内部节点赋 owner 会产生静态影子副本——渲染与脚本节点并存、玩家看到"假机关"(M2 事故)。
6. **`-s` 工具脚本编译期禁止引用游戏类**(类型标注也会拉起依赖链):autoload 在 -s 编译期不可见;一律 `load()` + 动态访问(docs/03 §1)。
7. **角色/回声碰撞圆半径 6**(圆心 `(0,-6)`,底点=脚底原点):r9 过不了 1 格门洞的菱形通道。
8. **跨场景通信只走 GameEvents 总线**;玩家可见文案只出自 `scripts/ui/ui_text.gd`,禁止散落硬编码。
9. **改核心机制(记录/回声/机关/关卡流程)后必跑回归与冒烟**(命令见 references/testing.md),并确认日志无 `SCRIPT ERROR` 与 `Error calling from signal`。
10. **每次任务收尾写 `logs/devlog.md`**(完成/问题与决定/下一步):每条规则背后都有一次返修,教训必须入册防二犯。

## 模块索引(按需读分册,不要全读)

| 任务涉及 | 读这个 | 内容 |
| --- | --- | --- |
| 项目结构、新文件放哪、节点通信 | [references/architecture.md](references/architecture.md) | 目录、场景组织、碰撞层/分组、信号总线 |
| 等距地图、Y-sort、碰撞形状 | [references/isometric.md](references/isometric.md) | 网格 64×32、坐标公式、Y-sort 锚点、脚印菱形 |
| 玩家移动/动画/重置 | [references/player.md](references/player.md) | 移动、碰撞、动画三态、reset_to |
| 时间记录 | [references/recording.md](references/recording.md) | 60Hz 采样、帧结构、30s 上限、clear_all/discard |
| 回声生成/回放/上限 | [references/echo.md](references/echo.md) | 逐帧回放、末帧停留、上限 3、X 删除、调试线 |
| 机关(开关/门/装置/出口) | [references/mechanisms.md](references/mechanisms.md) | 机关契约 + "新增一个压力开关"完整示例 |
| 关卡组装/重置/通关 | [references/levels.md](references/levels.md) | build 脚本模式、状态机、重置四步、教学提示链 |
| 测试 | [references/testing.md](references/testing.md) | 回归/冒烟工具、何时必跑、断言写法 |
| 命名、GDScript 风格、提交 | [references/code-style.md](references/code-style.md) | 代码规范、禁则、文档联动 |

## 接口速查(简单任务够用;涉及系统内部先读对应分册)

### Autoload
- `GameEvents`(`scripts/core/game_events.gd`):`recording_started` / `recording_stopped(duration)` / `echo_spawned(id)` / `echo_deleted(id)` / `echo_count_changed(count, cap)` / `echo_playback_started(duration)` / `echo_playback_stopped` / `notify_requested(text)` / `level_completed(id)` / `advance_requested` / `level_reset_requested`
- `SaveManager`(`scripts/save/save_manager.gd`):`mark_level_completed(id)` / `is_level_unlocked(id)`;存档 `user://save.json`

### 碰撞层(位值)与分组
| 层 | 位值 | 成员 | mask |
| --- | --- | --- | --- |
| 1 world | 1 | 墙体/门体/装置实体 | — |
| 2 player | 2 | 玩家 | 1 |
| 3 echo | 4 | 回声 | 1 |
| 4 trigger | 8 | 机关与出口 Area | 6(=player+echo) |

分组:`mechanism`(全部机关)、`echo_trigger`(玩家+回声,机关触发身份)、`echo`(回声)、`player`(玩家)。

### 关键契约
- 玩家 `PlayerController`(CharacterBody2D 层2 掩码1,r6 圆,速度 140):字段 `position / direction / anim_state(idle|walk|interact)` 是记录采样来源;公开 `recorder`(TimeRecorder)与 `reset_to(pos)`
- 记录 `TimeRecorder`(Player 子节点 `%TimeRecorder`):`recording`(最近已完成记录)、`is_recording`、`clear_all()` / `discard_buffer()`
- 回声 `EchoController`(层3,逐帧赋位回放、末帧停留)+ `EchoManager`(`max_echoes` 逐关配置 1/2/3:生成/X 删除/调试线,`echo_count()`)
- 机关:`PressureSwitch` / `SecurityDoor` / `TimeRecorderDevice` / `ExitArea` / `TimeLockSwitch`(倒计时自动释放)—— 契约与新增示例见 [references/mechanisms.md](references/mechanisms.md)
- 关卡:`LevelManagerBase` 基类(`next_scene` 推进链/状态机/重置四步)→ `Level01/02/03Manager`;构建脚本 `tools/build_level_XX.gd`
- 文案:`UIText`(`scripts/ui/ui_text.gd` 静态常量,T-01~T-18 与界面文案)

## 三大工作流

**新增机关** → 先读 [references/mechanisms.md](references/mechanisms.md):复用现有契约(Area2D 层4 掩码6、`echo_trigger` 组识别、`force_reset()`、脚印菱形、文案走 UIText),禁止另起一套触发系统。
**新增关卡** → 先读 [references/levels.md](references/levels.md):复用 `LevelManagerBase` + `tools/build_level_XX.gd` 构建模式;每关设置 `max_echoes` 与 `next_scene`。
**修改核心机制** → 改完必跑并确认全绿:

```
godot --path EchoesOfYesterday -s tools/regression_m5.gd     # TC-09/16/17/18/19/20/21(约 40s)
godot --path EchoesOfYesterday -s tools/smoke_screenshot.gd  # L1 全流程通关 + 截图
godot --path EchoesOfYesterday -s tools/smoke_level02.gd     # L2 全流程 + 推进
godot --path EchoesOfYesterday -s tools/smoke_level03.gd     # L3 全流程(时间锁)+ 章节完
```

任何 FAIL、`SCRIPT ERROR`、`Error calling from signal` 都须修复;流程类缺陷登记 `logs/issues.md`。

## 工具链注意

- CLI 调用一律加 `timeout`:`-s` 脚本运行时错误未到 `quit()` 会无限挂起。
- 测试脚本等待用 `await physics_frame`(渲染帧率不受控,process 帧计数会差 3 倍)。
- 手改 .tscn 时,sub_resource 的 id 变更必须同步全部引用。
- 输入模拟:轮询类动作用 `Input.action_press`;事件类处理器(`_unhandled_input`)用 `Input.parse_input_event(InputEventAction/Key)`。

## 任务收尾

`logs/devlog.md` 追加一条(完成/问题与决定/下一步)→ 有版本可感知变化则更新 `logs/changelog.md` → `git commit`(规范见 [references/code-style.md](references/code-style.md))。
