import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/identity_provider.dart';
import '../../../shared/models/user.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, twoFactor }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
    this.isLoading = false,
    this.twoFactorChallengeToken,
    this.twoFactorMethods = const [],
  });

  final AuthStatus status;
  final User? user;
  final String? error;
  final bool isLoading;
  final String? twoFactorChallengeToken;
  final List<String> twoFactorMethods;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    bool? isLoading,
    String? twoFactorChallengeToken,
    List<String>? twoFactorMethods,
    bool clearUser = false,
    bool clearError = false,
    bool clearTwoFactor = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
      isLoading: isLoading ?? this.isLoading,
      twoFactorChallengeToken: clearTwoFactor
          ? null
          : (twoFactorChallengeToken ?? this.twoFactorChallengeToken),
      twoFactorMethods: clearTwoFactor
          ? const []
          : (twoFactorMethods ?? this.twoFactorMethods),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(bootstrap);
    return const AuthState();
  }

  Future<AuthRepository> get _repo => ref.read(authRepositoryProvider.future);

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Hard backstop: never leave the app stuck on the "restoring…" splash.
      final user = await _restoreSession().timeout(const Duration(seconds: 15));
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        );
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (_) {
      // Timeout or any restore failure → show sign-in instead of hanging.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  Future<User?> _restoreSession() async {
    final repo = await _repo;
    return repo.tryRestoreSession();
  }

  Future<bool> _applyLoginResult(LoginResult result) async {
    if (result.twoFactorRequired) {
      state = AuthState(
        status: AuthStatus.twoFactor,
        isLoading: false,
        twoFactorChallengeToken: result.challengeToken,
        twoFactorMethods: result.verificationMethods,
      );
      return false;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      user: result.user,
      isLoading: false,
    );
    return true;
  }

  /// Returns true if fully logged in; false if failed or needs 2FA.
  Future<bool> login(String account, String password) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearTwoFactor: true,
    );
    try {
      final repo = await _repo;
      final result = await repo.login(account: account, password: password);
      return _applyLoginResult(result);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
        clearUser: true,
        clearTwoFactor: true,
      );
      return false;
    }
  }

  Future<bool> loginWithProvider(IdentityProvider provider) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearTwoFactor: true,
    );
    try {
      final repo = await _repo;
      final result = await repo.loginWithProvider(provider);
      return _applyLoginResult(result);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
        isLoading: false,
        clearUser: true,
        clearTwoFactor: true,
      );
      return false;
    }
  }

  Future<bool> verifyTwoFactor({
    required String code,
    String verificationMethod = 'two_factor',
  }) async {
    final token = state.twoFactorChallengeToken;
    if (token == null || token.isEmpty) {
      state = state.copyWith(error: '二次验证已过期，请重新登录');
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = await _repo;
      final user = await repo.verifyTwoFactor(
        challengeToken: token,
        code: code,
        verificationMethod: verificationMethod,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> startTwoFactorEmail() async {
    final token = state.twoFactorChallengeToken;
    if (token == null) return;
    final repo = await _repo;
    await repo.startTwoFactorEmail(challengeToken: token);
  }

  void cancelTwoFactor() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Drop the session locally (no server call) — used when the server address
  /// changes, so the user re-authenticates against the new origin.
  void signOutLocal() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  Future<void> refreshProfile() async {
    try {
      final repo = await _repo;
      final user = await repo.currentUser();
      if (user != null) {
        state = state.copyWith(user: user, status: AuthStatus.authenticated);
      }
    } catch (_) {}
  }

  Future<bool> updateProfile({
    String? displayName,
    String? avatarURL,
    String? locale,
    String? timezone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = await _repo;
      final user = await repo.patchMe(
        displayName: displayName,
        avatarURL: avatarURL,
        locale: locale,
        timezone: timezone,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        status: AuthStatus.authenticated,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = await _repo;
      await repo.logout();
    } finally {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
