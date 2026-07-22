import 'package:flutter/material.dart';

/// Design tokens for the "Graphite + Electric Indigo" system.
///
/// The [ColorScheme] carries Material's standard roles; [AppTokens] carries the
/// bespoke semantic roles the standard scheme has no slot for — the brand
/// gradient, chat bubble fills, hairline borders, status colors and the soft
/// accent wash used for hover / selected states. Widgets read these through
/// `Theme.of(context).extension<AppTokens>()` (see [AppTokensX.tokens]).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.brandGradient,
    required this.userBubble,
    required this.onUserBubble,
    required this.assistantBubble,
    required this.assistantBorder,
    required this.hairline,
    required this.softAccent,
    required this.codeBackground,
    required this.codeBorder,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.cardShadow,
    required this.floatingShadow,
  });

  /// Indigo → violet, painted on primary CTAs, the send button, the FAB and the
  /// brand mark. The one place the design spends its boldness.
  final List<Color> brandGradient;

  /// Outgoing (user) message fill and the ink that sits on it.
  final List<Color> userBubble;
  final Color onUserBubble;

  /// Incoming (assistant) message surface and its hairline outline.
  final Color assistantBubble;
  final Color assistantBorder;

  /// One-pixel divider / border color that reads as a line, never a slab.
  final Color hairline;

  /// Faint indigo wash for hovered / selected / pressed affordances.
  final Color softAccent;

  final Color codeBackground;
  final Color codeBorder;

  final Color success;
  final Color onSuccess;
  final Color successContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  /// Soft graphite elevation for raised surfaces (cards, sheets, input bar).
  final List<BoxShadow> cardShadow;

  /// Deeper shadow for floating elements (FAB, menus, dialogs).
  final List<BoxShadow> floatingShadow;

  LinearGradient get brandLinearGradient => LinearGradient(
    colors: brandGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get userBubbleGradient => LinearGradient(
    colors: userBubble,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const light = AppTokens(
    brandGradient: [Color(0xFF6366F5), Color(0xFF8B5CF6)],
    userBubble: [Color(0xFF6366F5), Color(0xFF8258F0)],
    onUserBubble: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFFFFFFFF),
    assistantBorder: Color(0xFFE7E8EF),
    hairline: Color(0xFFE7E8EF),
    softAccent: Color(0xFFEDEDFE),
    codeBackground: Color(0xFFF4F5F8),
    codeBorder: Color(0xFFE4E6ED),
    success: Color(0xFF15A05A),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCF6E6),
    warning: Color(0xFFC2740B),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFBEBD2),
    cardShadow: [
      BoxShadow(color: Color(0x0F1A1B2E), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x0A101014), blurRadius: 2, offset: Offset(0, 1)),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x2833356B),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
      BoxShadow(color: Color(0x14101014), blurRadius: 4, offset: Offset(0, 2)),
    ],
  );

  static const dark = AppTokens(
    brandGradient: [Color(0xFF7C7CFF), Color(0xFF9D7CFF)],
    userBubble: [Color(0xFF6E6EFB), Color(0xFF8A63F5)],
    onUserBubble: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFF1A1C23),
    assistantBorder: Color(0xFF2A2D37),
    hairline: Color(0xFF262933),
    softAccent: Color(0xFF20213F),
    codeBackground: Color(0xFF0B0C10),
    codeBorder: Color(0xFF262933),
    success: Color(0xFF34D399),
    onSuccess: Color(0xFF042016),
    successContainer: Color(0xFF12331F),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF241A02),
    warningContainer: Color(0xFF3A2E10),
    cardShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
  );

  @override
  AppTokens copyWith({
    List<Color>? brandGradient,
    List<Color>? userBubble,
    Color? onUserBubble,
    Color? assistantBubble,
    Color? assistantBorder,
    Color? hairline,
    Color? softAccent,
    Color? codeBackground,
    Color? codeBorder,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? floatingShadow,
  }) {
    return AppTokens(
      brandGradient: brandGradient ?? this.brandGradient,
      userBubble: userBubble ?? this.userBubble,
      onUserBubble: onUserBubble ?? this.onUserBubble,
      assistantBubble: assistantBubble ?? this.assistantBubble,
      assistantBorder: assistantBorder ?? this.assistantBorder,
      hairline: hairline ?? this.hairline,
      softAccent: softAccent ?? this.softAccent,
      codeBackground: codeBackground ?? this.codeBackground,
      codeBorder: codeBorder ?? this.codeBorder,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      cardShadow: cardShadow ?? this.cardShadow,
      floatingShadow: floatingShadow ?? this.floatingShadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      brandGradient: _lerpColors(brandGradient, other.brandGradient, t),
      userBubble: _lerpColors(userBubble, other.userBubble, t),
      onUserBubble: Color.lerp(onUserBubble, other.onUserBubble, t)!,
      assistantBubble: Color.lerp(assistantBubble, other.assistantBubble, t)!,
      assistantBorder: Color.lerp(assistantBorder, other.assistantBorder, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      softAccent: Color.lerp(softAccent, other.softAccent, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      codeBorder: Color.lerp(codeBorder, other.codeBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      floatingShadow: BoxShadow.lerpList(
        floatingShadow,
        other.floatingShadow,
        t,
      )!,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final n = a.length < b.length ? a.length : b.length;
    return [for (var i = 0; i < n; i++) Color.lerp(a[i], b[i], t)!];
  }
}

/// `context.tokens` — terse access to the bespoke design tokens.
extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
