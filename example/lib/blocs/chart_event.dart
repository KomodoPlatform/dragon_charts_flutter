import 'package:equatable/equatable.dart';

abstract class ChartEvent extends Equatable {
  const ChartEvent();

  @override
  List<Object> get props => [];
}

class ChartUpdated extends ChartEvent {}

class ChartDataPointAdded extends ChartEvent {}
