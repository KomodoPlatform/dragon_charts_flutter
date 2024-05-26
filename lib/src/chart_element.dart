import 'dart:ui';
import 'chart_data_transform.dart';

abstract class ChartElement {
  void paint(
      Canvas canvas, Size size, ChartDataTransform transform, double animation);
}
