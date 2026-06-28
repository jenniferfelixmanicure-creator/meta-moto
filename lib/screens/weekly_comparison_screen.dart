import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class WeeklyComparisonScreen extends StatelessWidget {
  const WeeklyComparisonScreen({super.key});

  static const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final prov = context.watch<AppProvider>();
    final comparativo = prov.comparativoDiaSemana;
    final esta = comparativo['esta']!;
    final passada = comparativo['passada']!;
    final totalEsta = prov.totalSemana;
    final totalPassada = prov.totalSemanaPassada;
    final corridasEsta = prov.corridasSemana;
    final corridasPassada = prov.corridasSemanaPassada;

    final diff = totalEsta - totalPassada;
    final diffPct = totalPassada > 0
        ? ((diff / totalPassada) * 100)
        : (totalEsta > 0 ? 100.0 : 0.0);
    final melhor = diff >= 0;

    final maxY = ([...esta, ...passada].reduce((a, b) => a > b ? a : b) * 1.3)
        .clamp(50.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Esta semana vs. passada'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo comparativo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.heroCard(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        melhor
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color:
                            melhor ? AppColors.success : AppColors.error,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          melhor
                              ? 'Você está indo melhor esta semana!'
                              : 'Semana passada foi melhor',
                          style: TextStyle(
                            color: melhor
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SemanaCard(
                          label: 'Esta semana',
                          valor: fmt.format(totalEsta),
                          corridas: corridasEsta,
                          color: AppColors.primary,
                          active: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SemanaCard(
                          label: 'Semana passada',
                          valor: fmt.format(totalPassada),
                          corridas: corridasPassada,
                          color: AppColors.silver,
                          active: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (melhor ? AppColors.success : AppColors.error)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            (melhor ? AppColors.success : AppColors.error)
                                .withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          melhor
                              ? '+${fmt.format(diff.abs())}'
                              : '-${fmt.format(diff.abs())}',
                          style: TextStyle(
                            color: melhor
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${melhor ? '+' : ''}${diffPct.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            color: (melhor
                                    ? AppColors.success
                                    : AppColors.error)
                                .withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'vs. semana passada',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gráfico de barras agrupadas
            const Text('Ganhos por dia',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Vermelho = esta semana · Cinza = semana passada',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(4, 16, 8, 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  groupsSpace: 12,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0
                            ? 'Esta: '
                            : 'Passada: ';
                        return BarTooltipItem(
                          '$label${fmt.format(rod.toY)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= 7) return const SizedBox();
                          return Text(_diasSemana[i],
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: AppColors.surfaceLight, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: esta[i],
                          color: AppColors.primary,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: passada[i],
                          color: AppColors.textMuted.withOpacity(0.5),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tabela dia a dia
            const Text('Dia a dia',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...List.generate(7, (i) {
              final e = esta[i];
              final p = passada[i];
              final d = e - p;
              final melhorDia = d >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(_diasSemana[i],
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Text(fmt.format(e),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                    Text(fmt.format(p),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(width: 10),
                    if (e > 0 || p > 0)
                      Text(
                        d >= 0
                            ? '+${fmt.format(d.abs())}'
                            : '-${fmt.format(d.abs())}',
                        style: TextStyle(
                          color: melhorDia
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SemanaCard extends StatelessWidget {
  final String label;
  final String valor;
  final int corridas;
  final Color color;
  final bool active;

  const _SemanaCard({
    required this.label,
    required this.valor,
    required this.corridas,
    required this.color,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.08) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(valor,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('$corridas corridas',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
