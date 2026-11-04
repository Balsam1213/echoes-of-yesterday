extends Node
## 全局信号总线(docs/02 §2.2):跨场景通信唯一通道,禁止节点跨树互引。
## 信号参数与语义如有变更,须同步 docs/02 与订阅方。

signal recording_started
signal recording_stopped(duration: float)
signal echo_spawned(echo_id: int)
signal echo_deleted(echo_id: int)
signal echo_count_changed(count: int, cap: int)
signal echo_playback_started(duration: float)
signal echo_playback_stopped
signal notify_requested(text: String)  # 面向玩家的提示(HUD 订阅,如 T-06 超限提示)
signal level_completed(level_id: int)
signal restart_requested  # 通关界面按任意键重玩(HUD 发出,关卡管理器执行重置)
