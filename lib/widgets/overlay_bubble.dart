import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../theme/app_theme.dart';

/// Painel flutuante estilo JetMax — aparece sobre o Uber/99 quando chega
/// uma oferta, mostrando R$/km · R$/hora · Nota · timer do turno · lucro líquido.
class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble> {
  String _plataforma = '';
  double _valor = 0;
  double? _distKm;
  int?    _tempMin;
  double? _eficiencia;
  double? _ganhoHora;
  double? _nota;
  double? _lucroLiquido;
  int?    _shiftInicioMs;
  bool    _baixaEficiencia = false;
  bool    _mini = false;

  Timer? _clockTimer;
  DateTime _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _agora = DateTime.now()),
    );
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
          _lucroLiquido   = (data['lucro_liquido'] as num?)?.toDouble();
          _shiftInicioMs  = (data['shift_inicio_ms'] as num?)?.toInt();
          _baixaEficiencia = data['baixa_eficiencia'] as bool? ?? false;
          _mini = false;
          _agora = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _fmt(double? v, {int dec = 2}) =>
      v != null ? v.toStringAsFixed(dec).replaceAll('.', ',') : '--';

  Color _corEficiencia(double? v) {
    if (v == null) return Colors.white54;
    if (v >= 3.0) return const Color(0xFF00E676);
    if (v >= 2.0) return const Color(0xFFFFD600);
    return const Color(0xFFFF5252);
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

  String _shiftTimer() {
    if (_shiftInicioMs == null) return '';
    final inicio = DateTime.fromMillisecondsSinceEpoch(_shiftInicioMs!);
    final diff = _agora.difference(inicio);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_mini) return _buildMini();
    return _buildPainel();
  }

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

  Widget _buildPainel() {
    final borderColor = _baixaEficiencia
        ? const Color(0xFFFFD600)
        : const Color(0xFF00C853);
    final timer = _shiftTimer();

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
                color: Colors.black.withOpacity(0.7),
                blurRadius: 20,
                spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(borderColor, timer),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            _buildMetrics(),
            const Divider(color: Color(0xFF1A1A1A), height: 1),
            _buildInfo(),
            if (_lucroLiquido != null) _buildLucroLiquido(),
          ],
        ),
      ),
    );
  }

  // ── cabeçalho: plataforma + timer + fechar/minimizar ─────────────────────
  Widget _buildHeader(Color accent, String timer) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Text(
              _plataforma.isEmpty ? 'Corrida' : _plataforma,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (timer.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white38, size: 12),
                const SizedBox(width: 3),
                Text(
                  timer,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _mini = true),
            child: const Icon(Icons.minimize_rounded, color: Colors.white38, size: 20),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => FlutterOverlayWindow.closeOverlay(),
            child: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }

  // ── 3 métricas grandes: R$/km · R$/hora · Nota ───────────────────────────
  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _MetricBox(
            label: 'R\$/km',
            value: _eficiencia != null ? _fmt(_eficiencia) : '--',
            color: _corEficiencia(_eficiencia),
          ),
          _divider(),
          _MetricBox(
            label: 'R\$/hora',
            value: _ganhoHora != null ? _fmt(_ganhoHora, dec: 0) : '--',
            color: _corHora(_ganhoHora),
          ),
          _divider(),
          _MetricBox(
            label: 'Nota',
            value: _nota != null ? _fmt(_nota) : '--',
            color: _corNota(_nota),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: const Color(0xFF1A1A1A),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── linha inferior: valor · km · minutos ─────────────────────────────────
  Widget _buildInfo() {
    final valorStr = 'R\$ ${_valor.toStringAsFixed(2).replaceAll('.', ',')}';
    final kmStr = _distKm != null
        ? '${_distKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
        : null;
    final minStr = _tempMin != null ? '${_tempMin} min' : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
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

  // ── lucro líquido (combustível descontado) ────────────────────────────────
  Widget _buildLucroLiquido() {
    final color = (_lucroLiquido! > 0)
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_gas_station_rounded,
              color: Colors.white30, size: 12),
          const SizedBox(width: 4),
          Text(
            'Lucro líquido: R\$ ${_lucroLiquido!.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
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
        Text(text,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Caixa de métrica grande ───────────────────────────────────────────────────

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
