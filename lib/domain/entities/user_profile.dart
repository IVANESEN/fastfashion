/// Ciudad con coordenadas, usada para consultar el clima.
class City {
  const City(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;

  static const sanSalvador = City('San Salvador', 13.6929, -89.2182);

  static const supported = <City>[
    sanSalvador,
    City('Santa Ana', 13.9942, -89.5597),
    City('San Miguel', 13.4833, -88.1833),
    City('Ciudad de Guatemala', 14.6349, -90.5069),
    City('Tegucigalpa', 14.0723, -87.1921),
    City('San José', 9.9281, -84.0907),
    City('Ciudad de México', 19.4326, -99.1332),
    City('Bogotá', 4.7110, -74.0721),
  ];

  static City byName(String? name) {
    return supported.firstWhere(
      (c) => c.name == name,
      orElse: () => sanSalvador,
    );
  }
}

/// Perfil público del usuario. Tabla `profiles`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.city,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final City city;
  final DateTime createdAt;

  String get initial => displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? displayName : parts.first;
  }

  UserProfile copyWith({String? displayName, City? city}) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'city': city.name,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      email: row['email'] as String? ?? '',
      displayName: row['display_name'] as String? ?? '',
      city: City.byName(row['city'] as String?),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
