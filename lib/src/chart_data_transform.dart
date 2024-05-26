class ChartDataTransform {
  final double minX, maxX, minY, maxY;
  final double width, height;

  ChartDataTransform({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.width,
    required this.height,
  }) : assert(
          [minX, maxX, minY, maxY, width, height]
              .every((element) => element.isFinite),
        );

  double transformX(double x) => (x - minX) / (maxX - minX) * width;

  double transformY(double y) => height - (y - minY) / (maxY - minY) * height;

  double invertX(double dx) => minX + (dx / width) * (maxX - minX);

  double invertY(double dy) => minY + (1 - dy / height) * (maxY - minY);
}
