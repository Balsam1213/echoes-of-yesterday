# recording —— 时间记录

> 实现:`scripts/recording/time_recorder.gd`(挂 Player 子节点 %TimeRecorder)、`scripts/recording/echo_recording.gd`;规范:docs/02 §5。

## 采样(硬规则:60Hz 物理帧驱动)

- `_physics_process` 中每物理帧采样一条;**禁止键盘输入重放式记录**(上位文档明确要求记录实际行为)。
- 采样源 = Player 的 `global_position / direction / anim_state` 三字段;交互事件 `events: []` 预留(InteractionManager 后续填充)。
- 上限 `MAX_FRAMES = 1800`(30s),到顶自动结束(E-03);采样率常量 `SAMPLE_RATE = 60.0`。

## 帧结构(docs/02 §5.2,回放契约,勿改字段名)

```gdscript
{ "t": int, "pos": Vector2, "dir": Vector2, "anim": String, "events": Array }
```

## EchoRecording(class_name,RefCounted)

- `frames: Array[Dictionary]`;`duration()` / `start_position()` / `end_position()`
- 仅内存持有最近 1 条,不落盘(02 §5.3);回声在 spawn 时快照引用——**多回声关卡冒烟必须"录一条发一条"**(L3 先例)。

## 输入与生命周期

- 输入 action:`record_toggle`(R)。`is_recording` 切换;结束时打包 `recording` 并 `GameEvents.recording_started/stopped` 广播。
- **起录门控(docs/13 §5.1)**:初始记录区(RecordingZone)外按 R → `T_RECORD_ZONE` 提示、不开始;门控读 `PlayerController.in_recording_zone`(L1—L3 无区域,默认 true 不受限)。
- **完成回原位**:`_stop()`(含 30s 满自动结束)后玩家 `reset_to(_start_pos)` 回到本次记录起点;通关静默取消(`discard_buffer`)不回移。
- 两个清除接口,**场景不同不可混用**:
  - `discard_buffer()` —— 只丢未完成缓冲,保留已完成记录。用途:通关静默取消(E-09)。
  - `clear_all() —— 未完成 + 已完成记录全清。用途:关卡重置(docs/02 §8.2 第 1 步);不匹配会导致重置后仍能播放旧记录。

## 交互事件(events,L5 起启用)

- PlayerController 按 E 命中 `interactable` 组目标 → 真实 toggle + 发 `interacted(target)`(录制中=真实行动,E-57);
- TimeRecorder 把 `{type:"interact", target: 相对关卡根的 NodePath}` 写入**当前采样帧**的 events;
- 回声重放到该帧时执行 target.toggle()(见 echo.md);旧记录 events 为空,天然兼容。
- 改动后必跑 regression_m6(TC-61a—d 覆盖采集/重放/翻转)。

## 修改约束

- 新增采样字段:先改 docs/02 §5.2 帧结构说明与本文件,再改代码,并确认回声回放端兼容(旧记录无新字段需容错)。
- 记录起点 = 开始采样后的第一帧位置;回声生成放在该位置(必在记录区内,docs/13 §5.1)。
- 改动后必跑 regression_m5(TC-09 覆盖 30s 上限、TC-19/20 覆盖清除语义)。
