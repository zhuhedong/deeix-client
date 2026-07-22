import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/billing.dart';

class BillingRepository {
  BillingRepository(this._dio);
  final Dio _dio;

  Future<BillingAccount> account() async {
    try {
      final response = await _dio.get(ApiEndpoints.billingAccount);
      final data = ApiEnvelope.unwrapMap(response);
      final accountMap = data['account'] is Map
          ? Map<String, dynamic>.from(data['account'] as Map)
          : data;
      return BillingAccount.fromApi(accountMap);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<BillingOverview> overview() async {
    try {
      final response = await _dio.get(ApiEndpoints.billingOverview);
      final data = ApiEnvelope.unwrapMap(response);
      return BillingOverview.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UsageSummary> usage({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.billingUsage,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = ApiEnvelope.unwrap(response);
      return UsageSummary.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final billingRepositoryProvider = FutureProvider<BillingRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return BillingRepository(dio);
});
