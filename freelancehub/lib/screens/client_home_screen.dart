import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/project_model.dart';

/// Model representing a recommended freelancer for client home.
class FreelancerProfile {
  final String id;
  final String name;
  final String title;
  final String rating;
  final String reviews;
  final String hourlyRate;
  final String badgeText;
  final String bio;
  final List<String> skills;
  final String initials;
  final String portfolioLabel;
  final List<String> highlights;
  bool isSaved;

  FreelancerProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    required this.badgeText,
    required this.bio,
    required this.skills,
    required this.initials,
    this.portfolioLabel = 'Portfolio',
    required this.highlights,
    this.isSaved = false,
  });
}

/// Model representing saved talent in the horizontal carousel.
class SavedTalentItem {
  final String id;
  final String name;
  final String title;
  final String rate;
  final String rating;
  final String initials;
  bool isSaved;

  SavedTalentItem({
    required this.id,
    required this.name,
    required this.title,
    required this.rate,
    required this.rating,
    required this.initials,
    this.isSaved = true,
  });
}

/// Client Home & Explore Screen
/// Built according to FreelanceHub Design System (docs/design.md, .agents/rules/ui-design.md)
/// Matches Stitch Screen `01 — Client Home & Explore` with brand-consistent colors & Lucide icons.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Banner visibility
  bool _showAmbientNotice = true;
  bool _showActionNeededBanner = true;

  // Category filter state
  int _selectedCategoryIndex = 0;
  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'All',
      'icon': LucideIcons.layers,
    },
    {
      'label': 'App Development',
      'icon': LucideIcons.smartphone,
    },
    {
      'label': 'UI/UX Design',
      'icon': LucideIcons.palette,
    },
    {
      'label': 'Web Development',
      'icon': LucideIcons.code,
    },
    {
      'label': 'AI & Data',
      'icon': LucideIcons.cpu,
    },
    {
      'label': 'Video & Motion',
      'icon': LucideIcons.video,
    },
    {
      'label': 'Content Writing',
      'icon': LucideIcons.fileText,
    },
  ];

  // Recommended Freelancers
  late List<FreelancerProfile> _freelancers;

  // Saved talent list
  late List<SavedTalentItem> _savedTalent;

  // Search filter
  String _searchQuery = '';
  ProjectModel? _realActiveProject;
  StreamSubscription<List<ProjectModel>>? _projectsSub;

  @override
  void initState() {
    super.initState();
    _enforceClientRole();
    _initData();
    _loadRealData();
  }

  void _initData() {
    if (FirebaseConfig.instance.isInitialized) {
      _freelancers = [];
      _savedTalent = [];
      return;
    }
    _freelancers = [
      FreelancerProfile(
        id: 'f-1',
        name: 'Sarah Jenkins',
        title: 'Staff Product & UI/UX Designer',
        rating: '4.9',
        reviews: '128',
        hourlyRate: '\$45/hr',
        badgeText: 'TOP RATED',
        bio:
            'Specializing in high-converting iOS and Android apps, design systems, and rapid interactive prototypes. 8+ years collaborating with tech founders.',
        skills: ['Figma', 'Mobile Design', 'Prototyping', 'Fintech'],
        initials: 'SJ',
        portfolioLabel: 'Portfolio',
        highlights: [
          'Fintech Neobank UI (12 screens)',
          'Crypto Wallet Design System',
          'SaaS Analytics Web Dashboard',
        ],
        isSaved: false,
      ),
      FreelancerProfile(
        id: 'f-2',
        name: 'David Chen',
        title: 'Senior Flutter & Backend Architect',
        rating: '5.0',
        reviews: '84',
        hourlyRate: '\$65/hr',
        badgeText: '100% SUCCESS',
        bio:
            'Cross-platform Flutter specialist building production-grade apps with high-frequency APIs, offline-first sync, and clean architecture.',
        skills: ['Flutter', 'Dart', 'Firebase', 'REST API'],
        initials: 'DC',
        portfolioLabel: 'Code Samples',
        highlights: [
          'High-throughput Trading App Engine',
          'Offline-first Logistics Mobile Client',
          'Realtime Chat & Audio Streaming App',
        ],
        isSaved: false,
      ),
    ];

    _savedTalent = [
      SavedTalentItem(
        id: 's-1',
        name: 'Priya Sharma',
        title: 'Motion & 3D Artist',
        rate: '\$50/hr',
        rating: '4.95',
        initials: 'PS',
        isSaved: true,
      ),
      SavedTalentItem(
        id: 's-2',
        name: 'Lucas Dubois',
        title: 'Next.js & Supabase',
        rate: '\$70/hr',
        rating: '5.0',
        initials: 'LD',
        isSaved: true,
      ),
      SavedTalentItem(
        id: 's-3',
        name: 'Elena Rostova',
        title: 'LLM Prompt Engineer',
        rate: '\$90/hr',
        rating: '4.9',
        initials: 'ER',
        isSaved: true,
      ),
    ];
  }

  void _loadRealData() async {
    try {
      if (!FirebaseConfig.instance.isInitialized) return;
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid != null) {
        _projectsSub = FirebaseService.instance.projectRepository
            .streamProjectsForClient(uid)
            .listen((projects) {
          if (!mounted) return;
          setState(() {
            try {
              _realActiveProject = projects.firstWhere(
                (p) => p.status == 'in_progress',
                orElse: () => projects.first,
              );
            } catch (_) {
              _realActiveProject = null;
            }
          });
        });
      }

      final remoteFreelancers = await FirebaseService.instance.freelancerRepository.getTopRatedFreelancers(limit: 10);
      if (mounted) {
        setState(() {
          _freelancers = remoteFreelancers.map((rf) {
            final nameParts = rf.name.trim().split(' ');
            final initials = nameParts.length > 1
                ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                : (rf.name.isNotEmpty ? rf.name[0].toUpperCase() : 'FL');
            return FreelancerProfile(
              id: rf.id,
              name: rf.name,
              title: rf.title.isNotEmpty ? rf.title : 'Senior Flutter Developer',
              rating: rf.rating.toStringAsFixed(1),
              reviews: rf.reviewsCount.toString(),
              hourlyRate: '\$${rf.hourlyRate.toStringAsFixed(0)}/hr',
              badgeText: rf.isTopRated ? 'TOP RATED' : 'VETTED PRO',
              bio: rf.bio.isNotEmpty ? rf.bio : 'Expert specialist ready to assist with your requirements.',
              skills: rf.skills.isNotEmpty ? rf.skills : ['Flutter', 'Mobile'],
              initials: initials,
              highlights: rf.services.isNotEmpty ? rf.services : ['High Quality Delivery', 'Clean Code'],
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Real data loading notice: $e');
    }
  }

  /// Ensure only Client accounts can view this screen
  void _enforceClientRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'freelancer') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Access restricted: Freelancers cannot view client screens.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/freelancer-onboarding');
      }
    });
  }

  @override
  void dispose() {
    _projectsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    await FirebaseService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  List<FreelancerProfile> get _filteredFreelancers {
    final query = _searchQuery.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex]['label'] as String;

    return _freelancers.where((f) {
      final matchesQuery = query.isEmpty ||
          f.name.toLowerCase().contains(query) ||
          f.title.toLowerCase().contains(query) ||
          f.skills.any((s) => s.toLowerCase().contains(query)) ||
          f.bio.toLowerCase().contains(query);

      final matchesCategory = selectedCategory == 'All' ||
          (selectedCategory == 'App Development' &&
              (f.skills.contains('Flutter') || f.skills.contains('Mobile Design'))) ||
          (selectedCategory == 'UI/UX Design' &&
              (f.skills.contains('Figma') || f.title.contains('Designer'))) ||
          (selectedCategory == 'Web Development' &&
              (f.skills.contains('REST API') || f.skills.contains('Firebase'))) ||
          (selectedCategory == 'AI & Data');

      return matchesQuery && matchesCategory;
    }).toList();
  }

  // --- Modals & User Actions ---

  /// Opens the Post a Task modal bottom sheet
  void _showPostTaskModal({String? initialTitle, String? initialScope, String? initialBudget}) {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final scopeCtrl = TextEditingController(text: initialScope ?? '');
    final budgetCtrl = TextEditingController(text: initialBudget ?? '500');
    String selectedCat = 'Mobile Apps';
    String timeline = '14 days';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.circlePlus,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Post a Project Task',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.of(context).pushNamed(
                                  '/post-task',
                                  arguments: {
                                    'title': titleCtrl.text,
                                    'description': scopeCtrl.text,
                                    'budget': double.tryParse(budgetCtrl.text) ?? 500.0,
                                    'category': selectedCat,
                                  },
                                );
                              },
                              icon: const Icon(LucideIcons.arrowUpRight, size: 14, color: AppColors.primary),
                              label: Text(
                                'Full Form',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Get proposals from vetted freelancers within minutes.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Project Title',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Flutter Mobile App MVP for Fintech Flow',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      items: const [
                        DropdownMenuItem(value: 'Mobile Apps', child: Text('Mobile Apps (Flutter & iOS)')),
                        DropdownMenuItem(value: 'UI/UX Design', child: Text('UI/UX Design & Figma Kits')),
                        DropdownMenuItem(value: 'Web Dev', child: Text('Web Development (Full Stack)')),
                        DropdownMenuItem(value: 'AI & Data', child: Text('AI Integration & LLM APIs')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedCat = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Scope & Deliverables',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: scopeCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Detail requirements, required milestones, tech stack, and acceptance criteria...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budget (USD)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: budgetCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  prefixStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                  filled: true,
                                  fillColor: AppColors.surfaceSecondary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Target Timeline',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: timeline,
                                items: const [
                                  DropdownMenuItem(value: '7 days', child: Text('7 days')),
                                  DropdownMenuItem(value: '14 days', child: Text('14 days')),
                                  DropdownMenuItem(value: '30 days', child: Text('30 days')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => timeline = val);
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surfaceSecondary,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a project title.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }

                          final scope = scopeCtrl.text.trim();
                          final budget = double.tryParse(budgetCtrl.text.trim()) ?? 500.0;
                          final days = timeline == '7 days' ? 7 : (timeline == '30 days' ? 30 : 14);
                          final deadline = DateTime.now().add(Duration(days: days));

                          Navigator.pop(ctx);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          String? createdTaskId;
                          try {
                            if (FirebaseConfig.instance.isInitialized) {
                              createdTaskId = await FirebaseService.instance.clientService.postTask(
                                title: title,
                                description: scope.isNotEmpty ? scope : 'Looking for an expert to deliver $title.',
                                category: selectedCat,
                                budget: budget,
                                deadline: deadline,
                              );
                            }
                          } catch (e) {
                            debugPrint('postTask error: $e');
                          }

                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Task "$title" published to Live Buyer Requests!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'View Proposals',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    '/task-details',
                                    arguments: createdTaskId,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                        label: Text(
                          'Post Task to Opportunities',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Opens the AI Brief Writer modal bottom sheet
  void _showAiBriefWriterModal() {
    final promptCtrl = TextEditingController(
      text: 'Fintech crypto wallet mobile app with biometric auth and live price feeds',
    );
    bool isGenerating = false;
    Map<String, dynamic>? generatedBrief;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.sparkles,
                                  size: 18,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'AI Project Brief Assistant',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      'Turn a 1-sentence idea into a structured scope, milestones, and estimate.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Describe your project idea',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: promptCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildQuickPromptChip(
                          'SaaS Dashboard',
                          promptCtrl,
                          setSheetState,
                        ),
                        _buildQuickPromptChip(
                          'E-Commerce Mobile App',
                          promptCtrl,
                          setSheetState,
                        ),
                        _buildQuickPromptChip(
                          'Figma UI Design System',
                          promptCtrl,
                          setSheetState,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: isGenerating
                            ? null
                            : () async {
                                setSheetState(() => isGenerating = true);
                                await Future.delayed(const Duration(milliseconds: 600));
                                setSheetState(() {
                                  isGenerating = false;
                                  generatedBrief = {
                                    'title': 'High-Conversion Fintech & Web3 Mobile Client',
                                    'scope':
                                        'End-to-end Flutter client featuring secure biometric enclave, Web3 wallet connect, interactive price charts, and push notifications.',
                                    'budget': '1200',
                                    'tech': 'Flutter • Dart • Supabase • WebSockets',
                                  };
                                });
                              },
                        icon: isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
                        label: Text(
                          isGenerating ? 'Generating Structured Scope...' : 'Generate Brief with AI',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (generatedBrief != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AI GENERATED BRIEF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Est: \$${generatedBrief!['budget']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              generatedBrief!['title'],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              generatedBrief!['scope'],
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Suggested Tech: ${generatedBrief!['tech']}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.of(context).pushNamed(
                              '/post-task',
                              arguments: {
                                'title': generatedBrief!['title'],
                                'description': generatedBrief!['scope'],
                                'budget': double.tryParse(generatedBrief!['budget'] ?? '500') ?? 500.0,
                              },
                            );
                          },
                          icon: const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primaryDark),
                          label: Text(
                            'Use this in Post a Task',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickPromptChip(
    String label,
    TextEditingController controller,
    StateSetter setSheetState,
  ) {
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          controller.text = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Opens Project Delivery Workspace Modal for Order #FH-9921
  void _showWorkspaceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ORDER #FH-9921 • FIXED PRICE',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mobile App MVP (Fintech Flow)',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            'AR',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Rivera',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Senior Flutter Developer • Milestone 4 in delivery',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '\$1,800',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Milestone Progress (3 of 4 Completed • 75%)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildMilestoneCheckRow(
                '1. UX Architecture & Wireframes',
                'Approved & Paid (\$450)',
                isDone: true,
              ),
              _buildMilestoneCheckRow(
                '2. Core Flutter UI Kit & Dark Mode',
                'Approved & Paid (\$550)',
                isDone: true,
              ),
              _buildMilestoneCheckRow(
                '3. Secure Biometrics & REST API',
                'Approved & Paid (\$400)',
                isDone: true,
              ),
              _buildMilestoneCheckRow(
                '4. Production Release & QA Testing',
                'Due Tomorrow, 6:00 PM (\$400 in Escrow)',
                isDone: false,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed(
                      '/task-details',
                      arguments: _realActiveProject?.taskId,
                    );
                  },
                  icon: const Icon(LucideIcons.listFilter, size: 16, color: AppColors.textPrimary),
                  label: Text(
                    'View Task & Candidate Proposals',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Direct chat opened with Alex Rivera.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.messageSquare, size: 16, color: AppColors.textPrimary),
                      label: Text(
                        'Message Alex',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(
                          '/project-workspace',
                          arguments: _realActiveProject,
                        );
                      },
                      icon: const Icon(LucideIcons.briefcase, size: 16, color: Colors.white),
                      label: Text(
                        'Open Workspace',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestoneCheckRow(String title, String subtitle, {required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? LucideIcons.badgeCheck : LucideIcons.clock,
            size: 16,
            color: isDone ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDone ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens Hire / Send Proposal bottom sheet for a freelancer
  void _showHireFreelancerModal(FreelancerProfile freelancer) {
    final noteCtrl = TextEditingController(
      text: 'Hi ${freelancer.name.split(' ').first}, I came across your profile and would love to discuss a project with you.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          freelancer.initials,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hire ${freelancer.name}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${freelancer.title} • ${freelancer.hourlyRate}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Proposal Invitation Message',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Escrow Protected: Funds are released only after you approve milestones.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final note = noteCtrl.text.trim();
                    try {
                      if (FirebaseConfig.instance.isInitialized) {
                        final currentUid = FirebaseService.instance.currentUser?.uid;
                        final currentName = FirebaseService.instance.currentUser?.displayName ?? 'Client';
                        if (currentUid != null) {
                          final convId = await FirebaseService.instance.messageRepository.getOrCreateConversation(
                            currentUserId: currentUid,
                            currentUserName: currentName,
                            recipientUserId: freelancer.id,
                            recipientUserName: freelancer.name,
                          );
                          await FirebaseService.instance.messageRepository.sendMessage(
                            MessageModel(
                              id: '',
                              conversationId: convId,
                              senderId: currentUid,
                              receiverId: freelancer.id,
                              message: note,
                              createdAt: DateTime.now(),
                            ),
                          );
                          await FirebaseService.instance.notificationService.notifyNewMessage(
                            recipientUserId: freelancer.id,
                            senderName: currentName,
                            messageSnippet: note,
                            conversationId: convId,
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('hire invitation notice: $e');
                    }

                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Invitation sent to ${freelancer.name}! They will reply shortly.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.send, size: 16, color: Colors.white),
                  label: Text(
                    'Send Project Invitation',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens Portfolio / Code Samples preview modal
  void _showPortfolioModal(FreelancerProfile freelancer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${freelancer.name} — ${freelancer.portfolioLabel}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...freelancer.highlights.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          LucideIcons.folderGit2,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(LucideIcons.externalLink, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showHireFreelancerModal(freelancer);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hire ${freelancer.name}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens Review Submission Modal for Marcus Vance (Milestone 2)
  void _showReviewSubmissionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SUBMISSION REVIEW • MILESTONE 2',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'E-Commerce Redesign (Checkout Flow)',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            'MV',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Marcus Vance',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Milestone: \$350.00',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"Hi! I finished the responsive shopping bag and payment checkout components in Figma, with full auto-layout and interactive prototype tokens. Please review!"',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(LucideIcons.fileArchive, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Checkout_Flow_v2.fig (18.4 MB)',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          if (FirebaseConfig.instance.isInitialized) {
                            await FirebaseService.instance.clientService.reviewMilestoneDeliverable(
                              projectId: 'project_ecommerce_9921',
                              milestoneId: 'milestone_2',
                              freelancerId: 'freelancer_marcus_vance',
                              milestoneTitle: 'Milestone 2',
                              amount: 350.0,
                              approved: false,
                              feedback: 'Revision requested by client.',
                            );
                          }
                        } catch (e) {
                          debugPrint('milestone revision error: $e');
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Revision request sent to Marcus Vance.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Request Changes',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() {
                          _showActionNeededBanner = false;
                        });
                        try {
                          if (FirebaseConfig.instance.isInitialized) {
                            await FirebaseService.instance.clientService.reviewMilestoneDeliverable(
                              projectId: 'project_ecommerce_9921',
                              milestoneId: 'milestone_2',
                              freelancerId: 'freelancer_marcus_vance',
                              milestoneTitle: 'Milestone 2',
                              amount: 350.0,
                              approved: true,
                            );
                          }
                        } catch (e) {
                          debugPrint('milestone approval error: $e');
                        }

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Milestone 2 approved! \$350 released from escrow.'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Approve & Release',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Opens Instant Filter Sheet
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Talent Filters',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategoryIndex = 0;
                        _searchController.clear();
                        _searchQuery = '';
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Experience Level',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChoiceChip('All Levels', isSelected: true),
                  _buildFilterChoiceChip('Top Rated Pro', isSelected: false),
                  _buildFilterChoiceChip('Senior Architect', isSelected: false),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Rate Range',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChoiceChip('Any Rate', isSelected: false),
                  _buildFilterChoiceChip('\$30 - \$60 /hr', isSelected: true),
                  _buildFilterChoiceChip('\$60+ /hr', isSelected: false),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChoiceChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.textPrimary : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// Opens Notifications Bottom Sheet
  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final uid = FirebaseService.instance.currentUser?.uid;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client Notifications',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (FirebaseConfig.instance.isInitialized && uid != null)
                StreamBuilder<List<NotificationModel>>(
                  stream: FirebaseService.instance.notificationRepository.streamUserNotifications(uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final notifications = snapshot.data ?? [];
                    if (notifications.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.bellOff, size: 36, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No notifications yet',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: notifications.map((notif) {
                        IconData icon;
                        switch (notif.type) {
                          case 'new_proposal':
                          case 'proposal_accepted':
                            icon = LucideIcons.badgeCheck;
                            break;
                          case 'new_message':
                            icon = LucideIcons.messageSquare;
                            break;
                          case 'escrow_funded':
                          case 'payment_released':
                            icon = LucideIcons.shieldCheck;
                            break;
                          default:
                            icon = LucideIcons.bell;
                        }
                        final diff = DateTime.now().difference(notif.createdAt);
                        String timeStr = diff.inMinutes < 60
                            ? '${diff.inMinutes}m ago'
                            : (diff.inHours < 24 ? '${diff.inHours}h ago' : '${diff.inDays}d ago');
                        return _buildNotificationItem(
                          icon: icon,
                          title: notif.title,
                          subtitle: notif.message,
                          time: timeStr,
                        );
                      }).toList(),
                    );
                  },
                )
              else ...[
                _buildNotificationItem(
                  icon: LucideIcons.badgeCheck,
                  title: 'Milestone Submitted for Review',
                  subtitle: 'Deliverable submitted on your active project.',
                  time: '2h ago',
                ),
                _buildNotificationItem(
                  icon: LucideIcons.shieldCheck,
                  title: 'Escrow Deposit Confirmed',
                  subtitle: 'Funds are securely locked in FreelanceHub escrow.',
                  time: '1d ago',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textDark,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Build ---

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
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(
                  LucideIcons.bell,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: _showNotificationsModal,
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          Tooltip(
            message: '$userName (Client)',
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logged in as $userName (Client Workspace)'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sign Out ($userName)',
            icon: const Icon(
              LucideIcons.logOut,
              size: 20,
              color: AppColors.textSecondary,
            ),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Subtle Ambient Notice Pill (Delight Micro-interaction)
              if (_showAmbientNotice) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Client Workspace • 1,420 vetted pros online today',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAmbientNotice = false;
                          });
                        },
                        child: const Icon(
                          LucideIcons.x,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Hero Callout Card (Find vetted experts or kickstart a project)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.zap,
                                size: 12,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Instant Matching',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avg. response 6 mins',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find vetted experts or kickstart a project',
                      style: GoogleFonts.inter(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scale your product with on-demand engineers, designers, and AI specialists.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showPostTaskModal(),
                          icon: const Icon(LucideIcons.circlePlus, size: 16, color: Colors.white),
                          label: Text(
                            '+ Post a Task',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: _showAiBriefWriterModal,
                          icon: const Icon(
                            LucideIcons.sparkles,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          label: Text(
                            'AI Brief Writer',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surfaceSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Search & Instant Filter Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search freelancers, skills (e.g. Flutter, UI)...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDisabled,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filter options',
                      icon: const Icon(
                        LucideIcons.slidersHorizontal,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _showFilterModal,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 4. Active Deliveries Quick Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Deliveries',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _realActiveProject != null ? '1' : (FirebaseConfig.instance.isInitialized ? '0' : '1'),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showWorkspaceModal,
                    child: Row(
                      children: [
                        Text(
                          'All Projects',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 15,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Active Project Card (Order #FH-9921)
              if (_realActiveProject == null && FirebaseConfig.instance.isInitialized)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(LucideIcons.folderOpen, size: 32, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'No Active Projects Yet',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Post a task to receive proposals and kick off work.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/post-task'),
                          icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                          label: Text(
                            'Post a Task',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _realActiveProject != null
                                ? 'FIXED PRICE • ORDER #${_realActiveProject!.id.length > 7 ? _realActiveProject!.id.substring(0, 7).toUpperCase() : _realActiveProject!.id}'
                                : 'FIXED PRICE • ORDER #FH-9921',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _realActiveProject != null
                                  ? (_realActiveProject!.status == 'in_progress' ? 'In Progress' : _realActiveProject!.status.replaceAll('_', ' ').toUpperCase())
                                  : 'In Progress',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _realActiveProject?.title ?? 'Mobile App MVP (Fintech Flow)',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _realActiveProject != null
                              ? 'Milestones: ${_realActiveProject!.completedMilestones} of ${_realActiveProject!.totalMilestones} completed'
                              : 'Milestones: 3 of 4 completed',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _realActiveProject != null
                              ? '${(_realActiveProject!.progress * 100).toInt()}%'
                              : '75%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _realActiveProject?.progress ?? 0.75,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(
                                  _realActiveProject != null && _realActiveProject!.freelancerName.isNotEmpty
                                      ? (_realActiveProject!.freelancerName.trim().split(' ').length > 1
                                          ? '${_realActiveProject!.freelancerName.trim().split(' ')[0][0]}${_realActiveProject!.freelancerName.trim().split(' ')[1][0]}'.toUpperCase()
                                          : _realActiveProject!.freelancerName.trim()[0].toUpperCase())
                                      : 'AR',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _realActiveProject?.freelancerName ?? 'Alex Rivera',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _realActiveProject != null
                                      ? 'Due: ${_realActiveProject!.dueDate.month}/${_realActiveProject!.dueDate.day}'
                                      : 'Due: Tomorrow, 6:00 PM',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showWorkspaceModal,
                            icon: const Icon(LucideIcons.arrowRight, size: 14, color: Colors.white),
                            label: Text(
                              'Workspace',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 5. Explore Categories Carousel (Explore Talent & Categories)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Explore Talent',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• Categories',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Browse all 40+',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.textPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : AppColors.border,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 15,
                              color: isSelected ? AppColors.primary : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 6. Top Recommended For You Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Top Recommended For You',
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Top Rated Freelancers',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Top Rated Freelancers matched to your fintech requirements',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Sort options',
                    icon: const Icon(
                      LucideIcons.arrowUpDown,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: _showFilterModal,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Freelancer Cards
              if (_filteredFreelancers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(LucideIcons.searchX, size: 28, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'No freelancers match your search filter.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategoryIndex = 0;
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: Text(
                            'Clear Filters',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredFreelancers.map((f) => _buildFreelancerCard(f)),

              const SizedBox(height: 24),

              // 7. Recently Saved Talent Mini-Deck
              if (_savedTalent.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.bookmarkCheck,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Recently Saved Talent',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_savedTalent.length} profiles',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 136,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedTalent.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _savedTalent[index];
                    return _buildSavedTalentCard(item);
                  },
                ),
              ),

              const SizedBox(height: 24),
              ],

              // 8. Recent Activity Feed Banner (Action Needed)
              if (_showActionNeededBanner) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.clipboardCheck,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ACTION NEEDED',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '2h ago',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Marcus Vance ',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const TextSpan(
                                    text: 'submitted Milestone 2 for review on ',
                                  ),
                                  TextSpan(
                                    text: '“E-Commerce Redesign”',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _showReviewSubmissionModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    'Review Submission',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showActionNeededBanner = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    'Later',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 2) {
            Navigator.of(context).pushNamed(
              '/project-workspace',
              arguments: _realActiveProject,
            );
          } else if (index == 3) {
            Navigator.of(context).pushNamed('/messages');
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.house, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.compass, size: 24),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.briefcase, size: 24),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageSquare, size: 24),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user, size: 24),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Builds a recommended Freelancer Card (e.g. Sarah Jenkins, David Chen)
  Widget _buildFreelancerCard(FreelancerProfile freelancer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            freelancer.initials,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                freelancer.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.badgeCheck,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            freelancer.title,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 13,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                freelancer.rating,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '(${freelancer.reviews} reviews)',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSecondary,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  freelancer.badgeText,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: freelancer.isSaved ? 'Remove bookmark' : 'Save freelancer',
                      icon: Icon(
                        freelancer.isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                        size: 20,
                        color: freelancer.isSaved ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          freelancer.isSaved = !freelancer.isSaved;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              freelancer.isSaved
                                  ? '${freelancer.name} saved to talent bookmarks.'
                                  : '${freelancer.name} removed from bookmarks.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  freelancer.bio,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: freelancer.skills
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
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
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STARTING AT',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          freelancer.hourlyRate.replaceAll('/hr', ''),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '/hr',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => _showPortfolioModal(freelancer),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        freelancer.portfolioLabel,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showHireFreelancerModal(freelancer),
                      icon: const Icon(LucideIcons.arrowUpRight, size: 14, color: Colors.white),
                      label: Text(
                        'Hire ${freelancer.name.split(' ').first}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a Mini Card in the Saved Talent Horizontal Carousel
  Widget _buildSavedTalentCard(SavedTalentItem item) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      item.initials,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    item.isSaved = !item.isSaved;
                  });
                },
                child: Icon(
                  item.isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                  size: 17,
                  color: item.isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.rate,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 11,
                    color: Color(0xFFFFB800),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item.rating,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
