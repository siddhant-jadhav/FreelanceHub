import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

/// Freelancer Onboarding - Step 1: Professional Profile
/// Designed strictly following FreelanceHub Design System & Stitch Reference.
/// Note: Instant Match Guarantee section removed as requested to free up space.
class FreelancerOnboardingScreen extends StatefulWidget {
  const FreelancerOnboardingScreen({super.key});

  @override
  State<FreelancerOnboardingScreen> createState() =>
      _FreelancerOnboardingScreenState();
}

class _FreelancerOnboardingScreenState
    extends State<FreelancerOnboardingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _customLangController = TextEditingController();

  String _selectedExperience = '';
  final Set<String> _selectedLanguages = <String>{};

  final List<Map<String, String>> _experienceLevels = [
    {
      'id': 'beginner',
      'title': 'Beginner',
      'subtitle': 'New to freelancing',
    },
    {
      'id': 'intermediate',
      'title': 'Intermediate',
      'subtitle': '1–3 yrs experience',
    },
    {
      'id': 'experienced',
      'title': 'Experienced',
      'subtitle': '3–5 yrs experience',
    },
    {
      'id': 'expert',
      'title': 'Expert',
      'subtitle': '5+ yrs, lead level',
    },
  ];

  final List<String> _availableLanguages = [
    'English (Fluent)',
    'Hindi (Native)',
    'Marathi',
    'Spanish',
    'French',
    'German',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enforceFreelancerRole();
  }

  void _enforceFreelancerRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Clients cannot view freelancer screens.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bioController.dispose();
    _customLangController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExperience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your experience level.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language you speak.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseService.instance.currentUser;
      if (user != null) {
        await FirebaseService.instance.database
            .ref('users/${user.uid}/profile')
            .update({
          'title': _titleController.text.trim(),
          'bio': _bioController.text.trim(),
          'experienceLevel': _selectedExperience,
          'languages': _selectedLanguages.toList(),
          'onboardingStep': 1,
        });
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Step 1 details saved successfully!'),
          backgroundColor: AppColors.primaryDark,
        ),
      );

      Navigator.of(context).pushNamed('/freelancer-onboarding-step2');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showAddLanguageDialog() {
    _customLangController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add a Language',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: _customLangController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Japanese, Arabic',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textDisabled,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newLang = _customLangController.text.trim();
              if (newLang.isNotEmpty) {
                setState(() {
                  if (!_availableLanguages.contains(newLang)) {
                    _availableLanguages.add(newLang);
                  }
                  _selectedLanguages.add(newLang);
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Step Progress Indicator
            _buildProgressBar(),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Unit ("Tell us about yourself")
                      _buildHeaderIntro(),

                      const SizedBox(height: 22),

                      // 1. Professional Title Field
                      _buildProfessionalTitleField(),

                      const SizedBox(height: 22),

                      // 2. Short Bio Field
                      _buildShortBioField(),

                      const SizedBox(height: 22),

                      // 3. Experience Level Selector
                      _buildExperienceLevelSection(),

                      const SizedBox(height: 22),

                      // 4. Languages You Speak
                      _buildLanguagesSection(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Bottom CTA Button (Saved automatically info + Continue)
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  /// Clean App Bar: leading back arrow, title, trailing user avatar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          LucideIcons.arrowLeft,
          size: 22,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Professional Profile',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Step 1 of 2 progress indicator (50% Completed)
  Widget _buildProgressBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP 1 OF 2',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '50% Completed',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Expanded(flex: 1, child: SizedBox()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header unit with icon badge, title & description
  Widget _buildHeaderIntro() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            LucideIcons.userCheck,
            size: 18,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about yourself',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Help clients understand who you are and what you do best.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Professional Title input field
  Widget _buildProfessionalTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: 'Professional Title ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Public header',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _titleController,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. Full-Stack Engineer & Designer',
            hintStyle: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppColors.textDisabled,
            ),
            prefixIcon: const Icon(
              LucideIcons.briefcase,
              size: 18,
              color: AppColors.textSecondary,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your professional title';
            }
            return null;
          },
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              LucideIcons.info,
              size: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Appears under your name in search results and client briefs.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Short Bio field with character counter
  Widget _buildShortBioField() {
    final int bioLength = _bioController.text.length;
    final bool isGoodLength = bioLength >= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: 'Short Bio ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$bioLength / 300',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.45,
          ),
          decoration: InputDecoration(
            hintText: 'Write a concise overview of your technical background...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textDisabled,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.all(14),
            filled: true,
            fillColor: AppColors.surfaceSecondary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a short bio';
            }
            if (value.trim().length < 20) {
              return 'Bio should be at least 20 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Keep it concise, friendly, and outcome-driven',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (isGoodLength)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.checkCircle,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Great length',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// Experience Level Selector (2x2 Grid)
  Widget _buildExperienceLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: 'Experience Level ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Select one',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.85,
          ),
          itemCount: _experienceLevels.length,
          itemBuilder: (context, index) {
            final item = _experienceLevels[index];
            final bool isSelected = _selectedExperience == item['id'];

            return GestureDetector(
              onTap: () {
                setState(() => _selectedExperience = item['id']!);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.white : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['title']!,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceContainer,
                          ),
                          child: isSelected
                              ? const Icon(
                                  LucideIcons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                    Text(
                      item['subtitle']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Languages You Speak section with selectable chips + Add Language
  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: 'Languages you speak ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Multiple choice',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._availableLanguages.map((lang) {
              final bool isSelected = _selectedLanguages.contains(lang);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedLanguages.remove(lang);
                    } else {
                      _selectedLanguages.add(lang);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          LucideIcons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            // Add Language Button Chip
            GestureDetector(
              onTap: _showAddLanguageDialog,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Add Language',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Bottom sticky action bar with Continue button and auto-save hint
  Widget _buildBottomActionBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
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
                          'Continue to Step 2',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
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
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.lock,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                'Information is automatically saved as you type',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
