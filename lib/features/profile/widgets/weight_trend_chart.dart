import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/weight_entry.dart';

/// A single-series line chart of weight over time, with an optional dashed
/// goal-weight reference line and a per-point tap tooltip.
class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.entries,
    required this.goalWeightKg,
    required this.color,
  });

  /// Chronologically ascending.
  final List<WeightEntry> entries;
  final double? goalWeightKg;
  final Color color;

  static const _height = 180.0;
  static const _hPad = 16.0;
  static const _vPad = 16.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (entries.length < 2) {
      return SizedBox(
        height: _height,
        child: Center(
          child: Text(
            entries.isEmpty
                ? 'Log your weight to see a trend here.'
                : 'Log one more entry to see a trend line.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final values = entries.map((e) => e.weightKg).toList();
    var minY = values.reduce((a, b) => a < b ? a : b);
    var maxY = values.reduce((a, b) => a > b ? a : b);
    if (goalWeightKg != null) {
      minY = minY < goalWeightKg! ? minY : goalWeightKg!;
      maxY = maxY > goalWeightKg! ? maxY : goalWeightKg!;
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.15;
    minY -= pad;
    maxY += pad;

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = _height;
          Offset pointAt(int i) {
            final x = entries.length == 1
                ? w / 2
                : _hPad + (w - 2 * _hPad) * (i / (entries.length - 1));
            final t = (entries[i].weightKg - minY) / (maxY - minY);
            final y = h - _vPad - (h - 2 * _vPad) * t;
            return Offset(x, y);
          }

          final points = [for (var i = 0; i < entries.length; i++) pointAt(i)];
          final goalY = goalWeightKg == null
              ? null
              : h - _vPad - (h - 2 * _vPad) * ((goalWeightKg! - minY) / (maxY - minY));

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrendPainter(
                    points: points,
                    color: color,
                    goalY: goalY,
                    gridColor: scheme.outlineVariant,
                  ),
                ),
              ),
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left: points[i].dx - 10,
                  top: points[i].dy - 10,
                  child: Tooltip(
                    message:
                        '${DateFormat.yMMMd().format(entries[i].timestamp)}: ${entries[i].weightKg.toStringAsFixed(1)} kg',
                    triggerMode: TooltipTriggerMode.tap,
                    child: const SizedBox(width: 20, height: 20),
                  ),
                ),
              Positioned(
                left: (points.last.dx - 28).clamp(0, w - 56),
                top: (points.last.dy - 28).clamp(0.0, h - 20),
                child: Text(
                  '${entries.last.weightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.points,
    required this.color,
    required this.goalY,
    required this.gridColor,
  });

  final List<Offset> points;
  final Color color;
  final double? goalY;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (goalY != null) {
      final dashPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, goalY!), Offset(x + 4, goalY!), dashPaint);
        x += 7;
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
    }
    canvas.drawCircle(points.last, 4.5, dotPaint);
    canvas.drawCircle(
      points.last,
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.goalY != goalY;
}
