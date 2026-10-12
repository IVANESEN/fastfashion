/// Estilo de una prenda u outfit.
enum GarmentStyle {
  casual('Casual'),
  formal('Formal'),
  sporty('Deportivo');

  const GarmentStyle(this.label);

  final String label;

  static GarmentStyle fromName(String? value) {
    return GarmentStyle.values.firstWhere(
      (s) => s.name == value,
      orElse: () => GarmentStyle.casual,
    );
  }
}
