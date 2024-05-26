
import 'package:flutter/material.dart';
import 'chart_data.dart';

class ChartTooltip extends StatelessWidget {
  final List<ChartData> dataPoints;
  final Color backgroundColor;

  const ChartTooltip({
    super.key,
    required this.dataPoints,
    this.backgroundColor = Colors.black,
  });

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
              const Icon(Icons.circle, color: Colors.white),
              Text(
                '(${data.x}, ${data.y})',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 36),
            ],
          );
        }).toList(),
      ),
    );
  }
}
