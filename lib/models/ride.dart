class Ride {
  final int? id;
  final double valor;
  final String plataforma;
  final DateTime data;
  final String? observacao;
  final int? shiftId;
  final double? distKm;

  Ride({
    this.id,
    required this.valor,
    required this.plataforma,
    required this.data,
    this.observacao,
    this.shiftId,
    this.distKm,
  });

  /// R$/km — null se distância desconhecida
  double? get eficiencia =>
      (distKm != null && distKm! > 0) ? valor / distKm! : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor': valor,
      'plataforma': plataforma,
      'data': data.toIso8601String(),
      'observacao': observacao,
      'shift_id': shiftId,
      'dist_km': distKm,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as int?,
      valor: (map['valor'] as num).toDouble(),
      plataforma: map['plataforma'] as String,
      data: DateTime.parse(map['data'] as String),
      observacao: map['observacao'] as String?,
      shiftId: map['shift_id'] as int?,
      distKm: (map['dist_km'] as num?)?.toDouble(),
    );
  }

  Ride copyWith({
    int? id,
    double? valor,
    String? plataforma,
    DateTime? data,
    String? observacao,
    int? shiftId,
    double? distKm,
  }) {
    return Ride(
      id: id ?? this.id,
      valor: valor ?? this.valor,
      plataforma: plataforma ?? this.plataforma,
      data: data ?? this.data,
      observacao: observacao ?? this.observacao,
      shiftId: shiftId ?? this.shiftId,
      distKm: distKm ?? this.distKm,
    );
  }
}

class Plataforma {
  static const String uber = 'Uber';
  static const String noventa9 = '99';
  static const String ifood = 'iFood';
  static const String lalamove = 'Lalamove';
  static const String indrive = 'InDrive';
  static const String particular = 'Particular';
  static const String outro = 'Outro';

  static const List<String> all = [uber, noventa9, ifood, lalamove, indrive, particular, outro];

  static String emoji(String plataforma) {
    switch (plataforma) {
      case uber: return '⚫';
      case noventa9: return '🟡';
      case ifood: return '🔴';
      case lalamove: return '🟠';
      case indrive: return '🟢';
      case particular: return '👤';
      default: return '💰';
    }
  }

  static int color(String plataforma) {
    switch (plataforma) {
      case uber: return 0xFF222222;
      case noventa9: return 0xFFFFCC00;
      case ifood: return 0xFFEA1D2C;
      case lalamove: return 0xFFFF6600;
      case indrive: return 0xFF00C853;
      case particular: return 0xFF7B61FF;
      default: return 0xFF4CAF50;
    }
  }
}
