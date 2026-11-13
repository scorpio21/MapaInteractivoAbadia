#!/usr/bin/env python3
"""Investigación no destructiva de GRH por habitación de La Abadía.

IMPORTANTE: Los registros GRH no son los «elementos» lógicos del visor web.
Lee bloques físicos de habitaciones.bin y exporta únicamente observaciones verificables.
"""
from __future__ import annotations
import argparse
from collections import Counter
import csv
from pathlib import Path

WIDTH, HEIGHT, LAYERS = 20, 22, 3
RECORD_BYTES = 4
ROOM_BYTES = WIDTH * HEIGHT * LAYERS * RECORD_BYTES


def grhs_room(blob: bytes, index: int):
    offset = index * ROOM_BYTES
    if index < 0 or offset + ROOM_BYTES > len(blob):
        raise ValueError(f'Bloque físico fuera de rango: {index}')
    for y in range(HEIGHT):
        for x in range(WIDTH):
            for layer in range(LAYERS):
                p = offset + ((y * WIDTH + x) * LAYERS + layer) * RECORD_BYTES
                grh = blob[p+2] | (blob[p+3] << 8)
                yield x, y, layer, grh


def save_csv(path, rows, fields):
    with path.open('w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter=';')
        w.writeheader()
        w.writerows(rows)


def run(bin_path: Path, out: Path, rooms):
    blob = bin_path.read_bytes()
    if len(blob) % ROOM_BYTES:
        raise ValueError(f'Tamaño incorrecto: {len(blob)}; no es divisible entre {ROOM_BYTES}')
    total = len(blob) // ROOM_BYTES
    out.mkdir(parents=True, exist_ok=True)
    summary = []
    for room in rooms:
        if room < 0 or room >= total:
            raise ValueError(f'Bloque {room} fuera de 0..{total-1}')
        records = list(grhs_room(blob, room))
        active = [(x,y,layer,grh) for x,y,layer,grh in records if grh != 0]
        counts = Counter(grh for _,_,_,grh in active)
        first = {}
        operations = []
        for order, (x,y,layer,grh) in enumerate(records):
            if grh == 0:
                continue
            if grh not in first:
                first[grh] = len(first) + 1
            operations.append({'orden_registro':order, 'x':x, 'y':y, 'capa':layer,
                               'grh':grh, 'aparicion_grh':first[grh]})
        save_csv(out / f'bloque_{room:03d}_grh.csv', operations,
                 ['orden_registro','x','y','capa','grh','aparicion_grh'])
        save_csv(out / f'bloque_{room:03d}_frecuencias.csv',
                 [{'grh':g,'veces':n,'primera_aparicion':first[g]} for g,n in counts.most_common()],
                 ['grh','veces','primera_aparicion'])
        summary.append({'bloque_fisico':room,'registros':len(records),
                        'grh_no_cero':len(active),'grh_distintos':len(counts),
                        'elementos_originales':'NO DISPONIBLES'})
    save_csv(out/'resumen.csv', summary,
             ['bloque_fisico','registros','grh_no_cero','grh_distintos','elementos_originales'])
    text = ['DIAGNÓSTICO - REGISTROS GRH (NO SON ELEMENTOS DEL VISOR)',
            f'Archivo: {bin_path}', f'Bloques físicos en el binario: {total}',
            'Formato verificado contra abadia_data.gd: 20x22x3, 4 bytes/GRH, bytes 2-3 LE.',
            'ATENCIÓN: Bloque físico y número lógico de habitación pueden diferir.',
            'La numeración 28/28 del visor original NO puede recuperarse contando GRH únicos.', '']
    for row in summary:
        text.append(f"Bloque {row['bloque_fisico']}: {row['registros']} registros, "
                    f"{row['grh_no_cero']} GRH no cero, "
                    f"{row['grh_distintos']} GRH distintos")
    (out/'LEEME_RESULTADOS.txt').write_text('\n'.join(text)+'\n',encoding='utf-8')
    print('\n'.join(text))

if __name__ == '__main__':
    p = argparse.ArgumentParser(description='Diagnóstico de registros GRH; no reemplaza elementos originales')
    p.add_argument('binario', type=Path, help='Ruta habitaciones.bin')
    p.add_argument('--salida', type=Path, default=Path('diagnostico_elementos'))
    p.add_argument('--bloques', nargs='+', type=int, default=[39, 69, 77, 103],
                   help='Índices FÍSICOS de bloque (no IDs lógicos necesariamente)')
    a = p.parse_args()
    run(a.binario, a.salida, a.bloques)
