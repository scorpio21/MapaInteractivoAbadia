extends Node

# Algoritmo BFS extraído de BuscadorRutas.java
var abbey_map

func _init(mapa) -> void:
	abbey_map = mapa

func buscar_camino(planta: int, origen: Vector2i, destino: Vector2i) -> Array:
	var visitados := {}
	var cola := []
	var padres := {}

	cola.append(origen)
	visitados[origen] = true

	while cola.size() > 0:
		var actual = cola.pop_front()

		if actual == destino:
			return _reconstruir_camino(padres, origen, destino)

		var vecinos := _obtener_vecinos(planta, actual)
		for vecino in vecinos:
			if not visitados.has(vecino):
				visitados[vecino] = true
				padres[vecino] = actual
				cola.append(vecino)

	return []

func _obtener_vecinos(planta: int, pos: Vector2i) -> Array:
	var vecinos := []
	var conexion = abbey_map.get_conexion(planta, pos.x, pos.y)

	if conexion & 0x01:
		vecinos.append(pos + Vector2i(1, 0))
	if conexion & 0x02:
		vecinos.append(pos + Vector2i(0, 1))
	if conexion & 0x04:
		vecinos.append(pos + Vector2i(-1, 0))
	if conexion & 0x08:
		vecinos.append(pos + Vector2i(0, -1))

	return vecinos

func _reconstruir_camino(padres: Dictionary, origen: Vector2i, destino: Vector2i) -> Array:
	var camino := []
	var actual = destino

	while actual != origen:
		camino.push_front(actual)
		actual = padres[actual]

	camino.push_front(origen)
	return camino

func buscar_camino_entre_plantas(planta_origen: int, planta_destino: int, origen: Vector2i, destino: Vector2i) -> Array:
	var escaleras := _buscar_escaleras(planta_origen, planta_destino)

	if escaleras.is_empty():
		return []

	var camino_a_escaleras = buscar_camino(planta_origen, origen, escaleras[0])
	var camino_desde_escaleras = buscar_camino(planta_destino, escaleras[1], destino)

	return camino_a_escaleras + camino_desde_escaleras

func _buscar_escaleras(planta_origen: int, planta_destino: int) -> Array:
	var escaleras := []

	for y in range(16):
		for x in range(16):
			var conexion = abbey_map.get_conexion(planta_origen, x, y)
			if planta_destino > planta_origen and (conexion & 0x10):
				escaleras.append(Vector2i(x, y))
			elif planta_destino < planta_origen and (conexion & 0x20):
				escaleras.append(Vector2i(x, y))

	return escaleras

func verificar_conexion(planta: int, origen: Vector2i, destino: Vector2i) -> bool:
	return buscar_camino(planta, origen, destino).size() > 0
