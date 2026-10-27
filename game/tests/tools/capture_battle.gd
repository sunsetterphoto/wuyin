extends SceneTree
## Renders the battle screen, plays a few menu turns and saves a screenshot.
## Needs a window (not --headless):
##   godot --path game -s res://tests/tools/capture_battle.gd -- <active 1|2> <turns> <out.png> [locale] [call text]

const BattleScreen := preload("res://scripts/battle/battle_screen.gd")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var active := int(args[0]) if args.size() > 0 else 2
	var turns := int(args[1]) if args.size() > 1 else 2
	var out: String = args[2] if args.size() > 2 else "user://battle.png"
	TranslationServer.set_locale(args[3] if args.size() > 3 else "de")
	var setup := BattleScreen.default_setup(active)
	setup["seed"] = 1234
	BattleScreen.setup = setup
	var screen: Control = load("res://scenes/battle/battle_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	for t in turns:
		if screen.battle.is_over():
			break
		for i in screen.battle.open_slots(0).size():
			var u: BattleUnit = screen.battle.unit_at(0, screen._slot)
			screen._on_move(u.usable_moves()[0])
			if screen._prompt.text == tr("BATTLE_CHOOSE_TARGET"):
				screen._submit(Battle.move_action(u.usable_moves()[0], 1, 0))
		await process_frame
	if args.size() > 4:
		await screen._on_call(args[4])
	for i in 10:
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("CAPTURED ", out)
	quit()
