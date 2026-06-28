enum VehicleType { moto, carro }

extension VehicleTypeExt on VehicleType {
  String get label => this == VehicleType.moto ? 'Moto' : 'Carro';
  String get emoji => this == VehicleType.moto ? '🏍' : '🚗';
  String get rideTerm => this == VehicleType.moto ? 'corrida' : 'viagem';
  String get rideTermPlural => this == VehicleType.moto ? 'corridas' : 'viagens';
  String get driverTerm => this == VehicleType.moto ? 'motoboy' : 'motorista';
  double get defaultKmL => this == VehicleType.moto ? 35.0 : 12.0;
  double get defaultConsumptionFactor => this == VehicleType.moto ? 0.035 : 0.085;
  List<String> get maintenanceItems => this == VehicleType.moto
      ? ['Óleo do motor', 'Corrente', 'Pneus', 'Freios', 'Filtro de ar', 'Velas', 'Relação']
      : ['Óleo do motor', 'Filtro de óleo', 'Pneus', 'Freios', 'Filtro de ar', 'Fluido de freio', 'Correia dentada'];
  List<String> get checklistItems => this == VehicleType.moto
      ? ['Gasolina ok?', 'Pneus calibrados?', 'Capacete limpo?', 'Freios funcionando?', 'Documentos em dia?', 'Celular carregado?', 'Protetor solar passado?', 'Água e lanche?']
      : ['Gasolina ok?', 'Pneus calibrados?', 'Óleo verificado?', 'Freios funcionando?', 'Documentos em dia?', 'Celular carregado?', 'Ar condicionado ok?', 'Água e lanche?'];
}

class VehicleProfile {
  final VehicleType type;
  final String model;
  final String plate;
  final double kmL;
  final double fuelPricePerLiter;
  final bool isMei;
  final String? cnpj;
  final double emergencyReservePct;

  const VehicleProfile({
    required this.type,
    this.model = '',
    this.plate = '',
    this.kmL = 35.0,
    this.fuelPricePerLiter = 6.50,
    this.isMei = false,
    this.cnpj,
    this.emergencyReservePct = 10.0,
  });

  double fuelCostPerKm() => fuelPricePerLiter / kmL;

  VehicleProfile copyWith({
    VehicleType? type,
    String? model,
    String? plate,
    double? kmL,
    double? fuelPricePerLiter,
    bool? isMei,
    String? cnpj,
    double? emergencyReservePct,
  }) {
    return VehicleProfile(
      type: type ?? this.type,
      model: model ?? this.model,
      plate: plate ?? this.plate,
      kmL: kmL ?? this.kmL,
      fuelPricePerLiter: fuelPricePerLiter ?? this.fuelPricePerLiter,
      isMei: isMei ?? this.isMei,
      cnpj: cnpj ?? this.cnpj,
      emergencyReservePct: emergencyReservePct ?? this.emergencyReservePct,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'model': model,
        'plate': plate,
        'kmL': kmL,
        'fuelPrice': fuelPricePerLiter,
        'isMei': isMei,
        'cnpj': cnpj ?? '',
        'reservePct': emergencyReservePct,
      };

  factory VehicleProfile.fromJson(Map<String, dynamic> j) => VehicleProfile(
        type: VehicleType.values[j['type'] as int? ?? 0],
        model: j['model'] as String? ?? '',
        plate: j['plate'] as String? ?? '',
        kmL: (j['kmL'] as num?)?.toDouble() ?? 35.0,
        fuelPricePerLiter: (j['fuelPrice'] as num?)?.toDouble() ?? 6.50,
        isMei: j['isMei'] as bool? ?? false,
        cnpj: j['cnpj'] as String?,
        emergencyReservePct:
            (j['reservePct'] as num?)?.toDouble() ?? 10.0,
      );
}
