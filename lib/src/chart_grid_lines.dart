
import 'package:flutter/material.dart';
import 'chart_element.dart';
import 'chart_data_transform.dart';

class ChartGridLines extends ChartElement {
  final bool isVertical;
  final int count;

  ChartGridLines({required this.isVertical, required this.count});

  @override
  void paint(Canvas canvas, Size size, ChartDataTransform transform, double animation) {
    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    if (isVertical) {
      for (double i = 0; i <= count; i++) {
        double x = i * size.width / count;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    } else {
      for (double i = 0; i <= count; i++) {
        double y = i * size.height / count;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }
}
