import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();

    _fadeAnim = CurvedAnimation(
        parent: _fadeCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _fadeCtrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack)),
    );
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  void _copyWhatsApp(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: '21978670637'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Número copiado!'),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Fundo animado com partículas
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              child: const SizedBox.expand(),
            ),
          ),

          // Gradiente de fundo
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF1A0000),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Logo animado com glow pulsante
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow externo
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withOpacity(0.25 * _pulseAnim.value),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Glow médio
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.06),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                          ),
                          // Logo
                          child!,
                        ],
                      ),
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/icons/logo.webp',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Nome do app
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Column(
                        children: [
                          const Text(
                            'META MOTO',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [
                                AppColors.primaryLight,
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ).createShader(rect),
                            child: const Text(
                              'SEU CONTROLE FINANCEIRO NA ESTRADA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Divisor decorativo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.surfaceLight,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 12),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.surfaceLight,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Card do desenvolvedor
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _DeveloperCard(
                        onCopyWhatsApp: () => _copyWhatsApp(context),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Versão do app
                    const _VersionBadge(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card do desenvolvedor ─────────────────────────────────────────────────────
class _DeveloperCard extends StatefulWidget {
  final VoidCallback onCopyWhatsApp;
  const _DeveloperCard({required this.onCopyWhatsApp});

  @override
  State<_DeveloperCard> createState() => _DeveloperCardState();
}

class _DeveloperCardState extends State<_DeveloperCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment(_shimmerCtrl.value * 2 - 1, -0.5),
              end: Alignment(_shimmerCtrl.value * 2, 0.5),
              colors: const [
                Color(0xFF1A0A0A),
                Color(0xFF220A0A),
                Color(0xFF1A0A0A),
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // "Programado por"
            const Text(
              'PROGRAMADO POR',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),

            // Avatar com iniciais
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'AP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nome
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFDDDDDD),
                ],
              ).createShader(rect),
              child: const Text(
                'Andre Pita',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 6),
            const Text(
              'Desenvolvedor Mobile',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 24),

            // Divisor
            Container(height: 1, color: AppColors.surfaceLight),
            const SizedBox(height: 20),

            // WhatsApp button
            GestureDetector(
              onTap: widget.onCopyWhatsApp,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF075E54).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF25D366).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            const Color(0xFF25D366).withOpacity(0.15),
                      ),
                      child: const Center(
                        child: Text('📱',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WhatsApp',
                          style: TextStyle(
                            color: Color(0xFF25D366),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '(21) 97867-0637',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.copy_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge de versão ───────────────────────────────────────────────────────────
class _VersionBadge extends StatelessWidget {
  const _VersionBadge();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Versão 1.0.0',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Feito com ❤️ para motoboys brasileiros',
          style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11),
        ),
      ],
    );
  }
}

// ── Partículas animadas de fundo ──────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static const _count = 18;
  static final _rng = math.Random(42);
  static final _particles = List.generate(_count, (i) {
    return [
      _rng.nextDouble(), // x normalizado
      _rng.nextDouble(), // y normalizado
      _rng.nextDouble() * 0.5 + 0.15, // speed
      _rng.nextDouble() * 2.5 + 1.0, // radius
      _rng.nextDouble(), // phase offset
    ];
  });

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final x = (p[0] * size.width +
              math.sin((progress + p[4]) * 2 * math.pi) * 20) %
          size.width;
      final y = (p[1] * size.height -
          progress * p[2] * size.height) %
          size.height;
      final r = p[3];
      final opacity =
          (math.sin((progress + p[4]) * 2 * math.pi) * 0.5 + 0.5) *
              0.25;

      paint.color =
          AppColors.primary.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y < 0 ? y + size.height : y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
