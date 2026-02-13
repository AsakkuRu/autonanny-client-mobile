import 'package:dio/dio.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyFilesApi {
  static Future<ApiResponse<UploadedFiles>> uploadFiles(
      List<XFile> files) async {
    var formData = FormData();

    for (var file in files) {
      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: file.name),
      ));
    }

    return RequestBuilder<UploadedFiles>().create(
      dioRequest: DioRequest.dio.post(
        "/files/upload_files",
        data: formData,
      ),
      onSuccess: (response) => UploadedFiles.fromJson(response.data),
    );
  }
}
