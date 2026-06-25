class Expense {
  final int? id;
  final double valor;
  final String tipo;
  final String descricao;
  final DateTime data;
  final double? km;

  Expense({
    this.id,
    required this.valor,
    required this.tipo,
    required this.descricao,
    required this.data,
    this.km,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valor': valor,
      'tipo': tipo,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'km': km,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      valor: (map['valor'] as num).toDouble(),
      tipo: map['tipo'] as String,
      descricao: map['descricao'] as String,
      data: DateTime.parse(map['data'] as String),
      km: map['km'] != null ? (map['km'] as num).toDouble() : null,
    );
  }
}

class TipoExpense {
  static const String combustivel = 'Combustível';
  static const String manutencao = 'Manutenção';
  static const List<String> all = [combustivel, manutencao];
}

class MaintenanceAlert {
  final int? id;
  final String tipo;
  final double kmAtual;
  final double kmProxima;
  final String descricao;

  MaintenanceAlert({
    this.id,
    required this.tipo,
    required this.kmAtual,
    required this.kmProxima,
    required this.descricao,
  });

  double get kmRestante => kmProxima - kmAtual;
  bool get precisaAtencao => kmRestante <= 500;
  bool get atrasado => kmRestante <= 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'km_atual': kmAtual,
      'km_proxima': kmProxima,
      'descricao': descricao,
    };
  }

  factory MaintenanceAlert.fromMap(Map<String, dynamic> map) {
    return MaintenanceAlert(
      id: map['id'] as int?,
      tipo: map['tipo'] as String,
      kmAtual: (map['km_atual'] as num).toDouble(),
      kmProxima: (map['km_proxima'] as num).toDouble(),
      descricao: map['descricao'] as String,
    );
  }

  MaintenanceAlert copyWith({
    int? id,
    String? tipo,
    double? kmAtual,
    double? kmProxima,
    String? descricao,
  }) {
    return MaintenanceAlert(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      kmAtual: kmAtual ?? this.kmAtual,
      kmProxima: kmProxima ?? this.kmProxima,
      descricao: descricao ?? this.descricao,
    );
  }
}

class TipoManutencao {
  static const String oleo = 'Troca de Óleo';
  static const String pneu = 'Pneu';
  static const String relacao = 'Relação (Corrente)';
  static const String freio = 'Pastilha de Freio';
  static const String vela = 'Vela de Ignição';
  static const String filtroAr = 'Filtro de Ar';
  static const List<String> all = [oleo, pneu, relacao, freio, vela, filtroAr];
  static Map<String, double> intervaloPadrao = {
    oleo: 3000,
    pneu: 15000,
    relacao: 8000,
    freio: 10000,
    vela: 12000,
    filtroAr: 6000,
  };
}
