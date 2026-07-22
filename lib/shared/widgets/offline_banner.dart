import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.message = '网络不可用，请检查连接'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: tokens.warningContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 17, color: tokens.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
