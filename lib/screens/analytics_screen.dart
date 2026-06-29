import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'vehicle_profile_screen.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Análise', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_car_rounded),
            tooltip: 'Perfil do veículo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const VehicleProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => context.read<AppProvider>().exportarCSV(),
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, prov, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              _AcceptanceCard(prov: prov),
              const SizedBox(height: 12),
              _RecordsCard(prov: prov),
              const SizedBox(height: 12),
              _FuelCard(prov: prov),
              const SizedBox(height: 12),
              _PlatformCard(prov: prov),
              const SizedBox(height: 12),
              _HourlyChart(prov: prov),
            ],
          );
        },
      ),
    );
  }
}

// ── Taxa de aceitação ─────────────────────────────────────────────────────────

class _AcceptanceCard extends StatelessWidget {
  final AppProvider prov;
  const _AcceptanceCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final pct = (prov.taxaAceitacaoHoje * 100).toStringAsFixed(0);
    final color = prov.taxaAceitacaoHoje >= 0.7
        ? AppColors.success
        : prov.taxaAceitacaoHoje >= 0.5
            ? AppColors.warning
            : AppColors.danger;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(Icons.percent_rounded, 'Taxa de Aceitação (hoje)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${prov.ofertasAceitasHoje} aceitas',
                      style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  Text('${prov.ofertasVistasHoje} vistas',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: '✅ Aceitei',
                  color: AppColors.success,
                  onTap: () => prov.registrarOfertaAceita(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  label: '❌ Recusei',
                  color: AppColors.danger,
                  onTap: () => prov.registrarOfertaRecusada(),
                ),
              ),
              const SizedBox(width: 10),
              _ActionBtn(
                label: 'Reset',
                color: AppColors.textMuted,
                onTap: () => prov.resetarOfertasHoje(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recordes ──────────────────────────────────────────────────────────────────

class _RecordsCard extends StatelessWidget {
  final AppProvider prov;
  const _RecordsCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final hoje = prov.recordeCorridaHoje;
    final semana = prov.recordeCorridaSemana;
    final melhor = prov.melhorHoraHoje;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(Icons.emoji_events_rounded, 'Recordes'),
          const SizedBox(height: 12),
          _RecordRow(
            label: '🏆 Melhor corrida hoje',
            value: hoje != null ? fmt.format(hoje.valor) : '--',
            sub: hoje?.plataforma,
          ),
          const SizedBox(height: 8),
          _RecordRow(
            label: '🗓 Melhor corrida semana',
            value: semana != null ? fmt.format(semana.valor) : '--',
            sub: semana?.plataforma,
          ),
          if (melhor != null) ...[
            const SizedBox(height: 8),
            _RecordRow(
              label: '⏰ Melhor hora hoje',
              value: '${melhor['hora']}h → ${fmt.format(melhor['valor'])}',
              sub: null,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Custo de combustível ──────────────────────────────────────────────────────

class _FuelCard extends StatelessWidget {
  final AppProvider prov;
  const _FuelCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final profile = prov.vehicleProfile;
    final costPerKm = profile.fuelCostPerKm();
    final ridesHoje = prov.ridesHoje;
    // Corridas hoje com distância registrada (observacao contém "km")
    // Como distKm não está no modelo Ride, usamos média do histórico de eficiência
    final mediaValor = ridesHoje.isEmpty
        ? 0.0
        : ridesHoje.fold(0.0, (s, r) => s + r.valor) / ridesHoje.length;

    // Estimativa custo/corrida: sem distância no modelo, usa R$/km inverso
    // Custo por corrida = custo/km × distância média estimada (valor / limiteEficiencia)
    final distMediaEst = prov.limiteEficiencia > 0
        ? mediaValor / prov.limiteEficiencia
        : 0.0;
    final custoCorrida = costPerKm * distMediaEst;
    final lucroCorrida = mediaValor - custoCorrida;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(Icons.local_gas_station_rounded, 'Combustível'),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatBox(
                label: 'Custo/km',
                value: 'R\$ ${costPerKm.toStringAsFixed(3).replaceAll('.', ',')}',
                color: AppColors.warning,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Custo est./corrida',
                value: fmt.format(custoCorrida),
                color: AppColors.danger,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Lucro líq. est.',
                value: fmt.format(lucroCorrida),
                color: lucroCorrida > 0 ? AppColors.success : AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${profile.kmL.toStringAsFixed(0)} km/L · R\$ ${profile.fuelPricePerLiter.toStringAsFixed(2).replaceAll('.', ',')} /L',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Comparativo de plataformas hoje ──────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final AppProvider prov;
  const _PlatformCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mapa = prov.ganhosPorPlataformaHoje;
    final total = mapa.values.fold(0.0, (a, b) => a + b);

    if (mapa.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Title(Icons.compare_arrows_rounded, 'Plataformas hoje'),
            SizedBox(height: 12),
            Center(
              child: Text('Nenhuma corrida registrada hoje',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final sorted = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(Icons.compare_arrows_rounded, 'Plataformas hoje'),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(fmt.format(e.value),
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: const Color(0xFF1E1E1E),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Gráfico ganhos por hora ───────────────────────────────────────────────────

class _HourlyChart extends StatelessWidget {
  final AppProvider prov;
  const _HourlyChart({required this.prov});

  @override
  Widget build(BuildContext context) {
    final mapa = prov.ganhosPorHoraHoje;

    if (mapa.isEmpty) {
      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Title(Icons.show_chart_rounded, 'Ganhos por hora'),
            SizedBox(height: 12),
            Center(
              child: Text('Nenhum dado ainda hoje',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final horas = mapa.keys.toList()..sort();
    final spots = horas
        .map((h) => FlSpot(h.toDouble(), mapa[h]!))
        .toList();
    final maxY = (mapa.values.reduce((a, b) => a > b ? a : b) * 1.2)
        .clamp(20.0, double.infinity);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Title(Icons.show_chart_rounded, 'Ganhos por hora (hoje)'),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF1E1E1E),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        'R\$${v.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}h',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 9),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Componentes auxiliares ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Title(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  const _RecordRow({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            if (sub != null)
              Text(sub!,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: color, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
