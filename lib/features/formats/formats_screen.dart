import 'package:flutter/material.dart';

class FormatsScreen extends StatelessWidget {
  const FormatsScreen({super.key});

  static const List<_FormatGroup> _groups = <_FormatGroup>[
    _FormatGroup(
      title: 'QR y matrices 2D',
      icon: Icons.qr_code_2,
      formats: <String>[
        'QR Code',
        'Micro QR',
        'Data Matrix',
        'Aztec',
        'PDF417',
        'MaxiCode',
      ],
    ),
    _FormatGroup(
      title: 'Comercio y productos',
      icon: Icons.inventory_2_outlined,
      formats: <String>[
        'EAN-13',
        'EAN-8',
        'UPC-A',
        'UPC-E',
        'GS1 DataBar',
        'GS1 DataBar Expanded',
        'GS1 DataBar Limited',
      ],
    ),
    _FormatGroup(
      title: 'Industria y logística',
      icon: Icons.local_shipping_outlined,
      formats: <String>[
        'Code 128',
        'Code 39',
        'Code 93',
        'Codabar',
        'ITF',
        'ITF-14',
        'Interleaved 2 of 5',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Formatos compatibles',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La aplicación solicita al motor detectar todos los '
                  'formatos disponibles. La compatibilidad exacta depende '
                  'del sistema operativo, el dispositivo y el navegador.',
                ),
              ],
            ),
          ),
        ),
        SliverList.separated(
          itemCount: _groups.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            final _FormatGroup group = _groups[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(group.icon),
                          const SizedBox(width: 10),
                          Text(
                            group.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: group.formats
                            .map((String format) => Chip(label: Text(format)))
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Contenido interpretado',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enlaces, texto, redes Wi-Fi, contactos, correos, '
                      'teléfonos, SMS, ubicaciones, eventos, ISBN, productos '
                      'y documentos compatibles con el motor nativo.',
                    ),
                    const Divider(height: 28),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.privacy_tip_outlined),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El reconocimiento se realiza localmente. El '
                            'historial queda guardado en el dispositivo y '
                            'puede borrarse desde la aplicación.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FormatGroup {
  const _FormatGroup({
    required this.title,
    required this.icon,
    required this.formats,
  });

  final String title;
  final IconData icon;
  final List<String> formats;
}
