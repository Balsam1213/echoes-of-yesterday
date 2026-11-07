# architecture —— 项目架构

> 硬规则源头:docs/03 §1、docs/02 §2;教训:影子副本(M2)、-s 编译解耦(M3)。

## 目录(仓库根)

```
docs/          00—16 上位文档体系(需求/技术/规范/章节规划/关卡/计划/测试)
logs/          devlog.md(每次任务必写)、changelog.md、issues.md
EchoesOfYesterday/   Godot 工程根
tools/         -s 构建与测试脚本(见 testing.md)
.agents/skills/echoes-of-yesterday-dev/   本技能
```

## 工程内目录(docs/03 §1,新文件必须归位)

| 路径 | 放什么 |
| --- | --- |
| `scenes/{main,player,echo,levels,mechanisms,ui,dev}` | 场景;dev_ 前缀=临时验证 |
| `scripts/{player,echo,recording,interaction,level,save,core}` | 脚本与场景同构;core=autoload |
| `assets/{characters,environment,mechanisms,ui,audio,effects}` | 素材 |
| `data/{levels,settings}` | 关卡配置预留 |
| `tools/` | 构建与测试脚本(见 testing.md) |

## Autoload(仅 2 个,新增须先改 docs/02 §2.2)

| 单例 | 文件 | 职责 |
| --- | --- | --- |
| `GameEvents` | `scripts/core/game_events.gd` | 全局信号总线:recording_started / recording_stopped(duration) / echo_spawned(id) / echo_deleted(id) / echo_count_changed(count, cap) / echo_playback_started(duration) / echo_playback_stopped / notify_requested(text) / level_started(id) / level_completed(id) / advance_requested / level_reset_requested |
| `SaveManager` | `scripts/save/save_manager.gd` | mark_level_completed(id) / is_level_unlocked(id);存档 user://save.json |

规则:跨场景通信只走 GameEvents;子→父用信号;禁止节点跨树互引、禁止 UI/关卡反向依赖子节点内部。

## 碰撞层(位值)与分组(全项目统一)

| 层 | 位值 | 成员 | mask |
| --- | --- | --- | --- |
| 1 world | 1 | 墙体/门体/装置实体 | — |
| 2 player | 2 | 玩家 | 1 |
| 3 echo | 4 | 回声 | 1 |
| 4 trigger | 8 | 机关/出口 Area | 6 |

分组:`mechanism`(机关)、`echo_trigger`(玩家+回声)、`echo`(回声)、`player`(玩家)。重置逻辑依赖分组遍历。

## 场景组装模式

关卡场景 = 根 Node2D(挂 LevelXXManager)+ `Floor`(TileMapLayer)+ `Decals`(地面贴花层)+ `RecordingZone`(L4—L6 初始记录区)+ `WallColliders`(StaticBody2D 菱形脚印集)+ `YSorted`(y_sort,实体)+ `EchoManager` + `UI`(CanvasLayer)。参考 `scenes/levels/Level_04.tscn` 与 `tools/build_level_04.gd`(第二章模板:记录区/出口区手搭注入)。

其他场景:`scenes/ui/LevelSelect.tscn`(关卡选择菜单,章末任意键/暂停菜单入口,`LevelSelect.previous_scene` 记录返回目标)。

**构建脚本铁律**:
- owner 只赋无主节点(`child.owner == null` 才赋,递归)——否则 pack() 展开实例子场景 → 静态影子副本(M2 事故:玩家看到假机关)。
- `-s` 脚本编译期禁止引用游戏类(类型标注也算):一律 `load("res://...").new()` + 动态访问;游戏脚本运行时加载不受限。
- 调用侧一律 `timeout 90 ...`;`-s` 出错未到 quit() 会挂起。
