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
signal level_completed(id: int)
signal advance_requested  # 完成界面按任意键:重置并进入下一关(末关=重玩)
signal level_reset_requested  # 暂停菜单"重新开始本关":仅重置当前关,不推进
