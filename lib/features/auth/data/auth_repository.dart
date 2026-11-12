import 'package:resaleroute/features/auth/domain/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstraction over authentication state and session mutations, enabling
/// Riverpod overrides in unit/widget tests without a live Supabase instance.
abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<void> signOut();
}

/// Production [AuthRepository] backed by [SupabaseClient].
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AppUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((authState) {
      final user = authState.session?.user;
      return user == null ? null : AppUser.fromSupabaseUser(user);
    });
  }

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : AppUser.fromSupabaseUser(user);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException(
        'Sign-in response did not include an authenticated user.',
      );
    }
    return AppUser.fromSupabaseUser(user);
  }

  @override
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': fullName},
    );
    final user = response.user;
    return user == null ? null : AppUser.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
