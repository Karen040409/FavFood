class IngredientModel {
  const IngredientModel({
    required this.name,
    required this.baseQuantity,
    required this.unit,
  });

  final String name;
  final double baseQuantity;
  final String unit;

  String displayForServings(int servingSize) {
    final quantity = baseQuantity * servingSize;
    final formatted =
        quantity == quantity.roundToDouble() ? quantity.toInt().toString() : quantity.toString();
    return '$formatted$unit $name';
  }

  /// Deserialize from a Firestore map.
  factory IngredientModel.fromMap(Map<String, dynamic> map) {
    return IngredientModel(
      name: (map['name'] as String?) ?? '',
      baseQuantity: (map['baseQuantity'] as num?)?.toDouble() ?? 0,
      unit: (map['unit'] as String?) ?? '',
    );
  }

  /// Serialize to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'baseQuantity': baseQuantity,
      'unit': unit,
    };
  }
}
