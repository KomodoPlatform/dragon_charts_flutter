import 'dart:ui';

import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';
import 'package:dragon_charts_flutter/src/chart_data_transform.dart';
import 'package:dragon_charts_flutter/src/marker_selection_strategies/marker_selection_strategies.dart';

class CartesianSelectionStrategy extends MarkerSelectionStrategy {
  CartesianSelectionStrategy({
    this.enableVertical = true,
    this.enableHorizontal = false,
    this.verticalLineColor = const Color.fromARGB(255, 158, 158, 158),
    this.horizontalLineColor = const Color.fromARGB(255, 158, 158, 158),
    this.lineWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 5.0,
    this.highlightFillColor,
    this.highlightBorderColor = const Color.fromRGBO(0, 0, 0, 0.87),
    this.highlightBorderWidth = 2.0,
  });
  final bool enableVertical;
  final bool enableHorizontal;
  final Color verticalLineColor;
  final Color horizontalLineColor;
  final double lineWidth;
  final double dashWidth;
  final double dashSpace;
  final Color? highlightFillColor;
  final Color highlightBorderColor;
  final double highlightBorderWidth;

  @override
  void handleHover(
    Offset localPosition,
    ChartDataTransform transform,
    List<ChartElement> elements,
    void Function(List<ChartData>, List<Offset>, List<Color>)
        updateHighlightedData,
  ) {
    final highlightedData = <ChartData>[];
    final highlightedPoints = <Offset>[];
    final highlightedColors = <Color>[];
    for (final element in elements) {
      if (element is ChartDataSeries) {
        for (final point in element.data) {
          final x = transform.transformX(point.x);
          final y = transform.transformY(point.y);
          if (enableVertical && (localPosition.dx - x).abs() < 5) {
            highlightedData.add(point);
            highlightedPoints.add(Offset(x, y));
            highlightedColors.add(element.color);
          }
          if (enableHorizontal && (localPosition.dy - y).abs() < 5) {
            highlightedData.add(point);
            highlightedPoints.add(Offset(x, y));
            highlightedColors.add(element.color);
          }
        }
      }
    }
    updateHighlightedData(
      highlightedData,
      highlightedPoints,
      highlightedColors,
    );
  }

  @override
  void handleTap(
    Offset localPosition,
    ChartDataTransform transform,
    List<ChartElement> elements,
    void Function(List<ChartData>, List<Offset>, List<Color>)
        updateHighlightedData,
  ) {
    handleHover(localPosition, transform, elements, updateHighlightedData);
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
    ChartDataTransform transform,
    List<Offset>? highlightedPoints,
    List<Color> highlightedColors,
    Offset? hoverPosition,
  ) {
    if (hoverPosition != null) {
      final linePaint = Paint()
        ..color = verticalLineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth;

      if (enableVertical) {
        double startY = 0.0;
        while (startY < size.height) {
          canvas.drawLine(
            Offset(hoverPosition.dx, startY),
            Offset(hoverPosition.dx, startY + dashWidth),
            linePaint,
          );
          startY += dashWidth + dashSpace;
        }
      }

      if (enableHorizontal) {
        linePaint.color = horizontalLineColor;
        double startX = 0.0;
        while (startX < size.width) {
          canvas.drawLine(
            Offset(startX, hoverPosition.dy),
            Offset(startX + dashWidth, hoverPosition.dy),
            linePaint,
          );
          startX += dashWidth + dashSpace;
        }
      }
    }

    if (highlightedPoints != null) {
      for (var i = 0; i < highlightedPoints.length; i++) {
        final point = highlightedPoints[i];
        final color = highlightedColors[i];
        final highlightPaint = Paint()
          ..color = highlightFillColor ?? color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 4, highlightPaint);

        final borderPaint = Paint()
          ..color = highlightBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlightBorderWidth;

        canvas.drawCircle(point, 5, borderPaint);
      }
    }
  }
}
