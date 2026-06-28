import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shift_widget.dart';
import '../widgets/earnings_card.dart';
import '../widgets/ride_tile.dart';
import '../models/ride.dart';
import 'add_ride_screen.dart';
import 'maintenance_screen.dart';
import 'notification_setup_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _compartilharWhatsApp(BuildContext context, AppProvider prov) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final progressoPct = (prov.progressoDiario * 100).toStringAsFixed(0);
    final kmHoje = prov.kmTurnoAtual > 0
        ? ' | ${prov.kmTurnoAtual.toStringAsFixed(1)} km'
        : '';
    final ganhoHora = prov.ganhoHoraAtual ?? prov.ganhoHoraHoje;
    final ganhoHoraStr = ganhoHora != null
        ? ' | ${fmt.format(ganhoHora)}/h'
        : '';

    final mensagem = '🏍 Hoje: ${prov.corridasHoje} corridas, '
        '${fmt.format(prov.totalHoje)}$kmHoje$ganhoHoraStr '
        '| Meta: $progressoPct%';

    Share.share(mensagem);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (ctx, prov, _) {
          final metaAtingida = prov.goal != null &&
              prov.goal!.valorDiario > 0 &&
              prov.totalHoje >= prov.goal!.valorDiario;

          return CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                expandedHeight: 100,
                collapsedHeight: 60,
                pinned: true,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/icons/logo.webp',
                            width: 32, height: 32),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('META MOTO',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2)),
                          Text(
                            DateFormat('EEEE, d MMM', 'pt_BR')
                                .format(DateTime.now()),
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded,
                        color: AppColors.textMuted, size: 20),
                    tooltip: 'Compartilhar resumo',
                    onPressed: () => _compartilharWhatsApp(context, prov),
                  ),
                  IconButton(
                    icon: const Icon(Icons.build_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaintenanceScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const NotificationSetupScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    tooltip: 'Sobre o app',
                    onPressed: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const AboutScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                        transitionDuration:
                            const Duration(milliseconds: 400),
                      ),
                    ),
                  ),
                ],
              ),

              // Banner meta atingida
              if (metaAtingida)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF006400), Color(0xFF004B00)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🏆',
                            style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Meta do dia batida! Parabéns!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ),
                        GestureDetector(
                          onTap: () =>
                              _compartilharWhatsApp(context, prov),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.share_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Compartilhar',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Turno
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver:
                    SliverToBoxAdapter(child: const ShiftWidget()),
              ),

              // Ganho por hora
              if (prov.shiftAtivo || prov.ganhoHoraHoje != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _GanhoHoraCard(
                      ganhoHora:
                          prov.ganhoHoraAtual ?? prov.ganhoHoraHoje,
                      ganhoKm: prov.kmTurnoAtual > 0 &&
                              prov.totalHoje > 0
                          ? prov.totalHoje / prov.kmTurnoAtual
                          : null,
                      turnoAtivo: prov.shiftAtivo,
                    ),
                  ),
                ),

              // Cards de ganhos
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverGrid(
                  delegate: SliverChildListDelegate([
                    EarningsCard(
                      title: 'Hoje',
                      value: prov.totalHoje,
                      meta: prov.goal?.valorDiario,
                      rides: prov.corridasHoje,
                      icon: Icons.today_rounded,
                      color: AppColors.primary,
                      showProgress: true,
                    ),
                    EarningsCard(
                      title: 'Esta Semana',
                      value: prov.totalSemana,
                      meta: prov.goal?.valorSemanal,
                      rides: prov.corridasSemana,
                      icon: Icons.view_week_rounded,
                      color: AppColors.silver,
                      showProgress: true,
                    ),
                  ]),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                ),
              ),

              // Lucro real
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _LucroCard(
                    ganhos: prov.totalHoje,
                    despesas: prov.despesasHoje,
                    lucro: prov.lucroHoje,
                  ),
                ),
              ),

              // Falta da meta
              if (prov.goal != null &&
                  prov.goal!.valorDiario > 0 &&
                  !metaAtingida)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Faltam ${fmt.format(prov.metaDiariaFaltando)} para bater a meta do dia',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Header corridas
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Corridas de hoje',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Text(
                              '${prov.corridasHoje} corrida${prov.corridasHoje != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                          if (prov.corridasHoje > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  _compartilharWhatsApp(context, prov),
                              child: const Icon(
                                  Icons.ios_share_rounded,
                                  color: AppColors.primary,
                                  size: 18),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Lista ou empty
              if (prov.ridesHoje.isEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                      child: _EmptyToday(
                          onAdd: () => _openAdd(context))),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final r = prov.ridesHoje[i];
                        return RideTile(
                            ride: r,
                            onDelete: () =>
                                prov.deleteRide(r.id!));
                      },
                      childCount: prov.ridesHoje.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Corrida',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddRideScreen(),
    );
  }
}

// ── Ganho por hora card ───────────────────────────────────────────────────────
class _GanhoHoraCard extends StatelessWidget {
  final double? ganhoHora;
  final double? ganhoKm;
  final bool turnoAtivo;

  const _GanhoHoraCard({
    this.ganhoHora,
    this.ganhoKm,
    required this.turnoAtivo,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.timer_rounded,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turnoAtivo
                      ? 'Eficiência do turno'
                      : 'Eficiência de hoje',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (ganhoHora != null)
                      Text(
                        '${fmt.format(ganhoHora!)}/h',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (ganhoHora != null && ganhoKm != null)
                      const Text(' · ',
                          style: TextStyle(
                              color: AppColors.textMuted)),
                    if (ganhoKm != null)
                      Text(
                        '${fmt.format(ganhoKm!)}/km',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (ganhoHora == null && ganhoKm == null)
                      const Text('Calculando...',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LucroCard extends StatelessWidget {
  final double ganhos;
  final double despesas;
  final double lucro;
  const _LucroCard(
      {required this.ganhos,
      required this.despesas,
      required this.lucro});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final positivo = lucro >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                (positivo ? AppColors.success : AppColors.error)
                    .withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lucro Real (hoje)',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _Item(
                      label: 'Ganhos',
                      value: ganhos,
                      color: AppColors.success)),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.surfaceLight),
              Expanded(
                  child: _Item(
                      label: 'Despesas',
                      value: despesas,
                      color: AppColors.error)),
              Container(
                  width: 1,
                  height: 36,
                  color: AppColors.surfaceLight),
              Expanded(
                child: _Item(
                  label: 'Lucro',
                  value: lucro,
                  color: positivo
                      ? AppColors.success
                      : AppColors.error,
                  bold: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;
  const _Item(
      {required this.label,
      required this.value,
      required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(fmt.format(value),
            style: TextStyle(
                color: color,
                fontSize: bold ? 15 : 13,
                fontWeight:
                    bold ? FontWeight.w800 : FontWeight.w600),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _EmptyToday extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyToday({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.moped_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Nenhuma corrida hoje',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
              'Adicione manualmente ou ative a\nleitura automática de notificações',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.4),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Adicionar corrida'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
