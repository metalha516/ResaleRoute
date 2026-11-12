import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resaleroute/core/router/app_router.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Root ResaleRoute widget configured with Dark-First Editorial Vault defaults
/// (`ThemeMode.dark`) and Riverpod-backed [GoRouter].
class ResaleRouteApp extends ConsumerWidget {
  const ResaleRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ResaleRoute',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
