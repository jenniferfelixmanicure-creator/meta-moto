import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prov = context.read<AppProvider>();
    final alerts = await prov.getMaintenanceAlerts();
    // Se não tem nenhuma alerta configurada, cria os padrões
    if (alerts.isEmpty) {
      final kmAtual = prov.kmTotalAcumulado;
      for (final tipo in TipoManutencao.all) {
        final intervalo = TipoManutencao.intervaloPadrao[tipo] ?? 5000;
        await prov.saveMaintenanceAlert(MaintenanceAlert(
          tipo: tipo,
          kmAtual: kmAtual,
          kmProxima: kmAtual + intervalo,
          descricao: tipo,
        ));
      }
      final refreshed = await prov.getMaintenanceAlerts();
      if (mounted) setState(() { _alerts = refreshed; _loading = false; });
    } else {
      // Atualiza o km atual com o acumulado
      final kmAtual = prov.kmTotalAcumulado;
      for (int i = 0; i < alerts.length; i++) {
        if (kmAtual > alerts[i].kmAtual) {
          alerts[i] = alerts[i].copyWith(kmAtual: kmAtual);
        }
      }
      if (mounted) setState(() { _alerts = alerts; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final kmAtual = prov.kmTotalAcumulado;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manutenção Preventiva'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.speed_rounded, color: AppColors.primary),
            tooltip: 'Atualizar KM',
            onPressed: () => _showKmDialog(prov),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // KM atual
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A3A), Color(0xFF1C1C2E)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quilometragem Atual',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          Text(
                            '${kmAtual.toStringAsFixed(0)} km',
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showKmDialog(prov),
                        child: const Text('Corrigir', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _alerts.isEmpty
                      ? const Center(
                          child: Text('Nenhum alerta configurado',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: _alerts.length,
                          itemBuilder: (ctx, i) {
                            final alert = _alerts[i];
                            final kmReal = alert.copyWith(kmAtual: kmAtual);
                            return _AlertCard(
                              alert: kmReal,
                              onReset: () => _resetAlert(kmReal, prov),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _resetAlert(MaintenanceAlert alert, AppProvider prov) async {
    final intervalo = TipoManutencao.intervaloPadrao[alert.tipo] ?? 5000;
    final atualizado = alert.copyWith(
      kmAtual: alert.kmAtual,
      kmProxima: alert.kmAtual + intervalo,
    );
    await prov.saveMaintenanceAlert(atualizado);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${alert.tipo} registrada! Próxima em ${atualizado.kmProxima.toStringAsFixed(0)} km.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showKmDialog(AppProvider prov) {
    final ctrl = TextEditingController(text: prov.kmTotalAcumulado.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Atualizar KM', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          decoration: const InputDecoration(
            suffixText: 'km',
            suffixStyle: TextStyle(color: AppColors.textMuted),
            hintText: '00000',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final km = double.tryParse(ctrl.text);
              if (km != null && km >= 0) {
                await prov.atualizarKmManual(km);
                await _load();
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final MaintenanceAlert alert;
  final VoidCallback onReset;
  const _AlertCard({required this.alert, required this.onReset});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (alert.atrasado) {
      statusColor = AppColors.error;
      statusLabel = 'ATRASADO';
      statusIcon = Icons.warning_rounded;
    } else if (alert.precisaAtencao) {
      statusColor = AppColors.warning;
      statusLabel = 'ATENÇÃO';
      statusIcon = Icons.info_rounded;
    } else {
      statusColor = AppColors.success;
      statusLabel = 'OK';
      statusIcon = Icons.check_circle_rounded;
    }

    final progress = (alert.kmAtual / alert.kmProxima).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(alert.tipo,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.atrasado
                    ? '${alert.kmRestante.abs().toStringAsFixed(0)} km atrasado!'
                    : 'Faltam ${alert.kmRestante.toStringAsFixed(0)} km',
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text('Próxima: ${alert.kmProxima.toStringAsFixed(0)} km',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: Icon(Icons.check_rounded, color: statusColor, size: 16),
              label: Text('Marcar como feita', style: TextStyle(color: statusColor, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: statusColor.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
