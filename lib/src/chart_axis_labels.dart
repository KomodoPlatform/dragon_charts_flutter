import 'package:flutter/material.dart';
import 'chart_element.dart';
import 'chart_data_transform.dart';

class ChartAxisLabels extends ChartElement {
  final bool isVertical;
  final int count;
  final String Function(double value) labelBuilder;
  final double reservedExtent;

  ChartAxisLabels({
    required this.isVertical,
    required this.count,
    required this.labelBuilder,
    this.reservedExtent = 30.0,
  });

  @override
  void paint(Canvas canvas, Size size, ChartDataTransform transform,
      double animation) {
    if (isVertical) {
      for (double i = 0; i <= count; i++) {
        double y = i * size.height / count;
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: labelBuilder(transform.invertY(y)),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        textPainter.paint(
            canvas, Offset(-textPainter.width - 5, y - textPainter.height / 2));
      }
    } else {
      for (double i = 0; i <= count; i++) {
        double x = i * size.width / count;
        TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: labelBuilder(transform.invertX(x)),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, size.height + 5));
      }
    }
  }
}
