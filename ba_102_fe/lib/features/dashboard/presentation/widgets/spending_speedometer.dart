import 'dart:math';

import 'package:flutter/material.dart';

class SpendingSpeedometer extends StatefulWidget{
  final double currentSpending;
  final double? limitAmount;
  final double alertPercentage;
  final bool isPrivacyMode;
  

  const SpendingSpeedometer({
    required this.currentSpending,
    required this.limitAmount,
    required this.alertPercentage,
    required this.isPrivacyMode,


    super.key
  });

  @override
  State<SpendingSpeedometer> createState() => _SpendingSpeedometerState();

}


class _SpendingSpeedometerState extends State<SpendingSpeedometer> with TickerProviderStateMixin {

  bool _hasShaken = false;
  @override
  void didUpdateWidget(SpendingSpeedometer old){
    super.didUpdateWidget(old);
    final isExceeded = widget.limitAmount != null && widget.currentSpending >= widget.limitAmount!;
    final wasExceeded = old.limitAmount != null && old.currentSpending >= old.limitAmount!;

    if(isExceeded && !wasExceeded && !_hasShaken){
      _shakeController.forward(from: 0.0);
      _hasShaken = true;
    }

    if(!isExceeded && wasExceeded){
      _hasShaken = false;
      _shakeController.reset();
    }
  }

  late AnimationController _settleController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _settleController = AnimationController(vsync: this,
    duration: const Duration(milliseconds: 900),

    );

    _shakeController = AnimationController(vsync: this,
    duration: const Duration(milliseconds: 500)
    );

    _shakeAnimation = Tween<double>(begin:0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    }

  @override
  void dispose() {
    _settleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final limit = widget.limitAmount ?? 0.0;
    final ratio = limit > 0? widget.currentSpending / limit: 0.0;

    final warningThreshold = (100 - widget.alertPercentage) / 100;
    Color arcColor = colorScheme.primary;
    if (limit > 0){
      if( ratio >=1.0){
        arcColor = Colors.red;
      }
      else if (ratio >= warningThreshold){
        arcColor = Colors.amber;
      }
    }

    if (_settleController.value == 0.0 || !_settleController.isAnimating){
      _settleController.animateTo(ratio.clamp(0.0, 1.15),
      curve: Curves.easeOutBack
      );
    }

    return AnimatedBuilder(animation: Listenable.merge([_settleController, _shakeController]),
     builder: (context, child){
      return Container(
        width: double.infinity,
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: arcColor.withValues(
              alpha: 0.05
            ),
            width: 1.5
            
          ),
          boxShadow: [
            BoxShadow(
              color: arcColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ]
        ),

        child: Column(
          children: [
            Expanded(child: 
            CustomPaint(
              size: Size.infinite,
              painter: SpeedometerPainter(ratio: _settleController.value,
               shakeOffset: currentShakeOffset, 
               arcColor: arcColor),
            ))
          ],
        ),
      );
     });


  }

  double get currentShakeOffset {
    if (!_shakeController.isAnimating) return 0.0;
    final progress = _shakeAnimation.value;

    return sin(progress * 12 * pi) * 0.05 * (1.0 - progress);
  }

}

class SpeedometerPainter extends CustomPainter{
  final double ratio;
  final double shakeOffset;
  final Color arcColor;

  SpeedometerPainter({
    required this.ratio,
    required this.shakeOffset,
    required this.arcColor
  });


  static const double _startAngle = 150 * (pi / 180);
  static const double _sweepAngle = 240 * (pi / 180);

  @override
  void paint(Canvas canvas, Size size) {
   
   final center = Offset(size.width /2 , size.height * 0.65);
   final radius =  size.width * 0.38;
   final strokeWidth = 12.0;


    // 1. Draw background track (grey arc)
    final trackPaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.25)
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
     _startAngle, 
    _sweepAngle, 
    false, 
    trackPaint
    );
    // 2. Draw progress arc (colored)

    final progressPaint = Paint()
    ..color = arcColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;


    final cleanRatio = ratio.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 
    _startAngle, 
    _sweepAngle * cleanRatio, 
    false, 
    progressPaint
    );
    // 3. Draw needle

    final clampedRatio = ratio.clamp(0.0, 1.15);

    final baseAngle = _startAngle + (_sweepAngle * clampedRatio);

    final needleAngle = baseAngle + shakeOffset;


    final needleLength = radius * 0.9;
    final needleTarget = Offset(
      center.dx + needleLength * cos(needleAngle)
      , center.dy + needleLength * sin(needleAngle)
      );

    final needlePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTarget, needlePaint);

    // 4. Draw pivot dot
    final pivotPaint = Paint()
    ..color = arcColor
    ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8.0 , pivotPaint);
    
    final innerPivotPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, innerPivotPaint);


  }


  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
    oldDelegate.shakeOffset != shakeOffset ||
    oldDelegate.arcColor != arcColor;


    
  }
}
