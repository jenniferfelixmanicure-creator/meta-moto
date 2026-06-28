import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../theme/app_theme.dart';

/// Painel de leitura de corrida — aparece sobre o Uber/99 quando chega
/// uma oferta, mostrando R$/km · R$/hora · Valor · Distância · Tempo.
/// Inspirado no JetMax.
class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  String _plataforma = '';
  double _valor = 0;
  double? _distKm;
  int? _tempMin;
  double? _eficiencia;   // R$/km
  double? _ganhoHora;    // R$/hora
  double? _nota;
  bool _baixaEficiencia = false;
  bool _mini = false;    // modo bolinha

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _plataforma     = data['plataforma'] as String? ?? '';
          _valor          = (data['valor'] as num?)?.toDouble() ?? 0;
          _distKm         = (data['dist_km'] as num?)?.toDouble();
          _tempMin        = (data['temp_min'] as num?)?.toInt();
          _eficiencia     = (data['eficiencia'] as num?)?.toDouble();
          _ganhoHora      = (data['ganho_hora'] as num?)?.toDouble();
          _nota           = (data['nota'] as num?)?.toDouble();
          _baixaEficiencia = data['baixa_eficiencia'] as bool? ?? false;
          _mini = false; // sempre expande quando chega nova oferta
        });
      }
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _fmt(double? v, {int dec = 2}) =>
      v != null ? v.toStringAsFixed(dec).replaceAll('.', ',') : '--';

  /// Verde se bom, amarelo se médio, vermelho se ruim
  Color _corEficiencia(double? v) {
    if (v == null) return Colors.white54;
    if (v >= 3.0) return const Color(0xFF00E676);   // verde
    if (v >= 2.0) return const Color(0xFFFFD600);   // amarelo
    return const Color(0xFFFF5252);                 // vermelho
  }

  Color _corHora(double? v) {
    if (v == null) return Colors.white54;
    if (v >= 40) return const Color(0xFF00E676);
    if (v >= 25) return const Color(0xFFFFD600);
    return const Color(0xFFFF5252);
  }

  Color _corNota(double? v) {
    if (v == null) return Colors.white54;
    if (v >= 4.8) return const Color(0xFF00E676);
    if (v >= 4.5) return const Color(0xFFFFD600);
    return const Color(0xFFFF5252);
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_mini) return _buildMini();
    return _buildPainel();
  }

  // Bolinha reduzida
  Widget _buildMini() {
    return GestureDetector(
      onTap: () => setState(() => _mini = false),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.6),
                blurRadius: 14,
                spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.moped_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // Painel completo estilo JetMax / Uber driver
  Widget _buildPainel() {
    final borderColor = _baixaEficiencia
        ? const Color(0xFFFFD600)
        : const Color(0xFF00C853);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 330,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(borderColor),
            _buildMetrics(),
            _buildInfo(),
          ],
        ),
      ),
    );
  }

  // ── cabeçalho: plataforma + botões ────────────────────────────────────────
  Widget _buildHeader(Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(Icons.moped_rounded, color: borderColor, size: 16),
          const SizedBox(width: 6),
          Text(
            _plataforma.isNotEmpty ? _plataforma.toUpperCase() : 'META MOTO',
            style: TextStyle(
              color: borderColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _mini = true),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove_rounded, color: Colors.white54, size: 18),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => FlutterOverlayWindow.closeOverlay(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3 métricas principais: R$/km · R$/hora · Nota ─────────────────────────
  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          _metric(
            label: 'R\$/km',
            value: _fmt(_eficiencia),
            color: _corEficiencia(_eficiencia),
          ),
          _divider(),
          _metric(
            label: 'R\$/hora',
            value: _fmt(_ganhoHora, dec: 0),
            color: _corHora(_ganhoHora),
          ),
          _divider(),
          _metric(
            label: 'Nota',
            value: _nota != null ? _fmt(_nota) : '--',
            color: _corNota(_nota),
            icon: _nota != null ? Icons.star_rounded : null,
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // indicador colorido (igual ao Uber)
              Container(
                width: 4,
                height: 20,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (icon != null) ...[
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 2),
              ],
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.white12,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── linha inferior: valor · distância · tempo ─────────────────────────────
  Widget _buildInfo() {
    final valorStr =
        'R\$ ${_valor.toStringAsFixed(2).replaceAll('.', ',')}';
    final kmStr = _distKm != null
        ? '${_distKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
        : null;
    final minStr = _tempMin != null ? '${_tempMin} min' : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _infoChip(Icons.attach_money_rounded, valorStr,
              const Color(0xFF00E676)),
          if (kmStr != null) ...[
            const SizedBox(width: 10),
            _infoChip(Icons.straighten_rounded, kmStr, Colors.white70),
          ],
          if (minStr != null) ...[
            const SizedBox(width: 10),
            _infoChip(Icons.timer_outlined, minStr, Colors.white70),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
