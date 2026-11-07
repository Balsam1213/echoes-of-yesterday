# echo —— 回声系统

> 实现:`scripts/echo/echo_controller.gd` + `scenes/echo/Echo.tscn`;`scripts/level/echo_manager.gd`(挂关卡场景);规范:docs/02 §6。

## EchoController(回声本体)

- CharacterBody2D,层 3(位值 4)、掩码 1;分组 `echo` + `echo_trigger`。**与玩家互不碰撞**(层 2/3 分离,设计决定)。
- 外观:玩家同图集,整体 modulate `#45D9F2` alpha 0.6 —— 必须与玩家一眼可辨(docs/02 §6)。
- 回放:**逐物理帧直接赋位**(`global_position = frame.pos`),不做物理移动解算——记录数据来自合法位置,解算反而引入偏差(T3.5 实测 max_pos_err=0.000)。**推论(E-51 总纲)**:回声不与"当下"环境解算,可穿过已升起的联动桥;唯一以当下伤害回声的是干扰场。
- **交互事件重放(L5,E-52)**:帧 `events` 非空 → 按记录的 target 路径(current_scene 解析)调用 `toggle()`;同帧同目标同效果,多次回放一致;目标缺失跳过 + push_warning,不中断回放。
- 播完 = 末帧停留 `idle`,**保留机关触发能力**(核心玩法:回声替玩家踩开关);`playback_finished(echo)` 信号。
- `setup(rec)` 注入记录;`echo_id` 静态自增;`debug_trajectory`(回放结束打印 max_pos_err,期望恒 0)。
- 碰撞圆 r6(与玩家一致,回放路径可能穿过门洞)。

## EchoManager(生成与管理,挂关卡根)

- 输入轮询(物理帧):`play_echo` 生成、`delete_echo` 删最新。
- 生成规则:`_player.recorder.recording` 最近已完成记录;实例化 Echo → 放入 YSorted 层 → `global_position = rec.start_position()`(**= 记录起点,必在记录区内**,docs/13 §5.1);上限 `max_echoes`(逐关 @export),超限 `GameEvents.notify_requested(UIText.T06_CAP)`;记录未结束按 Space 忽略(E-02)。
- 删除:X 删最新;`clear_all()` 供关卡重置(同时清残影)。
- **干扰消散 `dissolve(echo)`**(L4):InterferenceField 发 `echo_dissolved` → 关卡层接线到本方法;与 X 删除同路径(计数 −1、`echo_deleted` 广播、残影清理),回声当帧停止回放/触发,本体 0.3s 碎裂渐隐后释放;已触发的机关不回滚(E-43)。
- 计数广播:`GameEvents.echo_count_changed(count, cap)`(HUD 回声 ●○○ 依赖)。
- `ysorted_path`(@export)指向关卡 YSorted 层。

## 轨迹线与残影(docs/13 支柱 4)

- 由 **EchoManager** 创建,挂在**房间根(世界空间)**,点位 = 记录帧位置 —— 与真实轨迹逐点重合。
- **禁止挂到回声节点下**:会按局部坐标错位并随回声漂移(M3 用户反馈的原始 bug)。
- **轨迹残影**:回放结束**不再删除**,降透明度至 0.25 保留——大地图上玩家据此复盘"回声走了哪条路、何时到哪"(玩法支撑);删除/消散/重置时清理。

## 修改约束

- 回声不做寻路/不做物理碰撞解算;若未来需要与场景交互(如推箱),先改 docs/02 §6 再动代码。
- 生成时机:记录未结束忽略(E-02);重复 Space 可生成多回声(不同记录为第 3 关扩展,当前最近一条)。
