class ChartData {
  ChartData({required this.x, required this.y})
      : assert(x.isFinite && y.isFinite);
  final double x;
  final double y;
}
