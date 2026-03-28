import 'package:nanny_core/constants.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';

class ScheduleEditor {
  ScheduleEditor({
    this.maxChild = 4,
    required DriveTariff initTariff,
  }) {
    tariff = initTariff;
  }

  final int maxChild;

  String title = "";
  GraphType type = GraphType.week;
  int _childCount = 1;
  DriveTariff tariff = DriveTariff(id: 1);
  final List<OtherParametr> _otherParams = [];
  final List<Road> _roads = [];

  Schedule createSchedule(List<NannyWeekday>? weekDays, {int? id}) => Schedule(
      id: id,
      title: title,
      duration: type.duration,
      childrenCount: _childCount,
      datetimeCreate: DateTime.now(),
      //weekdays: weekDays ?? _roads.map((e) => e.weekDay).toSet().toList(),
      weekdays: _roads.map((e) => e.weekDay).toSet().toList(),
      tariff: tariff,
      otherParametrs: _otherParams,
      roads: _roads);

  int get childCount => _childCount;

  set childCount(int count) =>
      _childCount = count > maxChild ? maxChild : count;

  List<OtherParametr> get params => _otherParams;

  List<Road> get roads => _roads;

  bool addRoad(Road road) {
    _roads.add(road);
    return true;
  }

  bool deleteRoad(Road road) {
    _roads.remove(road);
    return true;
  }

  bool addParam(OtherParametr param) {
    if (_otherParams.where((e) => e.id == param.id).isNotEmpty) return false;

    _otherParams.add(param);
    return true;
  }

  void deleteParam(OtherParametr param) {
    _otherParams.removeWhere((item) => item.id == param.id);
  }

  bool valiateSchedule() {
    if (title.isEmpty || _childCount < 1 || _roads.isEmpty) return false;

    return true;
  }
}
