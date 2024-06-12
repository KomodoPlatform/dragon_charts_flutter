import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';
import 'package:dragon_charts_flutter/src/chart_data_transform.dart';
import 'package:dragon_charts_flutter/src/chart_tooltip.dart';
import 'package:dragon_charts_flutter/src/marker_selection_strategies/marker_selection_strategies.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ChartExtent {
  const ChartExtent({
    this.auto = true,
    this.padding = 0.1,
    this.min,
    this.max,
  });

  const ChartExtent.tight() : this(auto: true, padding: 0);
  final bool auto;
  final double padding;
  final double? min;
  final double? max;
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
///       isVertical: true, count: 5, labelBuilder: (value) => value.toStringAsFixed(2),
///     ),
///     ChartAxisLabels(
///       isVertical: false, count: 5, labelBuilder: (value) => value.toStringAsFixed(2),
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
///   tooltipBuilder: (context, dataPoints, dataColors) {
///     return YourTooltipWidget(
///       dataPoints: dataPoints,
///       dataColors: dataColors,
///     );
///   },
///   backgroundColor: Colors.white,
/// )
/// ```
class LineChart extends StatefulWidget {
  /// Creates a [LineChart] widget.
  ///
  /// The [elements] and [tooltipBuilder] are required. The [animationDuration],
  /// [domainExtent], [rangeExtent], and [backgroundColor] have default values.
  const LineChart({
    required this.elements,
    this.tooltipBuilder,
    this.animationDuration = const Duration(milliseconds: 500),
    this.domainExtent = const ChartExtent(),
    this.rangeExtent = const ChartExtent(),
    this.backgroundColor = Colors.black,
    this.padding = const EdgeInsets.all(30),
    this.markerSelectionStrategy,
    super.key,
  });

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
  final Widget Function(BuildContext, List<ChartData>, List<Color>)?
      tooltipBuilder;

  /// The extent of the domain (x-axis) of the chart.
  ///
  /// This can be used to control the automatic scaling and padding of the domain.
  final ChartExtent domainExtent;

  /// The extent of the range (y-axis) of the chart.
  ///
  /// This can be used to control the automatic scaling and padding of the range.
  final ChartExtent rangeExtent;

  /// The background color of the chart.
  ///
  /// The default value is black.
  final Color backgroundColor;

  /// The padding around the chart to accommodate labels and other elements.
  ///
  /// The default value is 30.0 on all sides.
  final EdgeInsets padding;

  /// The strategy to use for selecting markers on the chart.
  ///
  /// This parameter is optional. If not specified, no marker selection or painting will be done.
  final MarkerSelectionStrategy? markerSelectionStrategy;

  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _overlayController = OverlayPortalController();
  Offset? _hoverPosition;
  List<ChartData>? _highlightedData;
  List<Offset>? _highlightedPoints;
  List<Color> _highlightedColors = [];
  late AnimationController _controller;
  late Animation<double> _animation;
  // Additional state to hold the global hover position
  Offset? _globalHoverPosition;

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

  final GlobalKey _chartKey = GlobalKey();
  Size? _tooltipSize;

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
        _clearHighlightedData();
      });
    } else {
      _updateDomainRange();
    }
  }

  void _clearHighlightedData() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _overlayController.hide();
        setState(() {
          _hoverPosition = null;
          _highlightedData = null;
          _highlightedPoints = null;
          _highlightedColors = [];
        });
      }
    });
  }

  void _updateDomainRange() {
    var newMinX = double.infinity;
    var newMaxX = double.negativeInfinity;
    var newMinY = double.infinity;
    var newMaxY = double.negativeInfinity;

    for (final element in widget.elements) {
      if (element is ChartDataSeries) {
        for (final dataPoint in element.data) {
          final xValue = dataPoint.x;
          if (xValue < newMinX) newMinX = xValue;
          if (xValue > newMaxX) newMaxX = xValue;
          if (dataPoint.y < newMinY) newMinY = dataPoint.y;
          if (dataPoint.y > newMaxY) newMaxY = dataPoint.y;
        }
      }
    }

    if (!newMinX.isFinite ||
        newMaxX == double.negativeInfinity ||
        newMinY == double.infinity ||
        newMaxY == double.negativeInfinity) {
      newMinX = 0;
      newMaxX = 1;
      newMinY = 0;
      newMaxY = 1;
    }

    if (widget.domainExtent.auto) {
      final domainPaddingValue =
          (newMaxX - newMinX) * widget.domainExtent.padding;
      newMinX -= domainPaddingValue;
      newMaxX += domainPaddingValue;
    } else {
      newMinX = widget.domainExtent.min ?? newMinX;
      newMaxX = widget.domainExtent.max ?? newMaxX;
    }

    if (widget.rangeExtent.auto) {
      final rangePaddingValue =
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

  late ChartDataTransform transform;

  bool get areAnimationsFinite =>
      minXAnimation.value.isFinite &&
      maxXAnimation.value.isFinite &&
      minYAnimation.value.isFinite &&
      maxYAnimation.value.isFinite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: _chartKey,
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final chartSize = Size(
          size.width - widget.padding.horizontal,
          size.height - widget.padding.vertical,
        );

        if (!chartSize.isFinite || !areAnimationsFinite) {
          return Container();
        }

        transform = ChartDataTransform(
          minX: minXAnimation.value,
          maxX: maxXAnimation.value,
          minY: minYAnimation.value,
          maxY: maxYAnimation.value,
          width: chartSize.width,
          height: chartSize.height,
        );

        return Container(
          color: widget.backgroundColor,
          padding: widget.padding,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _hoverPosition = details.localPosition;
              });
            },
            onTapUp: (details) {
              _handleTap(details.localPosition);
            },
            onTapDown: (details) {
              _handleTap(details.localPosition);
            },
            child: MouseRegion(
              onHover: (details) {
                _handleHover(details.localPosition);
              },
              onExit: (details) {
                _clearHighlightedData();
              },
              child: OverlayPortal(
                controller: _overlayController,
                overlayChildBuilder: (context) {
                  if (_hoverPosition == null || _highlightedData == null) {
                    return Container();
                  }

                  return Stack(
                    children: [
                      if (_tooltipSize == null)
                        MeasureSize(
                          onSizeChange: (size) {
                            setState(() {
                              _tooltipSize = size;
                            });
                          },
                          child: Material(
                            color: Colors.transparent,
                            child: widget.tooltipBuilder != null
                                ? widget.tooltipBuilder!(
                                    context,
                                    _highlightedData!,
                                    _highlightedColors,
                                  )
                                : ChartTooltip(
                                    dataPoints: _highlightedData!,
                                    dataColors: _highlightedColors,
                                    backgroundColor: widget.backgroundColor,
                                  ),
                          ),
                        ),
                      if (_tooltipSize != null)
                        Positioned(
                          left: _calculateTooltipXPosition(
                            _globalHoverPosition!,
                            _tooltipSize!,
                            MediaQuery.of(context).size,
                          ),
                          top: _calculateTooltipYPosition(
                            _globalHoverPosition!,
                            _tooltipSize!,
                            MediaQuery.of(context).size,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: widget.tooltipBuilder != null
                                ? widget.tooltipBuilder!(
                                    context,
                                    _highlightedData!,
                                    _highlightedColors,
                                  )
                                : ChartTooltip(
                                    dataPoints: _highlightedData!,
                                    dataColors: _highlightedColors,
                                    backgroundColor: widget.backgroundColor,
                                  ),
                          ),
                        ),
                    ],
                  );
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final animatedElements = <ChartElement>[];
                    for (var i = 0; i < currentElements.length; i++) {
                      if (currentElements[i] is ChartDataSeries &&
                          oldElements[i] is ChartDataSeries) {
                        animatedElements.add(
                          (oldElements[i] as ChartDataSeries).animateTo(
                            currentElements[i] as ChartDataSeries,
                            _animation.value,
                          ),
                        );
                      } else {
                        animatedElements.add(currentElements[i]);
                      }
                    }
                    return CustomPaint(
                      size: chartSize,
                      painter: _LineChartPainter(
                        elements: animatedElements,
                        transform: transform,
                        highlightedPoints: _highlightedPoints,
                        highlightedColors: _highlightedColors,
                        animation: _animation.value,
                        markerSelectionStrategy: widget.markerSelectionStrategy,
                        hoverPosition: _hoverPosition,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Update highlighted data function
  void _updateHighlightedData(
    List<ChartData> highlightedData,
    List<Offset> highlightedPoints,
    List<Color> highlightedColors,
  ) {
    setState(() {
      _highlightedData = highlightedData;
      _highlightedPoints = highlightedPoints;
      _highlightedColors = highlightedColors;
    });
    if (highlightedData.isNotEmpty) {
      _overlayController.show();
    } else {
      _overlayController.hide();
    }
  }

  void _handleHover(Offset localPosition) {
    if (widget.markerSelectionStrategy != null) {
      final box = context.findRenderObject()! as RenderBox;
      final globalPosition = box.localToGlobal(localPosition);
      widget.markerSelectionStrategy!.handleHover(
        localPosition,
        transform,
        widget.elements,
        _updateHighlightedData,
      );
      setState(() {
        _hoverPosition = localPosition;
        _globalHoverPosition = globalPosition; // Store the global position
      });
    }
  }

  void _handleTap(Offset localPosition) {
    if (widget.markerSelectionStrategy != null) {
      final box = context.findRenderObject()! as RenderBox;
      final globalPosition = box.localToGlobal(localPosition);
      widget.markerSelectionStrategy!.handleTap(
        localPosition,
        transform,
        widget.elements,
        _updateHighlightedData,
      );
      setState(() {
        _hoverPosition = localPosition;
        _globalHoverPosition = globalPosition; // Store the global position
      });
    }
  }

  double _calculateTooltipXPosition(
    Offset globalPosition,
    Size tooltipSize,
    Size screenSize,
  ) {
    var xPosition = globalPosition.dx + 10; // Initial offset to the right
    if (xPosition + tooltipSize.width > screenSize.width) {
      // If tooltip exceeds right boundary
      xPosition =
          globalPosition.dx - tooltipSize.width - 10; // Offset to the left
    }
    if (xPosition < 10) {
      // Ensure tooltip doesn't go beyond the left boundary
      xPosition = 10;
    }
    return xPosition;
  }

  double _calculateTooltipYPosition(
    Offset globalPosition,
    Size tooltipSize,
    Size screenSize,
  ) {
    var yPosition = globalPosition.dy -
        tooltipSize.height -
        10; // Initial offset above the hover position
    if (yPosition < 10) {
      // If tooltip exceeds top boundary
      yPosition = globalPosition.dy + 10; // Offset below the hover position
    }
    if (yPosition + tooltipSize.height > screenSize.height) {
      // Ensure tooltip doesn't go beyond the bottom boundary
      yPosition = screenSize.height - tooltipSize.height - 10;
    }
    return yPosition;
  }

  @override
  void dispose() {
    _controller.dispose();
    // TODO?
    // _overlayController.dispose();
    super.dispose();
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.elements,
    required this.transform,
    required this.highlightedPoints,
    required this.highlightedColors,
    required this.animation,
    required this.markerSelectionStrategy,
    required this.hoverPosition,
  });
  final List<ChartElement> elements;
  final ChartDataTransform transform;
  final List<Offset>? highlightedPoints;
  final List<Color> highlightedColors;
  final double animation;
  final MarkerSelectionStrategy? markerSelectionStrategy;
  final Offset? hoverPosition;

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      element.paint(canvas, size, transform, animation);
    }

    if (markerSelectionStrategy != null) {
      markerSelectionStrategy!.paint(
        canvas,
        size,
        transform,
        highlightedPoints,
        highlightedColors,
        hoverPosition,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.highlightedPoints != highlightedPoints ||
        oldDelegate.animation != animation ||
        oldDelegate.hoverPosition != hoverPosition ||
        !listEquals(oldDelegate.elements, elements);
  }
}

typedef SizeCallback = void Function(Size size);

class MeasureSize extends StatefulWidget {
  const MeasureSize({
    required this.onSizeChange,
    required this.child,
    super.key,
  });
  final Widget child;
  final SizeCallback onSizeChange;

  @override
  _MeasureSizeState createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_postFrameCallback);
    return Container(
      key: widget.key,
      child: widget.child,
    );
  }

  void _postFrameCallback(_) {
    if (!mounted) return;
    final context = this.context;
    final size = context.size;
    if (size != null) {
      widget.onSizeChange(size);
    }
  }
}
