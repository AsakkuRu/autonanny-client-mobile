import 'package:nanny_core/api/api_models/base_models/api_response.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/child_medical_info.dart';
import 'package:nanny_core/models/from_api/emergency_contact.dart';

class NannyChildrenApi {
  // FE-MVP-012: Получение списка детей
  static Future<ApiResponse<List<Child>>> getChildren() async {
    return RequestBuilder<List<Child>>().create(
      dioRequest: DioRequest.dio.get("/users/children"),
      onSuccess: (response) {
        // Handle both formats: {children: [...]} or direct [...]
        final data = response.data;
        List<dynamic> childrenJson;
        if (data is List) {
          childrenJson = data;
        } else if (data is Map) {
          childrenJson = data['children'] ?? data['data'] ?? [];
        } else {
          childrenJson = [];
        }
        return childrenJson.map((json) => Child.fromJson(json)).toList();
      },
    );
  }

  // FE-MVP-012: Создание ребенка
  static Future<ApiResponse<int>> createChild(Child child) async {
    return RequestBuilder<int>().create(
      dioRequest: DioRequest.dio.post("/users/add_child", data: child.toJson()),
      onSuccess: (response) {
        // Handle different response formats
        final data = response.data;
        if (data is Map) {
          return (data['child_id'] ?? data['id'] ?? data['data']?['id'] ?? 0) as int;
        }
        return 0;
      },
      errorCodeMsgs: {
        400: "Некорректные данные ребенка"
      },
    );
  }

  // FE-MVP-012: Обновление ребенка
  static Future<ApiResponse> updateChild(int childId, Child child) async {
    return RequestBuilder().create(
      dioRequest: DioRequest.dio.put("/users/update_child/$childId", data: child.toJson()),
      errorCodeMsgs: {
        404: "Ребенок не найден",
        403: "Нет доступа к редактированию"
      },
    );
  }

  // FE-MVP-012: Удаление ребенка
  static Future<ApiResponse<void>> deleteChild(int childId) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.delete("/users/delete_child/$childId"),
      errorCodeMsgs: {
        404: "Ребенок не найден",
        403: "Нет доступа к удалению"
      },
    );
  }

  // FE-MVP-013: Получение медицинской информации ребенка
  static Future<ApiResponse<ChildMedicalInfo?>> getMedicalInfo(int childId) async {
    return RequestBuilder<ChildMedicalInfo?>().create(
      dioRequest: DioRequest.dio.get("/users/medical_info/$childId"),
      onSuccess: (response) {
        final data = response.data['medical_info'];
        if (data == null) return null;
        return ChildMedicalInfo.fromJson(data);
      },
      errorCodeMsgs: {
        404: "Медицинская информация не найдена"
      },
    );
  }

  // FE-MVP-013: Создание медицинской информации
  static Future<ApiResponse> createMedicalInfo(ChildMedicalInfo info) async {
    return RequestBuilder().create(
      dioRequest: DioRequest.dio.post("/users/medical_info", data: info.toJson()),
      errorCodeMsgs: {
        400: "Медицинская информация уже существует",
        404: "Ребенок не найден",
      },
    );
  }

  // FE-MVP-013: Обновление медицинской информации
  static Future<ApiResponse> updateMedicalInfo(int childId, ChildMedicalInfo info) async {
    return RequestBuilder().create(
      dioRequest: DioRequest.dio.put("/users/medical_info/$childId", data: info.toUpdateJson()),
      errorCodeMsgs: {
        404: "Медицинская информация не найдена"
      },
    );
  }

  // FE-MVP-013: Удаление медицинской информации
  static Future<ApiResponse<void>> deleteMedicalInfo(int childId) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.delete("/users/medical_info/$childId"),
      errorCodeMsgs: {
        404: "Медицинская информация не найдена"
      },
    );
  }

  // FE-MVP-014: Получение списка экстренных контактов
  static Future<ApiResponse<List<EmergencyContact>>> getEmergencyContacts(int childId) async {
    return RequestBuilder<List<EmergencyContact>>().create(
      dioRequest: DioRequest.dio.get("/users/emergency_contacts/$childId"),
      onSuccess: (response) {
        final List<dynamic> contactsJson = response.data['contacts'] ?? [];
        return contactsJson.map((json) => EmergencyContact.fromJson(json)).toList();
      },
      errorCodeMsgs: {
        404: "Ребенок не найден"
      },
    );
  }

  // FE-MVP-014: Создание экстренного контакта
  static Future<ApiResponse<int>> createEmergencyContact(EmergencyContact contact) async {
    return RequestBuilder<int>().create(
      dioRequest: DioRequest.dio.post("/users/emergency_contacts", data: contact.toJson()),
      onSuccess: (response) => response.data['contact_id'] as int,
      errorCodeMsgs: {
        404: "Ребенок не найден"
      },
    );
  }

  // FE-MVP-014: Обновление экстренного контакта
  static Future<ApiResponse> updateEmergencyContact(int contactId, EmergencyContact contact) async {
    return RequestBuilder().create(
      dioRequest: DioRequest.dio.put("/users/emergency_contacts/$contactId", data: contact.toJson()),
      errorCodeMsgs: {
        404: "Контакт не найден",
        403: "Нет доступа к контакту"
      },
    );
  }

  // FE-MVP-014: Удаление экстренного контакта
  static Future<ApiResponse<void>> deleteEmergencyContact(int contactId) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.delete("/users/emergency_contacts/$contactId"),
      errorCodeMsgs: {
        404: "Контакт не найден",
        403: "Нет доступа к контакту"
      },
    );
  }
}
