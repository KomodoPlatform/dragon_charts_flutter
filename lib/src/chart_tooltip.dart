import 'package:flutter/material.dart';
import 'chart_data.dart';

class ChartTooltip extends StatelessWidget {
  final List<ChartData> dataPoints;
  final Color backgroundColor;

  const ChartTooltip({
    Key? key,
    required this.dataPoints,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: dataPoints.map((data) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(Icons.circle, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                '(${data.x.toStringAsFixed(2)}, ${data.y.toStringAsFixed(2)})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
