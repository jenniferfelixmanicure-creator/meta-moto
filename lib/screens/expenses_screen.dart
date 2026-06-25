import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/expense.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Despesas'),
        backgroundColor: AppColors.background,
      ),
      body: Consumer<AppProvider>(
        builder: (ctx, prov, _) {
          final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
          final totalMes = prov.despesasMes;
          final combustivel = prov.expenses
              .where((e) => e.tipo == TipoExpense.combustivel)
              .fold(0.0, (s, e) => s + e.valor);
          final manutencao = prov.expenses
              .where((e) => e.tipo == TipoExpense.manutencao)
              .fold(0.0, (s, e) => s + e.valor);

          return Column(
            children: [
              // Resumo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Combustível',
                        value: combustivel,
                        icon: Icons.local_gas_station_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Manutenção',
                        value: manutencao,
                        icon: Icons.build_rounded,
                        color: const Color(0xFF7B61FF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Text('Total gasto este mês: ${fmt.format(totalMes)}',
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),

              // Lista
              Expanded(
                child: prov.expenses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💸', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('Nenhuma despesa registrada',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        itemCount: prov.expenses.length,
                        itemBuilder: (ctx, i) {
                          final e = prov.expenses[i];
                          return _ExpenseTile(
                            expense: e,
                            onDelete: () => prov.deleteExpense(e.id!),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Despesa', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(fmt.format(value),
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  const _ExpenseTile({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isCombust = expense.tipo == TipoExpense.combustivel;
    final color = isCombust ? AppColors.warning : const Color(0xFF7B61FF);
    final icon = isCombust ? Icons.local_gas_station_rounded : Icons.build_rounded;
    return Dismissible(
      key: Key('exp_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.descricao,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    '${expense.tipo} · ${DateFormat('d MMM HH:mm', 'pt_BR').format(expense.data)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  if (expense.km != null)
                    Text('${expense.km!.toStringAsFixed(0)} km',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Text(
              '- ${fmt.format(expense.valor)}',
              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  String _tipo = TipoExpense.combustivel;
  bool _saving = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nova Despesa', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            children: TipoExpense.all.map((t) {
              final sel = t == _tipo;
              final color = t == TipoExpense.combustivel ? AppColors.warning : const Color(0xFF7B61FF);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tipo = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? color.withOpacity(0.15) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? color : Colors.transparent),
                    ),
                    child: Center(
                      child: Text(t, style: TextStyle(color: sel ? color : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Descrição (ex: Gasolina posto Shell)'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valorCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Valor (R\$)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _dec('Quilometragem atual (opcional)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: _saving ? null : _salvar,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar Despesa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );

  Future<void> _salvar() async {
    final raw = _valorCtrl.text.replaceAll(',', '.').trim();
    final valor = double.tryParse(raw);
    if (valor == null || valor <= 0 || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha descrição e valor'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _saving = true);
    final kmRaw = _kmCtrl.text.replaceAll(',', '.').trim();
    final km = kmRaw.isEmpty ? null : double.tryParse(kmRaw);
    final expense = Expense(
      valor: valor,
      tipo: _tipo,
      descricao: _descCtrl.text.trim(),
      data: DateTime.now(),
      km: km,
    );
    await context.read<AppProvider>().addExpense(expense);
    if (mounted) Navigator.pop(context);
  }
}
