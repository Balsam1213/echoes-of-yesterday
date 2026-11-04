# 昨日回声 Echoes of Yesterday

> 以「时间记录与自我协作」为核心机制的 2.5D 等距像素风解谜游戏 · Windows PC · Godot 4.x + GDScript

## 当前阶段:第一关 Demo v0.1 已定版 ✓

第一关「第一次回声」完整可玩,覆盖核心闭环——

**移动 → 观察机关 → 记录行动(R)→ 生成回声(Space)→ 与回声协作 → 通过安全门 → 通关 → 重置**

核心系统五项(第一关即技术验证关卡)全部落地并通过回归:玩家移动、行动记录、回声回放、机关交互、关卡重置。里程碑 M0—M5 全部完成,tag `demo-v0.1`。

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

docs/ 文档体系为**唯一有效需求依据(自足模式)**。原始方案 docx 已移出仓库(2026-11-04);制作第 2—8 关时再将其放回作补充参考,规则见 `docs/00` §2.4。
