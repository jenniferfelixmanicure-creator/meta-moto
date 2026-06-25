import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../theme/app_theme.dart';

/// Widget exibido DENTRO do overlay flutuante.
/// Este widget roda num FlutterEngine separado (entry-point overlayMain).
class OverlayBubble extends StatefulWidget {
  const OverlayBubble({super.key});

  @override
  State<OverlayBubble> createState() => _OverlayBubbleState();
}

class _OverlayBubbleState extends State<OverlayBubble>
    with SingleTickerProviderStateMixin {
  String _plataforma = '';
  double _valor = 0;
  double? _distKm;
  double? _eficiencia;
  bool _baixaEficiencia = false;
  bool _expandido = true;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.9, end: 1.05).animate(
        CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Escuta dados enviados pelo app principal
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _plataforma = data['plataforma'] as String? ?? '';
          _valor = (data['valor'] as num?)?.toDouble() ?? 0;
          _distKm = (data['dist_km'] as num?)?.toDouble();
          _eficiencia = (data['eficiencia'] as num?)?.toDouble();
          _baixaEficiencia = data['baixa_eficiencia'] as bool? ?? false;
          _expandido = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valorStr =
        'R\$ ${_valor.toStringAsFixed(2).replaceAll('.', ',')}';
    final efStr = _eficiencia != null
        ? 'R\$ ${_eficiencia!.toStringAsFixed(2).replaceAll('.', ',')}/km'
        : null;

    if (!_expandido) {
      // Modo mini — só bolinha vermelha
      return GestureDetector(
        onTap: () => setState(() => _expandido = true),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2)
            ],
          ),
          child: const Icon(Icons.moped_rounded, color: Colors.white, size: 22),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedBuilder(
          animation: _baixaEficiencia ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
          builder: (_, child) => Transform.scale(
            scale: _baixaEficiencia ? _pulseAnim.value : 1.0,
            child: child,
          ),
          child: Container(
            width: 290,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _baixaEficiencia
                    ? AppColors.warning
                    : AppColors.primary.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_baixaEficiencia ? AppColors.warning : AppColors.primary)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.moped_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'META MOTO',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _expandido = false),
                      child: const Icon(Icons.remove_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          FlutterOverlayWindow.closeOverlay(),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Color(0xFF2A2A2A), height: 1),
                const SizedBox(height: 10),

                // Plataforma + Valor
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _plataforma,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            valorStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_baixaEficiencia)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: AppColors.warning, size: 16),
                            Text(
                              'BAIXA\nEFIC.',
                              style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // KM + R$/km
                Row(
                  children: [
                    if (_distKm != null) ...[
                      _Chip(
                        icon: Icons.route_rounded,
                        label:
                            '${_distKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                        color: AppColors.silver,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (efStr != null)
                      _Chip(
                        icon: Icons.speed_rounded,
                        label: efStr,
                        color: _baixaEficiencia
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                  ],
                ),

                if (_baixaEficiencia) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ Corrida abaixo do seu limite de eficiência!',
                      style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
