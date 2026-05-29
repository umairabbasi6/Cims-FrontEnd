import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/network/dio_error_message.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final void Function(String role) onLogin;

  const LoginScreen({
    super.key,
    required this.onLogin,
  });

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();

  final _passwordCtrl = TextEditingController();

  bool _obscure = true;

  String _selectedRole = '';

  bool _keepMeSignedIn = true;

  late final AnimationController _controller;

  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();

    _emailCtrl.dispose();
    _passwordCtrl.dispose();

    super.dispose();
  }

  Future<void> _login() async {
    try {
      ref
          .read(authLoadingProvider.notifier)
          .state = true;

      final repo = ref.read(
        authRepositoryProvider,
      );

      final response = await repo.login(
        username:
            _emailCtrl.text.trim(),

        password:
            _passwordCtrl.text.trim(),
        keepMeSignedIn: _keepMeSignedIn,
      );

      ref.invalidate(currentUserProvider);
      if (response.role == 'student') {
        ref.invalidate(currentStudentProvider);
      }

      widget.onLogin(response.role);
    } on DioException catch (e) {
      final message = dioErrorMessage(
        e,
        fallback: 'Login failed',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid username or password'),
        ),
      );
    } finally {
      ref
          .read(authLoadingProvider.notifier)
          .state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 980;

    return Scaffold(
      backgroundColor: const Color(0xFF020B24),
      body: FadeTransition(
        opacity: _fade,
        child: isWide ? _desktopLayout() : _mobileLayout(),
      ),
    );
  }

  // =====================================================
  // DESKTOP
  // =====================================================

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 12,
          child: _heroSection(),
        ),

        Expanded(
          flex: 11,
          child: _authSection(),
        ),
      ],
    );
  }

  // =====================================================
  // MOBILE
  // =====================================================

  Widget _mobileLayout() {
    return Stack(
      children: [
        _heroBackground(),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(24),

              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 420,
                ),

                child: _loginCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // HERO SECTION
  // =====================================================

  Widget _heroSection() {
    return Stack(
      children: [
        _heroBackground(),

        Padding(
          padding:
              const EdgeInsets.all(52),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  _buildLogoBadge(size: 42),

                  const SizedBox(width: 14),

                  const Text(
                    'CIMS',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 110),

              ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 560,
                ),

                child: Text(
                  'A unified institute\nplatform for medical\nsciences.',

                  style:
                      AppTextStyles.display
                          .copyWith(
                    color: Colors.white,
                    height: 1.02,
                    fontSize: 64,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 560,
                ),

                child: Text(
                  'Capital Institute\'s all-in-one suite for admissions, attendance, results, fees, and analytics — built for paramedical education.',

                  style:
                      AppTextStyles.bodyLg
                          .copyWith(
                    color: Colors.white
                        .withValues(
                      alpha: 0.82,
                    ),

                    height: 1.7,
                    fontSize: 17,
                  ),
                ),
              ),

              const Spacer(),

              Row(
                children: [
                  _heroStat(
                    '1,184',
                    'Active Students',
                    Icons.people_alt_rounded,
                  ),

                  const SizedBox(width: 20),

                  _heroStat(
                    '86',
                    'Faculty',
                    Icons.school_rounded,
                  ),

                  const SizedBox(width: 20),

                  _heroStat(
                    '8',
                    'Departments',
                    Icons.account_balance_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFF2F6BFF),
            Color(0xFF0E9AE7),
          ],
        ),
      ),

      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,

            child: Container(
              width: 320,
              height: 320,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: Colors.white
                    .withValues(
                  alpha: 0.12,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -140,
            left: -80,

            child: Container(
              width: 280,
              height: 280,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: Colors.white
                    .withValues(
                  alpha: 0.08,
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center:
                      const Alignment(
                    -0.4,
                    -0.3,
                  ),

                  radius: 1.2,

                  colors: [
                    Colors.white
                        .withValues(
                      alpha: 0.16,
                    ),

                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(
    String value,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // AUTH SECTION
  // =====================================================

  Widget _authSection() {
    return Container(
      color: const Color(0xFF020B24),

      child: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 30,
          ),

          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 430,
            ),

            child: _loginCard(),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // LOGIN CARD
  // =====================================================

  Widget _loginCard() {
    final loading = ref.watch(authLoadingProvider);
    final isWide = MediaQuery.of(context).size.width > 980;
    final cardPadding = isWide ? 34.0 : 20.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1224).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 50,
                offset: const Offset(0, 30),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (!isWide) ...[
                _buildLogoBadge(size: 84),
                const SizedBox(height: 20),
              ],
              Text(
                'WELCOME BACK',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to CIMS',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontSize: isWide ? 42 : 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Use your institute credentials. If you forgot your password, contact the admin office.',
                textAlign: isWide ? TextAlign.left : TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'USERNAME',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _inputField(
                controller: _emailCtrl,
                hint: 'admin',
                icon: Icons.mail_outline_rounded,
                autofocus: true,
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PASSWORD',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _inputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                obscure: _obscure,
                icon: Icons.lock_outline_rounded,
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white.withValues(alpha: 0.56),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _keepMeSignedIn = !_keepMeSignedIn;
                      });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _keepMeSignedIn,
                            onChanged: (val) {
                              setState(() {
                                _keepMeSignedIn = val ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Keep me signed in',
                          style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primarySoft,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign in to CIMS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR DEMO AS',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.42),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _roleButton(
                    'Admin',
                    'Full system',
                    'admin',
                  ),
                  const SizedBox(width: 10),
                  _roleButton(
                    'Teacher',
                    'Faculty',
                    'teacher',
                  ),
                  const SizedBox(width: 10),
                  _roleButton(
                    'Student',
                    'Portal',
                    'student',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© 2026 Capital Institute of Para Medical Sciences · v2.4.0',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.34),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // INPUT
  // =====================================================

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    bool autofocus = false,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      autofocus: autofocus,
      textInputAction: textInputAction,
      onSubmitted: (_) => _login(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: 0.46),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ROLE BUTTON
  // =====================================================

  Widget _roleButton(
    String title,
    String subtitle,
    String role,
  ) {
    final selected = _selectedRole == role;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _selectedRole = role;

            switch (role) {
              case 'teacher':
                _emailCtrl.text = 'teacher';
                _passwordCtrl.text = 'teacher123';
                break;

              case 'student':
                _emailCtrl.text = 'student';
                _passwordCtrl.text = 'student123';
                break;

              default:
                _emailCtrl.text = 'admin';
                _passwordCtrl.text = 'admin123';
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRoleIcon(role),
                color: selected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.46),
                size: 22,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(
                    alpha: selected ? 0.70 : 0.40,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBadge({double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.05),
          child: Image.asset(
            'assets/icons/Cims_logo.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'teacher':
        return Icons.school_rounded;
      case 'student':
        return Icons.person_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }
}
