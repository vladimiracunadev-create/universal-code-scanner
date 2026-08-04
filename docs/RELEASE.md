# Lista de publicación

Esta lista describe lo necesario para llevar la aplicación a las tiendas. **No
forma parte del alcance de 1.0.0**, que se publica como código fuente verificado
sin firma ni artefactos distribuibles. El estado real de verificación de la
versión actual está en [`../VALIDATION.md`](../VALIDATION.md).

## Calidad

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build apk --release`
- [ ] `flutter build appbundle --release`
- [ ] `flutter build web --release`
- [ ] `flutter build ipa --release` en macOS
- [ ] `flutter build macos --release` en macOS

## Dispositivos

- [ ] Android API 24, versión actual y tres gamas de hardware.
- [ ] iPhone con Touch ID y Face ID.
- [ ] iPad y rotación.
- [ ] macOS Intel y Apple Silicon cuando sea posible.
- [ ] Chrome, Safari, Edge y Firefox para PWA.
- [ ] HTTPS, HSTS, CSP y cabeceras de seguridad para la PWA.
- [ ] Cámara denegada, revocada y restaurada.
- [ ] Galería, PDF y memoria limitada.

## Banco de códigos

- [ ] Todos los formatos declarados.
- [ ] Invertidos, baja luz, pequeños, curvos, dañados y múltiples.
- [ ] URL sospechosas y esquemas bloqueados.
- [ ] Wi-Fi, OTP, vCard, VEVENT, GS1, pagos y AAMVA.
- [ ] PNG/SVG generado y relectura del resultado.

## Tiendas

- [ ] Identificador, firma y certificados.
- [ ] Íconos, splash, capturas y descripción.
- [ ] Política de privacidad final y correo de soporte.
- [ ] Declaraciones de uso de cámara, fotos, Face ID y datos.
- [ ] Revisión de dependencias y licencias.
