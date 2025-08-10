import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ApiServiceForWorks {
  final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://livemusicbucket.onrender.com/', headers: {}),
  );

  Future<UploadResponse> uploadImage(File file, String userId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'user_id': userId,
    });

    final response = await _dio.post('upload_work_image', data: formData);
    return UploadResponse.fromJson(response.data);
  }

  Future<UploadResponse> uploadVideo(File file, String userId) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      'user_id': userId,
    });

    final response = await _dio.post('upload_work_video', data: formData);
    return UploadResponse.fromJson(response.data);
  }

  Future<GetWorkMediaResponse> getWorkMedia(String userId) async {
    final response = await _dio.get(
      'get_work_media',
      queryParameters: {'user_id': userId},
    );
    return GetWorkMediaResponse.fromJson(response.data);
  }

  Future<DeleteResponse> deleteWorkMedia(String url) async {
    try {
      final response = await _dio.delete(
        'delete_work_media',
        data: {'url': url},
      );

      if (response.data is! Map<String, dynamic>) {
        return DeleteResponse(
          success: false,
          error: 'Respuesta del servidor inválida',
        );
      }

      return DeleteResponse.fromJson(response.data);
    } on DioError catch (e) {
      return DeleteResponse(
        success: false,
        error: e.response?.data?['error'] ?? e.message,
      );
    } catch (e) {
      return DeleteResponse(success: false, error: e.toString());
    }
  }
}

class UploadResponse {
  final String? url;
  final String? error;

  UploadResponse({this.url, this.error});

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      url: json['url'] as String?,
      error: json['error'] as String?,
    );
  }
}

class DeleteResponse {
  final bool success;
  final String? error;

  DeleteResponse({required this.success, this.error});

  factory DeleteResponse.fromJson(Map<String, dynamic> json) {
    return DeleteResponse(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }
}

class GetWorkMediaResponse {
  final List<String>? mediaUrls;

  GetWorkMediaResponse({this.mediaUrls});

  factory GetWorkMediaResponse.fromJson(Map<String, dynamic> json) {
    return GetWorkMediaResponse(
      mediaUrls:
          json['media_urls'] != null
              ? List<String>.from(json['media_urls'])
              : null,
    );
  }
}

class RetrofitInstanceForWorks {
  static final RetrofitInstanceForWorks _instance =
      RetrofitInstanceForWorks._internal();
  factory RetrofitInstanceForWorks() => _instance;

  final ApiServiceForWorks apiServiceForWorks;

  RetrofitInstanceForWorks._internal()
    : apiServiceForWorks = ApiServiceForWorks();
}

class UploadWorkMediaToServer extends ChangeNotifier {
  Future<File?> uriToFile(BuildContext context, Uri uri) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/${uri.path.split('/').last}');
    final bytes = await _readAsBytes(context, uri);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<bool> deleteWorkMedia(String url) async {
    try {
      final resp = await RetrofitInstanceForWorks().apiServiceForWorks
          .deleteWorkMedia(url);
      return resp.success;
    } catch (e) {
      return false;
    }
  }

  Future<void> uploadWorkImage(String userId, File imageFile) async {
    try {
      await RetrofitInstanceForWorks().apiServiceForWorks.uploadImage(
        imageFile,
        userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadWorkVideo(String userId, File videoFile) async {
    try {
      await RetrofitInstanceForWorks().apiServiceForWorks.uploadVideo(
        videoFile,
        userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>?> getWorkMedia(String userId) async {
    try {
      final resp = await RetrofitInstanceForWorks().apiServiceForWorks
          .getWorkMedia(userId);
      return resp.mediaUrls;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _readAsBytes(BuildContext context, Uri uri) async {
    final ByteData data = await DefaultAssetBundle.of(context).load(uri.path);
    return data.buffer.asUint8List();
  }
}
