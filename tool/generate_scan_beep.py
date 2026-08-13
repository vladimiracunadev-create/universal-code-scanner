#!/usr/bin/env python3
"""Genera el tono de confirmación de lectura sin dependencias externas.

El archivo resultante se versiona en `assets/sounds/` porque el sonido debe
existir en el paquete instalable: la aplicación no descarga recursos en tiempo
de ejecución. Se regenera con:

    python3 tool/generate_scan_beep.py

Es un doble pitido corto y agudo, la señal que usan los lectores de código de
barras de mostrador, con rampas de entrada y salida para que no suene un chasquido
al principio ni al final de cada tono.
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "sounds" / "scan_success.wav"

SAMPLE_RATE = 44_100
AMPLITUDE = 0.55
# (frecuencia en Hz, duración en segundos). Un silencio corto separa los tonos
# para que se perciban como dos pulsos y no como uno solo más largo.
TONES: tuple[tuple[float, float], ...] = ((2_000.0, 0.055), (0.0, 0.018), (2_800.0, 0.075))
# Duración de las rampas de volumen, en segundos.
RAMP = 0.006


def render() -> bytes:
    samples: list[int] = []
    for frequency, duration in TONES:
        total = int(SAMPLE_RATE * duration)
        ramp = max(1, int(SAMPLE_RATE * RAMP))
        for index in range(total):
            if frequency == 0.0:
                samples.append(0)
                continue
            envelope = min(1.0, index / ramp, (total - index) / ramp)
            value = math.sin(2 * math.pi * frequency * index / SAMPLE_RATE)
            samples.append(int(max(-1.0, min(1.0, value * envelope * AMPLITUDE)) * 32_767))
    return struct.pack(f"<{len(samples)}h", *samples)


def main() -> None:
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(render())
    print(f"Generado {OUTPUT.relative_to(ROOT).as_posix()} ({OUTPUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
