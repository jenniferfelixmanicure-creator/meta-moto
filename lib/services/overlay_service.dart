import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Controla o overlay flutuante (bolinha) sobre outros apps.
class OverlayService {
  static final OverlayService instance = OverlayService._();
  OverlayService._();

  static const double _baixaEficienciaLimite = 2.0;

  bool _overlayAtivo = false;
  bool get overlayAtivo => _overlayAtivo;

  Future<bool> hasPermission() async =>
      FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestPermission() async =>
      FlutterOverlayWindow.requestPermission();

  Future<void> mostrarCorridaDetectada({
    required String plataforma,
    required double valor,
    double? distKm,
    double limiteEficiencia = _baixaEficienciaLimite,
  }) async {
    if (!await hasPermission()) return;

    final eficiencia = (distKm != null && distKm > 0) ? valor / distKm : null;
    final baixaEficiencia = eficiencia != null && eficiencia < limiteEficiencia;

    await FlutterOverlayWindow.shareData({
      'plataforma': plataforma,
      'valor': valor,
      'dist_km': distKm,
      'eficiencia': eficiencia,
      'baixa_eficiencia': baixaEficiencia,
    });

    if (!_overlayAtivo) {
      await FlutterOverlayWindow.showOverlay(
        height: 200,
        width: 310,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        enableDrag: true,
        overlayTitle: 'Meta Moto',
        overlayContent: 'Corrida detectada',
      );
      _overlayAtivo = true;
    }

    Future.delayed(const Duration(seconds: 8), () async {
      if (_overlayAtivo) {
        await FlutterOverlayWindow.closeOverlay();
        _overlayAtivo = false;
      }
    });
  }

  Future<void> fechar() async {
    if (_overlayAtivo) {
      await FlutterOverlayWindow.closeOverlay();
      _overlayAtivo = false;
    }
  }
}
