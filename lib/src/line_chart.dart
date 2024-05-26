import 'package:flutter/material.dart';
import 'chart_data.dart';
import 'chart_element.dart';
import 'chart_data_series.dart';
import 'chart_data_transform.dart';

class GraphExtent {
  final bool auto;
  final double padding;
  final double? min;
  final double? max;

  const GraphExtent({
    this.auto = true,
    this.padding = 0.1,
    this.min,
    this.max,
  });

  const GraphExtent.tight() : this(auto: true, padding: 0.0);
}

/// A customizable and animated line chart widget for Flutter.
///
/// The [LineChart] class allows you to plot multiple data series with options
/// for custom tooltips and smooth animations when data points are added or
/// removed.
///
/// Example usage:
/// ```dart
/// LineChart(
///   elements: [
///     ChartGridLines(isVertical: false, count: 5),
///     ChartAxisLabels(
///       isVertical: true,
///       count: 5,
///       labelBuilder: (value) => value.toStringAsFixed(2),
///     ),
///     ChartAxisLabels(
///       isVertical: false,
///       count: 5,
///       labelBuilder: (value) => value.toStringAsFixed(2),
///     ),
///     ChartDataSeries(
///       data: [ChartData(x: 1.0, y: 2.0)],
///       color: Colors.blue,
///     ),
///     ChartDataSeries(
///       data: [ChartData(x: 1.0, y: 4.0)],
///       color: Colors.red,
///       lineType: LineType.bezier,
///     ),
///   ],
///   tooltipBuilder: (context, dataPoints) {
///     return CustomTooltip(dataPoints: dataPoints);
///   },
///   backgroundColor: Colors.white,
/// )
/// ```
class LineChart extends StatefulWidget {
  /// The list of elements to be rendered in the chart.
  ///
  /// This list typically includes instances of [ChartDataSeries],
  /// [ChartGridLines], and [ChartAxisLabels].
  final List<ChartElement> elements;

  /// The duration of the animation when the chart updates.
  ///
  /// The default value is 500 milliseconds.
  final Duration animationDuration;

  /// A builder function to create custom tooltips for data points.
  ///
  /// If not provided, a default tooltip will be used.
  final Widget Function(BuildContext, List<ChartData>)? tooltipBuilder;

  /// The extent of the domain (x-axis) of the chart.
  ///
  /// This can be used to control the automatic scaling and padding of the domain.
  final GraphExtent domainExtent;

  /// The extent of the range (y-axis) of the chart.
  ///
  /// This can be used to control the automatic scaling and padding of the range.
  final GraphExtent rangeExtent;

  /// The background color of the chart.
  ///
  /// The default value is black.
  final Color backgroundColor;

  /// Creates a [LineChart] widget.
  ///
  /// The [elements] and [tooltipBuilder] are required. The [animationDuration],
  /// [domainExtent], [rangeExtent], and [backgroundColor] have default values.
  const LineChart({
    Key? key,
    required this.elements,
    this.tooltipBuilder,
    this.animationDuration = const Duration(milliseconds: 500),
    this.domainExtent = const GraphExtent(auto: true, padding: 0.1),
    this.rangeExtent = const GraphExtent(auto: true, padding: 0.1),
    this.backgroundColor = Colors.black,
  }) : super(key: key);

  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _tooltipOverlay;
  // ignore: unused_field
  Offset? _hoverPosition;
  List<Offset>? _highlightedPoints;
  List<Color> _highlightedColors = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  List<ChartElement> oldElements = [];
  List<ChartElement> currentElements = [];

  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  late Animation<double> minXAnimation;
  late Animation<double> maxXAnimation;
  late Animation<double> minYAnimation;
  late Animation<double> maxYAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          oldElements = List.from(widget.elements);
        });
      }
    });
    oldElements = List.from(widget.elements);
    currentElements = List.from(widget.elements);
    _updateDomainRange();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant LineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.elements != widget.elements) {
      setState(() {
        oldElements = List.from(currentElements);
        currentElements = List.from(widget.elements);
        _controller.reset();
        _updateDomainRange();
        _controller.forward();
      });
    } else {
      _updateDomainRange();
    }
  }

  void _updateDomainRange() {
    double newMinX = double.infinity;
    double newMaxX = double.negativeInfinity;
    double newMinY = double.infinity;
    double newMaxY = double.negativeInfinity;

    for (var element in widget.elements) {
      if (element is ChartDataSeries) {
        for (var dataPoint in element.data) {
          double xValue = dataPoint.x;
          if (xValue < newMinX) newMinX = xValue;
          if (xValue > newMaxX) newMaxX = xValue;
          if (dataPoint.y < newMinY) newMinY = dataPoint.y;
          if (dataPoint.y > newMaxY) newMaxY = dataPoint.y;
        }
      }
    }

    if (newMinX == double.infinity ||
        newMaxX == double.negativeInfinity ||
        newMinY == double.infinity ||
        newMaxY == double.negativeInfinity) {
      newMinX = 0;
      newMaxX = 1;
      newMinY = 0;
      newMaxY = 1;
    }

    if (widget.domainExtent.auto) {
      double domainPaddingValue =
          (newMaxX - newMinX) * widget.domainExtent.padding;
      newMinX -= domainPaddingValue;
      newMaxX += domainPaddingValue;
    } else {
      newMinX = widget.domainExtent.min ?? newMinX;
      newMaxX = widget.domainExtent.max ?? newMaxX;
    }

    if (widget.rangeExtent.auto) {
      double rangePaddingValue =
          (newMaxY - newMinY) * widget.rangeExtent.padding;
      newMinY -= rangePaddingValue;
      newMaxY += rangePaddingValue;
    } else {
      newMinY = widget.rangeExtent.min ?? newMinY;
      newMaxY = widget.rangeExtent.max ?? newMaxY;
    }

    minXAnimation =
        Tween<double>(begin: minX, end: newMinX).animate(_controller);
    maxXAnimation =
        Tween<double>(begin: maxX, end: newMaxX).animate(_controller);
    minYAnimation =
        Tween<double>(begin: minY, end: newMinY).animate(_controller);
    maxYAnimation =
        Tween<double>(begin: maxY, end: newMaxY).animate(_controller);

    minX = newMinX;
    maxX = newMaxX;
    minY = newMinY;
    maxY = newMaxY;
  }

  void _showTooltip(
      BuildContext context, Offset position, List<ChartData> dataPoints) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hideTooltip();

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      final Size? size = renderBox?.size;

      if (size != null) {
        double left = position.dx + 10;
        double top = position.dy - 30;

        if (left + 100 > size.width) {
          left = size.width - 100;
        }
        if (top < 0) {
          top = 0;
        }

        _tooltipOverlay = OverlayEntry(
          builder: (context) => Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: widget.tooltipBuilder != null
                  ? widget.tooltipBuilder!(context, dataPoints)
                  : _defaultTooltip(context, dataPoints),
            ),
          ),
        );

        Overlay.of(context).insert(_tooltipOverlay!);
      }
    });
  }

  void _hideTooltip() {
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
    }
  }

  Widget _defaultTooltip(BuildContext context, List<ChartData> dataPoints) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: dataPoints.map((data) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 8),
              const SizedBox(width: 4),
              Text(
                '(${data.x}, ${data.y})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);

        ChartDataTransform transform = ChartDataTransform(
          minX: minXAnimation.value,
          maxX: maxXAnimation.value,
          minY: minYAnimation.value,
          maxY: maxYAnimation.value,
          width: size.width,
          height: size.height,
        );

        return Container(
          color: widget.backgroundColor,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _hoverPosition = details.localPosition;
              });
            },
            child: MouseRegion(
              onHover: (details) {
                final localPosition = details.localPosition;
                List<ChartData> highlightedData = [];
                _highlightedPoints = [];
                _highlightedColors = [];
                for (var element in widget.elements) {
                  if (element is ChartDataSeries) {
                    for (var point in element.data) {
                      double x = transform.transformX(point.x);
                      double y = transform.transformY(point.y);
                      if ((Offset(x, y) - localPosition).distance < 10) {
                        highlightedData.add(point);
                        _highlightedPoints!.add(Offset(x, y));
                        _highlightedColors.add(element.color);
                      }
                    }
                  }
                }
                if (highlightedData.isNotEmpty) {
                  _showTooltip(context, localPosition, highlightedData);
                } else {
                  _hideTooltip();
                }
                setState(() {
                  _hoverPosition = localPosition;
                });
              },
              onExit: (details) {
                _hideTooltip();
                setState(() {
                  _hoverPosition = null;
                  _highlightedPoints = null;
                  _highlightedColors = [];
                });
              },
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  List<ChartElement> animatedElements = [];
                  for (int i = 0; i < currentElements.length; i++) {
                    if (currentElements[i] is ChartDataSeries &&
                        oldElements[i] is ChartDataSeries) {
                      animatedElements.add((oldElements[i] as ChartDataSeries)
                          .animateTo(currentElements[i] as ChartDataSeries,
                              _animation.value));
                    } else {
                      animatedElements.add(currentElements[i]);
                    }
                  }
                  return CustomPaint(
                    size: size,
                    painter: _LineChartPainter(
                      elements: animatedElements,
                      transform: transform,
                      highlightedPoints: _highlightedPoints,
                      highlightedColors: _highlightedColors,
                      animation: _animation.value,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _controller.dispose();
    super.dispose();
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartElement> elements;
  final ChartDataTransform transform;
  final List<Offset>? highlightedPoints;
  final List<Color> highlightedColors;
  final double animation;

  _LineChartPainter({
    required this.elements,
    required this.transform,
    required this.highlightedPoints,
    required this.highlightedColors,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var element in elements) {
      element.paint(canvas, size, transform, animation);
    }

    if (highlightedPoints != null) {
      for (int i = 0; i < highlightedPoints!.length; i++) {
        var point = highlightedPoints![i];
        var color = highlightedColors[i];
        Paint highlightPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 4.0, highlightPaint);

        Paint borderPaint = Paint()
          // TODO: Make configurable and/or get from theme
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(point, 5.0, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
