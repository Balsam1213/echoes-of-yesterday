class_name UIText
extends RefCounted
## 面向玩家的全部文案唯一来源(docs/05 §6);禁止在 UI/关卡代码中散落硬编码文案。

const LEVEL_TITLE := "第一章 · 第1关 第一次回声"
const T01_KEYS := "WASD 移动 · R 记录 · 空格 回声 · X 删除回声 · Backspace 重置 · Esc 暂停"
const T02_CANNOT_PASS := "你无法一边踩住开关,一边穿过安全门。"
const T03_DEVICE := "检测到时间记录设备。该设备能够记录并重现你的行动。按下 R,开始记录。"
const T05_RECORDED := "记录完成。按 空格,播放这段记录。"
const T06_CAP := "回声数量已达上限(%d)。按 X 可删除回声。"
const T_NO_RECORDING := "没有可播放的记录。按 R 先记录一段行动。"
const T07_COMPLETE := "第一次回声已成功建立。\n你发现,过去的行动可以改变现在。"
const T14_COMPLETE := "门开了。你听见两个时间的脚步声重合在一起。"
const T18_COMPLETE := "三条路径,一个现在。第一章,完。"
const HINT_NEXT := "按任意键继续"
const HINT_REPLAY := "按任意键重玩"
const PAUSE_TITLE := "暂 停"
const BTN_CONTINUE := "继续游戏"
const BTN_RESTART := "重新开始本关"
const BTN_QUIT := "退出游戏"

const HINT_SECONDS := 4.0

static func echo_count_text(count: int, cap: int = 3) -> String:
	return "回声 " + "●".repeat(count) + "○".repeat(maxi(cap - count, 0))


## 完成界面三段文案按关卡选择(docs/10 §4 推进链;末关显示章节完+重玩)
static func complete_body(level_id: int) -> String:
	return [T07_COMPLETE, T14_COMPLETE, T18_COMPLETE][clampi(level_id - 1, 0, 2)]


static func complete_title(level_id: int) -> String:
	return ["—— 第一关 完成 ——", "—— 第二关 完成 ——", "—— 第一章 完 ——"][clampi(level_id - 1, 0, 2)]


static func complete_hint(level_id: int) -> String:
	return HINT_REPLAY if level_id >= 3 else HINT_NEXT
