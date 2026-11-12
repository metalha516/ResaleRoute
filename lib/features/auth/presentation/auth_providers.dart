import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resaleroute/features/auth/data/auth_repository.dart';
import 'package:resaleroute/features/auth/domain/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the active [AuthRepository].
///
/// Throws an explicit [StateError] if [Supabase.initialize] has not been called
/// unless overridden in tests via `ProviderScope(overrides: [...])`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    return SupabaseAuthRepository(Supabase.instance.client);
  } on Object catch (error) {
    throw StateError(
      'Supabase is not initialized. Initialize Supabase before reading '
      'authRepositoryProvider, or override authRepositoryProvider in tests. '
      '($error)',
    );
  }
});

/// Emits reactive [AppUser?] transitions from [AuthRepository.authStateChanges].
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Synchronously resolves the current [AppUser?] from the latest stream value
/// or falls back to [AuthRepository.currentUser] during initial stream startup.
final currentUserProvider = Provider<AppUser?>(
  (ref) =>
      ref.watch(authStateProvider).valueOrNull ??
      ref.watch(authRepositoryProvider).currentUser,
);
