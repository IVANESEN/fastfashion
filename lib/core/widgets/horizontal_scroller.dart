import 'package:flutter/material.dart';

/// Fila de chips desplazable de borde a borde.
///
/// El [padding] vive *dentro* del scroll: en reposo la fila queda alineada con
/// el resto del contenido, pero al desplazarse los chips salen por el borde
/// de la pantalla en vez de cortarse en el margen.
class HorizontalScroller extends StatelessWidget {
  const HorizontalScroller({
    required this.children,
    this.spacing = 8,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
