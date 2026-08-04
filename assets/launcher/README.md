# Iconos de la aplicación

Estos PNG **no son recursos de ejecución** y por eso no se declaran en la
sección `flutter: assets:` de `pubspec.yaml`: empaquetarlos dentro de la
aplicación solo aumentaría su tamaño sin que ningún widget los use. Son
entradas de compilación que `tool/bootstrap.py` copia a los proyectos nativos
generados.

| Ruta | Destino |
|---|---|
| `android/mipmap-*/ic_launcher.png` | Icono heredado de Android, cinco densidades |
| `android/mipmap-*/ic_launcher_foreground.png` | Capa frontal del icono adaptativo y del monocromo |
| `web/Icon-*.png` | Iconos de la PWA, incluidas las variantes *maskable* |
| `web/favicon.png` | Favicon del sitio |
| `icon-1024.png` | Maestro para documentación y fichas futuras |

## Cómo regenerarlos

El diseño vive en código, no en un binario opaco, para que la geometría sea
revisable en una revisión de cambios:

```bash
python3 -m pip install pillow
python3 tool/generate_launcher_icons.py
```

Pillow solo hace falta para redibujar el icono. Compilar la aplicación no lo
requiere, y por eso la CI no lo instala.
