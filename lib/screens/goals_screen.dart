import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/goal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _dCtrl = TextEditingController();
  final _sCtrl = TextEditingController();
  final _mCtrl = TextEditingController();
  bool _editando = false;
  bool _saving = false;

  @override
  void dispose() {
    _dCtrl.dispose();
    _sCtrl.dispose();
    _mCtrl.dispose();
    super.dispose();
  }

  void _preencherCampos(Goal? goal) {
    if (goal != null) {
      _dCtrl.text = goal.valorDiario > 0 ? goal.valorDiario.toStringAsFixed(2).replaceAll('.', ',') : '';
      _sCtrl.text = goal.valorSemanal > 0 ? goal.valorSemanal.toStringAsFixed(2).replaceAll('.', ',') : '';
      _mCtrl.text = goal.valorMensal > 0 ? goal.valorMensal.toStringAsFixed(2).replaceAll('.', ',') : '';
    }
    setState(() => _editando = true);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metas'),
        backgroundColor: AppColors.background,
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              onPressed: () {
                final prov = context.read<AppProvider>();
                _preencherCampos(prov.goal);
              },
            ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, prov, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_editando) ...[
                  // Progresso diário
                  _ProgressCard(
                    title: 'Meta Diária',
                    atual: prov.totalHoje,
                    meta: prov.goal?.valorDiario ?? 0,
                    icon: Icons.today_rounded,
                    color: AppColors.primary,
                    subtitulo: '${prov.corridasHoje} corridas hoje',
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(
                    title: 'Meta Semanal',
                    atual: prov.totalSemana,
                    meta: prov.goal?.valorSemanal ?? 0,
                    icon: Icons.view_week_rounded,
                    color: const Color(0xFF7B61FF),
                    subtitulo: '${prov.corridasSemana} corridas na semana',
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(
                    title: 'Meta Mensal',
                    atual: prov.totalMes,
                    meta: prov.goal?.valorMensal ?? 0,
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.accent,
                    subtitulo: 'Lucro: ${fmt.format(prov.lucroMes)}',
                  ),
                  const SizedBox(height: 24),
                  if (prov.goal == null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _preencherCampos(null),
                        icon: const Icon(Icons.add),
                        label: const Text('Definir Metas'),
                      ),
                    ),
                ] else ...[
                  const Text('Definir Metas',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Configure quanto deseja ganhar em cada período.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 24),
                  _GoalField(ctrl: _dCtrl, label: 'Meta Diária', icon: Icons.today_rounded, color: AppColors.primary),
                  const SizedBox(height: 14),
                  _GoalField(ctrl: _sCtrl, label: 'Meta Semanal', icon: Icons.view_week_rounded, color: const Color(0xFF7B61FF)),
                  const SizedBox(height: 14),
                  _GoalField(ctrl: _mCtrl, label: 'Meta Mensal', icon: Icons.calendar_month_rounded, color: AppColors.accent),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _editando = false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.surfaceLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : () => _salvar(prov),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Salvar Metas', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _salvar(AppProvider prov) async {
    setState(() => _saving = true);
    final parse = (String v) => double.tryParse(v.replaceAll(',', '.').trim()) ?? 0.0;
    final goal = Goal(
      valorDiario: parse(_dCtrl.text),
      valorSemanal: parse(_sCtrl.text),
      valorMensal: parse(_mCtrl.text),
      criadoEm: DateTime.now(),
    );
    await prov.saveGoal(goal);
    if (mounted) setState(() { _editando = false; _saving = false; });
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final double atual;
  final double meta;
  final IconData icon;
  final Color color;
  final String subtitulo;

  const _ProgressCard({
    required this.title,
    required this.atual,
    required this.meta,
    required this.icon,
    required this.color,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final semMeta = meta == 0;
    final progress = semMeta ? 0.0 : (atual / meta).clamp(0.0, 1.0);
    final atingida = !semMeta && atual >= meta;
    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (atingida)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Batida! 🏆', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmt.format(atual),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
              if (!semMeta) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('/ ${fmt.format(meta)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!semMeta) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation(atingida ? AppColors.success : color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(subtitulo, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                Text('$pct%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ] else
            Text('Meta não definida — toque em editar', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final Color color;

  const _GoalField({required this.ctrl, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: color, size: 20),
        prefixText: 'R\$ ',
        prefixStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}
