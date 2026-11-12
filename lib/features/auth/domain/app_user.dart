import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Canonical RBAC roles matching PostgreSQL `user_role` enum in `docs/05_Schema.md`.
enum UserRole {
  boutiqueOwner('boutique_owner'),
  boutiqueStaff('boutique_staff'),
  consignor('consignor'),
  authenticator('authenticator'),
  shopper('shopper');

  const UserRole(this.dbValue);

  /// Exact PostgreSQL `user_role` string value.
  final String dbValue;

  /// Parses a role string from JWT `app_metadata.role`, defaulting safely to
  /// [UserRole.shopper] for unknown or missing values.
  static UserRole fromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.dbValue == normalized) {
        return role;
      }
    }
    return UserRole.shopper;
  }

  /// Default landing route after sign-in per `docs/02_AppFlow.md` §2.
  String get defaultHomeRoute => switch (this) {
        UserRole.boutiqueOwner || UserRole.boutiqueStaff => '/staff/dashboard',
        UserRole.authenticator => '/auth-partner/queue',
        UserRole.consignor => '/consignor/overview',
        UserRole.shopper => '/shop/catalog',
      };
}

/// Authenticated ResaleRoute user derived strictly from server-signed JWT
/// `app_metadata` claims (`sync_profile_claims()`), never client-writable
/// `user_metadata` for authorization fields.
@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.boutiqueId,
    this.fullName,
  });

  /// Maps a Supabase [User] into an [AppUser].
  ///
  /// Security (T-01-10): `role` and `boutiqueId` are read exclusively from
  /// `user.appMetadata` (server-controlled), never `user.userMetadata`.
  factory AppUser.fromSupabaseUser(User user) {
    final rawRole = user.appMetadata['role'];
    final rawBoutiqueId = user.appMetadata['boutique_id'];
    final rawFullName =
        user.appMetadata['full_name'] ?? user.userMetadata?['full_name'];

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.fromString(rawRole is String ? rawRole : rawRole?.toString()),
      boutiqueId: rawBoutiqueId is String && rawBoutiqueId.isNotEmpty
          ? rawBoutiqueId
          : null,
      fullName: rawFullName is String && rawFullName.isNotEmpty
          ? rawFullName
          : null,
    );
  }

  final String id;
  final String email;
  final UserRole role;
  final String? boutiqueId;
  final String? fullName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.role == role &&
        other.boutiqueId == boutiqueId &&
        other.fullName == fullName;
  }

  @override
  int get hashCode => Object.hash(id, email, role, boutiqueId, fullName);

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, role: ${role.dbValue}, '
        'boutiqueId: $boutiqueId, fullName: $fullName)';
  }
}
