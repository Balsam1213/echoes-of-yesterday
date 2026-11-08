# 昨日回声 Echoes of Yesterday

> 以「时间记录与自我协作」为核心机制的 2.5D 等距像素风解谜游戏 · Windows PC · Godot 4.x + GDScript

## 当前阶段:第三章 v0.1 已交付 ✓(全三章,第 1—8 关 完整 Demo)

> **AI/开发者规范入口**:`.agents/skills/echoes-of-yesterday-dev/`(项目专属技能:架构约定、接口契约、等距规则、测试要求;SKILL.md + references/ 分册)。

完整核心闭环——

**移动 → 观察机关 → 记录行动(R)→ 生成回声(Space)→ 与回声协作 → 通过安全门 → 通关 → 重置**

**第一章「苏醒」(第 1—3 关)**:时间记录/回声回放/压力开关/安全门/时间锁;回声上限 1→2→3。
**第二章「时间异常」(第 4—6 关)**:干扰场(回声进入即消散)、脉冲板(0.5s 瞬踩+发射时机)、能量核心(E 键交互,记录 events 重放)、联动屏障(桥)、序列门——谜题围绕"回声运动过程的编排"展开:瞬时踩踏、途中交互、多回声时序。
**第三章「昨日回声」(第 7—8 关)**:相位门(实体止步、回声可穿)、悖论区(与过去的自己同场即碎)——新谜题语法「时空在场调度」:错峰共存、先过去再让过去发生、断电 10s 窗 × 时间锁 10s 窗的终局冲刺。全 8 关收束,通关揭晓「你也是一段回声」。全部通过自动化回归(回归套件 ×3 + 八关冒烟 + BFS 密封审计)。

里程碑:第一章 `demo-v0.1`/`chapter1-v0.2`,第二章 `chapter2-v0.1`,第三章 `chapter3-v0.1`(v0.4)。

## 仓库结构

```
Echoes of Yesterday/
├── README.md                    # 本文件:项目总览与导航
├── .gitignore
├── docs/                        # 开发文档体系(标准文件,自足闭环)
│   ├── 00_文档索引与文档规范.md    # 文档清单、文档管理规则、术语表
│   ├── 01_Demo需求规格说明书.md   # Demo 范围、功能/非功能需求
│   ├── 02_技术方案.md            # 引擎架构、记录/回放/机关系统设计
│   ├── 03_设计规范_工程与代码.md   # 目录、命名、GDScript、Git 规范
│   ├── 04_设计规范_美术UI与音频.md # 色彩、素材规格、UI 布局、音频
│   ├── 05_第一关关卡设计.md       # 布局、机关、流程、文案、边缘规则
│   ├── 06_执行计划与任务分解.md   # 里程碑 M0-M5、任务清单、DoD
│   ├── 07_工作说明与开发流程.md   # 日常开发循环、AI 协作、缺陷流程
│   ├── 08_测试用例与验收清单.md   # 测试用例 TC、最终验收清单
│   └── 09_Demo制作计划书.md       # 进度主控:里程碑状态/质量门/风险/开工清单
├── logs/                        # 日志体系
│   ├── devlog.md                # 开发日志(每次开发会话必写,最新在上)
│   ├── changelog.md             # 变更日志(版本可感知的变化)
│   └── issues.md                # 缺陷与问题跟踪
└── EchoesOfYesterday/           # Godot 4.x 工程目录(project.godot 已生成)
    ├── project.godot            # 视口/碰撞层命名/输入映射(03 §5)
    ├── scenes/  (main/player/echo/levels/mechanisms/ui/dev)
    ├── scripts/ (player/echo/recording/interaction/level/save)
    ├── assets/  (characters/environment/mechanisms/ui/audio/effects)
    └── data/    (levels/settings)
```

## 环境要求

| 工具 | 版本 | 用途 |
| --- | --- | --- |
| Godot | 4.3+(4.x 最新稳定版) | 游戏引擎;打开 `EchoesOfYesterday/project.godot` |
| VS Code | 最新稳定版 | 代码编辑;安装 godot-tools 扩展 |
| Git | 最新稳定版 | 版本管理 |

## 如何开始一项开发工作

1. 打开 `docs/06_执行计划与任务分解.md`,找到当前里程碑与任务编号;
2. 读 `logs/devlog.md` 最新一条,衔接上次进度;
3. 开发,并对照 `docs/08_测试用例与验收清单.md` 自测;
4. 收工前:写 `logs/devlog.md` → 有版本可见变化则更新 `logs/changelog.md` → `git commit`。

详细流程见 `docs/07_工作说明与开发流程.md`。

## 文档层级

docs/ 文档体系为**唯一有效需求依据(自足模式)**;原始方案要点已蒸馏入各章规划文档(规则见 `docs/00` §2.4)。
