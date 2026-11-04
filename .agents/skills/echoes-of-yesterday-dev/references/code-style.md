# code-style —— 代码规范与提交

> 权威:docs/03;本分册是高频条目速查。冲突以 docs/03 为准。

## 命名

| 对象 | 规则 | 例 |
| --- | --- | --- |
| 脚本文件 | snake_case.gd | `player_controller.gd` |
| 场景文件 | PascalCase.tscn | `Level_01.tscn` |
| class_name | PascalCase | `EchoController` |
| 变量/函数 | snake_case,私有 `_` 前缀 | `frame_index` |
| 常量 | CONSTANT_CASE | `MAX_ECHOES` |
| 信号 | snake_case 过去式 | `switch_activated` |
| 输入 action / 素材 | 见 docs/03 §2/§5 | `record_toggle` |

## GDScript 风格(docs/03 §3)

- Tab 缩进;函数参数与返回值必须类型标注,成员变量尽量标注。
- 声明顺序:`class_name` → `extends` → `##` 注释 → 信号 → 枚举 → 常量 → `@export` → 变量 → `@onready` → `_ready` → `_physics_process` → 其他。
- 节点引用用 `@onready var x: T = %UniqueName`(场景内勾选"作为唯一名称");禁止长路径硬编码。
- 魔法数字提为常量或 `@export`;`_physics_process` 内禁止实例化场景。
- 等距与碰撞两条硬规范:贴图偏移用 `Sprite2D.offset`;立起物碰撞=脚印菱形;角色碰撞圆 r6(详见 isometric.md)。

## 通信与文案

- 跨场景只走 `GameEvents` 总线;玩家可见文案只出自 `scripts/ui/ui_text.gd`(新增提示先加常量)。
- 重置依赖分组(`mechanism`/`echo`/`echo_trigger`/`player`):新对象记得入组。

## Git(docs/03 §6)

- 分支:`main`(稳定)/ `dev` / `feature/<主题>`;提交格式 `类型(范围): 中文描述`,类型 ∈ feat/fix/docs/refactor/test/chore。
- 粒度:每完成一个任务(T-x.x 或一个机制)至少一次提交;里程碑打 tag(`demo-v0.1` 先例)。
- 提交前:回归/冒烟(视改动范围)+ `git status` 确认无临时文件(冒烟截图不入库)。

## 文档联动(docs/00 §2.3)

- 改需求(01)→ 同步 02/05/06/08;改技术方案(02)→ 同步 03/05/06;改关卡(05)→ 同步 08。
- 重大修订追加文末修订记录 + `logs/changelog.md`;对上位文档的偏离登记 docs/00 偏离表。
- 每次开发会话收尾:`logs/devlog.md` 追加(完成/问题与决定/下一步)。
