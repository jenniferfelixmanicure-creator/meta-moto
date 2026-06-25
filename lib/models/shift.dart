class Shift {
  final int? id;
  final DateTime inicio;
  final DateTime? fim;
  final double totalGanho;
  final int totalCorridas;

  Shift({
    this.id,
    required this.inicio,
    this.fim,
    this.totalGanho = 0,
    this.totalCorridas = 0,
  });

  Duration get duracao {
    final end = fim ?? DateTime.now();
    return end.difference(inicio);
  }

  double get mediaPorHora {
    final horas = duracao.inSeconds / 3600;
    if (horas == 0) return 0;
    return totalGanho / horas;
  }

  bool get ativo => fim == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inicio': inicio.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'total_ganho': totalGanho,
      'total_corridas': totalCorridas,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as int?,
      inicio: DateTime.parse(map['inicio'] as String),
      fim: map['fim'] != null ? DateTime.parse(map['fim'] as String) : null,
      totalGanho: (map['total_ganho'] as num).toDouble(),
      totalCorridas: map['total_corridas'] as int,
    );
  }

  Shift copyWith({
    int? id,
    DateTime? inicio,
    DateTime? fim,
    double? totalGanho,
    int? totalCorridas,
  }) {
    return Shift(
      id: id ?? this.id,
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
      totalGanho: totalGanho ?? this.totalGanho,
      totalCorridas: totalCorridas ?? this.totalCorridas,
    );
  }
}
