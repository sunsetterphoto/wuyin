extends Node
## Autoload "Fonts": Chinese characters for every platform. Godot's built-in
## font has no CJK glyphs and Android does not reliably fall back to a system
## font, so a subset of Noto Sans CJK SC (OFL) hangs behind the default font.

const CJK_PATH := "res://assets/fonts/NotoSansCJKsc-Subset.otf"


func _enter_tree() -> void:
	if not ResourceLoader.exists(CJK_PATH):
		return
	var cjk: Font = load(CJK_PATH)
	var base := ThemeDB.fallback_font
	if base and cjk not in base.fallbacks:
		var list := base.fallbacks.duplicate()
		list.append(cjk)
		base.fallbacks = list
