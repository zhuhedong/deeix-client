import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/announcement.dart';

class AnnouncementRepository {
  AnnouncementRepository(this._dio);
  final Dio _dio;

  Future<List<Announcement>> list({bool includeDismissed = false}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.announcements,
        queryParameters: {if (includeDismissed) 'include_dismissed': true},
      );
      final data = ApiEnvelope.unwrap(response);
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
          ? data['results'] as List
          : const [];
      return list
          .whereType<Map>()
          .map((e) => Announcement.fromApi(Map<String, dynamic>.from(e)))
          .where((a) => a.id > 0)
          .toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return b.priority.compareTo(a.priority);
        });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> dismissToday(int id) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.announcementDismissToday(id),
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> close(int id) async {
    try {
      final response = await _dio.post(ApiEndpoints.announcementClose(id));
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final announcementRepositoryProvider = FutureProvider<AnnouncementRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return AnnouncementRepository(dio);
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = await ref.watch(announcementRepositoryProvider.future);
  return repo.list();
});
