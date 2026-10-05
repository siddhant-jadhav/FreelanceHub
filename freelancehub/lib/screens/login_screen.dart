import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/errors/app_exception.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

enum LoginRole { client, freelancer }

/// Login Screen (Client & Freelancer)
/// Designed following FreelanceHub Design System & Stitch Reference with refined spacing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole _selectedRole = LoginRole.client;

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseService.instance.signIn(
        identifier: _identifierController.text,
        password: _passwordController.text,
        fallbackRole:
            _selectedRole == LoginRole.client ? 'client' : 'freelancer',
      );

      if (!mounted) return;

      final resolvedRole = FirebaseService.instance.currentRole ??
          (_selectedRole == LoginRole.client ? 'client' : 'freelancer');
      FirebaseService.instance.setCurrentRole(resolvedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged in successfully as ${resolvedRole == 'client' ? 'Client' : 'Freelancer'}!',
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );

      // Forward to respective screen based on verified role
      if (resolvedRole == 'freelancer') {
        final email = _identifierController.text.trim().toLowerCase();
        final uid = FirebaseService.instance.currentUser?.uid;
        bool isDefaultAccount = email == 'siddhant@gmail.com';
        bool hasCompletedOnboarding = isDefaultAccount;
        if (!hasCompletedOnboarding && uid != null) {
          final profile = await FirebaseService.instance.getUserProfile(uid);
          hasCompletedOnboarding =
              profile?['profile']?['onboardingCompleted'] == true ||
              profile?['onboardingCompleted'] == true;
        }
        if (!mounted) return;
        if (hasCompletedOnboarding || isDefaultAccount) {
          Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/freelancer-onboarding');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Login failed. Please check your credentials.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Centered Branding & Welcome Header
                    _buildHeader(),

                    const SizedBox(height: 18),

                    // 2. Segmented Role Selector Pill
                    _buildRoleSegmentedControl(),

                    const SizedBox(height: 12),

                    // Quick Select Test Accounts
                    _buildTestAccountsSection(),

                    const SizedBox(height: 16),

                    // 3. Social Quick Logins
                    _buildSocialButtons(),

                    const SizedBox(height: 18),

                    // 4. Divider ("OR")
                    _buildDivider(),

                    const SizedBox(height: 18),

                    // 5. Form Inputs (Email/Username, Password)
                    _buildFormInputs(),

                    const SizedBox(height: 20),

                    // 6. Primary Action Button ("Continue ->")
                    _buildSubmitButton(),

                    const SizedBox(height: 18),

                    // 7. Legal and Sign Up Footer
                    _buildFooter(context),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Brand Identity & Headline
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          // Logo & App Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo_high.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'FreelanceHub',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(left: 2.5),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Log in to your account',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Connect, collaborate, and scale effortlessly',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Role Selector Pill (Client vs Freelancer)
  Widget _buildRoleSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          // Client Pill
          Expanded(
            child: _buildRolePill(
              role: LoginRole.client,
              label: 'Client',
              icon: LucideIcons.briefcase,
            ),
          ),
          // Freelancer Pill
          Expanded(
            child: _buildRolePill(
              role: LoginRole.freelancer,
              label: 'Freelancer',
              icon: LucideIcons.sparkles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePill({
    required LoginRole role,
    required String label,
    required IconData icon,
  }) {
    final bool isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color:
                  isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestAccountsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, size: 14, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'Select Verified Account:',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRole = LoginRole.client;
                      _identifierController.text = 'vedant@gmail.com';
                      _passwordController.text = 'password123';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _identifierController.text == 'vedant@gmail.com'
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _identifierController.text == 'vedant@gmail.com'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Vedant (Client)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _identifierController.text == 'vedant@gmail.com'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedRole = LoginRole.freelancer;
                      _identifierController.text = 'siddhant@gmail.com';
                      _passwordController.text = 'password123';
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: _identifierController.text == 'siddhant@gmail.com'
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _identifierController.text == 'siddhant@gmail.com'
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Siddhant (Freelancer)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _identifierController.text == 'siddhant@gmail.com'
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Social Login Buttons (Google & Apple)
  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Continue with Google
        _buildSocialButton(
          label: 'Continue with Google',
          leading: Image.asset(
            'assets/images/google_logo.png',
            width: 18,
            height: 18,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Continue with Google selected')),
            );
          },
        ),
        const SizedBox(height: 10),
        // Continue with Apple
        _buildSocialButton(
          label: 'Continue with Apple',
          leading: const Icon(
            LucideIcons.apple,
            size: 19,
            color: Colors.black,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Continue with Apple selected')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Divider ("OR")
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.border, thickness: 1),
        ),
      ],
    );
  }

  /// Form inputs (Email/Username, Password with forgot password link)
  Widget _buildFormInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email or username
        Text(
          'Email or username',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _identifierController,
          decoration: _inputDecoration(
            hintText: 'name@domain.com or @handle',
            prefixIcon: LucideIcons.mail,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email or username';
            }
            return null;
          },
        ),

        const SizedBox(height: 14),

        // Password row with Forgot password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Forgot Password flow')),
                );
              },
              child: Text(
                'Forgot password?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _inputDecoration(
            hintText: 'Enter your password',
            prefixIcon: LucideIcons.lock,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                size: 18,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: 18,
        color: AppColors.textSecondary,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  /// Primary Conversion CTA ("Continue ->")
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  /// Footer with terms note and sign up redirection
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: "By joining, you agree to FreelanceHub's\n",
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/signup');
              },
              child: Text(
                'Sign up',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
