class_name UIText
extends RefCounted
## 面向玩家的全部文案唯一来源(docs/05 §6);禁止在 UI/关卡代码中散落硬编码文案。

const LEVEL_TITLE := "第一章 · 第1关 第一次回声"

## 关卡标题按关卡编号选择(HUD 经 level_started 更新)
static func level_title(level_id: int) -> String:
	return [
		"第一章 · 第1关 第一次回声",
		"第一章 · 第2关 双重行动",
		"第一章 · 第3关 不同的路径",
		"第二章 · 第4关 时间干扰",
		"第二章 · 第5关 重复的实验",
		"第二章 · 第6关 失控区域",
	][clampi(level_id - 1, 0, 5)]

const T01_KEYS := "WASD 移动 · R 记录 · 空格 回声 · X 删除回声 · Backspace 重置 · Esc 暂停"
const T02_CANNOT_PASS := "你无法一边踩住开关,一边穿过安全门。"
const T03_DEVICE := "检测到时间记录设备。该设备能够记录并重现你的行动。按下 R,开始记录。"
const T05_RECORDED := "记录完成。按 空格,播放这段记录。"
const T06_CAP := "回声数量已达上限(%d)。按 X 可删除回声。"
const T_NO_RECORDING := "没有可播放的记录。按 R 先记录一段行动。"
const T_RECORD_ZONE := "时间记录只能从初始区域开始。回到出生点附近再按 R。"
const T07_COMPLETE := "第一次回声已成功建立。\n你发现,过去的行动可以改变现在。"
const T10_INTRO := "两台电闸,一扇双锁门。"
const T12_TWO_LOCKS := "门的两半锁栓需要同时缩回。也许,你可以让另一个自己帮忙。"
const T13_TWO_ECHOES := "两个自己,同时行动。"
const T14_COMPLETE := "门开了。你听见两个时间的脚步声重合在一起。"
const T15_EXPIRED := "十秒已过,时间锁松开了。重新踩上它,再次冲刺!"
const T16_LOCK := "时间锁咬合!剩余 %d 秒——冲!"
const T17_COUNTDOWN := "3…2…1…"
const T30_INTRO := "三台稳压开关,三盏灯。大门要它们同时咬合。"
const T31_LOCK_HINT := "时间锁:一旦另外两台电闸同时咬合,它只会维持 10 秒——到期就会松开,谁也留不住它。"
const T32_LAST_LOCK := "还差最后一道锁。踩上时间锁的瞬间,十秒倒计时开始——准备好冲刺!"
const T18_COMPLETE := "三条路径,一个现在。第一章,完。"

# —— 第二章(docs/13—16,2026-11-07)——
const T40_INTRO := "空气在震颤。这里的时间异常,会撕碎你的回声。"
const T41_FIELD_WARN := "时间干扰区。影子一旦进入,就会当场碎裂。"
const T42_DISSOLVED := "你的回声碎掉了。找一条干扰碰不到的路,重新记录。"
const T43_PULSE_HINT := "脉冲板:只在被经过的瞬间接通。站上去不动,是没有用的。"
const T44_SYNC_HINT := "两块脉冲板要在同一瞬间接通。看着你的回声,数着它的脚步,踩上另一块。"
const T45_COMPLETE := "影子碎掉的地方,路还留着。干扰区,穿过了。"
const T50_INTRO := "实验日志:第 41 次协同试验。八秒后,核心再次熄灭。"
const T51_CORE_HINT := "能量核心:靠近后按 E,启动或关闭。"
const T52_SHADOW_WALL := "影子不认识今天的墙。它只走它记录过的路。"
const T53_TRIAL := "试验开始:%d 秒后,核心将再次熄灭。"
const T54_COMPLETE := "第 42 次试验,成功。因为你不再是一个人做实验。"
const T60_INTRO := "失控区域。这里的机关不再讲道理——它们只认顺序。"
const T61_LOCK_HINT := "时间锁:踩上即启动,十秒后自动松开。"
const T62_ORDER_WRONG := "失控区域的机关认顺序。先来后到,乱了不认。"
const T63_COMPLETE := "失控的不是区域,是时间本身。第二章,完。"
const HINT_NEXT := "按任意键继续"
const HINT_REPLAY := "按任意键重玩"
const PAUSE_TITLE := "暂 停"
const BTN_CONTINUE := "继续游戏"
const BTN_RESTART := "重新开始本关"
const BTN_QUIT := "退出游戏"

const HINT_SECONDS := 4.0

static func echo_count_text(count: int, cap: int = 3) -> String:
	return "回声 " + "●".repeat(count) + "○".repeat(maxi(cap - count, 0))


## 完成界面三段文案按关卡选择(docs/13 §5 推进链;章节末关显示章节完)
## 第 3 关随第二章开放改为「继续」(next_scene → Level_04);第 6 关为章末(重玩)
static func complete_body(level_id: int) -> String:
	return [
		T07_COMPLETE, T14_COMPLETE, T18_COMPLETE,
		T45_COMPLETE, T54_COMPLETE, T63_COMPLETE,
	][clampi(level_id - 1, 0, 5)]


static func complete_title(level_id: int) -> String:
	match level_id:
		1: return "—— 第一关 完成 ——"
		2: return "—— 第二关 完成 ——"
		3: return "—— 第一章 完 ——"
		4: return "—— 第四关 完成 ——"
		5: return "—— 第五关 完成 ——"
		6: return "—— 第二章 完 ——"
		_: return "—— 第 %d 关 完成 ——" % level_id


static func complete_hint(level_id: int) -> String:
	return HINT_REPLAY if level_id >= 6 else HINT_NEXT
