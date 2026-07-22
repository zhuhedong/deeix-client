import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/file_object.dart';

class FileListPage {
  const FileListPage({required this.results, required this.total});
  final List<FileObject> results;
  final int total;
}

class FileRepository {
  FileRepository(this._dio);

  final Dio _dio;

  Future<FileListPage> list({int page = 1, int pageSize = 50}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.files,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = ApiEnvelope.unwrapMap(response);
      final results =
          (data['results'] is List ? data['results'] as List : const [])
              .whereType<Map>()
              .map((e) => FileObject.fromApi(Map<String, dynamic>.from(e)))
              .where((f) => f.fileID.isNotEmpty)
              .toList();
      final total = data['total'] is int
          ? data['total'] as int
          : results.length;
      return FileListPage(results: results, total: total);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FileObject> upload({
    required File file,
    String? fileName,
    String? purpose,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final name = fileName ?? file.uri.pathSegments.last;
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: name),
        if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      });

      final response = await _dio.post(
        ApiEndpoints.files,
        data: form,
        cancelToken: cancelToken,
        onSendProgress: onProgress,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      final data = ApiEnvelope.unwrapMap(response);
      final fileMap = data['file'] is Map
          ? Map<String, dynamic>.from(data['file'] as Map)
          : data;
      return FileObject.fromApi(fileMap);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String fileId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.file(fileId));
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<FileObject> getMeta(String fileId) async {
    try {
      final response = await _dio.get(ApiEndpoints.file(fileId));
      final data = ApiEnvelope.unwrapMap(response);
      final fileMap = data['file'] is Map
          ? Map<String, dynamic>.from(data['file'] as Map)
          : data;
      return FileObject.fromApi(fileMap);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Downloads `/files/{id}/content` with auth (bytes).
  Future<List<int>> downloadContent(String fileId) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.fileContent(fileId),
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw ApiException(message: 'empty file content');
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Writes authenticated content to a temp file; returns absolute path.
  Future<String> downloadToTemp(String fileId, {String? fileName}) async {
    final bytes = await downloadContent(fileId);
    final dir = await getTemporaryDirectory();
    final safe = (fileName == null || fileName.trim().isEmpty)
        ? fileId
        : fileName.replaceAll(RegExp(r'[/\\]'), '_');
    final path = '${dir.path}/deeix_$safe';
    final f = File(path);
    await f.writeAsBytes(bytes, flush: true);
    return f.path;
  }

  String contentUrl(String fileId) =>
      '${_dio.options.baseUrl}${ApiEndpoints.fileContent(fileId)}';
}

final fileRepositoryProvider = FutureProvider<FileRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return FileRepository(dio);
});
