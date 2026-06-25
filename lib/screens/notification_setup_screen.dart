import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class NotificationSetupScreen extends StatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  State<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _hasNotifPerm = false;
  bool _hasOverlayPerm = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final prov = context.read<AppProvider>();
    final notif = await prov.checkNotificationPermission();
    final overlay = await prov.checkOverlayPermission();
    if (mounted) {
      setState(() {
        _hasNotifPerm = notif;
        _hasOverlayPerm = overlay;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Automação & Overlay'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Status: Leitura de notificações ──────────────────────────
            _PermissionCard(
              title: 'Leitura de Notificações',
              subtitle: _hasNotifPerm
                  ? 'Ativo — corridas detectadas automaticamente'
                  : 'Necessário para detectar corridas',
              icon: Icons.notifications_active_rounded,
              active: _hasNotifPerm,
              checking: _checking,
              onActivate: () async {
                await prov.openNotificationSettings();
                await Future.delayed(const Duration(seconds: 2));
                await _check();
              },
            ),

            const SizedBox(height: 12),

            // ── Status: Overlay ──────────────────────────────────────────
            _PermissionCard(
              title: 'Overlay Flutuante (Bolinha)',
              subtitle: _hasOverlayPerm
                  ? 'Ativo — exibe corridas sobre qualquer app'
                  : 'Permite mostrar a bolinha sobre Uber/99/iFood',
              icon: Icons.picture_in_picture_rounded,
              active: _hasOverlayPerm,
              checking: _checking,
              onActivate: () async {
                await prov.requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 2));
                await _check();
              },
            ),

            const SizedBox(height: 24),

            // ── Limite de Eficiência ──────────────────────────────────────
            const Text('Limite de Eficiência',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Corridas abaixo deste valor por km exibem alerta de "Baixa Eficiência" na bolinha.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${fmt.format(prov.limiteEficiencia)}/km',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showLimiteDialog(prov),
                        child: const Text('Alterar',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Slider visual
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.warning,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.warning,
                      overlayColor: AppColors.warning.withOpacity(0.2),
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: prov.limiteEficiencia.clamp(0.5, 5.0),
                      min: 0.5,
                      max: 5.0,
                      divisions: 18,
                      label: '${fmt.format(prov.limiteEficiencia)}/km',
                      onChanged: (v) => prov.setLimiteEficiencia(
                          double.parse(v.toStringAsFixed(1))),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('R\$ 0,50/km',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      const Text('R\$ 5,00/km',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Como funciona ─────────────────────────────────────────────
            const Text('Como funciona',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _Step(
              num: '1',
              color: AppColors.primary,
              title: 'Corrida finalizada no app',
              desc:
                  'Uber, 99, iFood etc. enviam uma notificação com o valor e a distância da corrida.',
            ),
            _Step(
              num: '2',
              color: AppColors.primary,
              title: 'Meta Moto detecta em 2° plano',
              desc:
                  'O serviço extrai o valor (R\$) e a distância (km) via Regex — mesmo com a tela bloqueada.',
            ),
            _Step(
              num: '3',
              color: AppColors.warning,
              title: 'Bolinha aparece sobre o app',
              desc:
                  'A bolinha flutuante exibe o valor, km e R\$/km. Se a eficiência for baixa, pisca um alerta laranja.',
            ),
            _Step(
              num: '4',
              color: AppColors.success,
              title: 'Salvo automaticamente',
              desc:
                  'A corrida é registrada no histórico com a tag AUTO — sem você precisar digitar nada.',
            ),

            const SizedBox(height: 24),

            // ── Plataformas suportadas ────────────────────────────────────
            const Text('Plataformas detectadas automaticamente',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...[
              ('⚫', 'Uber Driver', 'com.ubercab.driver'),
              ('🟡', '99 Motorista', 'com.taxis99.driver'),
              ('🔴', 'iFood Courier', 'com.ifood.courier'),
              ('🟠', 'Lalamove', 'com.lalamove.android'),
              ('🟢', 'InDrive', 'sinet.startup.inDriver'),
            ].map((e) => _PlatformRow(emoji: e.$1, name: e.$2, pkg: e.$3)),

            const SizedBox(height: 24),

            // ── Histórico de detecções ────────────────────────────────────
            if (prov.detectedRides.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Últimas detecções automáticas',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('${prov.detectedRides.length} total',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              ...prov.detectedRides.take(10).map((d) => _DetectedTile(ride: d)),
            ],

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'O Meta Moto não armazena o conteúdo das notificações.\nApenas valor e distância são extraídos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 11, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showLimiteDialog(AppProvider prov) {
    final ctrl = TextEditingController(
        text: prov.limiteEficiencia.toStringAsFixed(2).replaceAll('.', ','));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Limite de Eficiência',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Corridas abaixo deste valor/km serão marcadas com alerta laranja na bolinha.',
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
              ],
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                prefixText: 'R\$ ',
                suffixText: '/km',
                prefixStyle: TextStyle(
                    color: AppColors.warning,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final v = double.tryParse(
                  ctrl.text.replaceAll(',', '.').trim());
              if (v != null && v > 0) {
                await prov.setLimiteEficiencia(v);
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

// ── Widgets internos ───────────────────────────────────────────────────────

class _PermissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool checking;
  final VoidCallback onActivate;

  const _PermissionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.checking,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [const Color(0xFF002A0A), AppColors.cardBg]
              : [const Color(0xFF2A0000), AppColors.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? AppColors.success.withOpacity(0.35)
              : AppColors.primary.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (active ? AppColors.success : AppColors.primary)
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: active ? AppColors.success : AppColors.primary,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: active
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 12)),
              ],
            ),
          ),
          if (!active)
            ElevatedButton(
              onPressed: checking ? null : onActivate,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ativar'),
            )
          else
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 22),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final Color color;
  final String title;
  final String desc;
  const _Step(
      {required this.num,
      required this.color,
      required this.title,
      required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final String emoji;
  final String name;
  final String pkg;
  const _PlatformRow(
      {required this.emoji, required this.name, required this.pkg});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(pkg,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Suportado',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DetectedTile extends StatelessWidget {
  final DetectedRide ride;
  const _DetectedTile({required this.ride});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final efStr = ride.eficiencia != null
        ? ' · ${fmt.format(ride.eficiencia!)}/km'
        : '';
    final kmStr = ride.distKm != null
        ? ' · ${ride.distKm!.toStringAsFixed(1)} km'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ride.baixaEficiencia
              ? AppColors.warning.withOpacity(0.25)
              : AppColors.success.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ride.baixaEficiencia
                ? Icons.warning_rounded
                : Icons.check_circle_rounded,
            color: ride.baixaEficiencia
                ? AppColors.warning
                : AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.plataforma}: ${fmt.format(ride.valor)}$kmStr$efStr',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (ride.baixaEficiencia)
                  const Text('Baixa eficiência',
                      style: TextStyle(
                          color: AppColors.warning, fontSize: 11)),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm', 'pt_BR').format(ride.horario),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
