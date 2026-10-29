"""Extremos geometricos de estudo, em coordenadas normalizadas; nao estimam anatomia de imagens."""
from __future__ import annotations

import math


def points(standing: tuple, action: str, index: int) -> list[list[float]]:
    result = [list(xy) for xy in standing]

    def turn(anchor: int, joints: tuple, degrees: float) -> None:
        angle = math.radians(degrees)
        ox, oy = result[anchor]
        for joint in joints:
            x, y = result[joint][0] - ox, result[joint][1] - oy
            result[joint] = [ox + x * math.cos(angle) - y * math.sin(angle),
                             oy + x * math.sin(angle) + y * math.cos(angle)]

    if action == 'idle':
        rise = (0, -.008, -.016, -.016, -.008, 0)[index]
        for joint in (0, 1, 2, 3, 4, 5, 6, 7, 14, 15, 16, 17):
            result[joint][1] += rise
    elif action == 'walk':
        swing = (20, 14, 0, -14, -20, -14, 0, 14)[index]
        turn(8, (9, 10), swing)
        turn(11, (12, 13), -swing)
        turn(2, (3, 4), -swing)
        turn(5, (6, 7), swing)
    elif action == 'attack':
        turn(5, (6, 7), (0, 40, -80, -55, 0)[index])
        turn(2, (3, 4), (0, -15, 30, 20, 0)[index])
    elif action == 'die':
        # Rotacao rigida do manequim conserva proporcoes; o artista decide queda, apoios e impacto.
        turn(8, tuple(range(18)), (0, -8, -25, -50, -75, -90, -90)[index])
        low, high = min(p[1] for p in result), max(p[1] for p in result)
        shift = (.97 - high) * min(1, index / 4)
        for p in result:
            p[1] += shift
        min_x, max_x = min(p[0] for p in result), max(p[0] for p in result)
        shift_x = max(0, .02 - min_x) - max(0, max_x - .98)
        for p in result:
            p[0] += shift_x
    if any(not 0 <= v <= 1 for xy in result for v in xy):
        raise ValueError('receita excedeu a tela; corrija a geometria, nao recorte o corpo')
    return result
