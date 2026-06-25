import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Rastreia automaticamente os quilômetros percorridos durante um turno ativo.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;
  double _kmTurno = 0.0;
  double _kmTotal = 0.0; // km acumulado (salvo no banco externamente)
  bool _tracking = false;

  final _kmController = StreamController<double>.broadcast();
  Stream<double> get kmStream => _kmController.stream;

  double get kmTurno => _kmTurno;
  double get kmTotal => _kmTotal;
  bool get isTracking => _tracking;

  void setKmTotal(double km) => _kmTotal = km;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startTracking() async {
    if (_tracking) return;
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    _tracking = true;
    _kmTurno = 0.0;
    _lastPosition = null;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // só atualiza após mover 20 metros
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      if (_lastPosition != null) {
        final dist = _calcDistKm(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        // Ignora saltos absurdos (>500m/s = GPS ruim)
        if (dist < 0.5) {
          _kmTurno += dist;
          _kmTotal += dist;
          _kmController.add(_kmTurno);
        }
      }
      _lastPosition = pos;
    });
  }

  Future<void> stopTracking() async {
    _tracking = false;
    await _positionSub?.cancel();
    _positionSub = null;
    _lastPosition = null;
  }

  void resetTurno() {
    _kmTurno = 0.0;
    _kmController.add(0.0);
  }

  /// Fórmula de Haversine — retorna distância em km.
  double _calcDistKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _rad(double deg) => deg * pi / 180;

  void dispose() {
    _positionSub?.cancel();
    _kmController.close();
  }
}
