import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/providers/spending_limits_provider.dart';

class SpendingSpeedometer extends ConsumerStatefulWidget {
  const SpendingSpeedometer({super.key});

  @override
  ConsumerState<SpendingSpeedometer> createState() => _SpendingSpeedometerState();
}

class _SpendingSpeedometerState extends ConsumerState<SpendingSpeedometer> with TickerProviderStateMixin {
  bool _hasShaken = false;

  late AnimationController _settleController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _settleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  double get currentShakeOffset {
    if (!_shakeController.isAnimating) return 0.0;
    final progress = _shakeAnimation.value;
    return sin(progress * 12 * pi) * 0.04 * (1.0 - progress);
  }

  void _cyclePeriod() {
    final current = ref.read(dashboardPeriodProvider);
    if (current == 'Week') {
      ref.read(dashboardPeriodProvider.notifier).state = 'Month';
    } else if (current == 'Month') {
      ref.read(dashboardPeriodProvider.notifier).state = 'Year';
    } else {
      ref.read(dashboardPeriodProvider.notifier).state = 'Week';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final isPrivacyMode = ref.watch(privacyModeProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final statusAsync = ref.watch(limitStatusProvider);

    return statusAsync.when(
      data: (status) {
        final currentSpending = status.currentSpending;
        final limit = status.limitAmount;
        final ratio = status.ratio;

        final isExceeded = limit != null && currentSpending >= limit;
        if (isExceeded && !_hasShaken) {
          _shakeController.forward(from: 0.0);
          _hasShaken = true;
        } else if (!isExceeded) {
          _hasShaken = false;
        }

        Color arcColor = colorScheme.primary;
        if (status.isExceeded) {
          arcColor = Colors.red;
        } else if (status.isWarning) {
          arcColor = Colors.amber;
        }

        _settleController.animateTo(
          ratio.clamp(0.0, 1.15),
          curve: Curves.easeOutBack,
        );

        return AnimatedBuilder(
          animation: Listenable.merge([_settleController, _shakeController]),
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: arcColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: arcColor.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _cyclePeriod,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Spendings this ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                period.toLowerCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: onSurface.withValues(alpha: 0.4),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPrivacyMode
                              ? '****'
                              : 'KES ${NumberFormat('#,###').format(currentSpending)}',
                          style: TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          limit == null
                              ? 'No Limit Set'
                              : 'Limit: KES ${NumberFormat('#,###').format(limit)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isExceeded ? Colors.red : onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    height: 100,
                    child: CustomPaint(
                      painter: SpeedometerPainter(
                        ratio: _settleController.value,
                        shakeOffset: currentShakeOffset,
                        arcColor: arcColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double ratio;
  final double shakeOffset;
  final Color arcColor;

  SpeedometerPainter({
    required this.ratio,
    required this.shakeOffset,
    required this.arcColor,
  });

  static const double _startAngle = 150 * (pi / 180);
  static const double _sweepAngle = 240 * (pi / 180);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.44;
    final strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final cleanRatio = ratio.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle * cleanRatio,
      false,
      progressPaint,
    );

    final clampedRatio = ratio.clamp(0.0, 1.15);
    final baseAngle = _startAngle + (_sweepAngle * clampedRatio);
    final needleAngle = baseAngle + shakeOffset;

    final needleLength = radius * 0.85;
    final needleTarget = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTarget, needlePaint);

    final pivotPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, pivotPaint);

    final innerPivotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, innerPivotPaint);
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.shakeOffset != shakeOffset ||
        oldDelegate.arcColor != arcColor;
  }
}
