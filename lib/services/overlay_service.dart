import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Controla o overlay flutuante que aparece sobre o app do Uber/99
/// quando chega uma oferta de corrida — igual ao JetMax.
class OverlayService {
  static final OverlayService instance = OverlayService._();
  OverlayService._();

  bool _overlayAtivo = false;
  bool get overlayAtivo => _overlayAtivo;

  Future<bool> hasPermission() async =>
      FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestPermission() async =>
      FlutterOverlayWindow.requestPermission();

  /// Exibe o overlay com os dados da oferta de corrida.
  /// Aparece imediatamente quando a notificação chega, antes de aceitar.
  Future<void> mostrarOferta({
    required String plataforma,
    required double valor,
    double? distKm,
    int? tempMin,
    double? eficiencia,
    double? ganhoHora,
    double? nota,
    double limiteEficiencia = 2.0,
    int? shiftInicioMs,
    double? fuelCostPerKm,
  }) async {
    if (!await hasPermission()) return;

    final baixaEficiencia =
        eficiencia != null && eficiencia < limiteEficiencia;

    // Lucro líquido: valor - custo de combustível (distância * custo/km)
    final lucroLiquido = (fuelCostPerKm != null && distKm != null)
        ? valor - distKm * fuelCostPerKm
        : null;

    final data = <String, dynamic>{
      'plataforma': plataforma,
      'valor': valor,
      'tipo': 'oferta',
      if (distKm != null) 'dist_km': distKm,
      if (tempMin != null) 'temp_min': tempMin,
      if (eficiencia != null) 'eficiencia': eficiencia,
      if (ganhoHora != null) 'ganho_hora': ganhoHora,
      if (nota != null) 'nota': nota,
      if (lucroLiquido != null) 'lucro_liquido': lucroLiquido,
      if (shiftInicioMs != null) 'shift_inicio_ms': shiftInicioMs,
      'baixa_eficiencia': baixaEficiencia,
    };

    final overlayHeight = (shiftInicioMs != null || lucroLiquido != null) ? 220 : 190;

    if (_overlayAtivo) {
      // Overlay já aberto: só atualiza os dados
      await FlutterOverlayWindow.shareData(data);
    } else {
      // Abre o overlay pela primeira vez
      await FlutterOverlayWindow.showOverlay(
        height: overlayHeight,
        width: 330,
        alignment: OverlayAlignment.topCenter,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        enableDrag: true,
        overlayTitle: 'Meta Moto',
        overlayContent: 'Oferta detectada',
      );
      _overlayAtivo = true;
      // Pequeno delay para o engine do overlay iniciar antes de enviar dados
      await Future.delayed(const Duration(milliseconds: 300));
      await FlutterOverlayWindow.shareData(data);
    }

    // Fecha automaticamente após 25 segundos (tempo médio de oferta do Uber)
    Future.delayed(const Duration(seconds: 25), () async {
      if (_overlayAtivo) {
        await FlutterOverlayWindow.closeOverlay();
        _overlayAtivo = false;
      }
    });
  }

  /// Compatibilidade com o fluxo legado (corrida concluída).
  Future<void> mostrarCorridaDetectada({
    required String plataforma,
    required double valor,
    double? distKm,
    double limiteEficiencia = 2.0,
  }) async {
    final eficiencia =
        (distKm != null && distKm > 0) ? valor / distKm : null;
    await mostrarOferta(
      plataforma: plataforma,
      valor: valor,
      distKm: distKm,
      eficiencia: eficiencia,
      limiteEficiencia: limiteEficiencia,
    );
  }

  Future<void> fechar() async {
    if (_overlayAtivo) {
      await FlutterOverlayWindow.closeOverlay();
      _overlayAtivo = false;
    }
  }
}
