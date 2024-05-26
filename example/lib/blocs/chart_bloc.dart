import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'chart_event.dart';
import 'chart_state.dart';
import 'package:dragon_charts_flutter/dragon_charts_flutter.dart';

class ChartBloc extends Bloc<ChartEvent, ChartState> {
  ChartBloc() : super(ChartState.initial()) {
    on<ChartUpdated>(_onChartUpdated);
    on<ChartDataPointAdded>(_onChartDataPointAdded);

    // Timer to periodically update chart data
    Timer.periodic(const Duration(seconds: 2), (timer) {
      add(ChartUpdated());
      if (Random().nextBool()) {
        add(ChartDataPointAdded());
      }
    });
  }

  Future<void> _onChartUpdated(
      ChartUpdated event, Emitter<ChartState> emit) async {
    final updatedData1 = state.data1
        .map((element) => ChartData(x: element.x, y: Random().nextDouble()))
        .toList();
    final updatedData2 = state.data2
        .map((element) => ChartData(x: element.x, y: Random().nextDouble()))
        .toList();
    emit(state.copyWith(data1: updatedData1, data2: updatedData2));
  }

  Future<void> _onChartDataPointAdded(
      ChartDataPointAdded event, Emitter<ChartState> emit) async {
    final newData1 = List<ChartData>.from(state.data1)
      ..add(ChartData(x: state.data1.last.x + 1, y: Random().nextDouble()));
    final newData2 = List<ChartData>.from(state.data2)
      ..add(ChartData(x: state.data2.last.x + 1, y: Random().nextDouble()));
    emit(state.copyWith(data1: newData1, data2: newData2));
  }
}
