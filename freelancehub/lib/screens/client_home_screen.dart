import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

/// Client Home & Marketplace Screen
/// Dedicated workspace for Client accounts (buyers).
/// Enforces role protection: Freelancers cannot access this screen.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Mobile Apps',
    'Web Dev',
    'UI/UX Design',
    'AI Services',
    'Copywriting',
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _enforceClientRole();
  }

  /// Ensure only Client accounts can view this screen
  void _enforceClientRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'freelancer') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Freelancers cannot view client screens.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/freelancer-onboarding');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    await FirebaseService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.instance.currentUser;
    final userName = user?.displayName ?? 'Client';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo_high.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.briefcase,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FreelanceHub',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'CLIENT',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              LucideIcons.logOut,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Client Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF003822),
                      Color(0xFF005230),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003822).withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CLIENT PORTAL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, $userName',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hire vetted professionals, manage contracts, and scale your business effortlessly.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search services, skills, or freelancers...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textDisabled,
                    ),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Category Filter Pills
              Text(
                'Explore Talent',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategoryIndex = index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Featured Freelancers List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Rated Freelancers',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildFreelancerCard(
                name: 'Alex Rivera',
                title: 'Senior Flutter & Full-Stack Developer',
                rating: '4.9',
                reviews: '124',
                hourlyRate: '\$45/hr',
                skills: ['Flutter', 'Firebase', 'Dart', 'Node.js'],
              ),

              const SizedBox(height: 12),

              _buildFreelancerCard(
                name: 'Elena Rostova',
                title: 'Product Designer & UI/UX Specialist',
                rating: '5.0',
                reviews: '89',
                hourlyRate: '\$50/hr',
                skills: ['Figma', 'Design Systems', 'UX Research'],
              ),

              const SizedBox(height: 12),

              _buildFreelancerCard(
                name: 'Marcus Chen',
                title: 'AI Integration & Backend Engineer',
                rating: '4.9',
                reviews: '56',
                hourlyRate: '\$65/hr',
                skills: ['Python', 'OpenAI', 'FastAPI', 'AWS'],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home, size: 20),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.compass, size: 20),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.shoppingBag, size: 20),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user, size: 20),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFreelancerCard({
    required String name,
    required String title,
    required String rating,
    required String reviews,
    required String hourlyRate,
    required List<String> skills,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  name[0],
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                hourlyRate,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 14,
                    color: Color(0xFFFFB800),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '($reviews reviews)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Contact',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
