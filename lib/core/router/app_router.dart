import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resaleroute/features/auth/domain/app_user.dart';
import 'package:resaleroute/features/auth/presentation/auth_login_screen.dart';
import 'package:resaleroute/features/auth/presentation/auth_providers.dart';
import 'package:resaleroute/features/authentication_partner/presentation/auth_inspection_screen.dart';
import 'package:resaleroute/features/authentication_partner/presentation/auth_review_queue_screen.dart';
import 'package:resaleroute/features/consignor_ledger/presentation/consignor_ledger_screen.dart';
import 'package:resaleroute/features/consignor_ledger/presentation/consignor_portal_screen.dart';
import 'package:resaleroute/features/intake_grading/presentation/boutique_dashboard_screen.dart';
import 'package:resaleroute/features/intake_grading/presentation/item_intake_wizard_screen.dart';
import 'package:resaleroute/features/inventory_markdown/presentation/inventory_markdown_screen.dart';
import 'package:resaleroute/features/provenance_storefront/presentation/product_provenance_screen.dart';
import 'package:resaleroute/features/provenance_storefront/presentation/shopper_catalog_screen.dart';
import 'package:resaleroute/features/returns_disputes/presentation/dispute_resolution_screen.dart';
import 'package:resaleroute/features/sustainability/presentation/sustainability_report_screen.dart';

/// Canonical GoRouter path definitions matching `docs/02_AppFlow.md` §2.
abstract final class RoutePaths {
  static const String login = '/login';
  static const String staffDashboard = '/staff/dashboard';
  static const String staffIntake = '/staff/intake';
  static const String staffInventory = '/staff/inventory';
  static const String authPartnerQueue = '/auth-partner/queue';
  static const String authPartnerReview = '/auth-partner/review/:id';
  static const String consignorOverview = '/consignor/overview';
  static const String consignorLedger = '/consignor/ledger';
  static const String shopCatalog = '/shop/catalog';
  static const String shopItem = '/shop/item/:id';
  static const String disputes = '/disputes/:id';
  static const String impact = '/impact';
}

class _RoutePolicy {
  const _RoutePolicy({
    required this.isPublic,
    required this.allowedRoles,
  });

  final bool isPublic;
  final Set<UserRole> allowedRoles;
}

const _loginPolicy = _RoutePolicy(
  isPublic: true,
  allowedRoles: <UserRole>{},
);

const _staffPolicy = _RoutePolicy(
  isPublic: false,
  allowedRoles: <UserRole>{UserRole.boutiqueStaff, UserRole.boutiqueOwner},
);

const _authenticatorPolicy = _RoutePolicy(
  isPublic: false,
  allowedRoles: <UserRole>{UserRole.authenticator},
);

const _consignorPolicy = _RoutePolicy(
  isPublic: false,
  allowedRoles: <UserRole>{UserRole.consignor},
);

const _shopPolicy = _RoutePolicy(
  isPublic: true,
  allowedRoles: <UserRole>{UserRole.shopper},
);

const _ownerOrShopperPolicy = _RoutePolicy(
  isPublic: false,
  allowedRoles: <UserRole>{UserRole.boutiqueOwner, UserRole.shopper},
);

_RoutePolicy? _policyForPath(String rawPath) {
  final parsed = Uri.tryParse(rawPath);
  final path = parsed?.path ?? rawPath;
  final segments = Uri(path: path).pathSegments;

  if (segments.length == 1 && segments[0] == 'login') {
    return _loginPolicy;
  }
  if (segments.length == 2 && segments[0] == 'staff') {
    return switch (segments[1]) {
      'dashboard' || 'intake' || 'inventory' => _staffPolicy,
      _ => null,
    };
  }
  if (segments.length == 2 &&
      segments[0] == 'auth-partner' &&
      segments[1] == 'queue') {
    return _authenticatorPolicy;
  }
  if (segments.length == 3 &&
      segments[0] == 'auth-partner' &&
      segments[1] == 'review' &&
      segments[2].isNotEmpty) {
    return _authenticatorPolicy;
  }
  if (segments.length == 2 && segments[0] == 'consignor') {
    return switch (segments[1]) {
      'overview' || 'ledger' => _consignorPolicy,
      _ => null,
    };
  }
  if (segments.length == 2 &&
      segments[0] == 'shop' &&
      segments[1] == 'catalog') {
    return _shopPolicy;
  }
  if (segments.length == 3 &&
      segments[0] == 'shop' &&
      segments[1] == 'item' &&
      segments[2].isNotEmpty) {
    return _shopPolicy;
  }
  if (segments.length == 2 &&
      segments[0] == 'disputes' &&
      segments[1].isNotEmpty) {
    return _ownerOrShopperPolicy;
  }
  if (segments.length == 1 && segments[0] == 'impact') {
    return _ownerOrShopperPolicy;
  }
  return null;
}

bool _isSafeInternalRedirect(String candidate, UserRole role) {
  if (candidate.isEmpty ||
      !candidate.startsWith('/') ||
      candidate.startsWith('//') ||
      candidate.contains('\\')) {
    return false;
  }
  final parsed = Uri.tryParse(candidate);
  if (parsed == null ||
      parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.host.isNotEmpty) {
    return false;
  }
  if (!parsed.path.startsWith('/') || parsed.path.startsWith('//')) {
    return false;
  }
  if (parsed.path == RoutePaths.login) {
    return false;
  }
  final policy = _policyForPath(parsed.path);
  return policy != null && policy.allowedRoles.contains(role);
}

/// Pure, unit-testable GoRouter role-guard resolver enforcing `docs/02_AppFlow.md`
/// §2 across unauthenticated visitors and all 5 [UserRole] values.
///
/// Validates `redirectUrl` (T-01-11) to block open redirects and unauthorized
/// post-login destinations.
String? resolveRoleRedirect({
  required String matchedLocation,
  required String fullUri,
  required AppUser? user,
  String? redirectUrl,
}) {
  final policy = _policyForPath(matchedLocation);

  if (user == null) {
    if (policy != null && policy.isPublic) {
      return null;
    }
    return '${RoutePaths.login}?redirectUrl=${Uri.encodeComponent(fullUri)}';
  }

  if (matchedLocation == RoutePaths.login) {
    if (redirectUrl != null && _isSafeInternalRedirect(redirectUrl, user.role)) {
      return redirectUrl;
    }
    return user.role.defaultHomeRoute;
  }

  if (policy == null || !policy.allowedRoles.contains(user.role)) {
    return user.role.defaultHomeRoute;
  }

  return null;
}

class _AuthRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Provides the application-wide [GoRouter] wired to reactive [authStateProvider].
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier();
  ref.listen<AsyncValue<AppUser?>>(
    authStateProvider,
    (_, __) => refreshNotifier.notify(),
  );

  final router = GoRouter(
    initialLocation: RoutePaths.shopCatalog,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      return resolveRoleRedirect(
        matchedLocation: state.matchedLocation,
        fullUri: state.uri.toString(),
        user: user,
        redirectUrl: state.uri.queryParameters['redirectUrl'],
      );
    },
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => AuthLoginScreen(
          redirectUrl: state.uri.queryParameters['redirectUrl'],
        ),
      ),
      GoRoute(
        path: RoutePaths.staffDashboard,
        builder: (context, state) => BoutiqueDashboardScreen(
          boutiqueId: state.uri.queryParameters['boutiqueId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.staffIntake,
        builder: (context, state) => ItemIntakeWizardScreen(
          consignorId: state.uri.queryParameters['consignorId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.staffInventory,
        builder: (context, state) => InventoryMarkdownScreen(
          filterStatus: state.uri.queryParameters['filterStatus'],
        ),
      ),
      GoRoute(
        path: RoutePaths.authPartnerQueue,
        builder: (context, state) => AuthReviewQueueScreen(
          priorityFilter: state.uri.queryParameters['priorityFilter'],
        ),
      ),
      GoRoute(
        path: RoutePaths.authPartnerReview,
        builder: (context, state) => AuthInspectionScreen(
          itemId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.consignorOverview,
        builder: (context, state) => const ConsignorPortalScreen(),
      ),
      GoRoute(
        path: RoutePaths.consignorLedger,
        builder: (context, state) => ConsignorLedgerScreen(
          payoutStatus: state.uri.queryParameters['payoutStatus'],
        ),
      ),
      GoRoute(
        path: RoutePaths.shopCatalog,
        builder: (context, state) => ShopperCatalogScreen(
          category: state.uri.queryParameters['category'],
          grade: state.uri.queryParameters['grade'],
        ),
      ),
      GoRoute(
        path: RoutePaths.shopItem,
        builder: (context, state) => ProductProvenanceScreen(
          itemId: state.pathParameters['id']!,
          qrToken: state.uri.queryParameters['qrToken'],
        ),
      ),
      GoRoute(
        path: RoutePaths.disputes,
        builder: (context, state) => DisputeResolutionScreen(
          disputeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.impact,
        builder: (context, state) => SustainabilityReportScreen(
          timeframe: state.uri.queryParameters['timeframe'],
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refreshNotifier.dispose();
  });

  return router;
});
