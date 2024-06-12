import 'dart:ui';

import 'package:dragon_charts_flutter/src/chart_data.dart';
import 'package:dragon_charts_flutter/src/chart_data_transform.dart';
import 'package:dragon_charts_flutter/src/chart_element.dart';

abstract class MarkerSelectionStrategy {
  void handleHover(
    Offset localPosition,
    ChartDataTransform transform,
    List<ChartElement> elements,
    void Function(List<ChartData>, List<Offset>, List<Color>)
        updateHighlightedData,
  );
  void handleTap(
    Offset localPosition,
    ChartDataTransform transform,
    List<ChartElement> elements,
    void Function(List<ChartData>, List<Offset>, List<Color>)
        updateHighlightedData,
  );

  void paint(
    Canvas canvas,
    Size size,
    ChartDataTransform transform,
    List<Offset>? highlightedPoints,
    List<Color> highlightedColors,
    Offset? hoverPosition,
  );
}
