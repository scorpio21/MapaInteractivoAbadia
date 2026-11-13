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

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_grhs: Array[int] = [0, 0, 0]
var selected_height: int = 0

func _ready() -> void:
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

	queue_redraw()

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

	queue_redraw()


func set_zoom(value: float) -> void:
	zoom_level = clamp(
		value,
		float(MIN_ZOOM),
		float(MAX_ZOOM)
	)

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

	# Las marcas se dibujan DESPUÉS del mapa.
	# Así siempre son visibles.
	if diagnostic_enabled:
		_draw_diagnostic_overlay()
	if diagnostic_enabled:
		_draw_selected_cell()

# ============================================================
# RENDER DE HABITACIÓN
# ============================================================

func _render_room() -> void:
	if data == null:
		return

	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):

			var dest_x: int = x * CELL_WIDTH
			var dest_y: int = y * CELL_HEIGHT

			# =====================================================
			# 1. TILE BASE
			#
			# El Java original SIEMPRE dibuja GRH 0 antes de
			# procesar las tres capas.
			#
			# GRH 0 corresponde a SRC=(0,0) del tileset.
			# =====================================================
			_draw_grh(
				dest_x,
				dest_y,
				0,
				x,
				y,
				-1
			)

			# =====================================================
			# 2. LAS TRES CAPAS DE LA CELDA
			# =====================================================
			for layer in range(LAYERS):
				var grh: int = data.get_grh(
					room_index,
					x,
					y,
					layer
				)

				if grh != 0:
					_draw_grh(
						dest_x,
						dest_y,
						grh,
						x,
						y,
						layer
					)


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


