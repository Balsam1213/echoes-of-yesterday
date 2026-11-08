# isometric —— 等距地图、Y-sort 与碰撞形状

> 硬规则源头:docs/03 §3.9+§4、docs/02 §3;教训:躺倒墙(M2 返修 2)、脚印穿模(M2 返修 3)。

## 网格与坐标

- TileMapLayer:`tile_shape = Isometric`、**`tile_layout = TILE_LAYOUT_DIAMOND_DOWN`(必须显式,默认 STACKED 是错的)**、`tile_size = Vector2i(64, 32)`。
- 格位→世界:`map_to_local(cell) = ((x−y)×32 + 32, (x+y)×16 + 16)`(返回格心)。
- **邻格世界距离(32px 口径,判定区设计必读)**:(x±1,y) 与 (x,y±1) 邻格在世界坐标分别为 32px 水平/垂直;(x+1,y−1) 为 64px 水平。**等距"竖向相邻"两格只隔 32px**——格心判定区(干扰场 r8)与走廊宽度都按此口径算:回声圆心(r6,foot−6)距邻格场心最近 26px,判定半径 >16 即可能被贴行走位噪声(±5px)误伤(L4 返修)。同时注意 **x0/y0 列是周界墙**,设计"窄道"不可用边界列。
- 移动为屏幕空间自由移动,不做格子吸附;机关判定靠 Area2D,格位对齐仅约束摆放。**屏幕正北 = 格 (x−1,y−1) 方向**(M2 返修沉淀)。

## Y-sort 锚点(最易错)

- 实体容器(YSorted)与关卡根的排序按**节点 position.y**。
- 立起物节点原点 = **脚印菱形中心**(格位);`map_to_local` 的返回值直接作为节点位置。
- 立方体贴图(64×80,脚印中心在贴图 (32,64))相对贴图中心偏移 (0,+24):
  - 裸 Sprite2D 入 YSorted(如周界墙):`sprite.position = 格位;sprite.offset = Vector2(0, -24)` —— **偏移必须用 offset,改 position 会把排序锚点北移 24px,墙"躺倒"**(M2 返修 2)。
  - 带碰撞的实体(StaticBody2D/Area2D 在格位,Sprite 为子节点):子 Sprite `position = Vector2(0, -24)`,父节点位置=锚点 ✓。
- 角色精灵:纹理 32×48,`position = Vector2(0, -24)`(脚底=原点)。

## 脚印菱形碰撞(docs/03 §4)

```gdscript
const FOOTPRINT := PackedVector2Array([Vector2(0,-16), Vector2(32,0), Vector2(0,16), Vector2(-32,0)])
var shape := ConvexPolygonShape2D.new()
shape.points = FOOTPRINT
```
- 所有立起物(墙/门/装置/方块)一律用脚印菱形;**禁止小矩形近似**(碰撞小于视觉 → "踩进方块才被挡")。
- 角色碰撞圆 **r6**(圆心 `(0,-6)`,底点=脚底):r9 过不了 1 格门洞的菱形通道。
- 相邻菱形共边即密封房间;门洞由门的 Blocker(菱形,开时 disabled)接管。

## 立方体贴图规格(占位)

64×80,脚印菱形中心 (32,64):顶面菱形(上移 h)+ 左右两个 2:1 斜面(左受光、右背光)。生成器:`tools/generate_placeholder_assets.gd`。正式素材替换时保持同规格与原点约定。

## 遮挡可见性(返修 2 沉淀,2026-11-08)

- **Y-sort 只保证「逐节点排序」,不保证「目标可见」**:目标格南东南 2 格内的墙/门立方体精灵(64×80,向上延伸)覆盖矩形**并起来**可能完全盖住底座类贴图——L7 的 S1 (14,7) 被 (15,8)∪(16,7) 完全遮住,单看正南邻格会漏判。放底座/开关前先算「遮挡锥」(南邻格 + 南东斜格 ×2 行),选锥内全空的格位;
- **开关底座挂 YSorted,不进 Decals**:Decals 恒在全部 YSorted 精灵之下,连「本应在其身后(北)」的墙基座都会盖住它;挂 YSorted 后按 y 正确排序(同格与角色平局时后加入者在上,角色仍绘制于底座之上)。Decals 只放纯地面着色与置顶标记(z_index=1);
- 危害/悖论覆层见硬规则 15:覆层节点先于 Decals 注入(Floor → 覆层 → Decals → YSorted)。

## 相机

Camera2D 作 Player 子节点,`position_smoothing_enabled`,边界由关卡设置 `player.camera_limit_rect`(构建脚本 `_camera_limits()` 计算:地板菱形外沿 −32/−48/+32/+16 余量)。
