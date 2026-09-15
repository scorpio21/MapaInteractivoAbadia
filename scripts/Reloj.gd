extends Node

var hora_actual := 22

func es_hora_prohibida() -> bool:
    return hora_actual >= 22 or hora_actual < 6

func avanzar_hora(delta: float) -> void:
    # Ejemplo simple: cada X segundos suma una hora
    # Aquí puedes hacer tu propia lógica
    pass



