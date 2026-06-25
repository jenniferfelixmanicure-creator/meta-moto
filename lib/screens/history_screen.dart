import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/ride.dart';
import '../widgets/ride_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filtroPlataforma;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Histórico'),
        backgroundColor: AppColors.background,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.textSecondary),
            color: AppColors.surface,
            onSelected: (v) => setState(() => _filtroPlataforma = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas', style: TextStyle(color: AppColors.textPrimary))),
              ...Plataforma.all.map((p) => PopupMenuItem(
                    value: p,
                    child: Text(p, style: const TextStyle(color: AppColors.textPrimary)),
                  )),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, prov, _) {
          final rides = _filtroPlataforma == null
              ? prov.rides
              : prov.rides.where((r) => r.plataforma == _filtroPlataforma).toList();

          if (rides.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('Nenhuma corrida registrada',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }

          // Agrupar por data
          final Map<String, List<Ride>> grouped = {};
          for (final r in rides) {
            final key = DateFormat('yyyy-MM-dd').format(r.data);
            grouped.putIfAbsent(key, () => []).add(r);
          }
          final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: keys.length,
            itemBuilder: (ctx, i) {
              final key = keys[i];
              final dayRides = grouped[key]!;
              final date = DateTime.parse(key);
              final total = dayRides.fold(0.0, (s, r) => s + r.valor);
              final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${dayRides.length} corridas · ${fmt.format(total)}',
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  ...dayRides.map((r) => RideTile(
                        ride: r,
                        onDelete: () => prov.deleteRide(r.id!),
                      )),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) return 'Hoje';
    if (date == today.subtract(const Duration(days: 1))) return 'Ontem';
    return DateFormat('EEEE, d MMM', 'pt_BR').format(d);
  }
}
