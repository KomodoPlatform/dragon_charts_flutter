import 'dart:ui';

import 'chart_element.dart';
import 'chart_data.dart';
import 'chart_data_transform.dart';
import 'dart:math';

enum LineType { straight, bezier }

class ChartDataSeries extends ChartElement {
  final List<ChartData> data;
  final Color color;
  final LineType lineType;

  ChartDataSeries({
    required this.data,
    required this.color,
    this.lineType = LineType.straight,
  });

  ChartDataSeries animateTo(
      ChartDataSeries newDataSeries, double animationValue) {
    List<ChartData> interpolatedData = [];

    for (int i = 0; i < min(data.length, newDataSeries.data.length); i++) {
      double oldY = data[i].y;
      double newY = newDataSeries.data[i].y;
      double interpolatedY = oldY + (newY - oldY) * animationValue;

      double oldX = data[i].x;
      double newX = newDataSeries.data[i].x;
      double interpolatedX = oldX + (newX - oldX) * animationValue;

      interpolatedData.add(ChartData(
        x: interpolatedX,
        y: interpolatedY,
      ));
    }

    return ChartDataSeries(
      data: interpolatedData,
      color: color,
      lineType: lineType,
    );
  }

  @override
  void paint(Canvas canvas, Size size, ChartDataTransform transform,
      double animation) {
    if (data.isEmpty) return;

    Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    Paint pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    bool first = true;

    if (lineType == LineType.straight) {
      for (var point in data) {
        double x = transform.transformX(point.x);
        double y = transform.transformY(point.y);

        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }

        canvas.drawCircle(Offset(x, y), 4.0, pointPaint);
      }
    } else if (lineType == LineType.bezier) {
      if (data.isNotEmpty) {
        path.moveTo(
            transform.transformX(data[0].x), transform.transformY(data[0].y));

        for (int i = 0; i < data.length - 1; i++) {
          double x1 = transform.transformX(data[i].x);
          double y1 = transform.transformY(data[i].y);
          double x2 = transform.transformX(data[i + 1].x);
          double y2 = transform.transformY(data[i + 1].y);

          double controlPointX1 = x1 + (x2 - x1) / 3;
          double controlPointY1 = y1;
          double controlPointX2 = x1 + 2 * (x2 - x1) / 3;
          double controlPointY2 = y2;

          path.cubicTo(controlPointX1, controlPointY1, controlPointX2,
              controlPointY2, x2, y2);

          canvas.drawCircle(Offset(x1, y1), 4.0, pointPaint);
        }
        canvas.drawCircle(
            Offset(transform.transformX(data.last.x),
                transform.transformY(data.last.y)),
            4.0,
            pointPaint);
      }
    }
    canvas.drawPath(path, linePaint);
  }
}
