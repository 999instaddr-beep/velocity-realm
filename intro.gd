extends Control

var done := false

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.modulate.a = 0.0
	add_child(box)

	var title := Label.new()
	title.text = "VELOCITY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	box.add_child(title)

	var line := ColorRect.new()
	line.color = Color(0.1, 0.83, 1.0)
	line.custom_minimum_size = Vector2(320, 4)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(line)

	var realm := Label.new()
	realm.text = "REALM"
	realm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	realm.add_theme_font_size_override("font_size", 44)
	realm.add_theme_color_override("font_color", Color(0.1, 0.83, 1.0))
	box.add_child(realm)

	var skip := Button.new()
	skip.text = "SKIP"
	skip.custom_minimum_size = Vector2(140, 70)
	var vs := get_viewport_rect().size
	skip.position = Vector2(vs.x - 170, vs.y - 100)
	skip.pressed.connect(_go)
	add_child(skip)

	var t := create_tween()
	t.tween_property(box, "modulate:a", 1.0, 1.5)
	t.tween_interval(1.5)
	t.tween_property(box, "modulate:a", 0.0, 0.8)
	t.tween_callback(_go)

func _go() -> void:
	if done:
		return
	done = true
	get_tree().change_scene_to_file("res://main.tscn")
