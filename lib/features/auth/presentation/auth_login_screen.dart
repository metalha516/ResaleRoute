import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/router/app_router.dart';
import 'package:resaleroute/core/theme/app_theme.dart';
import 'package:resaleroute/features/auth/presentation/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Editorial Vault sign-in screen for `/login`.
///
/// Accepts an optional [redirectUrl] query parameter. Successful sign-in relies
/// on `authStateProvider` + `appRouterProvider` reactive redirect guards to
/// validate [redirectUrl] against the authenticated user's role.
class AuthLoginScreen extends ConsumerStatefulWidget {
  const AuthLoginScreen({
    super.key,
    this.redirectUrl,
  });

  final String? redirectUrl;

  @override
  ConsumerState<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<AuthLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to sign in. Please verify your email and password.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Authentication service is currently unavailable. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: AppSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: palette.bgSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: palette.borderSubtle, width: 1),
                  boxShadow: AppTheme.cardShadows(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'RESALEROUTE VAULT',
                        style: AppTypography.labelSm.copyWith(
                          color: palette.accentLuxury,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Boutique & Partner Sign In',
                        style: AppTypography.headingMd.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sign in with your boutique, authenticator, consignor, '
                        'or shopper credentials.',
                        style: AppTypography.bodyMd.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                      if (widget.redirectUrl != null &&
                          widget.redirectUrl!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.bgElevated,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusButton,
                            ),
                            border: Border.all(
                              color: palette.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'DESTINATION: ${widget.redirectUrl}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoData.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: palette.statusDanger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusButton,
                            ),
                            border: Border.all(
                              color: palette.statusDanger,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.bodyMd.copyWith(
                              color: palette.statusDanger,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: AppTypography.bodyMd.copyWith(
                          color: palette.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'staff@boutique.com',
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Email address is required.';
                          }
                          if (!trimmed.contains('@') ||
                              !trimmed.contains('.')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        style: AppTypography.bodyMd.copyWith(
                          color: palette.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    palette.buttonOnPrimary,
                                  ),
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => context.go(RoutePaths.shopCatalog),
                        child: const Text('Browse Public Catalog'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
