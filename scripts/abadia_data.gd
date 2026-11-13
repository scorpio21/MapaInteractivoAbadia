class_name AbadiaData
extends RefCounted


const ROOM_WIDTH: int = 20
const ROOM_HEIGHT: int = 22
const LAYERS: int = 3

const BYTES_PER_GRH: int = 4
const GRHS_PER_ROOM: int = ROOM_WIDTH * ROOM_HEIGHT * LAYERS
const BYTES_PER_ROOM: int = GRHS_PER_ROOM * BYTES_PER_GRH

const HEIGHT_MAP_SIZE: int = 24
const BYTES_PER_HEIGHT_ROOM: int = 576


var habitaciones: PackedByteArray
var alturas: PackedByteArray


func load_habitaciones(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_error("No se pudo abrir habitaciones.bin: " + path)
		return false

	habitaciones = file.get_buffer(file.get_length())
	file.close()

	if habitaciones.size() % BYTES_PER_ROOM != 0:
		push_error(
			"habitaciones.bin tiene un tamaño incorrecto: %d bytes"
			% habitaciones.size()
		)
		return false


	return true


func load_alturas(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		push_warning(
			"No se pudo abrir alturas.bin: " + path
		)
		return false

	alturas = file.get_buffer(file.get_length())
	file.close()


	return true


func get_room_count() -> int:
	if habitaciones.is_empty():
		return 0

	return int(
		habitaciones.size() / BYTES_PER_ROOM
	)


func get_grh(
	room_index: int,
	x: int,
	y: int,
	layer: int
) -> int:

	if habitaciones.is_empty():
		return 0

	if room_index < 0 or room_index >= get_room_count():
		return 0

	if x < 0 or x >= ROOM_WIDTH:
		return 0

	if y < 0 or y >= ROOM_HEIGHT:
		return 0

	if layer < 0 or layer >= LAYERS:
		return 0


	# =========================================================
	# ESTRUCTURA REAL DE habitaciones.bin
	# =========================================================
	#
	# Java recorre:
	#
	#   y
	#     x
	#       capa 0
	#       capa 1
	#       capa 2
	#
	# Es decir:
	#
	#   (y * 20 + x) * 3 + layer
	#
	# NO:
	#
	#   layer * 440 + y * 20 + x
	#
	# =========================================================

	var cell_index: int = (
		y * ROOM_WIDTH
		+ x
	)

	var grh_index: int = (
		cell_index * LAYERS
		+ layer
	)

	var index: int = (
		room_index * BYTES_PER_ROOM
		+ grh_index * BYTES_PER_GRH
	)


	if index + 3 >= habitaciones.size():
		return 0


	# =========================================================
	# Cada registro:
	#
	# byte 0
	# byte 1
	# byte 2 = GRH low
	# byte 3 = GRH high
	#
	# Little Endian
	# =========================================================

	var lo: int = habitaciones[index + 2]
	var hi: int = habitaciones[index + 3]

	return lo | (hi << 8)


func get_height(
	room_index: int,
	x: int,
	y: int
) -> int:

	if alturas.is_empty():
		return 0

	var offset: int = (
		room_index * BYTES_PER_HEIGHT_ROOM
	)

	if (
		offset < 0
		or offset + BYTES_PER_HEIGHT_ROOM > alturas.size()
	):
		return 0

	if x < 0 or x >= HEIGHT_MAP_SIZE:
		return 0

	if y < 0 or y >= HEIGHT_MAP_SIZE:
		return 0

	return alturas[
		offset
		+ y * HEIGHT_MAP_SIZE
		+ x
	] & 0x0F
