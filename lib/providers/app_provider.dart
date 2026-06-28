import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/ride.dart';
import '../models/goal.dart';
import '../models/expense.dart';
import '../models/shift.dart';
import '../services/location_service.dart';
import '../services/overlay_service.dart';

class AppProvider extends ChangeNotifier {
  static const _channel =
      MethodChannel('com.metamoto.notifications/channel');
  static const _eventChannel =
      EventChannel('com.metamoto.notifications/events');

  final DatabaseHelper _db = DatabaseHelper.instance;
  final LocationService _loc = LocationService.instance;
  final OverlayService _overlay = OverlayService.instance;

  List<Ride> _rides = [];
  List<Expense> _expenses = [];
  Goal? _goal;
  Shift? _activeShift;
  bool _isLoading = false;
  Timer? _shiftTimer;
  StreamSubscription? _notificationSub;
  List<String> _recentAutoRides = [];
  double _kmTotalSalvo = 0.0;

  // ── Eficiência ────────────────────────────────────────────────────────────
  double _limiteEficiencia = 2.0; // R$/km mínimo aceitável
  List<DetectedRide> _detectedRides = []; // histórico das últimas detecções

  double get limiteEficiencia => _limiteEficiencia;
  List<DetectedRide> get detectedRides => List.unmodifiable(_detectedRides);

  // ── Getters básicos ───────────────────────────────────────────────────────
  List<Ride> get rides => _rides;
  List<Expense> get expenses => _expenses;
  Goal? get goal => _goal;
  Shift? get activeShift => _activeShift;
  bool get isLoading => _isLoading;
  bool get shiftAtivo => _activeShift != null;
  List<String> get recentAutoRides => _recentAutoRides;
  Stream<double> get kmStream => _loc.kmStream;
  double get kmTurnoAtual => _loc.kmTurno;
  double get kmTotalAcumulado => _kmTotalSalvo + _loc.kmTurno;

  // ── Totais de ganhos ──────────────────────────────────────────────────────
  double get totalHoje {
    final h = DateTime.now();
    return _rides
        .where((r) =>
            r.data.year == h.year &&
            r.data.month == h.month &&
            r.data.day == h.day)
        .fold(0.0, (s, r) => s + r.valor);
  }

  double get totalSemana {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final fim = inicio.add(const Duration(days: 7));
    return _rides
        .where((r) => !r.data.isBefore(inicio) && r.data.isBefore(fim))
        .fold(0.0, (s, r) => s + r.valor);
  }

  double get totalMes {
    final now = DateTime.now();
    return _rides
        .where(
            (r) => r.data.year == now.year && r.data.month == now.month)
        .fold(0.0, (s, r) => s + r.valor);
  }

  // ── Despesas ──────────────────────────────────────────────────────────────
  double get despesasHoje {
    final h = DateTime.now();
    return _expenses
        .where((e) =>
            e.data.year == h.year &&
            e.data.month == h.month &&
            e.data.day == h.day)
        .fold(0.0, (s, e) => s + e.valor);
  }

  double get despesasMes {
    final now = DateTime.now();
    return _expenses
        .where(
            (e) => e.data.year == now.year && e.data.month == now.month)
        .fold(0.0, (s, e) => s + e.valor);
  }

  double get lucroHoje => totalHoje - despesasHoje;
  double get lucroMes => totalMes - despesasMes;

  // ── Corridas ──────────────────────────────────────────────────────────────
  int get corridasHoje {
    final h = DateTime.now();
    return _rides
        .where((r) =>
            r.data.year == h.year &&
            r.data.month == h.month &&
            r.data.day == h.day)
        .length;
  }

  int get corridasSemana {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final fim = inicio.add(const Duration(days: 7));
    return _rides
        .where((r) => !r.data.isBefore(inicio) && r.data.isBefore(fim))
        .length;
  }

  List<Ride> get ridesHoje {
    final h = DateTime.now();
    return _rides
        .where((r) =>
            r.data.year == h.year &&
            r.data.month == h.month &&
            r.data.day == h.day)
        .toList();
  }

  // ── Metas ─────────────────────────────────────────────────────────────────
  double get progressoDiario =>
      (_goal == null || _goal!.valorDiario == 0)
          ? 0
          : (totalHoje / _goal!.valorDiario).clamp(0.0, 1.0);

  double get progressoSemanal =>
      (_goal == null || _goal!.valorSemanal == 0)
          ? 0
          : (totalSemana / _goal!.valorSemanal).clamp(0.0, 1.0);

  double get progressoMensal =>
      (_goal == null || _goal!.valorMensal == 0)
          ? 0
          : (totalMes / _goal!.valorMensal).clamp(0.0, 1.0);

  double get metaDiariaFaltando => _goal == null
      ? 0
      : (_goal!.valorDiario - totalHoje).clamp(0, double.infinity);

  Map<String, double> get ganhosPorPlataforma {
    final Map<String, double> map = {};
    for (final r in _rides) {
      map[r.plataforma] = (map[r.plataforma] ?? 0) + r.valor;
    }
    return map;
  }

  // ── Ganho por hora ────────────────────────────────────────────────────────
  /// Retorna R$/h do turno ativo, calculando pelo tempo decorrido desde o início.
  double? get ganhoHoraAtual {
    if (_activeShift == null) return null;
    final agora = DateTime.now();
    final minutosDecorridos = agora.difference(_activeShift!.inicio).inMinutes;
    if (minutosDecorridos < 1) return null;
    final horas = minutosDecorridos / 60.0;
    return totalHoje / horas;
  }

  /// R$/h de hoje com base no tempo do primeiro até o último registro.
  double? get ganhoHoraHoje {
    final hoje = ridesHoje;
    if (hoje.isEmpty) return null;
    final primeiro = hoje.last.data;
    final ultimo = hoje.first.data;
    final minutos = ultimo.difference(primeiro).inMinutes;
    if (minutos < 5) return null;
    final horas = minutos / 60.0;
    return totalHoje / horas;
  }

  // ── Comparativo semanal ───────────────────────────────────────────────────
  double get totalSemanaPassada {
    final now = DateTime.now();
    final inicioEsta = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final inicioPassada = inicioEsta.subtract(const Duration(days: 7));
    final fimPassada = inicioEsta;
    return _rides
        .where((r) =>
            !r.data.isBefore(inicioPassada) && r.data.isBefore(fimPassada))
        .fold(0.0, (s, r) => s + r.valor);
  }

  int get corridasSemanaPassada {
    final now = DateTime.now();
    final inicioEsta = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final inicioPassada = inicioEsta.subtract(const Duration(days: 7));
    final fimPassada = inicioEsta;
    return _rides
        .where((r) =>
            !r.data.isBefore(inicioPassada) && r.data.isBefore(fimPassada))
        .length;
  }

  /// Ganhos por dia da semana atual (index 0=seg..6=dom) e da semana passada.
  Map<String, List<double>> get comparativoDiaSemana {
    final now = DateTime.now();
    final inicioEsta = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final inicioPassada = inicioEsta.subtract(const Duration(days: 7));

    final esta = List<double>.filled(7, 0.0);
    final passada = List<double>.filled(7, 0.0);

    for (final r in _rides) {
      if (!r.data.isBefore(inicioEsta) &&
          r.data.isBefore(inicioEsta.add(const Duration(days: 7)))) {
        final d = r.data.weekday - 1; // 0=seg
        if (d >= 0 && d < 7) esta[d] += r.valor;
      } else if (!r.data.isBefore(inicioPassada) &&
          r.data.isBefore(inicioEsta)) {
        final d = r.data.weekday - 1;
        if (d >= 0 && d < 7) passada[d] += r.valor;
      }
    }
    return {'esta': esta, 'passada': passada};
  }

  // ── Carregamento ──────────────────────────────────────────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rides = await _db.getAllRides();
      _expenses = await _db.getAllExpenses();
      _goal = await _db.getGoal();
      _activeShift = await _db.getActiveShift();
      final kmStr = await _db.getSetting('km_total');
      _kmTotalSalvo = double.tryParse(kmStr ?? '0') ?? 0.0;
      _loc.setKmTotal(_kmTotalSalvo);

      // Carrega limite de eficiência salvo
      final prefs = await SharedPreferences.getInstance();
      _limiteEficiencia = prefs.getDouble('limite_eficiencia') ?? 2.0;

      if (_activeShift != null) {
        _startShiftTimer();
        _loc.startTracking();
      }

      // Atualiza o widget da home screen Android
      _syncWidget();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Envia dados atuais para o widget Android.
  void _syncWidget() {
    try {
      final metaDiaria = _goal?.valorDiario ?? 0.0;
      final ganhoHoje = totalHoje;
      final rph = ganhoHoraAtual ?? ganhoHoraHoje ?? 0.0;
      _channel.invokeMethod<void>('updateWidget', {
        'ganho_hoje': ganhoHoje,
        'meta_diaria': metaDiaria,
        'corridas_hoje': corridasHoje,
        'rph': rph,
      });
    } catch (_) {
      // Widget pode não estar instalado — ignora silenciosamente
    }
  }

  // ── Corridas ──────────────────────────────────────────────────────────────
  Future<void> addRide(Ride ride) async {
    await _db.insertRide(ride);
    if (_activeShift != null) {
      final updated = _activeShift!.copyWith(
        totalGanho: _activeShift!.totalGanho + ride.valor,
        totalCorridas: _activeShift!.totalCorridas + 1,
      );
      await _db.updateShift(updated);
      _activeShift = updated;
    }
    await loadData();
  }

  Future<void> deleteRide(int id) async {
    await _db.deleteRide(id);
    await loadData();
  }

  // ── Despesas ──────────────────────────────────────────────────────────────
  Future<void> addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    if (expense.km != null && expense.km! > _kmTotalSalvo) {
      _kmTotalSalvo = expense.km!;
      await _db.setSetting('km_total', _kmTotalSalvo.toString());
      _loc.setKmTotal(_kmTotalSalvo);
    }
    _expenses = await _db.getAllExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    _expenses = await _db.getAllExpenses();
    notifyListeners();
  }

  // ── Metas ─────────────────────────────────────────────────────────────────
  Future<void> saveGoal(Goal goal) async {
    await _db.saveGoal(goal);
    _goal = await _db.getGoal();
    notifyListeners();
  }

  // ── KM ────────────────────────────────────────────────────────────────────
  Future<void> atualizarKmManual(double km) async {
    _kmTotalSalvo = km;
    await _db.setSetting('km_total', km.toString());
    _loc.setKmTotal(km);
    notifyListeners();
  }

  Future<void> _salvarKmTurno() async {
    final novoTotal = _kmTotalSalvo + _loc.kmTurno;
    _kmTotalSalvo = novoTotal;
    await _db.setSetting('km_total', novoTotal.toString());
    _loc.setKmTotal(novoTotal);
  }

  // ── Turno ─────────────────────────────────────────────────────────────────
  Future<void> iniciarTurno() async {
    final shift = Shift(inicio: DateTime.now());
    final id = await _db.insertShift(shift);
    _activeShift = shift.copyWith(id: id);
    _startShiftTimer();
    await _loc.startTracking();
    notifyListeners();
  }

  Future<void> encerrarTurno() async {
    if (_activeShift == null) return;
    await _salvarKmTurno();
    final encerrado = _activeShift!.copyWith(
      fim: DateTime.now(),
      totalGanho: _activeShift!.totalGanho,
    );
    await _db.updateShift(encerrado);
    _activeShift = null;
    _shiftTimer?.cancel();
    _shiftTimer = null;
    await _loc.stopTracking();
    notifyListeners();
  }

  void _startShiftTimer() {
    _shiftTimer?.cancel();
    _shiftTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => notifyListeners());
  }

  // ── Eficiência ────────────────────────────────────────────────────────────
  /// Altera o limite de eficiência (R$/km mínimo aceitável).
  Future<void> setLimiteEficiencia(double limite) async {
    _limiteEficiencia = limite;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('limite_eficiencia', limite);
    notifyListeners();
  }

  /// Calcula eficiência de uma corrida. Retorna null se distância desconhecida.
  double? calcularEficiencia(double valor, double? distKm) {
    if (distKm == null || distKm <= 0) return null;
    return valor / distKm;
  }

  bool isBaixaEficiencia(double? eficiencia) =>
      eficiencia != null && eficiencia < _limiteEficiencia;

  // ── Manutenção ────────────────────────────────────────────────────────────
  Future<List<MaintenanceAlert>> getMaintenanceAlerts() =>
      _db.getAllMaintenanceAlerts();

  Future<void> saveMaintenanceAlert(MaintenanceAlert alert) =>
      _db.upsertMaintenanceAlert(alert);

  // ── Notificações Automáticas ──────────────────────────────────────────────
  Future<bool> checkNotificationPermission() async {
    try {
      return await _channel
              .invokeMethod<bool>('isNotificationListenerEnabled') ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  Future<bool> checkOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ??
          false;
    } catch (_) {
      return _overlay.hasPermission();
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {
      await _overlay.requestPermission();
    }
  }

  void startListeningNotifications() {
    _notificationSub?.cancel();
    _notificationSub = _eventChannel
        .receiveBroadcastStream()
        .listen(_onNotificationReceived, onError: (_) {});
  }

  void stopListeningNotifications() {
    _notificationSub?.cancel();
    _notificationSub = null;
  }

  void _onNotificationReceived(dynamic event) async {
    if (event is! Map) return;

    final plataforma = event['platform'] as String?;
    final valor      = (event['value'] as num?)?.toDouble();
    final tipo       = event['tipo'] as String? ?? 'conclusao';
    final distKm     = (event['dist_km'] as num?)?.toDouble();
    final tempMin    = (event['temp_min'] as num?)?.toInt();
    final ganhoHora  = (event['ganho_hora'] as num?)?.toDouble();
    final nota       = (event['nota'] as num?)?.toDouble();

    if (plataforma == null || valor == null || valor <= 0) return;

    final eficiencia = calcularEficiencia(valor, distKm);
    final baixa      = isBaixaEficiencia(eficiencia);

    // Registra no histórico de detecções
    _detectedRides.insert(
      0,
      DetectedRide(
        plataforma: plataforma,
        valor: valor,
        distKm: distKm,
        eficiencia: eficiencia,
        baixaEficiencia: baixa,
        horario: DateTime.now(),
      ),
    );
    if (_detectedRides.length > 30) _detectedRides.removeLast();

    // ── OFERTA: só mostra o overlay, NÃO salva no banco ──────────────────────
    if (tipo == 'oferta') {
      await _overlay.mostrarOferta(
        plataforma: plataforma,
        valor: valor,
        distKm: distKm,
        tempMin: tempMin,
        eficiencia: eficiencia,
        ganhoHora: ganhoHora,
        nota: nota,
        limiteEficiencia: _limiteEficiencia,
      );
      notifyListeners();
      return;
    }

    // ── CONCLUSÃO: salva no banco e mostra overlay ────────────────────────────
    final ride = Ride(
      valor: valor,
      plataforma: plataforma,
      data: DateTime.now(),
      observacao: distKm != null
          ? 'Auto | ${distKm.toStringAsFixed(1)} km'
          : 'Adicionado automaticamente',
    );
    await addRide(ride);

    final efStr = eficiencia != null
        ? ' | R\$ ${eficiencia.toStringAsFixed(2)}/km'
        : '';
    final kmStr = distKm != null ? ' | ${distKm.toStringAsFixed(1)} km' : '';
    _recentAutoRides.insert(
        0, '$plataforma: R\$ ${valor.toStringAsFixed(2)}$kmStr$efStr');
    if (_recentAutoRides.length > 20) _recentAutoRides.removeLast();

    await _overlay.mostrarOferta(
      plataforma: plataforma,
      valor: valor,
      distKm: distKm,
      eficiencia: eficiencia,
      ganhoHora: ganhoHora,
      limiteEficiencia: _limiteEficiencia,
    );

    notifyListeners();
  }

  // ── Relatórios ────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDailyEarningsForMonth(
          DateTime month) =>
      _db.getDailyEarningsForMonth(month);

  Future<Map<String, double>> getEarningsByPlatform(
          {DateTime? from, DateTime? to}) =>
      _db.getEarningsByPlatform(from, to);

  @override
  void dispose() {
    _shiftTimer?.cancel();
    _notificationSub?.cancel();
    _loc.dispose();
    super.dispose();
  }
}

/// Registro de corrida detectada automaticamente com dados de eficiência.
class DetectedRide {
  final String plataforma;
  final double valor;
  final double? distKm;
  final double? eficiencia;
  final bool baixaEficiencia;
  final DateTime horario;

  const DetectedRide({
    required this.plataforma,
    required this.valor,
    this.distKm,
    this.eficiencia,
    required this.baixaEficiencia,
    required this.horario,
  });
}
