# EchoesOfYesterday — Godot 工程目录

本目录是 **Godot 4.x 工程根目录**(docs/02 §2.1)。

> 当前状态:目录骨架已就位,`project.godot` **尚未创建**——它将在里程碑 M0 的任务 T0.2 中由 Godot 编辑器新建工程时生成(docs/06 §2 M0)。届时在本目录执行:新建工程 → 配置视口 640×360 → 配置输入映射(docs/03 §5)→ 命名碰撞层(docs/02 §4)。

## 目录用途(规范见 docs/03 §1)

```
scenes/
  main/        入口场景(Demo 阶段主场景直指 Level_01,可为空)
  player/      Player.tscn
  echo/        Echo.tscn
  levels/      Level_01.tscn 等关卡主场景
  mechanisms/  PressureSwitch / SecurityDoor / TimeRecorderDevice / ExitArea
  ui/          UI.tscn(HUD、暂停、通关)
  dev/         临时验证场景(dev_ 前缀,M5 前清理)
scripts/
  player/ echo/ recording/ interaction/ level/ save/   (与 scenes 同构)
assets/
  characters/ environment/ mechanisms/ ui/ audio/ effects/
data/
  levels/      关卡配置预留(JSON)
  settings/
```

- 空目录以 `.gitkeep` 占位,放入实际文件后可删除。
- 场景与脚本同目录同构;命名规范见 docs/03 §2。
