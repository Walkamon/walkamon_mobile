import '../datasources/remote/daily_step_datasource.dart';

class DailyStepRepository {
  DailyStepRepository({DailyStepDatasource? datasource})
    : _datasource = datasource ?? DailyStepDatasource();

  final DailyStepDatasource _datasource;

  Future<bool> syncStepDelta(int stepCount) {
    return _datasource.syncStepDelta(stepCount);
  }
}
