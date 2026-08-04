# Bloqueo de dependencias

El proyecto es una aplicación, no un paquete, por lo que `pubspec.lock` **se
versiona**. El archivo incluido se generó con Flutter 3.44.7, la versión fijada
en [`.fvmrc`](../../.fvmrc), y la CI comprueba que exista.

```bash
flutter pub get
```

## Restricciones conocidas

Tres dependencias no pueden fijarse en su última versión publicada porque
generan conflictos de resolución. Cada una está anclada de forma deliberada:

| Paquete | Fijado en | Motivo |
|---|---|---|
| `share_plus` | `12.0.2` | Desde `13.0.0` exige `win32 ^6`, incompatible con el `win32 ^5.9` que requiere `file_picker 11.x` |
| `pdfrx` | `2.4.5` | Desde `2.4.6` arrastra `archive ^4`, incompatible con el `archive ^3.6.1` que requiere `excel 4.0.6` |
| `excel` | `4.0.6` | Última versión publicada; es la que ancla `archive` a la serie 3 |

Estos anclajes deben revisarse cuando `excel` publique una versión sobre
`archive ^4`, o cuando `file_picker` estabilice su serie 12 sobre `win32 ^6`.
`flutter pub outdated` los muestra como actualizables, pero subirlos sin resolver
antes el conflicto rompe la resolución.

## Cadena de compilación de Android

`tool/bootstrap.py` fija además el Android Gradle Plugin, el Kotlin Gradle Plugin
y la distribución de Gradle del proyecto generado:

| Componente | Fijado en | Motivo |
|---|---|---|
| Android Gradle Plugin | `8.11.1` | La plantilla de Flutter 3.44.7 genera AGP 9, cuyo valor por defecto es Kotlin integrado |
| Kotlin Gradle Plugin | `2.2.20` | Mínimo que Flutter 3.44.7 no marca como obsoleto |
| Gradle | `8.14.3` | Compatible con AGP 8.11.1 y sin aviso de obsolescencia |

El motivo del anclaje de AGP es concreto: varios plugins de este conjunto de
dependencias —`file_picker` entre ellos— dejan de aplicar el Kotlin Gradle
Plugin en cuanto detectan AGP 9, dando por hecho que el Kotlin integrado está
activo. Pero la misma plantilla entrega `android.builtInKotlin=false`, así que
nadie compila el código Kotlin de esos plugins y la compilación falla con
`cannot find symbol: class FilePickerPlugin`. Activar el Kotlin integrado rompe
el caso contrario, en los plugins que sí aplican el plugin de Kotlin.

La serie 8 de AGP deja a todos los plugins en la ruta que todos soportan.
Revisar cuando esos plugins publiquen versiones compatibles con Kotlin
integrado.

## Antes de etiquetar una versión

```bash
./tool/finalize_stable.sh
```

Ese comando ejecuta la resolución, el análisis estricto, las pruebas, las
compilaciones de Android y web, y exige que el lockfile exista antes de
continuar.
