class_name AbadiaDiagnostics
extends RefCounted

const TILE_WIDTH: int = 16
const TILE_HEIGHT: int = 8
const BLACK_THRESHOLD: float = 0.04
const BLACK_RATIO_THRESHOLD: float = 0.90
const OPAQUE_RATIO_THRESHOLD: float = 0.75

var tiles_image: Image
var suspicious_cache: Dictionary = {}
var diagnostic_reason_cache: Dictionary = {}

func set_tiles_image(image: Image) -> void:
	tiles_image = image
	clear_cache()

func clear_cache() -> void:
	suspicious_cache.clear()
	diagnostic_reason_cache.clear()

func analyze_grh(grh: int, src_x: int, src_y: int) -> Dictionary:
	if suspicious_cache.has(grh):
		return {
			"suspicious": suspicious_cache[grh],
			"reason": diagnostic_reason_cache[grh]
		}

	var suspicious := false
	var reason := ""

	if tiles_image == null:
		suspicious = true
		reason = "tiles.png no disponible"
		_cache_grh(grh, suspicious, reason)
		return {"suspicious": suspicious, "reason": reason}

	var image_width := tiles_image.get_width()
	var image_height := tiles_image.get_height()
	if (
		src_x < 0
		or src_y < 0
		or src_x + TILE_WIDTH > image_width
		or src_y + TILE_HEIGHT > image_height
	):
		suspicious = true
		reason = "SOURCE FUERA DE tiles.png (%d,%d) en %dx%d" % [
			src_x, src_y, image_width, image_height
		]
		_cache_grh(grh, suspicious, reason)
		return {"suspicious": suspicious, "reason": reason}

	var total_pixels := TILE_WIDTH * TILE_HEIGHT
	var opaque_pixels := 0
	var black_pixels := 0
	for py in range(TILE_HEIGHT):
		for px in range(TILE_WIDTH):
			var color := tiles_image.get_pixel(src_x + px, src_y + py)
			if color.a > 0.10:
				opaque_pixels += 1
				var luminance := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
				if luminance <= BLACK_THRESHOLD:
					black_pixels += 1

	var opaque_ratio := float(opaque_pixels) / float(total_pixels)
	var black_ratio := 0.0
	if opaque_pixels > 0:
		black_ratio = float(black_pixels) / float(opaque_pixels)

	if opaque_ratio >= OPAQUE_RATIO_THRESHOLD and black_ratio >= BLACK_RATIO_THRESHOLD:
		suspicious = true
		reason = "TILE CASI NEGRO (negro %.1f%%, opaco %.1f%%)" % [
			black_ratio * 100.0, opaque_ratio * 100.0
		]
	elif opaque_pixels == 0:
		suspicious = true
		reason = "TILE TOTALMENTE TRANSPARENTE"

	_cache_grh(grh, suspicious, reason)
	return {"suspicious": suspicious, "reason": reason}

func _cache_grh(grh: int, suspicious: bool, reason: String) -> void:
	suspicious_cache[grh] = suspicious
	diagnostic_reason_cache[grh] = reason

func print_selected_cell(
	room_index: int,
	selected_cell: Vector2i,
	selected_grhs: Array[int],
	selected_height: int
) -> void:
	if selected_cell.x < 0 or selected_cell.y < 0:
		return

	print("")
	print("==========================================")
	print(" CELDA SELECCIONADA")
	print("==========================================")
	print("Room: " + str(room_index))
	print("Celda: (" + str(selected_cell.x) + ", " + str(selected_cell.y) + ")")
	for layer in range(selected_grhs.size()):
		var grh: int = selected_grhs[layer]
		print("GRH capa " + str(layer) + ": " + str(grh))
	print("Altura: " + str(selected_height))
	print("------------------------------------------")
	for layer in range(selected_grhs.size()):
		var grh: int = selected_grhs[layer]
		if grh == 0:
			print("Capa " + str(layer) + ": VACIA")
		else:
			var src_x: int = grh & 0xF0
			var src_y: int = ((grh & 0x0F) << 3) + ((grh >> 8) * 128)
			print("Capa " + str(layer) + ": GRH=" + str(grh) + " SRC=(" + str(src_x) + "," + str(src_y) + ")")
			print_selected_grh(grh)
	print("==========================================")
	print("")

func print_selected_grh(grh: int) -> void:
	if grh == 0:
		return

	var src_x: int = grh & 0xF0
	var src_y: int = ((grh & 0x0F) << 3) + ((grh >> 8) * 128)

	if tiles_image == null:
		print("No hay tiles_image disponible.")
		return

	print("")
	print("------------------------------------------")
	print(" ANALISIS DEL GRH")
	print("------------------------------------------")
	print("GRH: " + str(grh))
	print("SRC: (" + str(src_x) + "," + str(src_y) + ")")

	var total_pixels := TILE_WIDTH * TILE_HEIGHT
	var opaque_pixels := 0
	var transparent_pixels := 0
	var black_pixels := 0
	var min_r := 1.0
	var min_g := 1.0
	var min_b := 1.0
	var max_r := 0.0
	var max_g := 0.0
	var max_b := 0.0

	for py in range(TILE_HEIGHT):
		for px in range(TILE_WIDTH):
			var pixel_x := src_x + px
			var pixel_y := src_y + py
			if pixel_x < 0 or pixel_x >= tiles_image.get_width() or pixel_y < 0 or pixel_y >= tiles_image.get_height():
				continue
			var color := tiles_image.get_pixel(pixel_x, pixel_y)
			if color.a <= 0.10:
				transparent_pixels += 1
				continue
			opaque_pixels += 1
			min_r = min(min_r, color.r)
			min_g = min(min_g, color.g)
			min_b = min(min_b, color.b)
			max_r = max(max_r, color.r)
			max_g = max(max_g, color.g)
			max_b = max(max_b, color.b)
			var luminance := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			if luminance <= BLACK_THRESHOLD:
				black_pixels += 1

	print("Total píxeles: " + str(total_pixels))
	print("Opacos: " + str(opaque_pixels))
	print("Transparentes: " + str(transparent_pixels))
	print("Negros: " + str(black_pixels))
	if opaque_pixels > 0:
		var black_ratio := float(black_pixels) / float(opaque_pixels) * 100.0
		print("Porcentaje negro: " + str(snapped(black_ratio, 0.1)) + "%")
	print("RGB mínimo: " + str(min_r) + ", " + str(min_g) + ", " + str(min_b))
	print("RGB máximo: " + str(max_r) + ", " + str(max_g) + ", " + str(max_b))
	print("------------------------------------------")
	print("")

# Valida los límites de los GRH sin dibujar ni modificar el renderizador.
# No analiza el color de los tiles ni considera un GRH=0 como error.
static func find_out_of_bounds_grhs(data: AbadiaData, room_index: int, image_size: Vector2i) -> Array[Dictionary]:
	var problems: Array[Dictionary] = []
	for y in range(22):
		for x in range(20):
			for layer in range(3):
				var grh: int = data.get_grh(room_index, x, y, layer)
				if grh == 0:
					continue
				var src_x: int = grh & 0xF0
				var src_y: int = ((grh & 0x0F) << 3) + ((grh >> 8) * 128)
				if src_x < 0 or src_y < 0 or src_x + 16 > image_size.x or src_y + 8 > image_size.y:
					problems.append({
						"x": x, "y": y, "layer": layer, "grh": grh,
						"src_x": src_x, "src_y": src_y
					})
	return problems
