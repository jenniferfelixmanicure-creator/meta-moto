import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ShiftWidget extends StatelessWidget {
  const ShiftWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: prov.shiftAtivo
              ? [const Color(0xFF1A2E1A), const Color(0xFF1C1C2E)]
              : [AppColors.cardBg, AppColors.cardBg],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: prov.shiftAtivo
              ? AppColors.success.withOpacity(0.3)
              : AppColors.surfaceLight,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: prov.shiftAtivo ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                  boxShadow: prov.shiftAtivo
                      ? [BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                prov.shiftAtivo ? 'Turno em andamento' : 'Turno encerrado',
                style: TextStyle(
                  color: prov.shiftAtivo ? AppColors.success : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => prov.shiftAtivo
                    ? _confirmarEncerrar(context, prov)
                    : prov.iniciarTurno(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: prov.shiftAtivo
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: prov.shiftAtivo ? AppColors.error : AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    prov.shiftAtivo ? 'Encerrar' : 'Iniciar Turno',
                    style: TextStyle(
                      color: prov.shiftAtivo ? AppColors.error : AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (prov.shiftAtivo && prov.activeShift != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ShiftStat(
                    label: 'Tempo',
                    value: _formatDuration(prov.activeShift!.duracao),
                    icon: Icons.timer_rounded,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _ShiftStat(
                    label: 'Faturado',
                    value: fmt.format(prov.activeShift!.totalGanho),
                    icon: Icons.attach_money_rounded,
                    color: AppColors.success,
                  ),
                ),
                Expanded(
                  child: _ShiftStat(
                    label: 'R\$/hora',
                    value: fmt.format(prov.activeShift!.mediaPorHora),
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF7B61FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // KM rastreados
            StreamBuilder<double>(
              stream: prov.kmStream,
              initialData: prov.kmTurnoAtual,
              builder: (ctx, snap) {
                final km = snap.data ?? 0.0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${km.toStringAsFixed(1)} km rodados neste turno',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${prov.kmTotalAcumulado.toStringAsFixed(0)} km',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else if (!prov.shiftAtivo) ...[
            const SizedBox(height: 10),
            const Text(
              'Inicie um turno para acompanhar seu tempo, ganhos e km em tempo real.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _confirmarEncerrar(BuildContext context, AppProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Encerrar turno?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Você rodou ${prov.kmTurnoAtual.toStringAsFixed(1)} km e faturou '
          '${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(prov.activeShift?.totalGanho ?? 0)} neste turno.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              prov.encerrarTurno();
            },
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
  }
}

class _ShiftStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ShiftStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}
