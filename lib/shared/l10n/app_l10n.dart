import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Lightweight en/zh app strings (shipped Localizations, not hard-coded only-zh UI).
class AppL10n {
  AppL10n(this.locale);

  final Locale locale;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ??
        AppL10n(const Locale('zh'));
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  bool get isZh => locale.languageCode.toLowerCase().startsWith('zh');

  String _t(String zh, String en) => isZh ? zh : en;

  String get appName => 'DEEIX';
  String get conversations => _t('对话', 'Chats');
  String get settings => _t('设置', 'Settings');
  String get login => _t('登录', 'Sign in');
  String get logout => _t('退出登录', 'Sign out');
  String get register => _t('邮箱注册', 'Register');
  String get forgotPassword => _t('忘记密码', 'Forgot password');
  String get newChat => _t('新对话', 'New chat');
  String get searchChats => _t('搜索对话…', 'Search chats…');
  String get rename => _t('重命名', 'Rename');
  String get renameChat => _t('重命名对话', 'Rename chat');
  String get title => _t('标题', 'Title');
  String get cancel => _t('取消', 'Cancel');
  String get save => _t('保存', 'Save');
  String get delete => _t('删除', 'Delete');
  String get pin => _t('置顶', 'Pin');
  String get unpin => _t('取消置顶', 'Unpin');
  String get archive => _t('归档', 'Archive');
  String get unarchive => _t('取消归档', 'Unarchive');
  String get archived => _t('已归档', 'Archived');
  String get active => _t('进行中', 'Active');
  String get shareLink => _t('分享链接', 'Share link');
  String get revokeShare => _t('撤销分享', 'Revoke share');
  String get shareCopied => _t('分享链接已复制', 'Share link copied');
  String get archivedToast => _t('已归档', 'Archived');
  String get unarchivedToast => _t('已取消归档', 'Unarchived');
  String get emptyChats => _t('暂无对话，点击右下角开始', 'No chats yet. Tap + to start');
  String get loadChats => _t('加载对话列表…', 'Loading chats…');
  String get retry => _t('重试', 'Retry');
  String get hello => _t('你好', 'Hello');
  String get appearance => _t('外观', 'Appearance');
  String get themeSystem => _t('系统', 'System');
  String get themeLight => _t('浅色', 'Light');
  String get themeDark => _t('深色', 'Dark');
  String get language => _t('语言', 'Language');
  String get followSystem => _t('跟随系统', 'System default');
  String get chinese => _t('中文', 'Chinese');
  String get english => _t('English', 'English');
  String get fontSize => _t('字体大小', 'Font size');
  String get defaultModel => _t('默认模型', 'Default model');
  String get billing => _t('用量与订阅', 'Usage & billing');
  String get myFiles => _t('我的文件', 'My files');
  String get clearCache => _t('清除本地缓存', 'Clear local cache');
  String get cacheCleared => _t('已清除图片缓存与生成参数缓存', 'Cache cleared');
  String get apiAddress => _t('API 地址', 'API base URL');
  String get privacy => _t('隐私政策', 'Privacy policy');
  String get terms => _t('用户协议', 'Terms of service');
  String get about => _t('关于', 'About');
  String get profile => _t('个人资料', 'Profile');
  String get chat => _t('聊天', 'Chat');
  String get stop => _t('停止', 'Stop');
  String get regenerate => _t('重新生成', 'Regenerate');
  String get sendHint => _t('输入消息…', 'Message…');
  String get generating => _t('生成中…', 'Generating…');
  String get offline => _t('网络不可用，请检查连接', 'You are offline');
  String get account => _t('邮箱 / 用户名', 'Email / username');
  String get password => _t('密码', 'Password');
  String get nativeClient =>
      _t('原生客户端 · 对接原版 DEEIX-Chat API', 'Native client for DEEIX-Chat API');
  String get notSet => _t('未设置', 'Not set');
  String get selectDefaultModel => _t('选择默认模型', 'Select default model');
  String get confirmLogout => _t('确定退出当前账号？', 'Sign out of this account?');
  String get deleteChat => _t('删除对话', 'Delete chat');
  String get chatPreferences => _t('聊天偏好', 'Chat preferences');
  String get sendWithEnter => _t('Enter 发送', 'Enter to send');
  String get sendWithEnterHint => _t(
    '开启后 Enter 发送，Shift+Enter 换行；关闭后 ⌘/Ctrl+Enter 发送',
    'On: Enter sends, Shift+Enter newline. Off: ⌘/Ctrl+Enter sends',
  );
  String get bubbleStyle => _t('气泡样式', 'Bubble style');
  String get bubbleComfortable => _t('舒适', 'Comfortable');
  String get bubbleCompact => _t('紧凑', 'Compact');
  String deleteChatConfirm(String name) =>
      _t('确定删除「$name」？', 'Delete “$name”?');
  String renameFailed(String? err) => err ?? _t('重命名失败', 'Rename failed');
  String shareFailed(String? err) =>
      err ?? _t('创建分享失败', 'Failed to create share');
  String createFailed(String? err) =>
      err ?? _t('创建对话失败', 'Failed to create chat');
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(AppL10n(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppL10n> old) => false;
}
