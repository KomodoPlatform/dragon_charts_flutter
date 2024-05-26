import 'package:flutter_test/flutter_test.dart';
import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';

void main() {
  group('ChartData', () {
    test('should create an instance of ChartData', () {
      final chartData = ChartData(x: 1.0, y: 2.0);

      expect(chartData.x, 1.0);
      expect(chartData.y, 2.0);
    });
  });
}
