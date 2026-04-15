import 'package:flutter/material.dart';

enum PoiCategory {
  lodging(
    id: 'lodging',
    label: 'Unterkunft',
    icon: Icons.hotel,
    color: Color(0xFF9c27b0),
    gpxSym: 'Lodging',
    gpxType: 'accommodation',
  ),
  food(
    id: 'food',
    label: 'Verpflegung',
    icon: Icons.restaurant,
    color: Color(0xFFe67e22),
    gpxSym: 'Restaurant',
    gpxType: 'food',
  ),
  water(
    id: 'water',
    label: 'Trinkwasser',
    icon: Icons.water_drop,
    color: Color(0xFF2196f3),
    gpxSym: 'Drinking Water',
    gpxType: 'water',
  ),
  shop(
    id: 'shop',
    label: 'Einkauf',
    icon: Icons.shopping_cart,
    color: Color(0xFF4caf50),
    gpxSym: 'Shopping Center',
    gpxType: 'shop',
  ),
  scenic(
    id: 'scenic',
    label: 'Aussicht',
    icon: Icons.landscape,
    color: Color(0xFF009688),
    gpxSym: 'Scenic Area',
    gpxType: 'scenic',
  ),
  camping(
    id: 'camping',
    label: 'Camping',
    icon: Icons.holiday_village,
    color: Color(0xFF795548),
    gpxSym: 'Campground',
    gpxType: 'camping',
  ),
  info(
    id: 'info',
    label: 'Information',
    icon: Icons.info,
    color: Color(0xFF607d8b),
    gpxSym: 'Information',
    gpxType: 'info',
  ),
  other(
    id: 'other',
    label: 'Sonstiges',
    icon: Icons.place,
    color: Color(0xFFff5252),
    gpxSym: 'Flag, Red',
    gpxType: 'waypoint',
  );

  const PoiCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.gpxSym,
    required this.gpxType,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String gpxSym;
  final String gpxType;

  static PoiCategory fromId(String id) => PoiCategory.values.firstWhere(
        (c) => c.id == id,
        orElse: () => PoiCategory.other,
      );
}

class RoutePoi {
  final String id;
  final double lat;
  final double lon;
  final PoiCategory category;
  final String? name;
  final String? note;

  const RoutePoi({
    required this.id,
    required this.lat,
    required this.lon,
    required this.category,
    this.name,
    this.note,
  });

  RoutePoi copyWith({PoiCategory? category, String? name, String? note}) =>
      RoutePoi(
        id: id,
        lat: lat,
        lon: lon,
        category: category ?? this.category,
        name: name ?? this.name,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lon': lon,
        'category': category.id,
        if (name != null) 'name': name,
        if (note != null) 'note': note,
      };

  factory RoutePoi.fromJson(Map<String, dynamic> j) => RoutePoi(
        id: j['id'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        category: PoiCategory.fromId(j['category'] as String),
        name: j['name'] as String?,
        note: j['note'] as String?,
      );
}
