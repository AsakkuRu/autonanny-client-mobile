import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyConsts {
  // Продакшн сервер Timeweb
  // static const String domen = "http://188.225.76.45:8000";
  // static const String baseUrl = "http://188.225.76.45:8000/api/v1.0";
  // static const String baseUrlOld = "http://188.225.76.45:8000/api/v1.0";
  // static const String socketUrl = "ws://188.225.76.45:8000/api/v1.0";
  
  // Локальный бэкенд для разработки (10.0.2.2 - это localhost хост-машины для Android эмулятора)
  static const String domen = "http://10.0.2.2:8000";
  static const String baseUrl = "http://10.0.2.2:8000/api/v1.0";
  static const String baseUrlOld = "http://10.0.2.2:8000/api/v1.0";
  static const String socketUrl = "ws://10.0.2.2:8000/api/v1.0";

  static const String regFileToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZF91c2VyIjotMSwiZmJpZCI6IlJlZ2lzdHJhdGlvbiIsImV4cCI6NDg0MjY2NzY2NX0.lzICh4ya1hVSehS4tCFLBTwOTD6TDxaxoBpJgt6YRrw";
  static const String tinkoffPublikKey =
      "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv5yse9ka3ZQE0feuGtemYv3IqOlLck8zHUM7lTr0za6lXTszRSXfUO7jMb+L5C7e2QNFs+7sIX2OQJ6a+HG8kr+jwJ4tS3cVsWtd9NXpsU40PE4MeNr5RqiNXjcDxA+L4OsEm/BlyFOEOh2epGyYUd5/iO3OiQFRNicomT2saQYAeqIwuELPs1XpLk9HLx5qPbm8fRrQhjeUD5TLO8b+4yCnObe8vy/BMUwBfq+ieWADIjwWCMp2KTpMGLz48qnaD9kdrYJ0iyHqzb2mkDhdIzkim24A3lWoYitJCBrrB2xM05sm9+OdCI1f7nPNJbl5URHobSwR94IRGT7CJcUjvwIDAQAB";

  static late final List<LoginPath> availablePaths;
  static void setLoginPaths(List<LoginPath> path) => availablePaths = path;

  // Map Data
  static String get mapKey =>
      Platform.isAndroid ? androidMapApiKey : iosMapApiKey;
  static const String iosMapApiKey = "AIzaSyC5Hq53HqTuBP9DLze6N_3iKyIEAKGb_K4";
  static const String androidMapApiKey =
      "AIzaSyAl5F9CDJuusuBxOvYv8YFJ1KJb-5Z8h00";
  static const MarkerId curPosId = MarkerId("curPos");
  static const MarkerId driverPosId = MarkerId("driverPos");

  static late final BitmapDescriptor curPosIcon;
  static late final BitmapDescriptor driverPosIcon;

  static Future<void> initMarkerIcons() async {
    curPosIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration.empty,
        'packages/nanny_components/assets/images/map/client_location.png');
    driverPosIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty,
        'packages/nanny_components/assets/images/map/driver_location.png');
  }
}

// 3 - Operator
// 4 - Manager
// 5 - Partner
// 6 - Franchise admin

enum UserType {
  //client("Родитель", 0),
  //driver("Водитель", 0),
  //admin("Администратор", 0),

  //partner("Партнёр", 5),
  //operator("Оператор", 3),
  //manager("Менеджер", 4),
  //franchiseAdmin("Администратор франшизы", 6);

  client("Родитель", 1),
  driver("Водитель", 2),
  operator("Оператор", 3),
  manager("Менеджер", 4),
  partner("Партнёр", 5),
  franchiseAdmin("Администратор франшизы", 6),
  admin("Администратор", 7);

  final String name;
  final int id;
  const UserType(this.name, this.id);

  static UserType? fromId(int id) {
    return UserType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => UserType.client, // Default fallback
    );
  }

  // Extension to find a UserType by name
  static UserType? fromName(String name) {
    return UserType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => UserType.client,
    );
  }
}

enum UserStatus {
  active("Активен"),
  inactive("Не активен"),
  deleted("Удалён"),
  notConfirmed("Не подтверждён"),
  unrecognized("Неизвестен");

  final String name;
  const UserStatus(this.name);
}

// enum TariffType {
//   companion("Попутчик"),
//   econom("Эконом"),
//   comfort("Комфорт"),
//   business("Бизнес");

//   final String name;
//   const TariffType(this.name);
// }

// 1 - в один конец
// 2 - туда и обратно
// 3 - с промежуточной
// 4 - регулярная
// 5 - разовая
// 6 - на замену
// 7 - cовместная

enum DriveType {
  oneWay("В один конец", 0),
  roundTrip("Туда и обратно", 1),
  withInterPoint("С промежуточной точкой", 2);

  final String name;
  final int id;
  const DriveType(this.name, this.id);
}

enum OfferType {
  route("Маршрут"),
  oneTime("Разовая поездка"),
  replacement("На замену");

  final String name;
  const OfferType(this.name);
}

enum GraphType {
  week("Недельный", 7),
  month("Месячный", 30),
  halfYear("Полугодовой", 182),
  year("Годовой", 365);

  final String name;
  final int duration;
  const GraphType(this.name, this.duration);
}

// Для графиков в админке: индексы - тип периода графика

enum DateType {
  day("День"),
  week("Неделя"),
  month("Месяц"),
  year("Год");

  final String name;
  const DateType(this.name);
}

enum PeriodType { graph, table }

enum NannyWeekday {
  monday("Понедельник", "Пн"),
  tuesday("Вторник", "Вт"),
  wednesday("Среда", "Ср"),
  thursday("Четверг", "Чт"),
  friday("Пятница", "Пт"),
  saturday("Суббота", "Сб"),
  sunday("Воскресенье", "Вс");

  final String fullName;
  final String shortName;
  const NannyWeekday(this.fullName, this.shortName);
}

enum NotificationAction {
  message("message"),
  order("order"),
  orderRequest("order_request"),
  orderRequestSuccess("order_request_success"),
  orderRequestDenied("order_request_denied"),
  orderFeedback("order_feedback"),
  fine("fine"),
  replyOrder("reply_order");

  final String name;
  const NotificationAction(this.name);
}

// Map data
/// **Google address types**
///
/// `streetAddress` - указывает точный адрес
///
/// `route` - указывает именованный маршрут (например, «US 101»)
///
/// `intersection` - указывает на крупный перекресток, обычно двух основных дорог
///
/// `political` - указывает на политическую сущность. Обычно этот тип обозначает полигон какой-либо гражданской администрации
///
/// `country` - указывает национальное политическое образование и обычно является типом высшего порядка, возвращаемым геокодером
///
/// `adminArea1` - указывает гражданское лицо первого порядка ниже уровня страны. В Соединенных Штатах такими административными
/// уровнями являются штаты. Не все страны демонстрируют эти административные уровни. В большинстве случаев короткие названия
/// административной_области_уровня_1 будут точно соответствовать подразделениям ISO 3166-2 и другим широко распространенным спискам;
/// однако это не гарантируется, поскольку наши результаты геокодирования основаны на различных сигналах и данных о местоположении
///
/// `adminArea2` - указывает на гражданский объект второго порядка ниже уровня страны. В Соединенных Штатах такими административными
/// уровнями являются округа. Не все страны демонстрируют эти административные уровни
///
/// `adminArea3` - указывает на гражданское лицо третьего порядка ниже уровня страны. Этот тип указывает на незначительное
/// гражданское деление. Не все страны демонстрируют эти административные уровни
///
/// `adminArea4` - указывает на гражданский объект четвертого порядка ниже уровня страны. Этот тип указывает на
/// незначительное гражданское деление. Не все страны демонстрируют эти административные уровни
///
/// `adminArea5` - указывает на гражданскую единицу пятого порядка ниже уровня страны. Этот тип указывает на
/// незначительное гражданское деление. Не все страны демонстрируют эти административные уровни
///
/// `adminArea6` - указывает на гражданскую единицу шестого порядка ниже уровня страны. Этот тип указывает на
/// незначительное гражданское деление. Не все страны демонстрируют эти административные уровни
///
/// `adminArea7` - указывает на гражданское лицо седьмого порядка ниже уровня страны. Этот тип указывает на
/// незначительное гражданское деление. Не все страны демонстрируют эти административные уровни
///
/// `colloquialArea` - указывает часто используемое альтернативное имя объекта
///
/// `locality` - указывает на объединенное политическое образование города или поселка.
///
/// `sublocality` - указывает на гражданское образование первого порядка ниже населенного пункта.
/// Для некоторых локаций может быть присвоен один из дополнительных типов: sublocality_level_1 до sublocality_level_5.
/// Каждый уровень сублокации является гражданским образованием. Большие числа указывают на меньшую географическую область
///
/// `neighborhood` - указывает на именованный район
///
/// `premise` - указывает на названное место, обычно это здание или совокупность зданий с общим названием
///
/// `subpremise` - указывает на объект первого порядка ниже именованного местоположения, обычно это отдельное здание в
/// группе зданий с общим названием
///
/// `plus_code` - указывает закодированную ссылку на местоположение, полученную на основе широты и долготы.
/// Плюсовые коды можно использовать вместо адресов в местах, где их нет (где здания не пронумерованы или улицы не названы).
/// Подробности см. на https://plus.codes
///
/// `postal_code` - указывает почтовый индекс, используемый для адреса почтовой почты внутри страны
///
/// `natural_feature` - указывает на выдающуюся природную особенность
///
/// `airport` - указывает на аэропорт
///
/// `park` - указывает на именованный парк
///
/// `point_of_interest` - указывает на именованную достопримечательность. Как правило, эти «POI» представляют собой
/// известные местные объекты, которые нелегко вписать в другую категорию, например «Эмпайр-Стейт-Билдинг» или «Эйфелева башня»
enum AddressType {
  streetAddress("street_address"),
  streetNumber("street_number"),
  route("route"),
  intersection("intersection"),
  political("political"),
  country("country"),
  adminArea1("administrative_area_level_1"),
  adminArea2("administrative_area_level_2"),
  adminArea3("administrative_area_level_3"),
  adminArea4("administrative_area_level_4"),
  adminArea5("administrative_area_level_5"),
  adminArea6("administrative_area_level_6"),
  adminArea7("administrative_area_level_7"),
  colloquialArea("colloquial_area"),
  locality("locality"),
  sublocality("sublocality"),
  sublocalityLevel1("sublocality_level_1"),
  sublocalityLevel2("sublocality_level_2"),
  sublocalityLevel3("sublocality_level_3"),
  sublocalityLevel4("sublocality_level_4"),
  sublocalityLevel5("sublocality_level_5"),
  neighborhood("neighborhood"),
  premise("premise"),
  subpremise("subpremise"),
  plusCode("plus_code"),
  postalCode("postal_code"),
  naturalFeature("natural_feature"),
  airport("airport"),
  park("park"),
  pointOfInterest("point_of_interest"),

  indefined("indefined");

  final String jsonKey;
  const AddressType(this.jsonKey);

  static AddressType fromJsonKey(String key) => AddressType.values
      .firstWhere((e) => e.jsonKey == key, orElse: () => AddressType.indefined);
}

/// **Google location types**
///
/// `ROOFTOP` - возвращает только те адреса, для которых Google имеет информацию о местоположении с точностью до адреса
///
/// `RANGE_INTERPOLATED` - возвращает только те адреса, которые отражают приближение (обычно на дороге), интерполированное
/// между двумя точными точками (например, перекрестками). Интерполированный диапазон обычно указывает на то,
/// что геокоды крыши недоступны для адреса
///
/// `GEOMETRIC_CENTER` - возвращает только геометрические центры местоположения, такого как ломаная линия (например, улица)
/// или многоугольник (регион)
///
/// `APPROXIMATE` - возвращает только те адреса, которые характеризуются как приблизительные.
enum LocationType {
  rooftop("ROOFTOP"),
  rangeInterpolated("RANGE_INTERPOLATED"),
  geometricCenter("GEOMETRIC_CENTER"),
  approximate("APPROXIMATE");

  final String jsonKey;
  const LocationType(this.jsonKey);

  static LocationType fromJsonKey(String key) =>
      LocationType.values.firstWhere((e) => e.jsonKey == key);
}
