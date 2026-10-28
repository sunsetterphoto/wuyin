class_name Endings
extends RefCounted
## Which ending the journey earns (GDD "Mehrere Enden"). Every choice is
## counted by the code during the game; the model never decides this.
##
##   reconcile  Wusheng was convinced and his crane sang again.
##   bitter     More silenced Lingshou were defeated than freed: one region stays silent.
##   victory    Wusheng was defeated; the phoenix is reborn.


static func decide(state: GameState) -> String:
	if state.flag("wusheng_convinced") and state.flag("crane_sings"):
		return "reconcile"
	if int(state.stats.get("defeated_silenced", 0)) > int(state.stats.get("freed", 0)):
		return "bitter"
	return "victory"


## Lessons about farewell and renewal the player heard on the journey; each one
## unlocks an answer in the final conversation with Wusheng.
const LESSONS: Array[String] = ["lesson_bamboo", "lesson_fisher", "lesson_water", "lesson_forest", "lesson_fire",
	"lesson_leaves", "lesson_earth", "lesson_master"]


static func lessons(state: GameState) -> int:
	var n := 0
	for l in LESSONS:
		if state.flag(l):
			n += 1
	return n


## Epilogue facts for the closing texts.
static func epilogue(state: GameState) -> Array[String]:
	var out: Array[String] = []
	out.append("EPI_YAO_BACK" if state.flag("yao_returned") else "EPI_YAO_GONE")
	var convinced := int(state.stats.get("order_convinced", 0))
	var fought := int(state.stats.get("order_fought", 0))
	out.append("EPI_ORDER_TALK" if convinced >= fought else "EPI_ORDER_FIGHT")
	if state.flag("helped_rotfels"):
		out.append("EPI_ROTFELS")
	if int(state.stats.get("hatched", 0)) > 0:
		out.append("EPI_FARM")
	out.append("EPI_MASTER")
	return out
