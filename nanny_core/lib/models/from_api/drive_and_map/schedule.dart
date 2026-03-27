import 'package:flutter/material.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

class Schedule {
  Schedule({
    required this.title,
    this.isActive,
    required this.duration,
    required this.childrenCount,
    required this.datetimeCreate,
    required this.weekdays,
    required this.tariff,
    required this.otherParametrs,
    required this.roads,
    this.description = "",
    this.id,
    this.amountWeek,
    this.amountMonth,
    this.salary,
    this.isPaused,
    this.pauseFrom,
    this.pauseUntil,
    this.pauseReason,
    this.pauseInitiatedBy,
  });

  final int? id;
  final String title;
  final bool? isActive;
  final String description;
  final int duration;
  final int childrenCount;
  final DateTime datetimeCreate;
  final List<NannyWeekday> weekdays;
  final DriveTariff tariff;
  final List<OtherParametr> otherParametrs;
  final List<Road> roads;
  final double? salary;
  final double? amountWeek;
  final double? amountMonth;

  // FIX-005: поля паузы контракта
  final bool? isPaused;
  final String? pauseFrom;
  final String? pauseUntil;
  final String? pauseReason;
  final int? pauseInitiatedBy;

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final rawRoads = json["roads"];
    final roads = rawRoads == null
        ? <Road>[]
        : List<Road>.from(rawRoads.map((x) => Road.fromJson(x)));

    return Schedule(
      id: json["id"],
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      isActive: _parseBool(json["isActive"]),
      duration: json["duration"] ?? 0,
      childrenCount: json["children_count"] ?? 0,
      datetimeCreate: json["datetime_create"] != null
          ? DateTime.parse(json["datetime_create"] as String)
          : DateTime.now(),
      weekdays: json["week_days"] == null
          ? []
          : List<NannyWeekday>.from(
              json["week_days"].map((x) => NannyWeekday.values[x])),
      tariff: DriveTariff(id: json["id_tariff"]),
      otherParametrs: json["other_parametrs"] == null
          ? []
          : List<OtherParametr>.from(
              json["other_parametrs"]!.map((x) => OtherParametr.fromJson(x))),
      roads: roads,
      salary: json["salary"],
      amountMonth:
          roads.fold<double>(0, (sum, item) => sum + (item.amount ?? 0.0)),
      amountWeek:
          roads.fold<double>(0, (sum, item) => sum + (item.amount ?? 0.0)) / 4,
      // FIX-005: поля паузы от backend
      isPaused: _parseBool(json["is_paused"]),
      pauseFrom: json["pause_from"] as String?,
      pauseUntil: json["pause_until"] as String?,
      pauseReason: json["pause_reason"] as String?,
      pauseInitiatedBy: json["pause_initiated_by"] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "isActive": isActive,
        "duration": duration,
        "children_count": childrenCount,
        "datetime_create": datetimeCreate.toIso8601String(),
        "week_days": weekdays.map((x) => x.index).toList(),
        "id_tariff": tariff.id,
        "other_parametrs":
            otherParametrs.map((x) => x.toGraphJson(childrenCount)).toList(),
        "roads": roads.map((x) => x.toJson()).toList(),
      };
}

class Road {
  Road({
    required this.weekDay,
    required this.startTime,
    required this.endTime,
    required this.addresses,
    required this.title,
    required this.typeDrive,
    this.id,
    this.amount,
    this.children, // FE-MVP-015: Список ID детей для маршрута
  });

  final int? id;
  final double? amount;
  final NannyWeekday weekDay;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<DriveAddress> addresses;
  final String title;
  final List<DriveType> typeDrive;
  final List<int>? children; // FE-MVP-015: Список ID детей

  factory Road.fromJson(Map<String, dynamic> json) {
    return Road(
      id: json["id"],
      amount: json['amount']?.toDouble() ?? 0.0,
      weekDay: NannyWeekday.values[json["week_day"]],
      startTime: parseTime(json['start_time']),
      endTime: parseTime(json['end_time']),
      addresses: json["addresses"] == null
          ? []
          : List<DriveAddress>.from(
              json["addresses"]!.map((x) => DriveAddress.fromJson(x))),
      title: json["title"] ?? "",
      typeDrive: json["type_drive"] == null
          ? []
          : List<DriveType>.from(
              json["type_drive"].map((x) => DriveType.values.firstWhere(
                (dt) => dt.id == x,
                orElse: () => DriveType.oneWay,
              ))),
      children: json["children"] == null
          ? null
          : List<int>.from(json["children"]), // FE-MVP-015
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "week_day": weekDay.index,
        "start_time": startTime.formatTime(),
        "end_time": endTime.formatTime(),
        "addresses": addresses.map((x) => x.toJson()).toList(),
        "title": title,
        "type_drive": typeDrive.map((x) => x.id).toList(),
        if (children != null) "children": children, // FE-MVP-015
      };

  // Метод copyWith
  Road copyWith({
    int? id,
    double? amount,
    NannyWeekday? weekDay,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<DriveAddress>? addresses,
    String? title,
    List<DriveType>? typeDrive,
    List<int>? children, // FE-MVP-015
  }) {
    return Road(
      id: id ?? this.id,
      weekDay: weekDay ?? this.weekDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      addresses: addresses ?? this.addresses,
      title: title ?? this.title,
      typeDrive: typeDrive ?? this.typeDrive,
      amount: amount ?? this.amount,
      children: children ?? this.children, // FE-MVP-015
    );
  }

  static TimeOfDay parseTime(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts.first);
    int minutes = int.parse(parts.last);

    return TimeOfDay(hour: hours, minute: minutes);
  }
}

extension TimeParse on TimeOfDay {
  String formatTime() => "${hour < 10 ? "0$hour" : hour}"
      ":${minute < 10 ? "0$minute" : minute}";
}

extension RoadEquality on Road {
  bool isIdenticalTo(Road other) {
    return startTime == other.startTime &&
        endTime == other.endTime &&
        _areAddressesEqual(addresses, other.addresses) &&
        title == other.title &&
        _areTypesEqual(typeDrive, other.typeDrive);
  }

  // Вспомогательный метод для сравнения списков адресов
  bool _areAddressesEqual(List<DriveAddress> list1, List<DriveAddress> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final a = list1[i];
      final b = list2[i];
      if (a.fromAddress.address != b.fromAddress.address ||
          a.toAddress.address != b.toAddress.address ||
          a.fromAddress.location.latitude != b.fromAddress.location.latitude ||
          a.fromAddress.location.longitude !=
              b.fromAddress.location.longitude ||
          a.toAddress.location.latitude != b.toAddress.location.latitude ||
          a.toAddress.location.longitude != b.toAddress.location.longitude) {
        return false;
      }
    }
    return true;
  }

  // Вспомогательный метод для сравнения списков типов
  bool _areTypesEqual(List<DriveType> list1, List<DriveType> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
