/// Tipo de prenda. El valor `name` es el que se persiste en la base de datos.
enum GarmentCategory {
  top('Camisa', 'Camisas'),
  bottom('Pantalón', 'Pantalones'),
  shoes('Zapatos', 'Zapatos'),
  jacket('Chaqueta', 'Chaquetas');

  const GarmentCategory(this.label, this.plural);

  /// Nombre singular mostrado al usuario ("Camisa").
  final String label;

  /// Nombre plural usado en filtros ("Camisas").
  final String plural;

  static GarmentCategory fromName(String? value) {
    return GarmentCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => GarmentCategory.top,
    );
  }
}
