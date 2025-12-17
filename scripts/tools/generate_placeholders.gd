extends SceneTree

const OUTPUT_DIR := "res://assets/sprites/placeholder"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_make_player()
	_make_desk()
	_make_hook()
	_make_slot()
	_make_coat()
	_make_ticket()
	_make_anchor_ticket()
	quit()

func _make_player() -> void:
	var img := _create_image(128, 128)
	_draw_circle(img, Vector2i(64, 36), 22, Color("#ffe0b2"))
	_draw_circle_outline(img, Vector2i(64, 36), 22, 3, Color("#d4945c"))
	_draw_rect(img, Rect2i(40, 60, 48, 50), Color("#4c74c5"))
	_draw_rect(img, Rect2i(36, 60, 56, 12), Color("#74a8ff"))
	_draw_rect(img, Rect2i(34, 96, 18, 28), Color("#1f3250"))
	_draw_rect(img, Rect2i(76, 96, 18, 28), Color("#1f3250"))
	img.save_png("%s/player.png" % OUTPUT_DIR)

func _make_desk() -> void:
	var img := _create_image(256, 128)
	_draw_rect(img, Rect2i(8, 40, 240, 64), Color("#c7924b"))
	_draw_rect(img, Rect2i(20, 52, 216, 40), Color("#f3d8ab"))
	_draw_rect(img, Rect2i(32, 88, 32, 32), Color("#8d5b23"))
	_draw_rect(img, Rect2i(192, 88, 32, 32), Color("#8d5b23"))
	img.save_png("%s/desk.png" % OUTPUT_DIR)

func _make_hook() -> void:
	var img := _create_image(96, 192)
	_draw_rect(img, Rect2i(44, 12, 8, 120), Color("#6d7ea5"))
	_draw_circle(img, Vector2i(48, 20), 12, Color("#cbd7f5"))
	_draw_circle_outline(img, Vector2i(48, 20), 12, 3, Color("#4a5675"))
	for angle in range(0, 180):
		var rad := deg_to_rad(float(angle))
		var radius := 32
		var x := int(48 + cos(rad) * radius)
		var y := int(120 + sin(rad) * radius)
		_draw_circle(img, Vector2i(x, y), 4, Color("#4a5675"))
	img.save_png("%s/hook.png" % OUTPUT_DIR)

func _make_slot() -> void:
	var img := _create_image(100, 80)
	_draw_rect(img, Rect2i(8, 12, 84, 56), Color(1, 1, 1, 0))
	_draw_rect_outline(img, Rect2i(8, 12, 84, 56), 4, Color("#d9ccff"))
	_draw_rect_outline(img, Rect2i(20, 28, 60, 24), 2, Color("#8f7ed6"))
	img.save_png("%s/slot.png" % OUTPUT_DIR)

func _make_coat() -> void:
	var img := _create_image(128, 128)
	_draw_polygon(img, [
		Vector2i(24, 112),
		Vector2i(16, 56),
		Vector2i(36, 24),
		Vector2i(92, 24),
		Vector2i(112, 56),
		Vector2i(104, 112),
	], Color("#f2aa5c"))
	_draw_rect(img, Rect2i(58, 32, 12, 80), Color("#c26a2e"))
	img.save_png("%s/item_coat.png" % OUTPUT_DIR)

func _make_ticket() -> void:
	var img := _create_image(128, 80)
	_draw_rect(img, Rect2i(12, 16, 104, 48), Color("#ffd74c"))
	_draw_rect_outline(img, Rect2i(12, 16, 104, 48), 4, Color("#bf8a00"))
	_draw_rect(img, Rect2i(28, 32, 72, 16), Color("#ffef9c"))
	img.save_png("%s/item_ticket.png" % OUTPUT_DIR)

func _make_anchor_ticket() -> void:
	var img := _create_image(128, 96)
	_draw_rect(img, Rect2i(10, 20, 108, 56), Color("#c2e3ff"))
	_draw_rect_outline(img, Rect2i(10, 20, 108, 56), 4, Color("#287bd0"))
	_draw_circle(img, Vector2i(64, 48), 18, Color(0, 0, 0, 0))
	_draw_circle_outline(img, Vector2i(64, 48), 18, 3, Color("#287bd0"))
	_draw_rect(img, Rect2i(60, 24, 8, 24), Color("#287bd0"))
	_draw_rect(img, Rect2i(44, 60, 40, 6), Color("#287bd0"))
	img.save_png("%s/item_anchor_ticket.png" % OUTPUT_DIR)

func _create_image(width: int, height: int) -> Image:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _draw_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, color)

func _draw_rect_outline(img: Image, rect: Rect2i, thickness: int, color: Color) -> void:
	_draw_rect(img, Rect2i(rect.position.x, rect.position.y, rect.size.x, thickness), color)
	_draw_rect(img, Rect2i(rect.position.x, rect.position.y + rect.size.y - thickness, rect.size.x, thickness), color)
	_draw_rect(img, Rect2i(rect.position.x, rect.position.y, thickness, rect.size.y), color)
	_draw_rect(img, Rect2i(rect.position.x + rect.size.x - thickness, rect.position.y, thickness, rect.size.y), color)

func _draw_circle(img: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			if (Vector2(x, y) - Vector2(center)).length_squared() <= float(radius * radius):
				img.set_pixel(x, y, color)

func _draw_circle_outline(img: Image, center: Vector2i, radius: int, thickness: int, color: Color) -> void:
	var inner_sq := float((radius - thickness) * (radius - thickness))
	var outer_sq := float(radius * radius)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var dist := (Vector2(x, y) - Vector2(center)).length_squared()
			if dist <= outer_sq and dist >= inner_sq:
				img.set_pixel(x, y, color)

func _draw_polygon(img: Image, points: Array, color: Color) -> void:
	var min_y: int = points[0].y
	var max_y: int = points[0].y
	for point in points:
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	for y in range(min_y, max_y + 1):
		var intersections: Array = []
		for i in range(points.size()):
			var a: Vector2i = points[i]
			var b: Vector2i = points[(i + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				var t := float(y - a.y) / float(b.y - a.y)
				var x := int(a.x + t * (b.x - a.x))
				intersections.append(x)
		intersections.sort()
		for j in range(0, intersections.size(), 2):
			var x_start: int = intersections[j]
			var x_end: int = intersections[j + 1]
			for x in range(x_start, x_end + 1):
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)
