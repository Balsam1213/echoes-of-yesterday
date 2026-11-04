# player —— 玩家控制

> 实现:`scripts/player/player_controller.gd` + `scenes/player/Player.tscn`;规范:docs/02 §3、docs/03 §4。

## Player.tscn 结构

```
Player (CharacterBody2D, 层2 掩码1, motion_mode=1 floating)
├── CollisionShape2D   CircleShape2D r6,position (0,-6)   ← r6 是 1 格门洞通过性下限
├── Sprite (AnimatedSprite2D, %Sprite, position (0,-24), idle/walk/interact 三动画)
├── Camera (%Camera, position_smoothing 8,边界由 camera_limit_rect 设置)
└── TimeRecorder (%TimeRecorder, time_recorder.gd)        ← 记录器随玩家走
```

节点原点 = 脚底(记录与 Y-sort 基准);分组:`player` + `echo_trigger`。

## 移动与输入(docs/02 §3)

- 屏幕空间八向:`Input.get_vector("move_left","move_right","move_up","move_down")`,速度 `move_speed = 140.0`(@export),斜向由 get_vector 归一。
- 输入轮询全部在 `_physics_process`(60Hz)——记录系统依赖该帧律,禁止搬进 `_process`。
- 交互(interact)为 0.4s 定时状态,事件字段由 InteractionManager 在后续关卡填充(当前预留)。

## 状态与动画(记录采样的数据源)

| 字段 | 含义 | 合法值 |
| --- | --- | --- |
| `position` | 全局坐标(脚底原点) | — |
| `direction` | 最后非零移动方向(单位向量) | 任意归一 Vector2 |
| `anim_state` | 动画状态 | idle / walk / interact |

动画状态机:interact 进行中 > walk(有输入)> idle;切换后 `_sprite.play(anim_state)`。新增动画状态须先改 docs/02 §5.2 的帧结构说明。

## 对外接口

- `recorder: TimeRecorder` —— 记录器引用(关卡/回声管理经此取记录)
- `reset_to(pos: Vector2)` —— 关卡重置用:瞬移 + 清速度/朝向/交互计时/动画
- `camera_limit_rect: Rect2i`(@export)—— 相机边界,关卡构建时设置

## 修改约束

- 移动手感参数只动 `move_speed`,不改帧律;碰撞圆 r6 与"1 格门洞"绑定,放大前先读 isometric.md 的通道分析。
- 玩家与回声互不碰撞(层 2/3 分离、互不 mask):这是设计决定(回声是影像,物理互撞破坏复现精度)。
