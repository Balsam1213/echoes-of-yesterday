extends Node
## 全局信号总线(docs/02 §2.2):跨场景通信唯一通道,禁止节点跨树互引。
## 信号参数与语义如有变更,须同步 docs/02 与订阅方。

signal recording_started
signal recording_stopped(duration: float)
signal echo_spawned(echo_id: int)
signal echo_deleted(echo_id: int)
signal notify_requested(text: String)  # 面向玩家的提示(M4 HUD 订阅,如 T-06 超限提示)
signal level_completed(level_id: int)
