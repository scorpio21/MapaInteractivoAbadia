extends SceneTree
## Issue #3: comprueba recursos y generacion de la habitacion 61.
## No modifica el proyecto ni sustituye el renderizador.

const MAP_PATHS: Array[String] = [
	"res://assets/3d_cpc.map",
	"res://assets/3d.map",
	"res://assets/3d_cpc_cinta.map"
]
const TILESET_PATHS: Array[String] = [
	"res://assets/tiles_cpc.png",
	"res://assets/tiles_cpc_noche.png",
	"res://assets/tiles_msx.png",
	"res://assets/tiles_msx2.png",
	"res://assets/tiles_cga.png",
	"res://assets/tilesRemake.png",
	"res://assets/tiles_spectrum.png"
]
const TILESET_NAMES: Array[String] = [
	"Amstrad CPC", "Amstrad CPC noche", "MSX", "MSX2 Remake",
	"PC CGA", "Remake PC", "ZX Spectrum"
]
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS | ", description)
	else:
		failures += 1
		push_error("FAIL | " + description)

func _checksum(bytes: PackedByteArray) -> int:
	var total := 0
	for value in bytes:
		total += int(value)
	return total

func _run() -> void:
	_check(FileAccess.file_exists("res://assets/bloques.bin"), "bloques.bin presente")
	for i in range(TILESET_PATHS.size()):
		var atlas := load(TILESET_PATHS[i]) as Texture2D
		var good := atlas != null
		if good:
			good = atlas.get_width() >= 16 and atlas.get_height() >= 16
			good = good and atlas.get_width() % 16 == 0 and atlas.get_height() % 16 == 0
		_check(good, "tileset %d: %s" % [i, TILESET_NAMES[i]])

	var audio := load("res://assets/original.ogg") as AudioStream
	_check(audio != null, "musica original.ogg cargable")

	var generator := AbadiaScreenGenerator.new()
	for map_path in MAP_PATHS:
		var loaded := generator.load_from_files("res://assets/bloques.bin", map_path)
		_check(loaded, "mapa cargado: " + map_path.get_file())
		if not loaded:
			continue

		generator.set_extended_view(false)
		var normal_elements := generator.generate_screen(61)
		var normal_ok := normal_elements >= 0 and generator.width == 16 and generator.height == 20
		_check(normal_ok, "habitacion 61 normal 16x20 en " + map_path.get_file())
		if normal_ok:
			print("DATOS | mapa=", map_path.get_file(), " habitacion=61 vista=normal elementos=", normal_elements, " checksum=", _checksum(generator.tiles))

		generator.set_extended_view(true)
		var extended_elements := generator.generate_screen(61)
		var extended_ok := extended_elements >= 0 and generator.width == 32 and generator.height == 32
		_check(extended_ok, "habitacion 61 extendida 32x32 en " + map_path.get_file())
		if extended_ok:
			print("DATOS | mapa=", map_path.get_file(), " habitacion=61 vista=extendida elementos=", extended_elements, " checksum=", _checksum(generator.tiles))

	if failures == 0:
		print("ISSUE #3 PRUEBAS AUTOMATICAS OK | ", checks, " comprobaciones")
		print("PENDIENTE | comparar visualmente habitacion 61 y comprobar audio al pulsar el control")
	else:
		push_error("ISSUE #3 | %d fallos en %d comprobaciones" % [failures, checks])
	quit(0 if failures == 0 else 1)
