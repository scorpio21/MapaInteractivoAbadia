extends Node2D

# ============================================================
# MAPA INTERACTIVO - LA ABADÍA DEL CRIMEN
# Layout:
#   - Render lógico de la Abadía: 320x208
#   - Panel derecho fijo para el mapa
#   - Escalado automático sin cortar el render
#   - El minimapa nunca invade el área del render
# ============================================================

# Atlas del visor original: índice 0 NO es assets/tiles.png.
const ORIGINAL_TILESET_PATHS: Array[String] = [
	"res://assets/tiles_cpc.png",
	"res://assets/tiles_cpc_noche.png",
	"res://assets/tiles_msx.png",
	"res://assets/tiles_msx2.png",
	"res://assets/tiles_cga.png",
	"res://assets/tilesRemake.png",
	"res://assets/tiles_spectrum.png"
]
const TILESET_PATHS: Array[String] = [
	"res://assets/tiles.png",
	"res://assets/tiles_cpc_noche.png",
	"res://assets/tiles_msx.png",
	"res://assets/tiles_msx2.png",
	"res://assets/tiles_cga.png",
	"res://assets/tilesRemake.png",
	"res://assets/tiles_spectrum.png"
]
const MAP_PATHS: Array[String] = [
	"res://assets/3d_cpc.map",
	"res://assets/3d.map",
	"res://assets/3d_cpc_cinta.map"
]
const MUSIC_PATH := "res://assets/original.ogg"
const DEFAULT_TILESET: int = 0
const DEFAULT_MAP: int = 0
const HABITACIONES_PATH := "res://data/habitaciones.bin"
const ALTURAS_PATH := "res://data/alturas.bin"

const DEFAULT_ROOM: int = 23

# Resolución lógica original del framebuffer Java.
const FRAMEBUFFER_WIDTH: float = 320.0
const FRAMEBUFFER_HEIGHT: float = 208.0

# Panel derecho.
const SIDEBAR_WIDTH: float = 310.0
const SIDEBAR_GAP: float = 10.0
const OUTER_MARGIN: float = 4.0

# Zoom solicitado por el usuario. El zoom real se limita automáticamente
# al espacio disponible para que nunca se corte el render.
var requested_zoom: float = 5.0
var current_zoom: float = 1.0

var data: AbadiaData
var renderer: AbadiaRenderer
var mapa: MapaAbadia
var music_player: AudioStreamPlayer
var active_map_data: PackedByteArray
var original_generator: AbadiaScreenGenerator
var original_enabled: bool = false
var selected_tileset: int = DEFAULT_TILESET
var selected_map: int = DEFAULT_MAP
var original_mode_button: Button

var _layout_pending: bool = false

# Barra inferior temporal de pasos de dibujo.
var elements_footer: Panel
var elements_slider: HSlider
var elements_label: Label
var elements_status: Label
var _syncing_slider: bool = false
const FOOTER_HEIGHT: float = 76.0


func _ready() -> void:
	_configure_window()
	_load_data()
	_create_renderer()
	_create_map()
	_create_audio()
	_create_elements_footer()
	_connect_viewport_resize()
	_apply_layout()


func _configure_window() -> void:
	var window_size := Vector2i(1920, 1200)
	DisplayServer.window_set_size(window_size)

	var screen: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen)
	var position := (screen_size - window_size) / 2

	DisplayServer.window_set_position(position)


func _load_data() -> void:
	data = AbadiaData.new()

	if not data.load_habitaciones(HABITACIONES_PATH):
		push_error("No se pudo cargar habitaciones.bin")
		return

	if not data.load_alturas(ALTURAS_PATH):
		push_warning("No se pudo cargar alturas.bin")



func _create_renderer() -> void:
	if data == null:
		return

	# habitaciones.bin contiene GRH del atlas original 256x3376.
	# Los atlas Remake/MSX/CPC tienen otra distribución y requieren
	# un adaptador de coordenadas antes de poder usarse aquí.
	var tiles := load(TILESET_PATHS[0]) as Texture2D

	if tiles == null:
		push_error("No se pudo cargar tiles.png")
		return


	renderer = AbadiaRenderer.new()
	renderer.name = "AbadiaRenderer"
	add_child(renderer)

	renderer.setup(
		tiles,
		data,
		DEFAULT_ROOM
	)
	renderer.element_progress_changed.connect(_on_element_progress_changed)
	original_generator = AbadiaScreenGenerator.new()
	if original_generator.load_from_files("res://assets/bloques.bin", MAP_PATHS[DEFAULT_MAP]):
		var original_atlas := load(ORIGINAL_TILESET_PATHS[DEFAULT_TILESET]) as Texture2D
		if original_atlas == null:
			push_error("No se pudo cargar atlas arquitectónico")
		else:
			renderer.configure_original_engine(original_generator, original_atlas)
	else:
		push_error("No se pudo cargar intérprete original: " + original_generator.last_error)


func _create_map() -> void:
	mapa = MapaAbadia.new()
	mapa.name = "MapaAbadia"

	add_child(mapa)

	mapa.room_selected.connect(_on_room_selected)
	mapa.floor_changed.connect(_on_floor_changed)
	mapa.tileset_changed.connect(_on_tileset_changed)
	mapa.map_changed.connect(_on_map_changed)
	mapa.music_changed.connect(_on_music_changed)
	mapa.border_changed.connect(_on_border_changed)
	mapa.progressive_changed.connect(_on_progressive_changed)
	if mapa.extended_toggle != null:
		mapa.extended_toggle.toggled.connect(_on_extended_changed)

	mapa.set_tileset(DEFAULT_TILESET)
	mapa.set_map(DEFAULT_MAP)
	mapa.select_room(DEFAULT_ROOM)
	_on_map_changed(DEFAULT_MAP)

func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicaOriginal"
	music_player.stream = load(MUSIC_PATH) as AudioStream
	add_child(music_player)
	if music_player.stream == null:
		push_error("No se pudo cargar la música: " + MUSIC_PATH)
	else:
		music_player.volume_db = -8.0
		music_player.bus = "Master"

func _on_tileset_changed(index: int) -> void:
	if renderer == null or index < 0 or index >= ORIGINAL_TILESET_PATHS.size():
		return
	selected_tileset = index
	# En modo GRH, tiles.png se mantiene fijo para evitar alterar sus índices.
	# En modo original, se utiliza la imagen real seleccionada del visor.
	var original_atlas := load(ORIGINAL_TILESET_PATHS[index]) as Texture2D
	if original_atlas == null:
		push_error("No se pudo cargar el tileset: " + ORIGINAL_TILESET_PATHS[index])
		return
	renderer.set_original_tileset(original_atlas)
	if original_enabled:
		_apply_layout()

func _on_map_changed(index: int) -> void:
	if index < 0 or index >= MAP_PATHS.size():
		return
	var file := FileAccess.open(MAP_PATHS[index], FileAccess.READ)
	if file == null:
		push_error("No se pudo cargar el mapa: " + MAP_PATHS[index])
		return
	active_map_data = file.get_buffer(file.get_length())
	file.close()
	selected_map = index
	if renderer != null:
		renderer.set_original_map_bytes(active_map_data)
		_update_element_footer()

func _on_original_mode_pressed() -> void:
	if renderer == null or original_generator == null:
		return
	original_enabled = not original_enabled
	renderer.set_original_mode(original_enabled)
	original_enabled = renderer.original_mode
	original_mode_button.text = "Motor: ORIGINAL" if original_enabled else "Motor: GRH"
	_apply_layout()
	_update_element_footer()

func _on_border_changed(enabled: bool) -> void:
	if renderer != null:
		renderer.set_show_border(enabled)

func _on_progressive_changed(enabled: bool) -> void:
	if renderer != null:
		renderer.set_progressive_enabled(enabled)

func _on_extended_changed(enabled: bool) -> void:
	if renderer != null:
		renderer.set_original_extended(enabled)
		_apply_layout()

func _on_music_changed(enabled: bool) -> void:
	if music_player == null:
		return
	if music_player.stream == null:
		push_warning("Música no disponible: " + MUSIC_PATH)
		return
	if enabled:
		music_player.play()
	else:
		music_player.stop()


func _on_room_selected(room_number: int, floor: int) -> void:
	if renderer == null:
		return

	var data_block: int = mapa.logical_room_to_data_block(room_number)

	if data_block < 0 or data_block >= data.get_room_count():
		return

	renderer.set_room(data_block)
	renderer.set_original_room(room_number)
	_update_element_footer()


func _on_floor_changed(_floor: int) -> void:
	_apply_layout()


func _create_elements_footer() -> void:
	elements_footer = Panel.new()
	elements_footer.name = "BarraElementos"
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#182044")
	style.border_color = Color("#293568")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	elements_footer.add_theme_stylebox_override("panel", style)
	add_child(elements_footer)

	var caption := Label.new()
	caption.text = "Elementos"
	caption.position = Vector2(16, 12)
	caption.size = Vector2(82, 24)
	elements_footer.add_child(caption)

	elements_slider = HSlider.new()
	elements_slider.name = "DeslizadorElementos"
	elements_slider.min_value = 0
	elements_slider.max_value = 1
	elements_slider.step = 1
	elements_slider.value = 1
	elements_slider.value_changed.connect(_on_elements_slider_changed)
	elements_footer.add_child(elements_slider)

	elements_label = Label.new()
	elements_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	elements_footer.add_child(elements_label)

	original_mode_button = Button.new()
	original_mode_button.name = "BotonMotorOriginal"
	original_mode_button.text = "Motor: GRH"
	original_mode_button.tooltip_text = "Cambiar entre renderizador GRH y elementos originales"
	original_mode_button.pressed.connect(_on_original_mode_pressed)
	elements_footer.add_child(original_mode_button)

	elements_status = Label.new()
	elements_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elements_footer.add_child(elements_status)
	_update_element_footer()

func _on_elements_slider_changed(value: float) -> void:
	if _syncing_slider or renderer == null:
		return
	renderer.set_visible_elements(int(value))
	if mapa != null and mapa.progressive_toggle != null:
		mapa.progressive_toggle.set_pressed_no_signal(false)

func _on_element_progress_changed(_visible: int, _total: int) -> void:
	_update_element_footer()

func _update_element_footer() -> void:
	if renderer == null or elements_slider == null:
		return
	_syncing_slider = true
	elements_slider.max_value = float(renderer.total_elements)
	elements_slider.value = float(renderer.visible_elements)
	elements_slider.editable = renderer.total_elements > 0
	elements_label.text = "%d/%d" % [renderer.visible_elements, renderer.total_elements]
	var floor_name := ""
	if mapa != null:
		floor_name = ["Iglesia", "Scriptorium", "Biblioteca"][clampi(mapa.current_floor, 0, 2)]
	if original_enabled:
		elements_status.text = "Habitación: %d — Elementos: %d/%d — %s — Original (%s)" % [
			renderer.original_room_number, renderer.visible_elements, renderer.total_elements,
			floor_name, ["CPC", "MSX", "CPC cinta"][selected_map]]
	else:
		elements_status.text = "Habitación: %d — Pasos GRH: %d/%d — %s (provisional)" % [renderer.room_index, renderer.visible_elements, renderer.total_elements, floor_name]
	_syncing_slider = false

func _connect_viewport_resize() -> void:
	var viewport := get_viewport()

	if viewport == null:
		return

	if not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	if _layout_pending:
		return

	_layout_pending = true
	call_deferred("_apply_layout_deferred")


func _apply_layout_deferred() -> void:
	_layout_pending = false
	_apply_layout()


func _apply_layout() -> void:
	if renderer == null or mapa == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size

	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# --------------------------------------------------------
	# 1. Reservamos siempre el panel derecho.
	# --------------------------------------------------------
	var sidebar_x: float = viewport_size.x - SIDEBAR_WIDTH - OUTER_MARGIN

	if sidebar_x < FRAMEBUFFER_WIDTH + OUTER_MARGIN:
		# En ventanas extremadamente estrechas reducimos el ancho
		# del panel antes de permitir que invada el render.
		var minimum_render_width: float = FRAMEBUFFER_WIDTH + 20.0
		sidebar_x = minimum_render_width

	var render_area_x: float = OUTER_MARGIN
	var render_area_y: float = OUTER_MARGIN

	var render_area_width: float = (
		sidebar_x
		- SIDEBAR_GAP
		- render_area_x
	)

	var render_area_height: float = (
		viewport_size.y
		- OUTER_MARGIN * 2.0
		- FOOTER_HEIGHT - 8.0
	)

	if render_area_width < FRAMEBUFFER_WIDTH:
		render_area_width = FRAMEBUFFER_WIDTH

	if render_area_height < FRAMEBUFFER_HEIGHT:
		render_area_height = FRAMEBUFFER_HEIGHT

	# --------------------------------------------------------
	# 2. Calculamos el máximo zoom que cabe.
	#
	#    El framebuffer lógico siempre sigue siendo 320x208.
	#    No deformamos X/Y y nunca cortamos el render.
	# --------------------------------------------------------
	var logical_size: Vector2 = renderer.get_logical_render_size()
	var max_zoom_x: float = render_area_width / logical_size.x
	var max_zoom_y: float = render_area_height / logical_size.y

	var max_zoom: float = min(max_zoom_x, max_zoom_y)

	# Modo extendido puede necesitar reducir la escala para caber.
	max_zoom = max(max_zoom, 0.1)

	current_zoom = min(requested_zoom, max_zoom)

	renderer.set_zoom(current_zoom)

	var rendered_size := logical_size * current_zoom

	# --------------------------------------------------------
	# 3. Centramos el render dentro de su zona izquierda.
	# --------------------------------------------------------
	var render_x: float = render_area_x + (
		render_area_width - rendered_size.x
	) * 0.5

	var render_y: float = render_area_y + (
		render_area_height - rendered_size.y
	) * 0.5

	renderer.position = Vector2(
		round(render_x),
		round(render_y)
	)

	# --------------------------------------------------------
	# 4. Panel derecho.
	# --------------------------------------------------------
	var sidebar_size := Vector2(
		SIDEBAR_WIDTH,
		viewport_size.y - OUTER_MARGIN * 2.0 - FOOTER_HEIGHT - 8.0
	)

	mapa.position = Vector2(
		viewport_size.x - SIDEBAR_WIDTH - OUTER_MARGIN,
		OUTER_MARGIN
	)

	mapa.set_layout_size(sidebar_size)

	if elements_footer != null:
		elements_footer.position = Vector2(OUTER_MARGIN, viewport_size.y - FOOTER_HEIGHT - OUTER_MARGIN)
		elements_footer.size = Vector2(viewport_size.x - OUTER_MARGIN * 2.0, FOOTER_HEIGHT)
		elements_slider.position = Vector2(100, 10)
		# Reservar espacio para el conmutador de motor.
		elements_slider.size = Vector2(maxf(120.0, elements_footer.size.x - 360), 27)
		original_mode_button.position = Vector2(elements_footer.size.x - 235, 8)
		original_mode_button.size = Vector2(130, 32)
		elements_label.position = Vector2(elements_footer.size.x - 90, 12)
		elements_label.size = Vector2(72, 24)
		elements_status.position = Vector2(12, 43)
		elements_status.size = Vector2(elements_footer.size.x - 24, 24)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	if renderer == null or data == null:
		return

	if event is not InputEventKey:
		return

	match event.keycode:
		KEY_RIGHT:
			renderer.set_room(
				min(
					renderer.room_index + 1,
					data.get_room_count() - 1
				)
			)

		KEY_LEFT:
			renderer.set_room(
				max(
					renderer.room_index - 1,
					0
				)
			)

		KEY_HOME:
			renderer.set_room(0)

		KEY_END:
			renderer.set_room(
				data.get_room_count() - 1
			)

		KEY_1:
			requested_zoom = 1.0
			_apply_layout()

		KEY_2:
			requested_zoom = 2.0
			_apply_layout()

		KEY_3:
			requested_zoom = 3.0
			_apply_layout()

		KEY_4:
			requested_zoom = 4.0
			_apply_layout()

		KEY_5:
			requested_zoom = 5.0
			_apply_layout()

		KEY_PLUS, KEY_KP_ADD:
			requested_zoom = min(
				requested_zoom + 0.25,
				8.0
			)
			_apply_layout()

		KEY_MINUS, KEY_KP_SUBTRACT:
			requested_zoom = max(
				requested_zoom - 0.25,
				1.0
			)
			_apply_layout()
