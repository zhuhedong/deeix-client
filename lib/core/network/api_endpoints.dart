/// API paths relative to `/api/v1` (Swagger + web client).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String loginOptions = '/auth/login-options';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String refresh = '/auth/refresh';
  static const String me = '/me';
  static const String registerEmailStart = '/auth/register/email/start';
  static const String registerEmailComplete = '/auth/register/email/complete';
  static const String passwordResetStart = '/auth/password/reset/start';
  static const String passwordResetComplete = '/auth/password/reset/complete';
  static const String passwordChangeStart = '/auth/password/change/start';
  static const String passwordChangeComplete = '/auth/password/change/complete';

  /// Not always in Swagger; used by official web client.
  static const String twoFactorEmailStart = '/auth/2fa/email/start';
  static const String twoFactorVerify = '/auth/2fa/verify';
  static const String sessions = '/auth/sessions';
  static String sessionLogout(String sessionId) =>
      '/auth/sessions/$sessionId/logout';

  // Conversations
  static const String conversations = '/conversations';
  static String conversation(String publicId) => '/conversations/$publicId';
  static String conversationTitle(String publicId) =>
      '/conversations/$publicId/title';
  static String conversationStar(String publicId) =>
      '/conversations/$publicId/star';
  static String conversationArchive(String publicId) =>
      '/conversations/$publicId/archive';
  static String conversationMessages(String publicId) =>
      '/conversations/$publicId/messages';
  static String conversationMessageStream(String publicId) =>
      '/conversations/$publicId/messages/stream';
  static String conversationShare(String publicId) =>
      '/conversations/$publicId/share';
  static String conversationShareRegenerate(String publicId) =>
      '/conversations/$publicId/share/regenerate';
  static String conversationExport(String publicId) =>
      '/conversations/$publicId/export';
  static String conversationRuns(String publicId) =>
      '/conversations/$publicId/runs';
  static String conversationProject(String publicId) =>
      '/conversations/$publicId/project';

  // Projects
  static const String conversationProjects = '/conversation-projects';
  static String conversationProjectById(String publicId) =>
      '/conversation-projects/$publicId';

  static String runStream(String runId) => '/conversation-runs/$runId/stream';
  static String runCancel(String runId) => '/conversation-runs/$runId/cancel';

  // Messages
  static String message(String publicId) => '/messages/$publicId';
  static String messageFeedback(String publicId) =>
      '/messages/$publicId/feedback';

  // Models / files / tools
  static const String models = '/models';
  static const String files = '/files';
  static String file(String fileId) => '/files/$fileId';
  static String fileContent(String fileId) => '/files/$fileId/content';
  static const String mcpTools = '/mcp/tools';

  // Billing (read-only)
  static const String billingAccount = '/billing/account';
  static const String billingOverview = '/billing/overview';
  static const String billingUsage = '/billing/usage';
  static const String billingPlans = '/billing/plans';

  // User settings
  static const String userSettings = '/user/settings';

  // Announcements
  static const String announcements = '/announcements';
  static String announcementClose(int id) => '/announcements/$id/close';
  static String announcementDismissToday(int id) =>
      '/announcements/$id/dismiss-today';

  // Prompt presets
  static const String promptPresets = '/prompt-presets';

  // OAuth / OIDC providers (web-aligned)
  static String providerStart(String slug) => '/auth/providers/$slug/start';
  static String providerCallback(String slug) =>
      '/auth/providers/$slug/callback';
}
