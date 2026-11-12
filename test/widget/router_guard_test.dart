import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:resaleroute/app.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/router/app_router.dart';
import 'package:resaleroute/features/auth/data/auth_repository.dart';
import 'package:resaleroute/features/auth/domain/app_user.dart';
import 'package:resaleroute/features/auth/presentation/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AppUser? initialUser}) : _currentUser = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  void emitUser(AppUser? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = AppUser(
      id: 'user-signed-in',
      email: email,
      role: UserRole.boutiqueStaff,
      boutiqueId: 'boutique-1',
    );
    emitUser(user);
    return user;
  }

  @override
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return null;
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }

  Future<void> dispose() => _controller.close();
}

AppUser _userFor(UserRole role) {
  return AppUser(
    id: 'user-${role.dbValue}',
    email: '${role.dbValue}@resaleroute.test',
    role: role,
    boutiqueId: role == UserRole.boutiqueOwner || role == UserRole.boutiqueStaff
        ? 'boutique-1'
        : null,
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('resolveRoleRedirect — unauthenticated visitors', () {
    test('allows public routes /shop/catalog, /shop/item/:id, and /login', () {
      expect(
        resolveRoleRedirect(
          matchedLocation: '/shop/catalog',
          fullUri: '/shop/catalog',
          user: null,
        ),
        isNull,
      );
      expect(
        resolveRoleRedirect(
          matchedLocation: '/shop/item/item-1',
          fullUri: '/shop/item/item-1?qrToken=qr-123',
          user: null,
        ),
        isNull,
      );
      expect(
        resolveRoleRedirect(
          matchedLocation: '/login',
          fullUri: '/login',
          user: null,
        ),
        isNull,
      );
    });

    test('redirects protected routes to /login with encoded redirectUrl', () {
      final protectedUris = <String>[
        '/staff/dashboard',
        '/auth-partner/queue',
        '/consignor/overview',
        '/disputes/disp-1',
        '/impact',
      ];

      for (final uri in protectedUris) {
        final result = resolveRoleRedirect(
          matchedLocation: uri,
          fullUri: uri,
          user: null,
        );
        expect(
          result,
          '/login?redirectUrl=${Uri.encodeComponent(uri)}',
          reason: 'Expected unauthenticated access to $uri to redirect to login',
        );
      }
    });
  });

  group('resolveRoleRedirect — 5-role RBAC guard matrix', () {
    test('boutiqueOwner has access to staff, disputes, and impact routes', () {
      final owner = _userFor(UserRole.boutiqueOwner);

      for (final allowed in [
        '/staff/dashboard',
        '/staff/intake',
        '/staff/inventory',
        '/disputes/d1',
        '/impact',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: allowed,
            fullUri: allowed,
            user: owner,
          ),
          isNull,
          reason: 'boutiqueOwner should be allowed on $allowed',
        );
      }

      for (final forbidden in ['/auth-partner/queue', '/consignor/overview']) {
        expect(
          resolveRoleRedirect(
            matchedLocation: forbidden,
            fullUri: forbidden,
            user: owner,
          ),
          '/staff/dashboard',
          reason: 'boutiqueOwner should redirect from $forbidden',
        );
      }
    });

    test('boutiqueStaff has access to staff routes only', () {
      final staff = _userFor(UserRole.boutiqueStaff);

      for (final allowed in [
        '/staff/dashboard',
        '/staff/intake',
        '/staff/inventory',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: allowed,
            fullUri: allowed,
            user: staff,
          ),
          isNull,
        );
      }

      for (final forbidden in [
        '/disputes/d1',
        '/impact',
        '/auth-partner/queue',
        '/consignor/overview',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: forbidden,
            fullUri: forbidden,
            user: staff,
          ),
          '/staff/dashboard',
        );
      }
    });

    test('authenticator has access to auth-partner routes only', () {
      final authenticator = _userFor(UserRole.authenticator);

      for (final allowed in [
        '/auth-partner/queue',
        '/auth-partner/review/item-1',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: allowed,
            fullUri: allowed,
            user: authenticator,
          ),
          isNull,
        );
      }

      for (final forbidden in ['/staff/dashboard', '/consignor/overview']) {
        expect(
          resolveRoleRedirect(
            matchedLocation: forbidden,
            fullUri: forbidden,
            user: authenticator,
          ),
          '/auth-partner/queue',
        );
      }
    });

    test('consignor has access to consignor routes only', () {
      final consignor = _userFor(UserRole.consignor);

      for (final allowed in ['/consignor/overview', '/consignor/ledger']) {
        expect(
          resolveRoleRedirect(
            matchedLocation: allowed,
            fullUri: allowed,
            user: consignor,
          ),
          isNull,
        );
      }

      for (final forbidden in ['/staff/dashboard', '/auth-partner/queue']) {
        expect(
          resolveRoleRedirect(
            matchedLocation: forbidden,
            fullUri: forbidden,
            user: consignor,
          ),
          '/consignor/overview',
        );
      }
    });

    test('shopper has access to storefront, disputes, and impact routes', () {
      final shopper = _userFor(UserRole.shopper);

      for (final allowed in [
        '/shop/catalog',
        '/shop/item/item-1',
        '/disputes/d1',
        '/impact',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: allowed,
            fullUri: allowed,
            user: shopper,
          ),
          isNull,
        );
      }

      for (final forbidden in [
        '/staff/dashboard',
        '/auth-partner/queue',
        '/consignor/overview',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: forbidden,
            fullUri: forbidden,
            user: shopper,
          ),
          '/shop/catalog',
        );
      }
    });
  });

  group('resolveRoleRedirect — safe redirectUrl validation on /login', () {
    test('redirects to permitted internal redirectUrl with query parameters',
        () {
      final staff = _userFor(UserRole.boutiqueStaff);
      expect(
        resolveRoleRedirect(
          matchedLocation: '/login',
          fullUri: '/login?redirectUrl=%2Fstaff%2Fintake%3FconsignorId%3Dc1',
          user: staff,
          redirectUrl: '/staff/intake?consignorId=c1',
        ),
        '/staff/intake?consignorId=c1',
      );
    });

    test('blocks open redirects and unauthorized redirectUrl targets', () {
      final shopper = _userFor(UserRole.shopper);

      for (final unsafe in [
        'https://evil.example',
        'http://evil.example/phish',
        '//evil.example',
        '/\\evil.example',
        '/login',
        '/staff/dashboard',
      ]) {
        expect(
          resolveRoleRedirect(
            matchedLocation: '/login',
            fullUri: '/login',
            user: shopper,
            redirectUrl: unsafe,
          ),
          '/shop/catalog',
          reason: 'Unsafe or unauthorized redirectUrl "$unsafe" must fall back',
        );
      }
    });
  });

  group('ResaleRouteApp widget integration', () {
    testWidgets(
      'renders initial /shop/catalog with ThemeMode.dark (#0B0D10) and reacts to auth transitions',
      (WidgetTester tester) async {
        final fakeAuth = _FakeAuthRepository();
        addTearDown(fakeAuth.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuth),
            ],
            child: const ResaleRouteApp(),
          ),
        );
        await tester.pumpAndSettle();

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, ThemeMode.dark);

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, AppColors.dark.bgCanvas);
        expect(scaffold.backgroundColor, const Color(0xFF0B0D10));
        expect(find.text('Authenticated Catalog'), findsOneWidget);

        fakeAuth.emitUser(_userFor(UserRole.authenticator));
        await tester.pumpAndSettle();

        expect(find.text('Authentication Queue'), findsOneWidget);

        fakeAuth.emitUser(null);
        await tester.pumpAndSettle();

        expect(find.text('Boutique & Partner Sign In'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email Address'),
          'staff@resaleroute.test',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'VaultPass!123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
        await tester.pumpAndSettle();

        expect(find.text('Boutique Operations'), findsOneWidget);
      },
    );
  });
}
