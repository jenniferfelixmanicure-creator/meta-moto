import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  double? _firstVal;
  String? _op;
  bool _justCalc = false;

  void _press(String val) {
    setState(() {
      if (val == 'C') {
        _display = '0';
        _expression = '';
        _firstVal = null;
        _op = null;
        _justCalc = false;
        return;
      }
      if (val == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
        return;
      }
      if (val == '=') {
        if (_firstVal != null && _op != null) {
          final second = double.tryParse(_display) ?? 0;
          double result;
          switch (_op) {
            case '+': result = _firstVal! + second; break;
            case '-': result = _firstVal! - second; break;
            case '×': result = _firstVal! * second; break;
            case '÷': result = second == 0 ? 0 : _firstVal! / second; break;
            default: result = second;
          }
          _expression = '${_firstVal!.toStringAsFixed(result == result.roundToDouble() ? 0 : 2)} $_op $second =';
          _display = result == result.roundToDouble()
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
          _firstVal = null;
          _op = null;
          _justCalc = true;
        }
        return;
      }
      if (['+', '-', '×', '÷'].contains(val)) {
        _firstVal = double.tryParse(_display);
        _op = val;
        _expression = '${_display} $val';
        _display = '0';
        _justCalc = false;
        return;
      }
      if (val == '%') {
        final v = double.tryParse(_display) ?? 0;
        _display = (v / 100).toString();
        if (_display.endsWith('.0')) _display = _display.replaceAll('.0', '');
        return;
      }
      if (val == ',') {
        if (!_display.contains('.')) _display += '.';
        return;
      }
      if (_justCalc) { _display = val; _justCalc = false; return; }
      _display = _display == '0' ? val : _display + val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calculadora'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Aba de taxas rápidas
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calcular taxa rápida',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _TaxaBtn(label: 'Taxa 25%', onTap: () => _calcTaxa(25)),
                      const SizedBox(width: 8),
                      _TaxaBtn(label: 'Taxa 27%', onTap: () => _calcTaxa(27)),
                      const SizedBox(width: 8),
                      _TaxaBtn(label: 'Taxa 30%', onTap: () => _calcTaxa(30)),
                      const SizedBox(width: 8),
                      _TaxaBtn(label: 'Combustível', onTap: () => _calcComb()),
                    ],
                  ),
                ],
              ),
            ),

            // Display
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_expression,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                        textAlign: TextAlign.right),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        _display.replaceAll('.', ','),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Teclado
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _buildRow(['C', '⌫', '%', '÷']),
                  _buildRow(['7', '8', '9', '×']),
                  _buildRow(['4', '5', '6', '-']),
                  _buildRow(['1', '2', '3', '+']),
                  _buildRow(['0', ',', '=', '']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: keys.map((k) {
          if (k.isEmpty) return const Expanded(child: SizedBox());
          final isOp = ['+', '-', '×', '÷', '%'].contains(k);
          final isEq = k == '=';
          final isSpec = ['C', '⌫'].contains(k);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _press(k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 62,
                  decoration: BoxDecoration(
                    color: isEq
                        ? AppColors.primary
                        : isOp
                            ? AppColors.primary.withOpacity(0.15)
                            : isSpec
                                ? AppColors.surfaceLight
                                : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      k,
                      style: TextStyle(
                        color: isEq
                            ? Colors.white
                            : isOp
                                ? AppColors.primary
                                : AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _calcTaxa(double pct) {
    final v = double.tryParse(_display) ?? 0;
    final taxa = v * pct / 100;
    final liquido = v - taxa;
    _showResult('Taxa de $pct%',
        'Bruto: R\$ ${v.toStringAsFixed(2)}\n'
        'Taxa: R\$ ${taxa.toStringAsFixed(2)}\n'
        'Líquido: R\$ ${liquido.toStringAsFixed(2)}');
  }

  void _calcComb() {
    showDialog(
      context: context,
      builder: (ctx) {
        final kmCtrl = TextEditingController();
        final litroCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Consumo de Combustível', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kmCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'KM rodados', suffixText: 'km'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: litroCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Litros abastecidos', suffixText: 'L'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final km = double.tryParse(kmCtrl.text.replaceAll(',', '.')) ?? 0;
                final l = double.tryParse(litroCtrl.text.replaceAll(',', '.')) ?? 0;
                Navigator.pop(ctx);
                if (km > 0 && l > 0) {
                  _showResult('Consumo médio',
                      '${(km / l).toStringAsFixed(1)} km/litro\n'
                      '${(l / km * 100).toStringAsFixed(1)} L/100km');
                }
              },
              child: const Text('Calcular'),
            ),
          ],
        );
      },
    );
  }

  void _showResult(String title, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.8)),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _TaxaBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TaxaBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text(label,
              style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
