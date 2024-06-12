import 'dart:ui';
import 'package:dragon_charts_flutter/src/chart_data_transform.dart';

abstract class ChartElement {
  void paint(
    Canvas canvas,
    Size size,
    ChartDataTransform transform,
    double animation,
  );
}
