// Pure-Dart verification of shipped protocol helpers (no flutter_tester).
// Run: dart run tool/verify_protocol.dart

import 'dart:convert';
import 'dart:io';

import 'package:deeix_client/core/constants/app_config.dart';
import 'package:deeix_client/core/network/api_endpoints.dart';
import 'package:deeix_client/core/network/api_response.dart';
import 'package:deeix_client/core/utils/ndjson_stream.dart';
import 'package:deeix_client/core/utils/stream_events.dart';
import 'package:deeix_client/core/auth/pkce.dart';
import 'package:deeix_client/core/utils/export_transcript.dart';
import 'package:deeix_client/shared/models/announcement.dart';
import 'package:deeix_client/shared/models/billing.dart';
import 'package:deeix_client/shared/models/conversation.dart';
import 'package:deeix_client/shared/models/conversation_share.dart';
import 'package:deeix_client/shared/models/identity_provider.dart';
import 'package:deeix_client/shared/models/llm_model.dart';
import 'package:deeix_client/shared/models/message.dart';
import 'package:deeix_client/shared/models/message_attachment.dart';
import 'package:deeix_client/shared/models/session.dart';
import 'package:deeix_client/shared/models/mcp_tool.dart';
import 'package:deeix_client/shared/models/project.dart';
import 'package:deeix_client/shared/models/prompt_preset.dart';
import 'package:deeix_client/shared/models/user.dart';
import 'package:dio/dio.dart';

int _failed = 0;

void check(String name, bool ok, [String? detail]) {
  if (ok) {
    stdout.writeln('PASS  $name');
  } else {
    _failed++;
    stdout.writeln('FAIL  $name${detail != null ? ' — $detail' : ''}');
  }
}

Future<void> main() async {
  stdout.writeln('=== DEEIX client protocol verification ===');

  check('api base', AppConfig.apiBaseUrl == 'https://vps.cli-help.com');
  check('api prefix', AppConfig.apiPrefix == '/api/v1');
  check('login path', ApiEndpoints.login == '/auth/login');
  check(
    'stream path',
    ApiEndpoints.conversationMessageStream('x') ==
        '/conversations/x/messages/stream',
  );
  check('models path', ApiEndpoints.models == '/models');
  check('files path', ApiEndpoints.files == '/files');
  check('2fa verify path', ApiEndpoints.twoFactorVerify == '/auth/2fa/verify');
  check(
    'password reset path',
    ApiEndpoints.passwordResetStart == '/auth/password/reset/start',
  );
  check(
    'share path',
    ApiEndpoints.conversationShare('c1') == '/conversations/c1/share',
  );
  check(
    'feedback path',
    ApiEndpoints.messageFeedback('m1') == '/messages/m1/feedback',
  );
  check(
    'billing overview path',
    ApiEndpoints.billingOverview == '/billing/overview',
  );

  final okResp = Response(
    requestOptions: RequestOptions(path: '/auth/login'),
    statusCode: 200,
    data: {
      'errorMsg': '',
      'data': {
        'accessToken': 'tok',
        'user': {'id': 1},
      },
    },
  );
  final data = ApiEnvelope.unwrapMap(okResp);
  check('envelope unwrap accessToken', data['accessToken'] == 'tok');

  var threw = false;
  try {
    ApiEnvelope.unwrap(
      Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 400,
        data: {
          'errorMsg': 'username must be at least 3',
          'errorCode': 'request.invalid_body',
          'data': null,
        },
      ),
    );
  } on ApiException catch (e) {
    threw = e.message.contains('username must be at least 3');
  }
  check('envelope 4xx errorMsg', threw);

  final listResp = Response(
    requestOptions: RequestOptions(path: '/conversations'),
    statusCode: 200,
    data: {
      'errorMsg': '',
      'data': {
        'results': [
          {'publicID': 'c1', 'title': 'T', 'isStarred': true},
        ],
        'total': 1,
      },
    },
  );
  final results = ApiEnvelope.unwrapResults(listResp);
  check('unwrapResults length', results.length == 1);

  final user = User.fromApi({
    'user': {
      'id': 7,
      'publicID': 'u7',
      'displayName': 'Dee',
      'username': 'dee',
      'email': 'd@e.com',
    },
  });
  check('user publicID', user.publicID == 'u7');
  check('user displayLabel', user.displayLabel == 'Dee');

  final conv = Conversation.fromApi({
    'publicID': 'conv1',
    'title': 'Hello',
    'model': 'm1',
    'isStarred': true,
    'updatedAt': '2026-07-01T00:00:00Z',
  });
  check('conversation publicID', conv.publicID == 'conv1');
  check('conversation starred', conv.isStarred);

  final msg = ChatMessage.fromApi({
    'id': 3,
    'publicID': 'msg3',
    'role': 'assistant',
    'content': 'hi',
    'runID': 'r1',
    'parentPublicID': 'u0',
    'sourcePublicID': 'a0',
    'branchReason': 'retry',
  });
  check('message publicID preferred', msg.id == 'msg3');
  check('message role', msg.role == MessageRole.assistant);
  check('message parentPublicID', msg.parentPublicID == 'u0');
  check('message branchReason', msg.branchReason == 'retry');

  // MessageResponse.attachments is a JSON string (web parseAttachments).
  final attJson = jsonEncode([
    {
      'file_id': 'f_img_1',
      'file_name': 'shot.png',
      'mime_type': 'image/png',
      'file_category': 'image',
      'file_size': 1234,
      'kind': 'image',
      'processing_ready': true,
    },
    {
      'file_id': 'f_doc_1',
      'file_name': 'notes.txt',
      'mime_type': 'text/plain',
      'kind': 'file',
    },
  ]);
  final withAtt = ChatMessage.fromApi({
    'publicID': 'msg_att',
    'role': 'user',
    'content': 'see image',
    'contentType': 'mixed',
    'attachments': attJson,
  });
  check('attachments parsed count', withAtt.attachments.length == 2);
  check('attachment image flag', withAtt.attachments.first.isImage);
  check('attachment file id', withAtt.attachments.first.fileID == 'f_img_1');
  check(
    'parseAttachments empty',
    MessageAttachment.parseAttachments(null).isEmpty &&
        MessageAttachment.parseAttachments('').isEmpty,
  );

  // Platform permission / network surface files (static audit in same run)
  final root = Directory.current.path;
  final iosPlist = File('$root/ios/Runner/Info.plist').readAsStringSync();
  check(
    'ios NSCameraUsageDescription',
    iosPlist.contains('NSCameraUsageDescription'),
  );
  check(
    'ios NSPhotoLibraryUsageDescription',
    iosPlist.contains('NSPhotoLibraryUsageDescription'),
  );
  final androidMain = File(
    '$root/android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  check(
    'android main INTERNET permission',
    androidMain.contains('android.permission.INTERNET'),
  );

  // P1 surface presence
  bool hasFile(String rel, String needle) {
    final f = File('$root/$rel');
    if (!f.existsSync()) return false;
    return f.readAsStringSync().contains(needle);
  }

  check(
    'surface 2fa page',
    hasFile(
      'lib/features/auth/presentation/two_factor_page.dart',
      'verifyTwoFactor',
    ),
  );
  check(
    'surface password reset',
    hasFile(
      'lib/features/auth/presentation/password_reset_page.dart',
      'passwordResetStart',
    ),
  );
  check(
    'surface profile patch',
    hasFile(
      'lib/features/auth/presentation/profile_page.dart',
      'updateProfile',
    ),
  );
  check(
    'surface archive UI',
    hasFile(
      'lib/features/conversation/presentation/conversation_list_page.dart',
      "value: 'archive'",
    ),
  );
  check(
    'surface unarchive UI',
    hasFile(
          'lib/features/conversation/presentation/conversation_list_page.dart',
          "value: 'unarchive'",
        ) &&
        hasFile(
          'lib/features/conversation/presentation/conversation_list_page.dart',
          'archived: false',
        ),
  );
  check(
    'surface archived list status',
    hasFile(
          'lib/features/conversation/presentation/conversation_controller.dart',
          "statusParam",
        ) &&
        hasFile(
          'lib/features/conversation/presentation/conversation_controller.dart',
          "'archived'",
        ),
  );
  check(
    'surface i18n AppL10n',
    hasFile('lib/shared/l10n/app_l10n.dart', 'class AppL10n') &&
        hasFile('lib/shared/l10n/app_l10n.dart', "'Chats'") &&
        hasFile('lib/app.dart', 'AppL10n.delegate') &&
        hasFile('lib/app.dart', 'GlobalMaterialLocalizations.delegate'),
  );
  check(
    'surface share create',
    hasFile(
      'lib/features/conversation/data/conversation_repository.dart',
      'createShare',
    ),
  );
  check(
    'surface edit resend',
    hasFile(
      'lib/features/chat/presentation/chat_controller.dart',
      'editAndResend',
    ),
  );
  check(
    'surface feedback',
    hasFile(
      'lib/features/chat/presentation/chat_controller.dart',
      'setFeedback',
    ),
  );
  check(
    'surface think panel',
    hasFile(
      'lib/features/chat/presentation/widgets/message_bubble.dart',
      '思考过程',
    ),
  );
  check(
    'surface math',
    hasFile(
      'lib/features/chat/presentation/widgets/message_bubble.dart',
      'Math.tex',
    ),
  );
  check(
    'surface file list page',
    hasFile(
      'lib/features/file/presentation/files_page.dart',
      'fileRepositoryProvider',
    ),
  );
  check(
    'surface billing page',
    hasFile(
      'lib/features/billing/presentation/billing_page.dart',
      'BillingOverview',
    ),
  );
  check(
    'surface locale/font settings',
    hasFile(
      'lib/features/settings/presentation/settings_page.dart',
      'fontScaleProvider',
    ),
  );
  check(
    'surface gen options',
    hasFile(
      'lib/features/chat/presentation/chat_page.dart',
      'genOptionsProvider',
    ),
  );
  check(
    'surface file preview page',
    hasFile('lib/shared/widgets/file_preview_page.dart', 'FilePreviewPage') &&
        hasFile('lib/shared/widgets/file_preview_page.dart', 'PdfViewer'),
  );
  check(
    'surface chat prefs send enter',
    hasFile(
          'lib/core/settings/app_preferences.dart',
          'sendWithEnterProvider',
        ) &&
        hasFile(
          'lib/features/settings/presentation/settings_page.dart',
          'sendWithEnterProvider',
        ),
  );
  check(
    'surface bubble style',
    hasFile('lib/core/settings/app_preferences.dart', 'bubbleStyleProvider'),
  );
  check(
    'surface branch UI',
    hasFile(
          'lib/features/chat/presentation/chat_controller.dart',
          'selectBranch',
        ) &&
        hasFile(
          'lib/features/chat/presentation/widgets/message_bubble.dart',
          '_BranchNav',
        ) &&
        hasFile(
          'lib/core/utils/stream_events.dart',
          'filterBranchVisibleMessages',
        ),
  );
  check(
    'surface rag/ocr status',
    hasFile(
          'lib/features/chat/presentation/widgets/message_bubble.dart',
          'ragSources',
        ) &&
        hasFile('lib/core/utils/stream_events.dart', 'rag_search') &&
        hasFile('lib/shared/models/file_object.dart', 'processingLabel'),
  );
  check(
    'surface model search filter',
    hasFile(
          'lib/features/chat/presentation/widgets/chat_input.dart',
          '_ModelPickerSheet',
        ) &&
        hasFile(
          'lib/features/chat/presentation/widgets/chat_input.dart',
          '搜索模型',
        ),
  );
  check(
    'message branch fields fromApi',
    hasFile('lib/shared/models/message.dart', 'parentPublicID') &&
        hasFile('lib/shared/models/message.dart', 'sourcePublicID'),
  );
  check(
    'surface sessions page',
    hasFile(
      'lib/features/auth/presentation/sessions_page.dart',
      'logoutSession',
    ),
  );
  check(
    'surface projects page',
    hasFile(
          'lib/features/project/presentation/projects_page.dart',
          'ProjectRepository',
        ) ||
        hasFile(
          'lib/features/project/presentation/projects_page.dart',
          'projectRepositoryProvider',
        ),
  );
  check(
    'surface mcp tools',
    hasFile('lib/features/tools/data/tools_repository.dart', 'mcpTools') ||
        hasFile(
          'lib/features/tools/data/tools_repository.dart',
          'ApiEndpoints.mcpTools',
        ),
  );
  check(
    'surface export markdown',
    hasFile('lib/core/utils/export_transcript.dart', 'messagesToMarkdown'),
  );
  final md = messagesToMarkdown([
    ChatMessage.localUser('hi'),
    ChatMessage(id: 'a', role: MessageRole.assistant, content: 'hello'),
  ]);
  check(
    'export markdown pure',
    md.contains('### User') && md.contains('hello'),
  );

  final parser = NdjsonObjectStream();
  final events = await parser
      .parse(
        Stream<List<int>>.fromIterable([
          utf8.encode('{"type":"delta","delta":"A'),
          utf8.encode(
            'B"}\n{"type":"completed","data":{'
            '"userMessage":{"publicID":"u","role":"user","content":"q"},'
            '"assistantMessage":{"publicID":"a","role":"assistant","content":"AB"}}}',
          ),
        ]),
      )
      .toList();
  check('ndjson event count', events.length == 2);
  final d = mapStreamEvent(events[0]);
  check('map delta', d.delta == 'AB' && !d.done);
  final c = mapStreamEvent(events[1]);
  check(
    'map completed',
    c.done &&
        c.finalAssistantMessage?.content == 'AB' &&
        c.finalUserMessage?.id == 'u',
  );
  final err = mapStreamEvent({'type': 'error', 'message': 'boom'});
  check('map error', err.done && err.error == 'boom');

  final think = mapStreamEvent({
    'type': 'upstream_think_delta',
    'delta': 'reason…',
  });
  check('map think delta', think.thinkDelta == 'reason…' && !think.done);

  final proc = mapStreamEvent({
    'type': 'process_update',
    'trace': {
      'status': 'running',
      'tools': [
        {'name': 'search', 'status': 'done'},
      ],
    },
  });
  check(
    'map process/tool',
    proc.processStatus == 'running' &&
        (proc.toolSummary?.contains('search') ?? false),
  );

  final rag = mapStreamEvent({
    'type': 'rag_search',
    'sources': [
      {'title': '手册.pdf'},
      {'fileName': 'notes.md'},
    ],
  });
  check(
    'map rag_search',
    (rag.ragSources?.length == 2) &&
        (rag.ragSummary?.contains('2') ?? false) &&
        !rag.done,
  );

  final fproc = mapStreamEvent({
    'type': 'file_proc',
    'fileName': 'scan.pdf',
    'status': 'extracting',
  });
  check(
    'map file_proc',
    (fproc.fileProcMessage?.contains('scan.pdf') ?? false) && !fproc.done,
  );

  final branchMsgs = [
    ChatMessage.fromApi({'publicID': 'u1', 'role': 'user', 'content': 'q'}),
    ChatMessage.fromApi({
      'publicID': 'a1',
      'role': 'assistant',
      'content': 'v1',
      'parentPublicID': 'u1',
    }),
    ChatMessage.fromApi({
      'publicID': 'a2',
      'role': 'assistant',
      'content': 'v2',
      'parentPublicID': 'u1',
      'branchReason': 'retry',
    }),
  ];
  final visibleLatest = filterBranchVisibleMessages(branchMsgs);
  check(
    'branch filter default latest',
    visibleLatest.map((m) => m.id).join(',') == 'u1,a2',
  );
  final visibleFirst = filterBranchVisibleMessages(
    branchMsgs,
    selectedIndexByParent: const {'u1': 0},
  );
  check(
    'branch filter first sibling',
    visibleFirst.map((m) => m.id).join(',') == 'u1,a1',
  );

  final traced = ChatMessage.fromApi({
    'publicID': 'a3',
    'role': 'assistant',
    'content': 'x',
    'processTrace': {
      'status': 'completed',
      'promptTrace': {
        'blocks': [
          {
            'kind': 'rag',
            'sourceRefs': [
              {'sourceType': 'file_chunk', 'title': '公司手册'},
            ],
          },
        ],
      },
    },
  });
  check(
    'processTrace rag sources',
    traced.ragSources.contains('公司手册') && traced.processStatus == 'completed',
  );

  final fbUp = messageFeedbackBody('up');
  final fbClear = messageFeedbackBody(null);
  check('feedback body up', fbUp['feedback'] == 'up');
  check('feedback body clear', fbClear['feedback'] == null);

  final share = ConversationShare.fromApi({
    'shareID': 's_abc',
    'status': 'active',
    'titleSnapshot': 't',
    'messageCount': 2,
  });
  check(
    'share public url',
    share.publicUrl('https://vps.cli-help.com') ==
        'https://vps.cli-help.com/share/s_abc',
  );

  final overview = BillingOverview.fromApi({
    'overview': {
      'mode': 'usage',
      'periodUsedUSD': 1.5,
      'periodRemainingUSD': 8.5,
      'periodCreditUSD': 10,
      'plan': {'name': 'Pro'},
      'account': {'balanceUSD': 3.2, 'currency': 'USD'},
      'subscriptionEntitlements': [
        {'name': 'priority'},
      ],
    },
  });
  check('billing overview mode', overview.mode == 'usage');
  check('billing overview plan', overview.planName == 'Pro');
  check('billing overview balance', overview.account?.balanceUSD == 3.2);

  final model = LlmModel.fromApi({
    'platformModelName': 'demo-model',
    'vendor': 'x',
    'description': '',
    'icon': '',
    'sortOrder': 1,
    'capabilitiesJSON': '{"vision":true,"tools":true}',
    'pricing': {
      'isFree': false,
      'inputUSDPerMTokens': 1,
      'outputUSDPerMTokens': 2,
      'mode': 'token',
    },
  });
  check(
    'model capability tags',
    model.capabilityTags.contains('vision') &&
        model.capabilityTags.contains('tools'),
  );
  check(
    'model pricing summary',
    model.pricingSummary != null && model.pricingSummary!.contains('USD'),
  );

  final session = ActiveSession.fromApi({
    'sessionID': 'sess1',
    'current': true,
    'deviceLabel': 'iPhone',
    'clientIP': '1.2.3.4',
  });
  check('session map', session.sessionID == 'sess1' && session.current);

  final project = ConversationProject.fromApi({
    'publicID': 'p1',
    'name': 'Work',
    'description': 'd',
    'sortOrder': 2,
  });
  check('project map', project.publicID == 'p1' && project.name == 'Work');

  final tool = McpTool.fromApi({
    'id': 9,
    'name': 'web_search',
    'displayName': 'Web Search',
    'serverName': 'mcp',
  });
  check('mcp tool map', tool.id == 9 && tool.label == 'Web Search');

  final ann = Announcement.fromApi({
    'id': 3,
    'title': 'Hello',
    'contentMarkdown': '**hi**',
    'pinned': true,
    'priority': 10,
  });
  check('announcement map', ann.id == 3 && ann.pinned);

  final preset = PromptPreset.fromApi({
    'id': 1,
    'title': 'Summarize',
    'content': 'Please summarize',
    'enabled': true,
    'sortOrder': 1,
  });
  check('prompt preset map', preset.title == 'Summarize');

  final idp = IdentityProvider.fromApi({
    'publicID': 'p1',
    'slug': 'github',
    'name': 'GitHub',
    'loginEnabled': true,
    'type': 'oauth2',
  });
  check('identity provider map', idp.slug == 'github' && idp.loginEnabled);

  final pkce = PkcePair.generate();
  check(
    'pkce pair',
    pkce.verifier.isNotEmpty &&
        pkce.challenge.isNotEmpty &&
        pkce.verifier != pkce.challenge,
  );

  check(
    'surface search page',
    hasFile('lib/features/search/presentation/search_page.dart', '_search'),
  );
  check(
    'surface announcement banner',
    hasFile(
      'lib/features/announcement/presentation/announcement_banner.dart',
      'dismissToday',
    ),
  );
  check(
    'surface sso login',
    hasFile(
          'lib/features/auth/data/auth_repository.dart',
          'loginWithProvider',
        ) &&
        hasFile(
          'lib/features/auth/presentation/login_page.dart',
          'loginWithProvider',
        ),
  );
  check(
    'surface prompt presets',
    hasFile(
      'lib/features/chat/presentation/chat_page.dart',
      'promptPresetsProvider',
    ),
  );
  check(
    'ios deeix url scheme',
    File('$root/ios/Runner/Info.plist').readAsStringSync().contains('deeix'),
  );
  check(
    'android deeix scheme',
    File(
      '$root/android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync().contains('android:scheme="deeix"'),
  );

  // Live public smoke (no secrets)
  try {
    final client = HttpClient();
    final req = await client.getUrl(
      Uri.parse(
        '${AppConfig.apiBaseUrl}${AppConfig.apiPrefix}/auth/login-options',
      ),
    );
    req.headers.set(HttpHeaders.userAgentHeader, 'deeix-client-verify/1.0');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    check('live login-options status', res.statusCode == 200);
    check('live login-options has data', json['data'] is Map);
    await File(
      Platform.environment['VERIFY_OUT_DIR'] != null
          ? '${Platform.environment['VERIFY_OUT_DIR']}/login_options.json'
          : 'login_options.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    client.close(force: true);
  } catch (e) {
    check('live login-options', false, e.toString());
  }

  stdout.writeln('=== ${_failed == 0 ? 'ALL PASSED' : 'FAILED: $_failed'} ===');
  exit(_failed == 0 ? 0 : 1);
}
