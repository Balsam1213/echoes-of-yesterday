class_name EchoRecording
extends RefCounted
## 一段已结束的行动记录(docs/02 §5.2):60Hz 物理帧采样,按时间序保存。
## demo 仅内存持有,不落盘(02 §5.3)。

const SAMPLE_RATE := 60.0
const MAX_FRAMES := 1800  # 30 秒上限(FR-005)

## 帧结构:{ t: int, pos: Vector2, dir: Vector2, anim: String, events: Array[String] }
var frames: Array[Dictionary] = []


func duration() -> float:
	return frames.size() / SAMPLE_RATE


func start_position() -> Vector2:
	return frames[0]["pos"] if not frames.is_empty() else Vector2.ZERO


func end_position() -> Vector2:
	return frames[-1]["pos"] if not frames.is_empty() else Vector2.ZERO
