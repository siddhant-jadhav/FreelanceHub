import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

/// Data model representing a Buyer Request / Opportunity
class BuyerRequest {
  final String id;
  final String clientName;
  final String clientCountry;
  final String? clientBadge;
  final double clientRating;
  final int clientOrdersCount;
  final String title;
  final String description;
  final List<String> skills;
  final String category;
  final double budget;
  final int deliveryDays;
  int offersSent;
  final int maxOffers;
  final String timeAgo;
  bool isSaved;
  bool hasSubmittedOffer;
  String? submittedPitch;
  double? submittedAmount;
  int? submittedDays;

  BuyerRequest({
    required this.id,
    required this.clientName,
    required this.clientCountry,
    this.clientBadge,
    required this.clientRating,
    required this.clientOrdersCount,
    required this.title,
    required this.description,
    required this.skills,
    required this.category,
    required this.budget,
    required this.deliveryDays,
    required this.offersSent,
    this.maxOffers = 10,
    required this.timeAgo,
    this.isSaved = false,
    this.hasSubmittedOffer = false,
    this.submittedPitch,
    this.submittedAmount,
    this.submittedDays,
  });
}

/// Buyer Requests & Opportunities Screen
/// Designed following FreelanceHub Design System (design.md) & Stitch Reference.
/// Color palette strictly adheres to AppColors (no harsh purples/neons).
/// All interactive features (filtering, search, saving, send proposal) are fully functional.
class BuyerRequestsScreen extends StatefulWidget {
  const BuyerRequestsScreen({super.key});

  @override
  State<BuyerRequestsScreen> createState() => _BuyerRequestsScreenState();
}

class _BuyerRequestsScreenState extends State<BuyerRequestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  int _dailyOffersRemaining = 10;
  final Set<String> _expandedDescriptions = <String>{};

  late List<BuyerRequest> _requests;

  @override
  void initState() {
    super.initState();
    _enforceFreelancerRole();
    _initializeRequests();
  }

  void _enforceFreelancerRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Clients cannot view buyer requests.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    });
  }

  void _initializeRequests() {
    _requests = [
      BuyerRequest(
        id: 'br_1',
        clientName: 'Sarah Jenkins',
        clientCountry: 'United States',
        clientRating: 5.0,
        clientOrdersCount: 14,
        title: 'Need complete Flutter mobile app UI design for FinTech wallet with 8 screens',
        description:
            'Looking for an expert designer to create modern, clean Figma/code mockups for our crypto wallet application. Experience with financial charts, payment flows, and responsive layouts required.',
        category: 'Mobile Design',
        skills: ['Figma', 'Flutter', 'FinTech Wallet', 'Mobile UI'],
        budget: 650.00,
        deliveryDays: 5,
        offersSent: 6,
        timeAgo: 'Posted 2 hours ago',
      ),
      BuyerRequest(
        id: 'br_2',
        clientName: 'Marcus Vance',
        clientCountry: 'United Kingdom',
        clientBadge: 'ENTERPRISE',
        clientRating: 4.9,
        clientOrdersCount: 31,
        title: 'Landing page redesign & Tailwind CSS conversion for SaaS startup',
        description:
            'Seeking a refined front-end specialist to revamp our current landing page into clean Tailwind and React components with smooth micro-interactions, responsive grid, and fast loading performance.',
        category: 'Web Dev',
        skills: ['Tailwind CSS', 'React', 'Landing Page', 'UI Redesign'],
        budget: 400.00,
        deliveryDays: 3,
        offersSent: 4,
        timeAgo: 'Posted 4 hours ago',
      ),
      BuyerRequest(
        id: 'br_3',
        clientName: 'Elena Rostova',
        clientCountry: 'Germany',
        clientBadge: 'E-COMMERCE BRAND',
        clientRating: 5.0,
        clientOrdersCount: 8,
        title: 'Shopify mobile UI enhancements & checkout optimization',
        description:
            'Need an experienced designer to restructure our mobile product pages and checkout flow to boost conversion rate. High fidelity Figma files and user journey wireframes ready for handover.',
        category: 'Mobile Design',
        skills: ['Shopify Plus', 'Mobile UI', 'Checkout Flow', 'E-Commerce'],
        budget: 850.00,
        deliveryDays: 7,
        offersSent: 9,
        timeAgo: 'Posted 5 hours ago',
      ),
      BuyerRequest(
        id: 'br_4',
        clientName: 'David Sterling',
        clientCountry: 'Canada',
        clientRating: 4.8,
        clientOrdersCount: 19,
        title: 'Complete Brand Identity & Design System for AI Automation Agency',
        description:
            'Looking for a creative branding specialist to build our complete visual identity including modern logo wordmark, curated color palette, typography guidelines, and social media presentation kit.',
        category: 'Branding',
        skills: ['Brand Identity', 'Logo Design', 'Design System', 'Typography'],
        budget: 550.00,
        deliveryDays: 6,
        offersSent: 3,
        timeAgo: 'Posted 6 hours ago',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final Set<String> categories = {'All'};
    for (final req in _requests) {
      categories.add(req.category);
    }
    categories.add('Saved');
    return categories.toList();
  }

  List<BuyerRequest> get _filteredRequests {
    final query = _searchController.text.trim().toLowerCase();
    return _requests.where((req) {
      // Category filter
      if (_selectedCategory == 'Saved' && !req.isSaved) {
        return false;
      } else if (_selectedCategory != 'All' && _selectedCategory != 'Saved') {
        if (req.category != _selectedCategory) return false;
      }

      // Search query filter
      if (query.isNotEmpty) {
        final titleMatch = req.title.toLowerCase().contains(query);
        final descMatch = req.description.toLowerCase().contains(query);
        final clientMatch = req.clientName.toLowerCase().contains(query);
        final skillMatch = req.skills.any((s) => s.toLowerCase().contains(query));
        if (!titleMatch && !descMatch && !clientMatch && !skillMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _toggleSaveRequest(BuyerRequest request) {
    setState(() {
      request.isSaved = !request.isSaved;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          request.isSaved
              ? 'Saved to your bookmarked opportunities!'
              : 'Removed from bookmarks.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  void _showSendOfferModal(BuyerRequest request) {
    if (_dailyOffersRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily offer limit reached. Resets in 12 hours.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final priceController =
        TextEditingController(text: request.budget.toStringAsFixed(0));
    final daysController =
        TextEditingController(text: request.deliveryDays.toString());
    final pitchController = TextEditingController();
    String selectedGig = 'Flutter Mobile App Development & UI';
    final List<String> availableGigs = [
      'Flutter Mobile App Development & UI',
      'Modern Figma UI/UX Design System',
      'Full-Stack Web & API Integration',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Title & Close
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.send,
                              size: 16,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Send Custom Offer',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Opportunity Context Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Client: ${request.clientName} • Budget: \$${request.budget.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Select Gig
                  Text(
                    'Select Matching Gig / Service',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedGig,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        items: availableGigs.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedGig = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Offer Price & Delivery Time Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offer Price (\$)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                prefixStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceSecondary,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery (Days)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: daysController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                suffixText: 'Days',
                                suffixStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceSecondary,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
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

                  const SizedBox(height: 14),

                  // Proposal Pitch Description
                  Text(
                    'Cover Letter / Proposal Pitch',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: pitchController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Explain why you are the best fit for this project, relevant portfolio links, and your timeline...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textDisabled,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      contentPadding: const EdgeInsets.all(12),
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

                  const SizedBox(height: 18),

                  // Submit Proposal Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (pitchController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please write a brief proposal cover letter.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        setState(() {
                          request.hasSubmittedOffer = true;
                          request.offersSent += 1;
                          request.submittedPitch = pitchController.text.trim();
                          request.submittedAmount =
                              double.tryParse(priceController.text) ?? request.budget;
                          request.submittedDays =
                              int.tryParse(daysController.text) ?? request.deliveryDays;
                          _dailyOffersRemaining -= 1;
                        });

                        _showOfferSuccessDialog(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: Text(
                        'Submit Proposal (Uses 1 Offer)',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOfferSuccessDialog(BuyerRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCheck,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Proposal Sent!',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your custom offer of \$${(request.submittedAmount ?? request.budget).toStringAsFixed(0)} was delivered to ${request.clientName}. You will be notified when they respond.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back to Requests',
                    style: GoogleFonts.inter(
                      fontSize: 14,
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
    final filtered = _filteredRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Live Opportunity Stream Header Banner
                    _buildStreamBanner(),

                    const SizedBox(height: 16),

                    // 2. Search & Filter Bar
                    _buildSearchField(),

                    const SizedBox(height: 14),

                    // 3. Category Filter Chips
                    _buildCategoryChips(),

                    const SizedBox(height: 16),

                    // 4. Request Count & Sorting Headline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filtered.length} Opportunities',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$_dailyOffersRemaining Offers Left Today',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 5. List of Buyer Request Cards
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(
                              LucideIcons.inbox,
                              size: 40,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No buyer requests found',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try selecting another category or clear your search query.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.map((req) => _buildRequestCard(req)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
          } else if (index != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  index == 2
                      ? 'Opening Orders...'
                      : index == 3
                          ? 'Opening Inbox...'
                          : 'Opening Earnings...',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
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
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard, size: 19),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.inbox, size: 19),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.clipboardList, size: 19),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messageSquare, size: 19),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.wallet, size: 19),
            label: 'Earnings',
          ),
        ],
      ),
    );
  }

  /// App Bar: Clean FreelanceHub top bar with back navigation and mode switch
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          LucideIcons.arrowLeft,
          size: 20,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Buyer Requests',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'LIVE',
              style: GoogleFonts.inter(
                fontSize: 9.5,
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
          tooltip: 'Dashboard',
          icon: const Icon(
            LucideIcons.layoutDashboard,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 1. Live Stream Banner
  Widget _buildStreamBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      'Live Opportunity Stream',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'High Match',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_requests.length} Active Buyer Requests',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Matched automatically to your core skills: Mobile UI, Flutter, React, Branding.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Search Field
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search requests by skill, title, or client...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textDisabled,
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 18,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  /// 3. Category Filter Chips
  Widget _buildCategoryChips() {
    final categories = _categories;

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          int count = 0;
          if (cat == 'All') {
            count = _requests.length;
          } else if (cat == 'Saved') {
            count = _requests.where((r) => r.isSaved).length;
          } else {
            count = _requests.where((r) => r.category == cat).length;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.textPrimary : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : AppColors.border,
                ),
              ),
              child: Text(
                '$cat ($count)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 4. Buyer Request Card
  Widget _buildRequestCard(BuyerRequest req) {
    final bool isExpanded = _expandedDescriptions.contains(req.id);
    final bool isNearLimit = req.offersSent >= 8;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Row
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  req.clientName[0],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            req.clientName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (req.clientBadge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              req.clientBadge!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 12, color: Color(0xFFFFB800)),
                        const SizedBox(width: 3),
                        Text(
                          '${req.clientRating.toStringAsFixed(1)} (${req.clientOrdersCount} orders)',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' • ${req.clientCountry}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Save / Bookmark Icon Button
              IconButton(
                icon: Icon(
                  req.isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                  size: 20,
                  color: req.isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
                tooltip: req.isSaved ? 'Bookmarked' : 'Save opportunity',
                onPressed: () => _toggleSaveRequest(req),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Request Title
          Text(
            req.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Request Description with Read More Toggle
          Text(
            req.description,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            maxLines: isExpanded ? 10 : 2,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDescriptions.remove(req.id);
                } else {
                  _expandedDescriptions.add(req.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                isExpanded ? 'Show less' : 'Read more',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),

          // Skill Tag Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: req.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // 3-Metric Block Row: BUDGET, DELIVERY, OFFERS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'BUDGET',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${req.budget.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                Column(
                  children: [
                    Text(
                      'DELIVERY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${req.deliveryDays} Days',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                Column(
                  children: [
                    Text(
                      'OFFERS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${req.offersSent}/${req.maxOffers} Sent',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isNearLimit ? AppColors.warning : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Bottom Action Row: Posted Time & Send Offer Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    req.timeAgo,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              req.hasSubmittedOffer
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.badgeCheck, size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Offer Sent (\$${(req.submittedAmount ?? req.budget).toStringAsFixed(0)})',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _showSendOfferModal(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(LucideIcons.send, size: 14),
                        label: Text(
                          'Send Offer',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
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
}
