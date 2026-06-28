import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_nav.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _OnboardingStep(
      icon: Icons.notifications_active_rounded,
      iconColor: Color(0xFFFF6B35),
      title: 'Leitura de Notificações',
      subtitle: 'Para detectar suas corridas automaticamente',
      description:
          'O Meta Moto lê as notificações do Uber, 99 e iFood para registrar cada corrida no momento que ela aparece — sem você precisar fazer nada.',
      tip: 'Configurações → Notificações → Acesso especial → Leitura de notificações → Meta Moto ✓',
      stepNum: '1 de 3',
    ),
    _OnboardingStep(
      icon: Icons.picture_in_picture_alt_rounded,
      iconColor: Color(0xFF7B61FF),
      title: 'Overlay Flutuante',
      subtitle: 'Bolinha que aparece sobre qualquer app',
      description:
          'Quando uma corrida for detectada, uma bolinha aparece em cima do Uber mostrando o valor e a eficiência em tempo real — assim você decide se aceita ou não.',
      tip: 'Configurações → Apps → Meta Moto → Exibir sobre outros apps ✓',
      stepNum: '2 de 3',
    ),
    _OnboardingStep(
      icon: Icons.gps_fixed_rounded,
      iconColor: Color(0xFF2ECC71),
      title: 'Localização em Segundo Plano',
      subtitle: 'Para contar os km rodados no turno',
      description:
          'Com a localização ativa durante o turno, o app conta automaticamente os quilômetros rodados — essencial para calcular R\$/km e a eficiência de cada corrida.',
      tip: 'Configurações → Apps → Meta Moto → Permissões → Localização → Sempre permitir ✓',
      stepNum: '3 de 3',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNav(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/icons/logo.webp',
                        width: 32, height: 32),
                  ),
                  const SizedBox(width: 10),
                  const Text('META MOTO',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Pular',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _StepPage(step: _steps[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _steps.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finish();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPage < _steps.length - 1
                            ? 'Próximo'
                            : 'Começar a usar',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  final _OnboardingStep step;
  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Icon circle with glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.iconColor.withOpacity(0.08),
                  border: Border.all(
                      color: step.iconColor.withOpacity(0.2), width: 1.5),
                ),
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.iconColor.withOpacity(0.12),
                ),
                child: Icon(step.icon, color: step.iconColor, size: 48),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(step.stepNum,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Text(step.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(step.subtitle,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text(step.description,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // How-to tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: step.iconColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: step.iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(step.tip,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final String tip;
  final String stepNum;

  const _OnboardingStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.tip,
    required this.stepNum,
  });
}
