/// Read-only billing DTOs mapped from `/billing/*`.
class BillingAccount {
  const BillingAccount({
    this.balanceUSD,
    this.currency = 'USD',
    this.status = '',
    this.raw = const {},
  });

  final double? balanceUSD;
  final String currency;
  final String status;
  final Map<String, dynamic> raw;

  factory BillingAccount.fromApi(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    return BillingAccount(
      balanceUSD: asDouble(
        json['balanceUSD'] ?? json['balance'] ?? json['balance_usd'],
      ),
      currency: '${json['currency'] ?? 'USD'}',
      status: '${json['status'] ?? ''}',
      raw: json,
    );
  }
}

class BillingOverview {
  const BillingOverview({
    this.mode = '',
    this.periodUsedUSD,
    this.periodRemainingUSD,
    this.periodCreditUSD,
    this.planName,
    this.account,
    this.subscriptionLabels = const [],
  });

  final String mode;
  final double? periodUsedUSD;
  final double? periodRemainingUSD;
  final double? periodCreditUSD;
  final String? planName;
  final BillingAccount? account;
  final List<String> subscriptionLabels;

  factory BillingOverview.fromApi(Map<String, dynamic> json) {
    // envelope data may be { overview: {...} } or the overview itself
    Map<String, dynamic> o = json;
    if (json['overview'] is Map) {
      o = Map<String, dynamic>.from(json['overview'] as Map);
    }
    double? asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    BillingAccount? account;
    if (o['account'] is Map) {
      account = BillingAccount.fromApi(
        Map<String, dynamic>.from(o['account'] as Map),
      );
    }
    String? planName;
    if (o['plan'] is Map) {
      final name =
          '${(o['plan'] as Map)['name'] ?? (o['plan'] as Map)['title'] ?? ''}';
      planName = name.isEmpty ? null : name;
    }
    final entitlements = <String>[];
    if (o['subscriptionEntitlements'] is List) {
      for (final e in o['subscriptionEntitlements'] as List) {
        if (e is Map) {
          entitlements.add('${e['name'] ?? e['planName'] ?? e['code'] ?? e}');
        } else {
          entitlements.add('$e');
        }
      }
    }
    return BillingOverview(
      mode: '${o['mode'] ?? ''}',
      periodUsedUSD: asDouble(o['periodUsedUSD']),
      periodRemainingUSD: asDouble(o['periodRemainingUSD']),
      periodCreditUSD: asDouble(o['periodCreditUSD']),
      planName: planName,
      account: account,
      subscriptionLabels: entitlements,
    );
  }
}

class UsageSummary {
  const UsageSummary({this.total = 0, this.results = const []});

  final int total;
  final List<Map<String, dynamic>> results;

  factory UsageSummary.fromApi(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final results =
          (map['results'] is List ? map['results'] as List : const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      final total = map['total'] is int ? map['total'] as int : results.length;
      return UsageSummary(total: total, results: results);
    }
    if (data is List) {
      final results = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return UsageSummary(total: results.length, results: results);
    }
    return const UsageSummary();
  }
}
