import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../theme/app_theme.dart';

/// Controla o overlay flutuante (bolinha) sobre outros apps.
class OverlayService {
  static final OverlayService instance = OverlayService._();
  OverlayService._();

  static const double _baixaEficienciaLimite = 2.0; // R$/km padrão

  bool _overlayAtivo = false;
  bool get overlayAtivo => _overlayAtivo;

  Future<bool> hasPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  Future<void> requestPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  Future<void> mostrarCorridaDetectada({
    required String plataforma,
    required double valor,
    double? distKm,
    double limiteEficiencia = _baixaEficienciaLimite,
  }) async {
    if (!await hasPermission()) return;

    final eficiencia = (distKm != null && distKm > 0) ? valor / distKm : null;
    final baixaEficiencia = eficiencia != null && eficiencia < limiteEficiencia;

    // Envia dados para o overlay via shareData
    await FlutterOverlayWindow.shareData({
      'plataforma': plataforma,
      'valor': valor,
      'dist_km': distKm,
      'eficiencia': eficiencia,
      'baixa_eficiencia': baixaEficiencia,
    });

    // Abre o overlay se não estiver aberto
    if (!_overlayAtivo) {
      await FlutterOverlayWindow.showOverlay(
        height: 180,
        width: 300,
        alignment: OverlayAlignment.centerRight,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        enableDrag: true,
        overlayTitle: 'Meta Moto',
        overlayContent: 'Corrida detectada',
        startPosition: const OverlayPosition(0, -100),
      );
      _overlayAtivo = true;
    }

    // Auto-fecha após 8 segundos
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
