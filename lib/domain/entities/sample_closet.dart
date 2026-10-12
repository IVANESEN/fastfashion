import 'garment_category.dart';
import 'garment_color.dart';
import 'garment_style.dart';

/// Plantilla de prenda de ejemplo (sin id ni usuario).
class SampleGarment {
  const SampleGarment(this.name, this.category, this.style, this.color);

  final String name;
  final GarmentCategory category;
  final GarmentStyle style;
  final GarmentColor color;
}

/// Clóset de ejemplo basado en el diseño de la app. Sirve para el usuario
/// demo y para el botón "Cargar prendas de ejemplo".
abstract final class SampleCloset {
  static const items = <SampleGarment>[
    SampleGarment(
      'Camisa oxford azul',
      GarmentCategory.top,
      GarmentStyle.casual,
      GarmentPalette.blue,
    ),
    SampleGarment(
      'Polo negro',
      GarmentCategory.top,
      GarmentStyle.formal,
      GarmentPalette.black,
    ),
    SampleGarment(
      'Blusa lila',
      GarmentCategory.top,
      GarmentStyle.casual,
      GarmentPalette.lilac,
    ),
    SampleGarment(
      'Camiseta blanca',
      GarmentCategory.top,
      GarmentStyle.casual,
      GarmentPalette.white,
    ),
    SampleGarment(
      'Camiseta deportiva gris',
      GarmentCategory.top,
      GarmentStyle.sporty,
      GarmentPalette.gray,
    ),
    SampleGarment(
      'Chino beige',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.beige,
    ),
    SampleGarment(
      'Jeans oscuro',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.navy,
    ),
    SampleGarment(
      'Pantalón blanco',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.white,
    ),
    SampleGarment(
      'Pantalón de vestir negro',
      GarmentCategory.bottom,
      GarmentStyle.formal,
      GarmentPalette.black,
    ),
    SampleGarment(
      'Jogger gris',
      GarmentCategory.bottom,
      GarmentStyle.sporty,
      GarmentPalette.gray,
    ),
    SampleGarment(
      'Tenis blancos',
      GarmentCategory.shoes,
      GarmentStyle.sporty,
      GarmentPalette.white,
    ),
    SampleGarment(
      'Mocasines café',
      GarmentCategory.shoes,
      GarmentStyle.formal,
      GarmentPalette.brown,
    ),
    SampleGarment(
      'Sandalias camel',
      GarmentCategory.shoes,
      GarmentStyle.casual,
      GarmentPalette.camel,
    ),
    SampleGarment(
      'Chaqueta de mezclilla',
      GarmentCategory.jacket,
      GarmentStyle.casual,
      GarmentPalette.blue,
    ),
  ];
}
