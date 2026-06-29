import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_profile.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class VehicleProfileScreen extends StatefulWidget {
  const VehicleProfileScreen({super.key});

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen> {
  late VehicleType _type;
  late TextEditingController _modelCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _kmLCtrl;
  late TextEditingController _fuelPriceCtrl;
  late TextEditingController _reservePctCtrl;
  bool _isMei = false;
  late TextEditingController _cnpjCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppProvider>().vehicleProfile;
    _type          = p.type;
    _modelCtrl     = TextEditingController(text: p.model);
    _plateCtrl     = TextEditingController(text: p.plate);
    _kmLCtrl       = TextEditingController(text: p.kmL.toStringAsFixed(1));
    _fuelPriceCtrl = TextEditingController(
        text: p.fuelPricePerLiter.toStringAsFixed(2).replaceAll('.', ','));
    _reservePctCtrl = TextEditingController(
        text: p.emergencyReservePct.toStringAsFixed(0));
    _isMei  = p.isMei;
    _cnpjCtrl = TextEditingController(text: p.cnpj ?? '');
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _kmLCtrl.dispose();
    _fuelPriceCtrl.dispose();
    _reservePctCtrl.dispose();
    _cnpjCtrl.dispose();
    super.dispose();
  }

  double _parse(String v) =>
      double.tryParse(v.replaceAll(',', '.').trim()) ?? 0;

  Future<void> _salvar() async {
    setState(() => _saving = true);
    final profile = VehicleProfile(
      type: _type,
      model: _modelCtrl.text.trim(),
      plate: _plateCtrl.text.trim().toUpperCase(),
      kmL: _parse(_kmLCtrl.text).clamp(1, 200),
      fuelPricePerLiter: _parse(_fuelPriceCtrl.text).clamp(0.1, 30),
      isMei: _isMei,
      cnpj: _isMei && _cnpjCtrl.text.trim().isNotEmpty
          ? _cnpjCtrl.text.trim()
          : null,
      emergencyReservePct: _parse(_reservePctCtrl.text).clamp(0, 50),
    );
    await context.read<AppProvider>().saveVehicleProfile(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil salvo ✓'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Perfil do Veículo',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _salvar,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : const Text('Salvar',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Tipo de veículo ──────────────────────────────────────────────
          const _SectionLabel('Tipo de veículo'),
          const SizedBox(height: 10),
          Row(
            children: VehicleType.values.map((t) {
              final selected = t == _type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: t == VehicleType.moto ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.primary : const Color(0xFF1E1E1E),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          t.label,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Modelo e Placa ───────────────────────────────────────────────
          const _SectionLabel('Identificação'),
          const SizedBox(height: 10),
          _Field(
            label: 'Modelo (ex: Honda Biz 125)',
            controller: _modelCtrl,
            hint: 'Modelo do veículo',
          ),
          const SizedBox(height: 12),
          _Field(
            label: 'Placa',
            controller: _plateCtrl,
            hint: 'ABC1D23',
            caps: true,
            maxLength: 8,
          ),

          const SizedBox(height: 24),

          // ── Consumo e Combustível ────────────────────────────────────────
          const _SectionLabel('Consumo'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Consumo (km/L)',
                  controller: _kmLCtrl,
                  hint: '35',
                  numeric: true,
                  suffix: 'km/L',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: 'Preço do combustível',
                  controller: _fuelPriceCtrl,
                  hint: '6,50',
                  numeric: true,
                  prefix: 'R\$',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Consumer<AppProvider>(
            builder: (_, prov, __) {
              final kmL = _parse(_kmLCtrl.text).clamp(1.0, 200.0);
              final price = _parse(_fuelPriceCtrl.text).clamp(0.1, 30.0);
              final costPerKm = kmL > 0 ? price / kmL : 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Custo por km:',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    Text(
                      'R\$ ${costPerKm.toStringAsFixed(3).replaceAll('.', ',')} / km',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Reserva de emergência ────────────────────────────────────────
          const _SectionLabel('Reserva de emergência'),
          const SizedBox(height: 10),
          _Field(
            label: '% do ganho guardado por corrida',
            controller: _reservePctCtrl,
            hint: '10',
            numeric: true,
            suffix: '%',
          ),

          const SizedBox(height: 24),

          // ── MEI ──────────────────────────────────────────────────────────
          const _SectionLabel('MEI'),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _isMei = !_isMei),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E1E1E)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sou MEI',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Switch(
                    value: _isMei,
                    onChanged: (v) => setState(() => _isMei = v),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_isMei) ...[
            const SizedBox(height: 12),
            _Field(
              label: 'CNPJ',
              controller: _cnpjCtrl,
              hint: '00.000.000/0001-00',
              numeric: true,
              maxLength: 18,
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _salvar,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar Perfil',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final bool caps;
  final String? suffix;
  final String? prefix;
  final int? maxLength;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.caps = false,
    this.suffix,
    this.prefix,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: [
            if (numeric) FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            if (caps) UpperCaseTextFormatter(),
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixText: prefix != null ? '$prefix ' : null,
            prefixStyle: const TextStyle(
                color: AppColors.textMuted, fontSize: 15),
            suffixText: suffix,
            suffixStyle: const TextStyle(
                color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    return newVal.copyWith(text: newVal.text.toUpperCase());
  }
}
