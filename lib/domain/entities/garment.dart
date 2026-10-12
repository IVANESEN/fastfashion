import 'garment_category.dart';
import 'garment_color.dart';
import 'garment_style.dart';

/// Una prenda del clóset del usuario.
class Garment {
  const Garment({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.style,
    required this.color,
    required this.createdAt,
    this.imageUrl,
    this.wearCount = 0,
    this.lastWornAt,
  });

  final String id;
  final String userId;
  final String name;
  final GarmentCategory category;
  final GarmentStyle style;
  final GarmentColor color;
  final DateTime createdAt;

  /// URL pública (Supabase Storage) o data-URI (base de datos local).
  final String? imageUrl;
  final int wearCount;
  final DateTime? lastWornAt;

  bool get hasPhoto => imageUrl != null && imageUrl!.isNotEmpty;

  /// ¿Se usó dentro de los últimos [days] días respecto a [now]?
  bool wornWithin(int days, DateTime now) {
    final worn = lastWornAt;
    if (worn == null) return false;
    return now.difference(worn).inDays < days;
  }

  Garment copyWith({
    String? name,
    GarmentCategory? category,
    GarmentStyle? style,
    GarmentColor? color,
    String? imageUrl,
    bool clearImage = false,
    int? wearCount,
    DateTime? lastWornAt,
  }) {
    return Garment(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      style: style ?? this.style,
      color: color ?? this.color,
      createdAt: createdAt,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      wearCount: wearCount ?? this.wearCount,
      lastWornAt: lastWornAt ?? this.lastWornAt,
    );
  }

  /// Fila con los nombres de columna de la tabla `garments`.
  Map<String, dynamic> toRow() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'category': category.name,
    'style': style.name,
    'color_name': color.name,
    'color_value': color.value,
    'image_url': imageUrl,
    'wear_count': wearCount,
    'last_worn_at': lastWornAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory Garment.fromRow(Map<String, dynamic> row) {
    final colorValue = (row['color_value'] as num?)?.toInt() ?? 0xFF808080;
    return Garment(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String? ?? 'Prenda',
      category: GarmentCategory.fromName(row['category'] as String?),
      style: GarmentStyle.fromName(row['style'] as String?),
      color: GarmentPalette.fromValue(
        colorValue,
        name: row['color_name'] as String?,
      ),
      imageUrl: row['image_url'] as String?,
      wearCount: (row['wear_count'] as num?)?.toInt() ?? 0,
      lastWornAt: _parseDate(row['last_worn_at']),
      createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
