import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/chart_bloc.dart';
import '../blocs/chart_state.dart';
import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Line Chart with Animation')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: BlocBuilder<ChartBloc, ChartState>(
          builder: (context, state) {
            return LineChart(
              domainExtent: const ChartExtent.tight(),
              backgroundColor: Theme.of(context).cardColor,
              elements: [
                ChartGridLines(isVertical: false, count: 5),
                ChartAxisLabels(
                    isVertical: true,
                    count: 5,
                    labelBuilder: (value) => value.toStringAsFixed(2)),
                ChartAxisLabels(
                    isVertical: false,
                    count: 5,
                    labelBuilder: (value) => value.toStringAsFixed(2)),
                ChartDataSeries(data: state.data1, color: Colors.blue),
                ChartDataSeries(
                    data: state.data2,
                    color: Colors.red,
                    lineType: LineType.bezier),
              ],
              // tooltipBuilder: (context, dataPoints) {
              //   return ChartTooltip(
              //       dataPoints: dataPoints, backgroundColor: Colors);
              // },
            );
          },
        ),
      ),
    );
  }
}
