# Landing de GitHub Pages

Esta carpeta es el sitio publicado en
<https://vladimiracunadev-create.github.io/universal-code-scanner/>.

El workflow [`deploy-landing.yml`](../.github/workflows/deploy-landing.yml) monta
el sitio final en tres pasos:

| Ruta publicada | Origen |
|---|---|
| `/` | esta carpeta tal cual |
| `/assets/capturas/*.png` | copiadas de `docs/images/capturas/` |
| `/assets/flujo-seguridad.svg` | copiado de `docs/images/` |
| `/assets/icon-512.png` | copiado de `assets/launcher/web/Icon-512.png` |
| `/app/` | `flutter build web --release --base-href /universal-code-scanner/app/` |

Las imágenes **no se duplican aquí**: viven una sola vez en el repositorio y se
copian al artefacto durante la publicación. Por eso, al abrir `index.html`
directamente desde el disco, las capturas, el diagrama y el enlace a `/app/`
aparecen rotos. Para verlos en local, reproduce el montaje:

```bash
mkdir -p /tmp/_site/assets/capturas
cp -r landing/. /tmp/_site/
cp docs/images/capturas/*.png /tmp/_site/assets/capturas/
cp docs/images/flujo-seguridad.svg /tmp/_site/assets/
cp assets/launcher/web/Icon-512.png /tmp/_site/assets/icon-512.png
python3 -m http.server 8000 --directory /tmp/_site
```

La PWA de `/app/` solo se genera en el workflow. Para probarla en local basta
con `flutter run -d chrome`, sin `--base-href`.
