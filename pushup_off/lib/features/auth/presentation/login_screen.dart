import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/presentation/settings_controller.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'you@email.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _displayNameController = TextEditingController(text: 'Yerosen Tamrat');
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password')),
      );
      return;
    }

    final notifier = ref.read(authControllerProvider.notifier);
    bool success;
    if (_isSignUp) {
      success = await notifier.signUpWithEmail(email, password, displayName);
    } else {
      success = await notifier.signInWithEmail(email, password);
    }

    if (success) await _finishAuth();
  }

  Future<void> _signInWithGoogle() async {
    final success =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success) await _finishAuth();
  }

  Future<void> _finishAuth() async {
    final preferences = ref.read(preferencesServiceProvider);
    await preferences.setSignedIn(true);
    if (!mounted) return;
    context.go(
      preferences.hasSeenOnboarding() ? RoutePaths.home : RoutePaths.onboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 56x56 Lime Brand Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentLime,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.textOnAccent,
                  size: 30,
                ),
              ),

              const SizedBox(height: 20),

              // Title "PUSH-UP OFF"
              Text(
                'PUSH-UP\nOFF',
                style: AppTypography.heroNumber(fontSize: 60),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                "Your camera counts every rep. Bad form doesn't make the cut.",
                style: AppTypography.bodyLarge(color: AppColors.textMuted),
              ),

              const SizedBox(height: 30),

              // Error Banner if present
              if (authState.errorMessage != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style:
                              AppTypography.bodySmall(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Display Name Field (Sign Up Only)
              if (_isSignUp) ...[
                Text(
                  'Full Name',
                  style: AppTypography.bodyMedium(color: AppColors.textMuted)
                      .copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _displayNameController,
                  style: AppTypography.bodyLarge(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Yerosen Tamrat',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email Field
              Text(
                'Email',
                style: AppTypography.bodyMedium(color: AppColors.textMuted)
                    .copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(
                  hintText: 'you@email.com',
                ),
              ),

              const SizedBox(height: 16),

              // Password Field
              Text(
                'Password',
                style: AppTypography.bodyMedium(color: AppColors.textMuted)
                    .copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(
                  hintText: 'At least 8 characters',
                ),
              ),

              const SizedBox(height: 22),

              // Primary Log In / Sign Up Button
              PrimaryButton(
                label: authState.isLoading
                    ? 'Loading...'
                    : (_isSignUp ? 'Create account' : 'Log in'),
                height: 56,
                borderRadius: 16,
                onPressed: authState.isLoading ? null : _submit,
              ),

              const SizedBox(height: 16),

              // Divider "or"
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      'or',
                      style: AppTypography.caption(color: AppColors.textMuted),
                    ),
                  ),
                  const Expanded(
                      child: Divider(color: AppColors.border, thickness: 1)),
                ],
              ),

              const SizedBox(height: 16),

              // Continue with Google Button
              SizedBox(
                height: 56,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(
                        color: AppColors.borderLight, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata_rounded,
                          size: 28, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(
                        'Continue with Google',
                        style: AppTypography.titleMedium(color: AppColors.text),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Footer Toggle Sign In / Sign Up
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignUp ? 'Already have an account? ' : 'New here? ',
                      style:
                          AppTypography.bodyMedium(color: AppColors.textMuted),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: Text(
                          _isSignUp ? 'Log in' : 'Create an account',
                          style: AppTypography.bodyMedium(
                                  color: AppColors.accentLime)
                              .copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
