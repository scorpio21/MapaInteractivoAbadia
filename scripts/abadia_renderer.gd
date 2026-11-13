class_name AbadiaRenderer
extends Node2D

const VIEW_WIDTH: int = 320
const VIEW_HEIGHT: int = 208

const MAP_WIDTH: int = 320
const MAP_HEIGHT: int = 176

const CELL_WIDTH: int = 16
const CELL_HEIGHT: int = 8

const ROOM_WIDTH: int = 20
const ROOM_HEIGHT: int = 22
const LAYERS: int = 3

const TILE_WIDTH: int = 16
const TILE_HEIGHT: int = 8

const DEFAULT_ZOOM: int = 3
const MIN_ZOOM: int = 1
const MAX_ZOOM: int = 5

# ============================================================
# DIAGNÓSTICO
# ============================================================

# Si está activo, los GRH sospechosos se marcan en rojo.
var diagnostic_enabled: bool = false

# Imagen de tiles para analizar píxeles.
var tiles_image: Image
var diagnostics: AbadiaDiagnostics = AbadiaDiagnostics.new()

# Cuadrados sospechosos encontrados durante el render.
var suspicious_tiles: Array[Dictionary] = []

# ============================================================
# RENDER
# ============================================================

var tiles_texture: Texture2D
var data: AbadiaData
var room_index: int = 0
var zoom_level: float = DEFAULT_ZOOM

# Visualización progresiva provisional por grupos de GRH.
# El contador NO equivale a los elementos lógicos originales del visor.
var show_border: bool = true
var progressive_enabled: bool = false
const PROGRESSIVE_INTERVAL: float = 0.16
const TEST_ROOM: int = 77
const TEST_ROOM_STEPS: int = 28
const MAX_PREVIEW_STEPS: int = 32
var total_elements: int = 1
var visible_elements: int = 1
var _progressive_accumulator: float = 0.0

# Motor arquitectónico ORIGINAL (bloques.bin + 3d*.map).
# Modo GRH anterior permanece disponible para comparar.
var original_mode: bool = false
var original_generator: AbadiaScreenGenerator
var original_tileset: Texture2D
var original_room_number: int = 23
var original_extended: bool = false

func configure_original_engine(generator: AbadiaScreenGenerator, atlas: Texture2D) -> void:
	original_generator = generator
	original_tileset = atlas
	if original_mode:
		_restart_progressive()

func set_original_mode(enabled: bool) -> void:
	if enabled and (original_generator == null or original_tileset == null):
		push_warning("Motor arquitectónico no disponible; se mantiene el GRH")
		return
	original_mode = enabled
	_restart_progressive()

func set_original_room(number: int) -> void:
	original_room_number = number
	if original_mode:
		_restart_progressive()

func set_original_map_bytes(bytes: PackedByteArray) -> void:
	if original_generator == null:
		return
	original_generator.set_screen_data(bytes)
	if original_mode:
		_restart_progressive()

func set_original_tileset(atlas: Texture2D) -> void:
	if atlas == null:
		return
	original_tileset = atlas
	if original_mode:
		queue_redraw()

func set_original_extended(enabled: bool) -> void:
	original_extended = enabled
	if original_generator != null:
		original_generator.set_extended_view(enabled)
	if original_mode:
		_restart_progressive()

func get_logical_render_size() -> Vector2:
	if original_mode and original_generator != null and original_tileset != null:
		var tile_width: float = float(original_tileset.get_width()) / 16.0
		var tile_height: float = float(original_tileset.get_height()) / 16.0
		return Vector2(float(AbadiaScreenGenerator.EXTENDED_WIDTH if original_extended else AbadiaScreenGenerator.BASE_WIDTH) * tile_width,
			float(AbadiaScreenGenerator.EXTENDED_HEIGHT if original_extended else AbadiaScreenGenerator.BASE_HEIGHT) * tile_height)
	return Vector2(VIEW_WIDTH, VIEW_HEIGHT)


signal element_progress_changed(visible: int, total: int)

func set_show_border(enabled: bool) -> void:
	show_border = enabled
	queue_redraw()

func _refresh_element_count() -> void:
	if original_mode and original_generator != null:
		var result: int = original_generator.generate_screen(original_room_number, -1)
		total_elements = maxi(0, result)
		return
	# Recuento provisional por GRH únicos, calculado para la habitación activa.
	# Para la 77 conservamos 28 pasos de prueba; no son elementos .map reales.
	if data == null:
		total_elements = 1
		return
	var unique_grhs: Dictionary = {}
	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):
			for layer in range(LAYERS):
				var grh: int = data.get_grh(room_index, x, y, layer)
				if grh != 0:
					unique_grhs[grh] = true
	total_elements = TEST_ROOM_STEPS if room_index == TEST_ROOM else clampi(unique_grhs.size(), 1, MAX_PREVIEW_STEPS)

func set_visible_elements(count: int) -> void:
	progressive_enabled = false
	set_process(false)
	visible_elements = clampi(count, 0, total_elements)
	element_progress_changed.emit(visible_elements, total_elements)
	queue_redraw()

func set_progressive_enabled(enabled: bool) -> void:
	progressive_enabled = enabled
	_restart_progressive()

func _restart_progressive() -> void:
	_refresh_element_count()
	_progressive_accumulator = 0.0
	visible_elements = 0 if progressive_enabled else total_elements
	set_process(progressive_enabled)
	element_progress_changed.emit(visible_elements, total_elements)
	queue_redraw()

func _process(delta: float) -> void:
	if not progressive_enabled:
		set_process(false)
		return
	_progressive_accumulator += delta
	var interval: float = 0.1 if original_mode else PROGRESSIVE_INTERVAL
	while _progressive_accumulator >= interval and visible_elements < total_elements:
		_progressive_accumulator -= interval
		visible_elements += 1
		element_progress_changed.emit(visible_elements, total_elements)
	if visible_elements >= total_elements:
		progressive_enabled = false
		set_process(false)
	queue_redraw()


var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_grhs: Array[int] = [0, 0, 0]
var selected_height: int = 0

func _ready() -> void:
	set_process(false)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func setup(
	p_tiles_texture: Texture2D,
	p_data: AbadiaData,
	p_room_index: int = 0
) -> void:
	tiles_texture = p_tiles_texture
	data = p_data
	room_index = p_room_index

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Obtenemos una copia de la imagen para poder analizar
	# los píxeles del tileset.
	if tiles_texture != null:
		tiles_image = tiles_texture.get_image()
	diagnostics.set_tiles_image(tiles_image)

	_restart_progressive()

func set_tiles_texture(texture: Texture2D) -> void:
	tiles_texture = texture
	tiles_image = texture.get_image() if texture != null else null
	diagnostics.set_tiles_image(tiles_image)
	queue_redraw()


func set_room(index: int) -> void:
	if data == null:
		return

	var count: int = data.get_room_count()

	if count <= 0:
		return

	if index < 0:
		index = 0

	if index >= count:
		index = count - 1

	room_index = index

	_restart_progressive()


func set_zoom(value: float) -> void:
	zoom_level = clampf(value, 0.1 if original_mode else float(MIN_ZOOM), float(MAX_ZOOM))

	scale = Vector2(
		zoom_level,
		zoom_level
	)

	queue_redraw()

func zoom_in() -> void:
	set_zoom(zoom_level + 1)


func zoom_out() -> void:
	set_zoom(zoom_level - 1)


# ============================================================
# ENTRADA DEL DIAGNÓSTICO
# ============================================================

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	if event is InputEventKey:
		if event.keycode == KEY_F3:
			diagnostic_enabled = not diagnostic_enabled

			print(
                "Diagnóstico GRH: %s"
				% (
                    "ACTIVADO"
					if diagnostic_enabled
					else "DESACTIVADO"
				)
			)

			queue_redraw()


# ============================================================
# DIBUJADO PRINCIPAL
# ============================================================

func _draw() -> void:
	scale = Vector2(
#		effective_zoom
		zoom_level,
		zoom_level
	)

	if original_mode and original_generator != null and original_tileset != null:
		_draw_original_screen()
		return

	# Fondo original.
	draw_rect(
		Rect2(
			0,
			0,
			VIEW_WIDTH,
			VIEW_HEIGHT
		),
		Color.BLACK
	)

	if tiles_texture == null:
		return

	if data == null:
		return

	if data.get_room_count() <= 0:
		return

	# Limpiamos los resultados del render actual.
	suspicious_tiles.clear()

	_render_room()

	if show_border:
		draw_rect(Rect2(0.5, 0.5, MAP_WIDTH - 1.0, MAP_HEIGHT - 1.0), Color(0.68, 0.68, 0.68, 0.8), false, 1.0)

	# Las marcas se dibujan DESPUÉS del mapa.
	# Así siempre son visibles.
	if diagnostic_enabled:
		_draw_diagnostic_overlay()
	if diagnostic_enabled:
		_draw_selected_cell()

# ============================================================
# DIBUJO ARQUITECTÓNICO ORIGINAL: orden de elementos del .map
# ============================================================

func _draw_original_screen() -> void:
	var image_size: Vector2 = get_logical_render_size()
	draw_rect(Rect2(Vector2.ZERO, image_size), Color.BLACK)
	var result: int = original_generator.generate_screen(original_room_number, visible_elements)
	if result < 0:
		return
	var atlas_w: int = original_tileset.get_width()
	var atlas_h: int = original_tileset.get_height()
	var tile_w: int = atlas_w / 16
	var tile_h: int = atlas_h / 16
	if tile_w <= 0 or tile_h <= 0:
		return
	var width: int = original_generator.width
	var height: int = original_generator.height
	var planes: int = original_generator.num_planes
	var buffer: PackedByteArray = original_generator.tiles
	var source_zero := Rect2(0.0, 0.0, float(tile_w), float(tile_h))
	for y in range(height):
		for x in range(width):
			var dest := Rect2(float(x * tile_w), float(y * tile_h), float(tile_w), float(tile_h))
			# Exactamente como el canvas JS: base 0, después planos no vacíos.
			draw_texture_rect_region(original_tileset, dest, source_zero)
			for plane in range(planes):
				var index: int = ((y * width + x) * planes + plane) * 3 + 2
				var tile_id: int = int(buffer[index])
				if tile_id == 0:
					continue
				var src := Rect2(float((tile_id & 15) * tile_w), float((tile_id >> 4) * tile_h), float(tile_w), float(tile_h))
				draw_texture_rect_region(original_tileset, dest, src)
	if show_border and original_extended:
		draw_rect(Rect2(Vector2.ZERO, image_size), Color(0.68, 0.68, 0.68, 0.8), false, 1.0)

# ============================================================
# RENDER DE HABITACIÓN
# ============================================================

func _render_room() -> void:
	if data == null:
		return

	# Agrupación temporal por tipo de GRH: NO son elementos
	# estructurales del .map. Evita el corte por filas y conserva el
	# orden original de superposición de todos los tiles.
	var operations: Array[Vector4i] = []
	var distinct_grhs: Array[int] = []
	var found_grhs: Dictionary = {}
	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):
			operations.append(Vector4i(x, y, 0, -1))
			for layer in range(LAYERS):
				var grh: int = data.get_grh(room_index, x, y, layer)
				if grh != 0:
					operations.append(Vector4i(x, y, grh, layer))
					if not found_grhs.has(grh):
						found_grhs[grh] = true
						distinct_grhs.append(grh)

	var grh_to_step: Dictionary = {}
	if total_elements > 1:
		var count: int = distinct_grhs.size()
		for i in range(count):
			var step: int = int(floor(float(i) * float(total_elements) / float(maxi(1, count))))
			grh_to_step[distinct_grhs[i]] = step

	for op in operations:
		var step: int = 0 if op.z == 0 else int(grh_to_step.get(op.z, 0))
		if visible_elements <= step:
			continue
		_draw_grh(op.x * CELL_WIDTH, op.y * CELL_HEIGHT, op.z, op.x, op.y, op.w)


# ============================================================
# DIBUJO DE GRH
# ============================================================

func _draw_grh(
	dest_x: int,
	dest_y: int,
	grh: int,
	cell_x: int,
	cell_y: int,
	layer: int
) -> void:

	# =============================================================
	# GRH 0 ES VÁLIDO
	#
	# En el motor Java original GRH 0 no se ignora.
	# Corresponde al tile SRC=(0,0), utilizado como fondo/base.
	# =============================================================

	var src_x: int = (
		grh & 0xF0
	)

	var src_y: int = (
		((grh & 0x0F) << 3)
		+ ((grh >> 8) * 128)
	)

	var source_rect := Rect2(
		src_x,
		src_y,
		TILE_WIDTH,
		TILE_HEIGHT
	)

	# =============================================================
	# DIAGNÓSTICO
	# =============================================================

	if diagnostic_enabled and grh != 0:
		var diagnostic: Dictionary = diagnostics.analyze_grh(grh, src_x, src_y)

		if diagnostic["suspicious"]:
			suspicious_tiles.append({
				"x": dest_x,
				"y": dest_y,
				"cell_x": cell_x,
				"cell_y": cell_y,
				"layer": layer,
				"grh": grh,
				"src_x": src_x,
				"src_y": src_y,
				"reason": diagnostic["reason"]
			})

	# =============================================================
	# DESTINO
	# =============================================================

	var destination_rect := Rect2(
		dest_x,
		dest_y,
		TILE_WIDTH,
		TILE_HEIGHT
	)

	# =============================================================
	# IMPORTANTE:
	#
	# NO dibujamos magenta.
	#
	# El tile conserva su transparencia original, igual que Java.
	# =============================================================

	draw_texture_rect_region(
		tiles_texture,
		destination_rect,
		source_rect
	)

# ============================================================
# MARCAS ROJAS
# ============================================================

func _draw_diagnostic_overlay() -> void:
	# Inspección separada del motor gráfico. Solo se ejecuta con F3.
	if data == null or tiles_image == null:
		return

	var anomalies: Array[Dictionary] = AbadiaDiagnostics.find_out_of_bounds_grhs(
		data, room_index, tiles_image.get_size()
	)
	for anomaly in anomalies:
		var rect := Rect2(
			float(anomaly["x"]) * CELL_WIDTH,
			float(anomaly["y"]) * CELL_HEIGHT,
			TILE_WIDTH,
			TILE_HEIGHT
		)
		draw_rect(rect, Color.YELLOW, false, 1.0)
		print("[GRH FUERA] Room=%d Celda=(%d,%d) Capa=%d GRH=%d SRC=(%d,%d)" % [
			room_index, anomaly["x"], anomaly["y"], anomaly["layer"],
			anomaly["grh"], anomaly["src_x"], anomaly["src_y"]
		])


func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if not event.pressed:
			return

		if data == null:
			return

		if not diagnostic_enabled:
			return

		# Posición del ratón respecto al renderer.
		var local_pos: Vector2 = to_local(event.position)

		# Fuera del mapa.
		if local_pos.x < 0:
			return

		if local_pos.y < 0:
			return

		if local_pos.x >= MAP_WIDTH:
			return

		if local_pos.y >= MAP_HEIGHT:
			return

		# Convertir píxeles a celda.
		var cell_x: int = int(
			floor(local_pos.x / CELL_WIDTH)
		)

		var cell_y: int = int(
			floor(local_pos.y / CELL_HEIGHT)
		)

		if cell_x < 0 or cell_x >= ROOM_WIDTH:
			return

		if cell_y < 0 or cell_y >= ROOM_HEIGHT:
			return

		selected_cell = Vector2i(
			cell_x,
			cell_y
		)

		selected_grhs = [
			data.get_grh(
				room_index,
				cell_x,
				cell_y,
				0
			),
			data.get_grh(
				room_index,
				cell_x,
				cell_y,
				1
			),
			data.get_grh(
				room_index,
				cell_x,
				cell_y,
				2
			)
		]

		selected_height = data.get_height(
			room_index,
			cell_x,
			cell_y
		)

		diagnostics.print_selected_cell(
			room_index, selected_cell, selected_grhs, selected_height
		)

		queue_redraw()
func _draw_selected_cell() -> void:

	if selected_cell.x < 0:
		return

	var x: int = selected_cell.x * CELL_WIDTH
	var y: int = selected_cell.y * CELL_HEIGHT

	var rect := Rect2(
		x,
		y,
		CELL_WIDTH,
		CELL_HEIGHT
	)

	draw_rect(
		rect,
		Color(
			1.0,
			1.0,
			1.0,
			1.0
		),
		false,
		2.0
	)


