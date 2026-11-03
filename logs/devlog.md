# 开发日志 DevLog

> **规则:每次开发会话收工前必须追加一条,最新条目置于文件最上方**(`---` 分隔线之上)。
> 下一次开工时,先读本文件最新 1—2 条以恢复上下文(docs/07 §3.1)。

## 条目格式模板

```markdown
## YYYY-MM-DD | 主题(对应里程碑/任务号)
**完成**:
- (做了什么,对应 T-x.x / TC / 缺陷 ID)
**问题与决定**:
- (遇到的问题、做出的技术/设计决定及理由)
**下一步**:
- (下次开工的第一个动作)
```

---

## 2026-11-04 | M1:等距测试房间与玩家系统(T1.1—T1.4)

**完成**:
- Godot 4.7.2 就位(`Documents/Godot/`);`--import` 验证手写 project.godot 解析通过,引擎规范化 features→4.7;
- T1.1:`tools/generate_placeholder_assets.gd` 生成 6 张占位素材(地板/墙/测试方块/玩家三帧);`tools/build_dev_room.gd` 构建 `scenes/dev/dev_grid_test.tscn`(12×8 DIAMOND_DOWN 等距房、TileMapLayer 地板、周界墙、3 个 Y-sort 验证方块、四边边界碰撞);
- T1.2—T1.4:`player_controller.gd`(八向移动 140px/s、direction/anim_state 可采样字段、interact 状态)+ `Player.tscn`(层2/掩码1、floating 模式、脚底碰撞圆 r9、idle/walk/interact 三动画、平滑跟随镜头+limit)+ 主场景暂设 dev 房;
- 验证:headless 运行 90 帧无错误;窗口冒烟截图核验——地板菱形无缝对齐、墙体/玩家/方块位置正确、镜头跟随生效。

**问题与决定**:
- **pack() 陷阱**:程序化创建的节点必须显式设 `owner` 指向场景根,否则 PackedScene.pack() 打包出空场景;
- **等距布局**:引擎默认 `tile_layout=STACKED`,经典菱形须显式设 `TILE_LAYOUT_DIAMOND_DOWN`(T4.1 构建 Level_01 时必须保持);
- 墙体用 Sprite2D+StaticBody2D 占位而非 tilemap 墙贴图:墙贴图进 TileMapLayer 的纹理锚点与 y-sort origin 行为未验证,留待 T4.1;
- 相机 limit 在「房间小于视口」时表现为整房可见基本不动;Level_01(更大)下再验证跟随+边界夹取;
- 引擎会删除 project.godot 中等于默认值的行(aspect=keep、physics 60Hz),意图不变、默认值即所需;
- 主场景暂指 `dev_grid_test.tscn`,T4.1 切换为 `Level_01.tscn`。

**下一步**:
- 人工验收 TC-01/02(移动/碰撞)与 Y-sort(绕测试方块走一圈)→ M1 关闭 → M2/T2.1 压力开关。

## 2026-11-04 | Demo 制作计划书定稿与 M0 启动

**完成**:
- 新增 `docs/09_Demo制作计划书.md`(制作主控:里程碑状态表/质量门/风险/开工清单);
- 文档体系自足化:docs/00 §2.4、README、docs/06 已移除对已删除 docx 的依赖(用户确认:docx 不再恢复,做第 2—8 关时再放回);
- **T0.2/T0.3 完成**:手写 `EchoesOfYesterday/project.godot`——视口 640×360、窗口覆盖 1280×720、stretch=canvas_items/keep、gl_compatibility 渲染、纹理最近邻过滤、物理 60Hz 显式声明、4 层碰撞命名(world/player/echo/trigger)、10 个输入 action(物理键码);
- **T0.4 完成**:git 署名(仓库局部:balsam1213)、首次两个提交(docs 基线 / 工程配置)、tag `demo-v0.0`。

**问题与决定**:
- Godot 尚未安装 → project.godot 由手工编写,**解析验证留待首次打开**(09 §9.3 人工检查单);若打开时报输入映射异常,在项目设置→输入映射中核对修正即可;
- autoload 本次不注册(GameEvents/SaveManager 脚本尚未创建,注册会启动报错),随 M1/M4 对应任务加入;
- 渲染选 gl_compatibility + 最近邻过滤:2D 像素游戏最稳,像素不会模糊。

**下一步**:
- 安装 Godot 4.3+(09 §9.2)→ 走 09 §9.3 检查单验证工程配置 → M0 状态改 ✅ → 开始 M1/T1.1(等距测试房间)。

## 2026-11-04 | 项目启动:方案评审与文档体系建立(M0 前置)

**完成**:
- 初始化 Git 仓库(默认分支 `main`),建立 `.gitignore`;
- 通读《昨日回声_游戏开发方案v1.0.docx》,确认 Demo 范围 = 第一关「第一次回声」;
- 建立 docs/ 文档体系 9 份(00—08)与 logs/ 日志体系(devlog/changelog/issues);
- 建立 `EchoesOfYesterday/` Godot 工程目录骨架(scenes/scripts/assets/data 及子目录)。

**问题与决定**:
- 记录/回放驱动方式:**决定全部由 60Hz 物理帧驱动**(`_physics_process` 逐帧采样与回放),天然保证不同显示帧率下轨迹一致(应对上位文档验证点 R7);
- 玩家与回声**互不碰撞**(碰撞层 2/3 分离):回声是影像,物理卡位会破坏复现精度与协作体验;
- X 键行为简化为「删除最新回声」,多回声选择器推迟;
- 主菜单不在 Demo 范围(偏离登记 D-01),Demo 主场景直指 Level_01;
- 门增加防夹规则:门洞内有实体时延迟关闭。

**下一步**:
- 执行 docs/06 的 M0:安装 Godot 4.3+ → 新建工程(T0.2:640×360、输入映射、碰撞层命名)→ 建立分支模型并首次提交(T0.4)。
