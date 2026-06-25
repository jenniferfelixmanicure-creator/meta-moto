class Goal {
  final int? id;
  final double valorDiario;
  final double valorSemanal;
  final double valorMensal;
  final DateTime criadoEm;

  Goal({
    this.id,
    required this.valorDiario,
    required this.valorSemanal,
    required this.valorMensal,
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor_diario': valorDiario,
      'valor_semanal': valorSemanal,
      'valor_mensal': valorMensal,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as int?,
      valorDiario: (map['valor_diario'] as num).toDouble(),
      valorSemanal: (map['valor_semanal'] as num).toDouble(),
      valorMensal: (map['valor_mensal'] as num).toDouble(),
      criadoEm: DateTime.parse(map['criado_em'] as String),
    );
  }

  Goal copyWith({
    int? id,
    double? valorDiario,
    double? valorSemanal,
    double? valorMensal,
    DateTime? criadoEm,
  }) {
    return Goal(
      id: id ?? this.id,
      valorDiario: valorDiario ?? this.valorDiario,
      valorSemanal: valorSemanal ?? this.valorSemanal,
      valorMensal: valorMensal ?? this.valorMensal,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
