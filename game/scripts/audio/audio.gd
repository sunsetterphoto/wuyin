class_name Audio
extends RefCounted
## Static access to the Music autoload, so scripts compile and run even where
## autoloads don't exist (headless tools, tests): there every call is a no-op.


static func _node() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Music") if tree else null


static func play(id: String) -> void:
	var n := _node()
	if n:
		n.play(id)


static func sfx(name: String) -> void:
	var n := _node()
	if n:
		n.sfx(name)


static func current() -> String:
	var n := _node()
	return n.current if n else ""


static func set_muffled(on: bool) -> void:
	var n := _node()
	if n:
		n.set_muffled(on)
