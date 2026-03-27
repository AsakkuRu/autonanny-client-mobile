class Driver {
  Driver({
      required this.city,
      required this.description,
      required this.age,
      required this.refCode,
      required this.driverLicense,
      required this.carData,
      required this.answers,
      this.experienceYears,
      this.money = "",
      this.inn = "",
  });

  final int city;
  final String description;
  final int age;
  final String refCode;
  final String money;
  final String inn;
  final DriverLicense? driverLicense;
  final CarData? carData;
  final Answers? answers;
  final int? experienceYears;

  factory Driver.fromJson(Map<String, dynamic> json){ 
      return Driver(
          city: json["city"] ?? 0,
          description: json["description"] ?? "",
          age: json["age"] ?? 0,
          refCode: json["refCode"] ?? "",
          driverLicense: json["driverLicense"] == null ? null : DriverLicense.fromJson(json["driverLicense"]),
          carData: json["carData"] == null ? null : CarData.fromJson(json["carData"]),
          answers: json["answers"] == null ? null : Answers.fromJson(json["answers"]),
          experienceYears: json["experienceYears"] ?? json["experience_years"],
          money: json['money'] ?? "",
          inn: json["inn_data"] ?? "Пусто"
      );
  }

  factory Driver.createRegForm() => Driver(
    city: -1, 
    description: "", 
    age: -1, 
    refCode: "", 
    driverLicense: null, 
    carData: null, 
    answers: null,
    experienceYears: null,
  );

  Map<String, dynamic> toJson() => {
      "city": city,
      "description": description,
      "age": age,
      "refCode": refCode,
      "driverLicense": driverLicense?.toJson(),
      "carData": carData?.toJson(),
      "answers": answers?.toJson(),
      "experienceYears": experienceYears,
      "inn_data": inn
  };

  Driver copyWith({
    int? city,
    String? description,
    int? age,
    String? refCode,
    DriverLicense? driverLicense,
    CarData? carData,
    Answers? answers,
    int? experienceYears,
    String? inn 
  }) {
    return Driver(
      city: city ?? this.city,
      description: description ?? this.description,
      age: age ?? this.age,
      refCode: refCode ?? this.refCode,
      driverLicense: driverLicense ?? this.driverLicense,
      carData: carData ?? this.carData,
      answers: answers ?? this.answers,
      experienceYears: experienceYears ?? this.experienceYears,
      inn: inn ?? this.inn
    );
  }
}

class Answers {
  Answers({
      this.first = "",
      this.second = "",
      this.third = "",
      this.fourth = "",
      this.fifth = "",
      this.sixth = "",
      this.seventh = "",
  });

  final String first;
  final String second;
  final String third;
  final String fourth;
  final String fifth;
  final String sixth;
  final String seventh;

  factory Answers.fromJson(Map<String, dynamic> json){ 
      return Answers(
          first: json["first"] ?? "",
          second: json["second"] ?? "",
          third: json["third"] ?? "",
          fourth: json["fourth"] ?? "",
          fifth: json["fifth"] ?? "",
          sixth: json["sixth"] ?? "",
          seventh: json["seventh"] ?? "",
      );
  }

  Map<String, dynamic> toJson() => {
      "first": first,
      "second": second,
      "third": third,
      "fourth": fourth,
      "fifth": fifth,
      "sixth": sixth,
      "seventh": seventh,
  };

  Answers copyWith({
    String? first,
    String? second,
    String? third,
    String? fourth,
    String? fifth,
    String? sixth,
    String? seventh    
  }) {
    return Answers(
      first: first ?? this.first,
      second: second ?? this.second,
      third: third ?? this.third,
      fourth: fourth ?? this.fourth,
      fifth: fifth ?? this.fifth,
      sixth: sixth ?? this.sixth,
      seventh: seventh ?? this.seventh
    );
  }
}

class CarData {
  CarData({
      required this.autoMark,
      required this.autoModel,
      required this.autoColor,
      required this.releaseYear,
      required this.stateNumber,
      required this.ctc,
  });

  final int autoMark;
  final int autoModel;
  final int autoColor;
  final int releaseYear;
  final String stateNumber;
  final String ctc;

  factory CarData.fromJson(Map<String, dynamic> json){ 
      return CarData(
          autoMark: json["autoMark"] ?? 0,
          autoModel: json["autoModel"] ?? 0,
          autoColor: json["autoColor"] ?? 0,
          releaseYear: json["releaseYear"] ?? 0,
          stateNumber: json["state_number"] ?? "",
          ctc: json["ctc"] ?? "",
      );
  }

  Map<String, dynamic> toJson() => {
      "autoMark": autoMark,
      "autoModel": autoModel,
      "autoColor": autoColor,
      "releaseYear": releaseYear,
      "state_number": stateNumber,
      "ctc": ctc,
  };

  CarData copyWith({
    int? autoMark,
    int? autoModel,
    int? autoColor,
    int? releaseYear,
    String? stateNumber,
    String? ctc    
  }) {
    return CarData(
      autoMark: autoMark ?? this.autoMark,
      autoModel: autoModel ?? this.autoModel,
      autoColor: autoColor ?? this.autoColor,
      releaseYear: releaseYear ?? this.releaseYear,
      stateNumber: stateNumber ?? this.stateNumber,
      ctc: ctc ?? this.ctc
    );
  }
}

/// For DriverInfoView
class CarDataText {
  CarDataText({
      required this.autoMark,
      required this.autoModel,
      required this.autoColor,
      required this.releaseYear,
      required this.stateNumber,
      required this.ctc,
  });

  final String autoMark;
  final String autoModel;
  final String autoColor;
  final int releaseYear;
  final String stateNumber;
  final String ctc;

  factory CarDataText.fromJson(Map<String, dynamic> json){ 
      return CarDataText(
          autoMark: json["mark"] ?? "",
          autoModel: json["model"] ?? "",
          autoColor: json["color"] ?? "",
          releaseYear: json["year"] ?? 0,
          stateNumber: json["state_number"] ?? "",
          ctc: json["ctc"] ?? "",
      );
  }

  Map<String, dynamic> toJson() => {
      "mark": autoMark,
      "model": autoModel,
      "color": autoColor,
      "year": releaseYear,
      "state_number": stateNumber,
      "ctc": ctc,
  };

  CarDataText copyWith({
    String? autoMark,
    String? autoModel,
    String? autoColor,
    int? releaseYear,
    String? stateNumber,
    String? ctc    
  }) {
    return CarDataText(
      autoMark: autoMark ?? this.autoMark,
      autoModel: autoModel ?? this.autoModel,
      autoColor: autoColor ?? this.autoColor,
      releaseYear: releaseYear ?? this.releaseYear,
      stateNumber: stateNumber ?? this.stateNumber,
      ctc: ctc ?? this.ctc
    );
  }
}

class DriverLicense {
  DriverLicense({
      required this.license,
      required this.receiveCountry,
      required this.receiveDate,
  });

  final String license;
  final int receiveCountry;
  final String receiveDate;

  factory DriverLicense.fromJson(Map<String, dynamic> json){ 
      return DriverLicense(
          license: json["license"] ?? "",
          receiveCountry: json["receiveCountry"] ?? 0,
          receiveDate: json["receiveDate"] ?? "",
      );
  }

  Map<String, dynamic> toJson() => {
      "license": license,
      "receiveCountry": receiveCountry,
      "receiveDate": receiveDate,
  };

  DriverLicense copyWith({
    String? license,
    int? receiveCountry,
    String? receiveDate    
  }) {
    return DriverLicense(
      license: license ?? this.license,
      receiveCountry: receiveCountry ?? this.receiveCountry,
      receiveDate: receiveDate ?? this.receiveDate
    );
  }
}

/*
{
	"city": 0,
	"description": "string",
	"age": 0,
	"refCode": "string",
	"driverLicense": {
		"license": "string",
		"receiveCountry": 0,
		"receiveDate": "string"
	},
	"carData": {
		"autoMark": 0,
		"autoModel": 0,
		"autoColor": 0,
		"releaseYear": 0,
		"state_number": "string",
		"ctc": "string"
	},
	"answers": {
		"first": "string",
		"second": "string",
		"third": "string",
		"fourth": "string",
		"fifth": "string",
		"sixth": "string",
		"seventh": "string"
	}
}*/
