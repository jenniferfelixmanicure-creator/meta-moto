import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/ride.dart';
import 'calculator_screen.dart';
import 'weekly_comparison_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _mes = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final mes = _mes;
    final data = await prov.getDailyEarningsForMonth(mes);
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mesStr = DateFormat('MMMM yyyy', 'pt_BR').format(mes);
    final total =
        data.fold(0.0, (s, d) => s + (d['total'] as num).toDouble());
    final totalCorridas =
        data.fold(0, (s, d) => s + (d['corridas'] as num).toInt());

    // Carrega logo
    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/icons/logo.webp');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final pdf = pw.Document();
    final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  child: pw.Image(logo),
                ),
              if (logo != null) pw.SizedBox(width: 12),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('META MOTO',
                      style: pw.TextStyle(
                          fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Relatório Financeiro — $mesStr',
                      style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Resumo
          pw.Row(
            children: [
              _pdfStat('Total do mês', fmt.format(total)),
              pw.SizedBox(width: 16),
              _pdfStat('Total de corridas', '$totalCorridas'),
              pw.SizedBox(width: 16),
              _pdfStat(
                'Média por dia',
                data.isEmpty
                    ? 'R\$ 0,00'
                    : fmt.format(total / data.length),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabela
          pw.Text('Corridas por dia',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('Data', bold: true),
                  _pdfCell('Ganhos', bold: true),
                  _pdfCell('Corridas', bold: true),
                ],
              ),
              ...data.map((d) {
                final date =
                    DateTime.parse(d['dia'] as String);
                return pw.TableRow(
                  children: [
                    _pdfCell(DateFormat('EEE, dd/MM', 'pt_BR')
                        .format(date)),
                    _pdfCell(
                        fmt.format((d['total'] as num).toDouble())),
                    _pdfCell(
                        '${(d['corridas'] as num).toInt()}'),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Gerado pelo Meta Moto em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'MetaMoto_$mesStr.pdf',
    );
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows_rounded,
                color: AppColors.silver),
            tooltip: 'Comparativo semanal',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WeeklyComparisonScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.primary),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_rounded,
                color: AppColors.primary),
            tooltip: 'Calculadora',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculatorScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Por Dia'),
            Tab(text: 'Por Plataforma'),
          ],
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, prov, _) {
          return TabBarView(
            controller: _tab,
            children: [
              _DailyTab(
                  mes: _mes,
                  onMesChanged: (m) => setState(() => _mes = m)),
              _PlatformTab(prov: prov),
            ],
          );
        },
      ),
    );
  }
}

// --- Aba diária ---
class _DailyTab extends StatefulWidget {
  final DateTime mes;
  final void Function(DateTime) onMesChanged;
  const _DailyTab({required this.mes, required this.onMesChanged});

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_DailyTab old) {
    super.didUpdateWidget(old);
    if (old.mes != widget.mes) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<AppProvider>();
    _data = await prov.getDailyEarningsForMonth(widget.mes);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mesStr =
        DateFormat('MMMM yyyy', 'pt_BR').format(widget.mes);
    final total =
        _data.fold(0.0, (s, d) => s + (d['total'] as num).toDouble());
    final totalCorridas =
        _data.fold(0, (s, d) => s + (d['corridas'] as num).toInt());

    return _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seletor de mês
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => widget.onMesChanged(
                          DateTime(widget.mes.year, widget.mes.month - 1)),
                    ),
                    Text(mesStr,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => widget.onMesChanged(
                          DateTime(widget.mes.year, widget.mes.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                          label: 'Total do mês',
                          value: fmt.format(total),
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                          label: 'Corridas',
                          value: '$totalCorridas',
                          color: const Color(0xFF7B61FF)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniStat(
                          label: 'Média/dia',
                          value: _data.isEmpty
                              ? 'R\$ 0,00'
                              : fmt.format(total / _data.length),
                          color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_data.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Sem dados para este mês',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 15)),
                    ),
                  )
                else ...[
                  // Gráfico de barras
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(0, 16, 8, 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _data
                                .map((d) =>
                                    (d['total'] as num).toDouble())
                                .reduce((a, b) => a > b ? a : b) *
                            1.2,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem:
                                (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                fmt.format(rod.toY),
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= _data.length)
                                  return const SizedBox();
                                final dia =
                                    (_data[idx]['dia'] as String)
                                        .substring(8);
                                if (int.parse(dia) % 5 != 0 &&
                                    dia != '01')
                                  return const SizedBox();
                                return Text(dia,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 10));
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: AppColors.surfaceLight,
                              strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups:
                            _data.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: (e.value['total'] as num)
                                    .toDouble(),
                                color: AppColors.primary,
                                width: 8,
                                borderRadius:
                                    const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._data.map((d) {
                    final dia = d['dia'] as String;
                    final total =
                        (d['total'] as num).toDouble();
                    final corridas =
                        (d['corridas'] as num).toInt();
                    final date = DateTime.parse(dia);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                              DateFormat('EEE, d', 'pt_BR')
                                  .format(date),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('$corridas corridas',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12)),
                          const SizedBox(width: 12),
                          Text(fmt.format(total),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
  }
}

// --- Aba plataforma ---
class _PlatformTab extends StatelessWidget {
  final AppProvider prov;
  const _PlatformTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final ganhos = prov.ganhosPorPlataforma;
    if (ganhos.isEmpty) {
      return const Center(
        child: Text('Sem dados de plataforma ainda',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 15)),
      );
    }
    final total = ganhos.values.fold(0.0, (a, b) => a + b);
    final sorted = ganhos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sections = sorted.map((e) {
      final pct = e.value / total;
      final color = Color(Plataforma.color(e.key));
      return PieChartSectionData(
        value: e.value,
        color: color,
        title: '${(pct * 100).toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12),
      );
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 48,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...sorted.map((e) {
            final pct = (e.value / total * 100).toStringAsFixed(1);
            final color = Color(Plataforma.color(e.key));
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(Plataforma.emoji(e.key),
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text('$pct% do total',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(fmt.format(e.value),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
