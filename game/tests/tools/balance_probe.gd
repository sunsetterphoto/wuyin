extends SceneTree
func _init() -> void:
	var turns := []
	var wins := [0, 0]
	for s in 200:
		var b := Battle.create(s, [
			[{"id": "bambaer", "level": 10}, {"id": "glutfasan", "level": 10}, {"id": "wawalurch", "level": 10}],
			[{"id": "rollschupp", "level": 10}, {"id": "zirpo", "level": 10}, {"id": "firnleopard", "level": 10}]], 2)
		var a0 := BattleAI.new(s + 1)
		var a1 := BattleAI.new(s + 2)
		while not b.is_over() and b.turn < 200:
			a0.fill(b, 0); a1.fill(b, 1); b.resolve_turn()
		turns.append(b.turn); wins[b.winner] += 1
	turns.sort()
	print("2v2 turns median=%d min=%d max=%d wins=%s" % [turns[100], turns[0], turns[199], wins])
	var hits := []
	for s in 200:
		var b := Battle.create(s, [[{"id": "bambaer", "level": 10}], [{"id": "glutfasan", "level": 10}]], 1)
		var a0 := BattleAI.new(s + 1)
		var a1 := BattleAI.new(s + 2)
		while not b.is_over() and b.turn < 200:
			a0.fill(b, 0); a1.fill(b, 1); b.resolve_turn()
		hits.append(b.turn)
	hits.sort()
	print("1v1 turns median=%d min=%d max=%d" % [hits[100], hits[0], hits[199]])
	quit()
