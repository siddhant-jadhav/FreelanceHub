import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

/// Freelancer Onboarding - Step 2: Skills & Services
/// Follows FreelanceHub Design System & Stitch Reference strictly.
/// Starts with empty user inputs (no pre-filled design data).
/// No profile icon in the top right.
class FreelancerOnboardingStep2Screen extends StatefulWidget {
  const FreelancerOnboardingStep2Screen({super.key});

  @override
  State<FreelancerOnboardingStep2Screen> createState() =>
      _FreelancerOnboardingStep2ScreenState();
}

class _FreelancerOnboardingStep2ScreenState
    extends State<FreelancerOnboardingStep2Screen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // User input controllers - start completely empty
  final TextEditingController _skillSearchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final Set<String> _selectedSkills = <String>{};
  final Set<String> _selectedCategories = <String>{};

  String _selectedCurrency = 'USD (\$)';
  final List<String> _currencyOptions = [
    'USD (\$)',
    'EUR (€)',
    'GBP (£)',
    'INR (₹)',
  ];

  final List<String> _suggestedSkills = [
    'Java',
    'Node.js',
    'AI/ML',
    'Graphic Design',
    'Content Writing',
    'Video Editing',
    'Data Science',
    'Digital Marketing',
    'Flutter',
    'React',
    'Python',
    'UI/UX Design',
    'Figma',
    'TypeScript',
  ];

  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 'app_dev',
      'title': 'App Development',
      'icon': LucideIcons.smartphone,
    },
    {
      'id': 'ui_ux',
      'title': 'UI/UX Design',
      'icon': LucideIcons.penTool,
    },
    {
      'id': 'web_dev',
      'title': 'Web Development',
      'icon': LucideIcons.code,
    },
    {
      'id': 'graphic_design',
      'title': 'Graphic Design',
      'icon': LucideIcons.palette,
    },
    {
      'id': 'ai_data',
      'title': 'AI & Data',
      'icon': LucideIcons.sparkles,
    },
    {
      'id': 'video_animation',
      'title': 'Video & Animation',
      'icon': LucideIcons.video,
    },
    {
      'id': 'content_writing',
      'title': 'Content Writing',
      'icon': LucideIcons.fileText,
    },
    {
      'id': 'marketing',
      'title': 'Marketing',
      'icon': LucideIcons.trendingUp,
    },
  ];

  bool _isCompleting = false;

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
    _skillSearchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    final cleanSkill = skill.trim();
    if (cleanSkill.isEmpty) return;

    if (_selectedSkills.length >= 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 15 skills maximum.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedSkills.contains(cleanSkill)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$cleanSkill" is already added.'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    setState(() {
      _selectedSkills.add(cleanSkill);
      _skillSearchController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  void _handleCompleteProfile() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 core skill to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 1 service category.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isCompleting = true);

    try {
      final user = FirebaseService.instance.currentUser;
      if (user != null) {
        // 1. Update Cloud Firestore
        try {
          final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
          await FirebaseService.instance.userRepository.updateOnboardingProgress(
            user.uid,
            step: 2,
            completed: true,
          );
          await FirebaseService.instance.freelancerRepository.updateSkills(
            user.uid,
            _selectedSkills.toList(),
          );
          await FirebaseService.instance.freelancerRepository.updateRate(
            user.uid,
            price,
          );
        } catch (_) {}

        // 2. Mirror to Realtime Database
        try {
          await FirebaseService.instance.database
              .ref('users/${user.uid}/profile')
              .update({
            'skills': _selectedSkills.toList(),
            'categories': _selectedCategories.toList(),
            'startingPrice': _priceController.text.trim(),
            'currency': _selectedCurrency,
            'onboardingStep': 2,
            'onboardingCompleted': true,
          });
        } catch (_) {}
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      _showSuccessDialog();
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
        setState(() => _isCompleting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCheck,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Profile Completed!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your freelancer profile is now live. Clients can discover your skills and invite you to projects.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/freelancer-dashboard',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Go to Dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Tagline
                      _buildHeader(),

                      const SizedBox(height: 22),

                      // Section 1: Core Skills & Search
                      _buildCoreSkillsSection(),

                      const SizedBox(height: 24),

                      // Section 2: Service Categories Grid
                      _buildServiceCategoriesSection(),

                      const SizedBox(height: 24),

                      // Section 3: Starting Price (Optional)
                      _buildStartingPriceSection(),

                      const SizedBox(height: 18),

                      // Section 4: Micro-banner
                      _buildMicroBanner(),

                      const SizedBox(height: 24),

                      // Section 5: Bottom Action Buttons
                      _buildBottomActionButtons(context),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// App Bar: back arrow and title, NO profile icon in top right
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
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
        'Skills & Services',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Step 2 of 2 progress indicator (100% Completed)
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
                'STEP 2 OF 2',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '100% Completed',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Headline & Subheading
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What can you help clients with?',
          style: GoogleFonts.inter(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your skills and the services you want to offer.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Core Skills Section with search input, selected pills, and suggested chips
  Widget _buildCoreSkillsSection() {
    final remainingSuggestions = _suggestedSkills
        .where((s) => !_selectedSkills.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                text: 'Your Core Skills ',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${_selectedSkills.length} selected (max 15)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Search text field
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _skillSearchController,
            textInputAction: TextInputAction.done,
            onSubmitted: _addSkill,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search skills (e.g. Flutter, React, Figma)...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textDisabled,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                size: 18,
                color: AppColors.textSecondary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  LucideIcons.plusCircle,
                  size: 18,
                  color: AppColors.primary,
                ),
                tooltip: 'Add skill',
                onPressed: () => _addSkill(_skillSearchController.text),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Selected Skills Chips
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _selectedSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeSkill(skill),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 14),

        // Suggested for you
        Text(
          'SUGGESTED FOR YOU',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: remainingSuggestions.map((skill) {
            return GestureDetector(
              onTap: () => _addSkill(skill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.plus,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Service Categories 2-Column Grid
  Widget _buildServiceCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Service Categories ',
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
        const SizedBox(height: 2),
        Text(
          'Select at least 1 category',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _serviceCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, index) {
            final cat = _serviceCategories[index];
            final String id = cat['id'] as String;
            final String title = cat['title'] as String;
            final IconData icon = cat['icon'] as IconData;
            final bool isSelected = _selectedCategories.contains(id);

            return GestureDetector(
              onTap: () => _toggleCategory(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD6F5E3)
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 11,
                          color: Colors.white,
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

  /// Starting Price Card (Optional)
  Widget _buildStartingPriceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Starting Price (Optional)',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Set a baseline rate for simple projects. You can adjust this for any proposal or gig.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Currency dropdown container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    icon: const Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    items: _currencyOptions.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(
                          c,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCurrency = val);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Price input - starts completely empty
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '50.00',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDisabled,
                      ),
                      prefixText: '\$ ',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            '/ project or hr',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Informational micro-banner
  Widget _buildMicroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.shieldCheck,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Profiles with clear skills receive up to 3x more direct client inquiries within their first week.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action buttons: back & "Complete Profile"
  Widget _buildBottomActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Back button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),

            const SizedBox(width: 10),

            // Complete Profile button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCompleting ? null : _handleCompleteProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCompleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.rocket,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Complete Profile',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Center(
          child: Text(
            'You can update these details anytime from your Profile Settings.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
