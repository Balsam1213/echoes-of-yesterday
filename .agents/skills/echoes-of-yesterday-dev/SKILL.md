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
当前进度:**全三章(第 1—8 关)已交付**(tag `chapter1-v0.2` / `chapter2-v0.1` / `chapter3-v0.1`,Windows 运行包 v0.4,完整 Demo 收官)。
第一章(第 1—3 关):回声上限 1/2/3、压力开关/安全门/时间锁;第二章(第 4—6 关):干扰场/脉冲板/能量核心/联动桥/序列门 + 初始记录区 + 关卡选择菜单;第三章(第 7—8 关,docs/17—19):悖论区/相位门 + 时空在场调度(全游戏 8 关收官)。
仓库布局:`docs/`(上位文档 00—19)、`logs/`(devlog/changelog/issues)、`EchoesOfYesterday/`(Godot 工程)、`tools/`(构建与测试脚本)。

本技能是**操作入口**;`docs/00—19` 是上位文档,冲突时以 docs 为准(docs/00 §2.4)。

## 硬规则(每条都有一次返修教训,违反即返修)

1. **记录与回放只由 60Hz 物理帧驱动**(`_physics_process`):显示帧率不受控,驱动错误破坏复现一致性(NFR-02)。
2. **等距 TileSet 必须显式 `tile_layout = TILE_LAYOUT_DIAMOND_DOWN`**:引擎默认 STACKED,坐标数学会全错。
3. **立起物贴图偏移用 `Sprite2D.offset`,禁止烘进 `position`**:position 是 Y-sort 与逻辑的唯一锚点,烘进去墙会"躺倒穿模"。
4. **立起物碰撞 = 脚印菱形** `ConvexPolygonShape2D`,points `(0,-16, 32,0, 0,16, -32,0)`:小矩形近似会导致"踩进方块才被挡"。
5. **构建脚本的 owner 只赋无主节点**(`child.owner == null` 才赋):给实例子场景内部节点赋 owner 会产生静态影子副本——渲染与脚本节点并存、玩家看到"假机关"(M2 事故)。**实例场景内部子节点的属性修改 pack() 同样不记录**——需覆盖时改用手搭节点(出口区教训)。
6. **`-s` 工具脚本编译期禁止引用游戏类**(类型标注也会拉起依赖链):autoload 在 -s 编译期不可见;一律 `load()` + 动态访问(docs/03 §1)。
7. **角色/回声碰撞圆半径 6**(圆心 `(0,-6)`,底点=脚底原点):r9 过不了 1 格门洞的菱形通道。
8. **跨场景通信只走 GameEvents 总线**;玩家可见文案只出自 `scripts/ui/ui_text.gd`,禁止散落硬编码。
9. **改核心机制(记录/回声/机关/关卡流程)后必跑回归与冒烟**(命令见 references/testing.md),并确认日志无 `SCRIPT ERROR` 与 `Error calling from signal`。
10. **每次任务收尾写 `logs/devlog.md`**(完成/问题与决定/下一步):每条规则背后都有一次返修,教训必须入册防二犯。
11. **记录只能从初始记录区开始(L4—L6),记录完成回到记录起点**(docs/13 §5.1):回声一律从出生区出发,杜绝"远端起录"跳过回声旅程;L1—L3 无区域默认不受限。
12. **干扰场判定圈 = 格心圆 r8**(视觉全格覆格):等距竖向邻格 (x,y±1) 世界距离仅 32px,回声圆心距邻格场心最近 26px——任何格心判定半径都按此口径算,贴行车道(r8 裕量 ≥11px)绝不误伤。
13. **出口门必须正对出口且不占回声必经渡口**(L6 返修:门挪开一格即被绕过);动门位前先验证回声跨区连通性。
14. **冒烟铁律**:推进链必须断言到 `current_scene` 变化;长路线录制**持键连续走位**(逐帧 press/release 速度减半,会超 30s 记录上限),轴向死区 4px 防顶墙;常规走位用**逐格中心链**(相邻格心方向恰为等距轴,屏幕 45° 对角会切角穿判定区);`.tscn` 根节点脚本变量属性排在 `script = ...` 行**之后**。
15. **危害/悖论覆层先于 Decals 注入**(Floor → 覆层 → Decals → YSorted):覆层是「地面着色」,开关底座/出生标记等贴花恒在其上——反序会把区内的开关完全盖住(L7 返修:P1 内 S2 不可见)。**底座/开关类贴图挂 YSorted**(正确参与遮挡,Decals 恒被墙体精灵覆盖),摆放前先算目标格的「遮挡锥」(南东南 2 格墙精灵覆盖矩形的并集,L7 返修 2:S1 被 (15,8)∪(16,7) 完全遮住)。
16. **测试脚本对 `user://save.json` 备份/还原**(开跑备份 → 隔离断言 → 收尾还原):测试直接写存档会污染开发机——「第八关未玩先解锁、第一关反而灰置」即源于此;菜单另有保底:**第一关恒可选**。

## 模块索引(按需读分册,不要全读)

| 任务涉及 | 读这个 | 内容 |
| --- | --- | --- |
| 项目结构、新文件放哪、节点通信 | [references/architecture.md](references/architecture.md) | 目录、场景组织、碰撞层/分组、信号总线 |
| 等距地图、Y-sort、碰撞形状 | [references/isometric.md](references/isometric.md) | 网格 64×32、坐标公式、Y-sort 锚点、脚印菱形、32px 邻格口径 |
| 玩家移动/动画/重置/记录区标志 | [references/player.md](references/player.md) | 移动、碰撞、动画三态、reset_to、in_recording_zone、E 交互 |
| 时间记录 | [references/recording.md](references/recording.md) | 60Hz 采样、帧结构(含 events)、30s 上限、记录区门控、完成回原位 |
| 回声生成/回放/消散/残影 | [references/echo.md](references/echo.md) | 逐帧回放、末帧停留、上限 3、X 删除、events 重放、干扰消散、轨迹残影 |
| 机关(12 件) | [references/mechanisms.md](references/mechanisms.md) | 契约 + 压力开关/安全门/装置/出口/时间锁/干扰场/脉冲板/能量核心/联动屏障/记录区/悖论区/相位门 |
| 关卡组装/重置/通关/推进 | [references/levels.md](references/levels.md) | build 脚本模式、状态机、重置四步、教学提示链、L4—L8 要点、关卡选择菜单 |
| 测试 | [references/testing.md](references/testing.md) | 回归/冒烟工具、何时必跑、断言写法、走位助手 |
| 命名、GDScript 风格、提交 | [references/code-style.md](references/code-style.md) | 代码规范、禁则、文档联动 |

## 接口速查(简单任务够用;涉及系统内部先读对应分册)

### Autoload
- `GameEvents`(`scripts/core/game_events.gd`):`recording_started` / `recording_stopped(duration)` / `echo_spawned(id)` / `echo_deleted(id)` / `echo_count_changed(count, cap)` / `echo_playback_started(duration)` / `echo_playback_stopped` / `notify_requested(text)` / `level_started(id)` / `level_completed(id)` / `advance_requested` / `level_reset_requested`
- `SaveManager`(`scripts/save/save_manager.gd`):`mark_level_completed(id)` / `is_level_unlocked(id)`;存档 `user://save.json`

### 碰撞层(位值)与分组
| 层 | 位值 | 成员 | mask |
| --- | --- | --- | --- |
| 1 world | 1 | 墙体/门体/装置实体/屏障/核心实体 | — |
| 2 player | 2 | 玩家 | 1 |
| 3 echo | 4 | 回声 | 1 |
| 4 trigger | 8 | 机关与出口 Area | 6(=player+echo) |

分组:`mechanism`(机关)、`echo_trigger`(玩家+回声,机关触发身份)、`echo`(回声)、`player`(玩家)、`interactable`(可 E 交互物,须实现 `toggle()`)。

### 关键契约
- 玩家 `PlayerController`(CharacterBody2D 层2 掩码1,r6 圆,速度 140):字段 `position / direction / anim_state(idle|walk|interact)` 是记录采样来源;公开 `recorder`(TimeRecorder)、`reset_to(pos)`、`in_recording_zone`(记录区标志,默认 true)、`interacted(target)` 信号(E 交互)
- 记录 `TimeRecorder`(Player 子节点 `%TimeRecorder`):`recording`(最近已完成记录)、`is_recording`、`clear_all()` / `discard_buffer()`;**起录门控**(区外按 R 提示不开始)、**完成回原位**;帧结构 `{t, pos, dir, anim, events}`,events 记录 `{type:"interact", target:NodePath}`
- 回声 `EchoController`(层3,逐帧赋位回放、末帧停留、**events 帧重执行 target.toggle()**)+ `EchoManager`(`max_echoes` 逐关配置、`dissolve(echo)` 干扰消散注销、轨迹残影)
- 机关:PressureSwitch / SecurityDoor / TimeRecorderDevice / ExitArea / TimeLockSwitch(倒计时,靠近文案可覆写) / **InterferenceField**(干扰场,格心判定圆 r8) / **PulsePad**(瞬踩 0.5s 固定窗) / **EnergyCore**(E 交互 toggle,auto_off_seconds) / **ToggleBarrier**(升降桥,升起防夹) / **RecordingZone**(初始记录区) / **ParadoxField**(悖论区,玩家∧回声同场→区内回声全消散,E-71) / **PhaseGate**(相位门,set_phased 双态,实体止步回声恒穿,E-75/76)——契约见 [references/mechanisms.md](references/mechanisms.md)
- 关卡:`LevelManagerBase` 基类(`next_scene` 推进链/状态机/重置四步;next_scene 为空=章末→任意键打开关卡选择)→ `Level01…08Manager`;构建脚本 `tools/build_level_01..08.gd`;菜单 `scenes/ui/LevelSelect.tscn`(第一关恒可选)
- 文案:`UIText`(`scripts/ui/ui_text.gd` 静态常量,T-01~T-89 与界面文案)

## 四大工作流

**新增机关** → 先读 [references/mechanisms.md](references/mechanisms.md):复用现有契约(Area2D 层8 掩码6 或按需、`mechanism` 组、`echo_trigger` 组识别、`force_reset()`、脚印菱形、文案走 UIText),禁止另起一套触发系统。
**新增关卡** → 先读 [references/levels.md](references/levels.md):复用 `LevelManagerBase` + `tools/build_level_0X.gd` 构建模式(记录区/出口区手搭注入);每关设置 `max_echoes` 与 `next_scene`;冒烟必须断言推进。
**修改核心机制** → 改完必跑并确认全绿:

```
godot --path EchoesOfYesterday -s tools/regression_m5.gd     # TC-09/16/17/18/19/20/21/47(约 40s)
godot --path EchoesOfYesterday -s tools/regression_m6.gd     # 第二章机关:TC-48/49/61、E-54/55/59(约 60s)
godot --path EchoesOfYesterday -s tools/regression_m7.gd     # 第三章机关:悖论双向消散/多回声/相位门/断电窗(约 90s)
godot --path EchoesOfYesterday -s tools/smoke_screenshot.gd  # L1 全流程通关 + 截图
godot --path EchoesOfYesterday -s tools/smoke_level02.gd     # L2 全流程 + 推进
godot --path EchoesOfYesterday -s tools/smoke_level03.gd     # L3 全流程(时间锁)+ 推进 L4
godot --path EchoesOfYesterday -s tools/smoke_level04.gd     # L4 全流程(干扰/同振)+ 推进 L5
godot --path EchoesOfYesterday -s tools/smoke_level05.gd     # L5 全流程(events/时序)+ 推进 L6
godot --path EchoesOfYesterday -s tools/smoke_level06.gd     # L6 全流程(序列/冲刺)+ 推进 L7
godot --path EchoesOfYesterday -s tools/smoke_level07.gd     # L7 全流程(相位门/悖论/北侧发射)+ 推进 L8
godot --path EchoesOfYesterday -s tools/smoke_level08.gd     # L8 全流程(断电窗冲刺)+ 章末菜单断言
```

**发布运行包(v0.5 起走 CI 自动化)** → 更新 `export_presets.cfg` 版本/描述(**project.godot `config/version` 一并同步**)→ 重写 `distribution/操作说明.txt`(受追踪的唯一源;build/ 被忽略,CI 取不到)→ `git tag chapterX-v0.x && git push --tags` → GitHub Actions `release.yml` 自动「导出→启动冒烟→zip→挂 Release」。本地手工导出仍可用:`godot --headless --path . --export-release "Windows Desktop" "../build/EchoesOfYesterday.exe"` → 启动冒烟(`--headless --quit-after 180`)→ zip。注意:exe 未签名,SmartScreen 提示属正常(操作说明已附放行指引)。CI 细节:`.github/workflows/`(ci.yml = 12 套件并行矩阵;release.yml = tag 自动发布;导出输出须绝对路径 + 预先 mkdir,见 devlog 2026-11-11)。

## 工具链注意

- CLI 调用一律加 `timeout`:`-s` 脚本运行时错误未到 `quit()` 会无限挂起。
- 测试脚本等待用 `await physics_frame`(渲染帧率不受控,process 帧计数会差 3 倍)。
- 手改 .tscn 时,sub_resource 的 id 变更必须同步全部引用;根节点脚本变量属性排在 `script = ...` 之后。
- 输入模拟:轮询类动作用 `Input.action_press`;事件类处理器(`_unhandled_input`)用 `Input.parse_input_event(InputEventAction/Key)`。
- 大地图相机边界由构建脚本 `_camera_limits()` 推算,无需手填。

## 任务收尾

`logs/devlog.md` 追加一条(完成/问题与决定/下一步)→ 有版本可感知变化则更新 `logs/changelog.md` → `git commit`(规范见 [references/code-style.md](references/code-style.md))。
