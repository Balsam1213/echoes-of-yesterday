# EchoesOfYesterday —— Godot 工程说明

《昨日回声 Echoes of Yesterday》Godot 4.x 工程根目录。
当前状态:**第一章(第 1—3 关)已交付**(tag `chapter1-v0.2`)。

## 快速开始

1. 用 Godot 4.3+(建议 4.7.2)打开本目录的 `project.godot`;
2. F5 运行——主场景为第一关 `scenes/levels/Level_01.tscn`;
3. 通关第 1 关后自动进入第 2、3 关(进度存于 `user://save.json`)。

## 目录速览

| 目录 | 内容 |
| --- | --- |
| `scenes/levels/` | Level_01/02/03(三章关卡) |
| `scenes/{player,echo,mechanisms,ui}/` | 玩家、回声、机关、UI 场景 |
| `scripts/` | 与 scenes 同构;`core/`=autoload(GameEvents/SaveManager) |
| `assets/` | 占位素材(正式美术待替换) |
| `tools/` | 构建与测试脚本(关卡构建/冒烟/回归/泄漏探针) |
| `export_presets.cfg` | Windows 导出配置(嵌入 PCK 单文件) |

## 开发规范

项目专属技能 `.agents/skills/echoes-of-yesterday-dev/`(仓库根)与 `docs/00—12` 文档体系——改代码前必读。
