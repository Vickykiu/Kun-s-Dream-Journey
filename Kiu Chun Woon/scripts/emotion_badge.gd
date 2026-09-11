extends Control
@export_enum("happy", "calm", "worried", "sad") var emotion: String = "calm":
	set(value):
		emotion = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.43
	var ink := Color("#30232b")
	var face := Color("#f1c97b")
	if emotion == "worried":
		face = Color("#a9c9df")
	elif emotion == "sad":
		face = Color("#c3a7cb")
	draw_circle(center + Vector2(0, 3), radius + 2, Color(0, 0, 0, 0.45))
	draw_circle(center, radius, face)
	draw_arc(center, radius, 0, TAU, 48, Color("#f8e4bb"), 2, true)
	for side in [-1.0, 1.0]:
		var eye := center + Vector2(side * radius * 0.34, -radius * 0.18)
		draw_circle(eye, radius * 0.085, ink)
		if emotion == "worried" or emotion == "sad":
			draw_line(eye + Vector2(-radius * 0.16, -radius * 0.19),
				eye + Vector2(radius * 0.16, -radius * 0.26), ink, 2, true)
	if emotion == "happy":
		draw_arc(center + Vector2(0, radius * 0.02), radius * 0.48,
			0.20, PI - 0.20, 24, ink, 3, true)
	elif emotion == "sad":
		draw_arc(center + Vector2(0, radius * 0.68), radius * 0.35,
			PI + 0.30, TAU - 0.30, 24, ink, 3, true)
	elif emotion == "worried":
		draw_arc(center + Vector2(0, radius * 0.33), radius * 0.14,
			0, TAU, 24, ink, 2, true)
		draw_circle(center + Vector2(radius * 0.64, -radius * 0.06),
			radius * 0.12, Color("#5fa8dc"))
	else:
		draw_arc(center + Vector2(0, radius * 0.04), radius * 0.38,
			0.45, PI - 0.45, 24, ink, 2, true)
