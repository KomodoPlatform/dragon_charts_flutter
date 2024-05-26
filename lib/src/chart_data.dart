class ChartData {
  final double x;
  final double y;

  ChartData({required this.x, required this.y})
      : assert(x.isFinite && y.isFinite);
}
