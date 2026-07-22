import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deeix_client/shared/theme/app_theme.dart';
import 'package:deeix_client/shared/theme/app_tokens.dart';
import 'package:deeix_client/shared/widgets/ui_kit.dart';
import 'package:deeix_client/shared/widgets/loading_view.dart';
import 'package:deeix_client/shared/widgets/error_view.dart';
import 'package:deeix_client/shared/widgets/offline_banner.dart';
import 'package:deeix_client/shared/models/message.dart';
import 'package:deeix_client/features/chat/presentation/widgets/message_bubble.dart';

Widget _harness(ThemeData theme) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: ListView(
        children: [
          const OfflineBanner(),
          const SizedBox(height: 12),
          const Center(child: BrandMark(size: 64)),
          const AssistantAvatar(),
          const SizedBox(height: 12),
          GradientButton(onPressed: () {}, child: const Text('登录')),
          const SizedBox(height: 12),
          const TypingIndicator(),
          const SectionLabel('外观'),
          AppCardGroup(
            children: const [
              ListTile(title: Text('语言'), subtitle: Text('跟随系统')),
              ListTile(title: Text('字体大小')),
            ],
          ),
          const SizedBox(height: 12),
          const LoadingView(message: '加载中…'),
          const SizedBox(height: 12),
          const ErrorView(message: '网络错误'),
          const EmptyState(
            useBrandMark: true,
            title: '开始新的对话',
            message: '发送第一条消息即可开始。',
          ),
          MessageBubble(
            message: const ChatMessage(
              id: 'u1',
              role: MessageRole.user,
              content: '帮我把 UI 升级重构一下',
            ),
          ),
          MessageBubble(
            message: ChatMessage(
              id: 'a1',
              role: MessageRole.assistant,
              platformModelName: 'gpt-5',
              content:
                  '好的，这是重构方案：\n\n- 设计系统\n- `代码` 高亮\n\n```dart\nvoid main() {}\n```',
              thinking: '先分析现有主题…',
              createdAt: DateTime(2026, 7, 21, 9, 30),
            ),
          ),
          const MessageBubble(
            message: ChatMessage(
              id: 'a2',
              role: MessageRole.assistant,
              isStreaming: true,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('design system renders (light)', (tester) async {
    await tester.pumpWidget(_harness(AppTheme.light()));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    expect(find.byType(BrandMark), findsWidgets);
  });

  testWidgets('design system renders (dark)', (tester) async {
    await tester.pumpWidget(_harness(AppTheme.dark()));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    expect(find.text('登录'), findsOneWidget);
  });

  test('AppTokens lerp + light/dark differ', () {
    expect(AppTokens.light.hairline, isNot(AppTokens.dark.hairline));
    final mid = AppTokens.light.lerp(AppTokens.dark, 0.5);
    expect(mid, isA<AppTokens>());
  });
}
