import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/proposal_model.dart';
import '../services/notification_service.dart';
import 'buyer_requests_screen.dart';

/// Send Custom Offer & Proposal Screen for Freelancers.
/// Strictly implements FreelanceHub Design System (docs/design.md and .agents/rules/ui-design.md).
/// Features:
/// - Clean minimalist header with back navigation and help guide.
/// - Buyer Request context card with Verified Client badge.
/// - Associated Gig switcher with bottom sheet selection.
/// - Single Payment vs. Milestones payment switcher with interactive milestone manager.
/// - Rich Proposal Pitch & Scope editor with live character counter, AI refinement, and sample attachments.
/// - Offer Pricing & Timeline controls (custom price, stepper delivery days, revision pill selector).
/// - Deliverables inclusion toggles (Source Files, Commercial Use, High Res, Prototype).
/// - Offer Expiration picker (1, 3, 7, 14 days).
/// - Sticky Bottom Floating Action Bar with real-time 20% fee breakdown and net earnings calculation.
class SendOfferScreen extends StatefulWidget {
  final BuyerRequest? initialRequest;

  const SendOfferScreen({super.key, this.initialRequest});

  @override
  State<SendOfferScreen> createState() => _SendOfferScreenState();
}

class _SendOfferScreenState extends State<SendOfferScreen> {
  late BuyerRequest _request;
  bool _initialized = false;

  // Selected Gig
  late Map<String, dynamic> _selectedGig;
  final List<Map<String, dynamic>> _availableGigs = [
    {
      'title': 'I will design modern mobile app UI/UX for iOS & Android',
      'category': 'Mobile Design',
      'rating': 5.0,
      'reviews': 148,
      'level': 'Level 2 Seller',
      'icon': LucideIcons.smartphone,
    },
    {
      'title': 'I will develop responsive Flutter & Dart mobile applications',
      'category': 'Mobile Dev',
      'rating': 4.9,
      'reviews': 92,
      'level': 'Top Rated',
      'icon': LucideIcons.code,
    },
    {
      'title': 'I will build high-converting SaaS landing pages in React',
      'category': 'Web Dev',
      'rating': 5.0,
      'reviews': 64,
      'level': 'Level 2 Seller',
      'icon': LucideIcons.layoutGrid,
    },
    {
      'title': 'I will create complete brand identity and design systems',
      'category': 'Branding',
      'rating': 4.8,
      'reviews': 38,
      'level': 'Level 1 Seller',
      'icon': LucideIcons.palette,
    },
  ];

  // Offer Details
  String _paymentType = 'single'; // 'single' or 'milestone'
  late TextEditingController _pitchController;
  late TextEditingController _priceController;
  int _deliveryDays = 4;
  String _selectedRevision = 'Unlimited';
  final List<String> _revisionOptions = ['1 Rev', '3 Revs', '5 Revs', 'Unlimited'];

  // Deliverables
  bool _includeSourceFiles = true;
  bool _includeCommercialUse = true;
  bool _includeHighRes = true;
  bool _includePrototype = true;

  // Expiration
  int _expirationDays = 3;

  // Milestones
  final List<Map<String, dynamic>> _milestones = [
    {
      'title': 'Milestone 1: Wireframes & UX Flow Architecture',
      'amount': 250.0,
      'days': 2,
    },
    {
      'title': 'Milestone 2: High-Fidelity UI Screens & Component Library',
      'amount': 250.0,
      'days': 1,
    },
    {
      'title': 'Milestone 3: Clickable Prototype & Developer Handoff',
      'amount': 100.0,
      'days': 1,
    },
  ];

  // Portfolio samples attached
  final List<String> _attachedSamples = [
    'Fintech_Wallet_CaseStudy.pdf',
    'Mobile_Design_System_Figma.fig',
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedGig = _availableGigs.first;

    _pitchController = TextEditingController(
      text:
          'Hi Sarah, I would love to build the FinTech wallet experience for your Flutter app!\n\n'
          'Here is what I will deliver:\n'
          '• Complete design system in Figma (Atomic components + Auto-layout)\n'
          '• 24+ beautifully crafted, highly usable pixel-perfect wallet screens\n'
          '• High-fidelity clickable prototype for testing and developer handoff\n'
          '• Clean SVG assets, design tokens, and developer documentation\n\n'
          'Ready to kick off right away and deliver within 4 days.',
    );

    _priceController = TextEditingController(text: '600.00');
    _enforceFreelancerRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BuyerRequest) {
        _request = args;
        _priceController.text = _request.budget.toStringAsFixed(2);
        _deliveryDays = _request.deliveryDays;
        final name = _request.clientName.trim().isNotEmpty ? _request.clientName.trim().split(' ').first : 'Client';
        _pitchController.text =
            'Hi $name, I would love to build this for your project!\n\n'
            'Here is what I will deliver:\n'
            '• High-quality Flutter application code following clean architecture\n'
            '• Fully tested and production-ready implementation\n'
            '• Complete documentation and setup guide\n\n'
            'Ready to kick off right away and deliver high performance results.';
      } else if (widget.initialRequest != null) {
        _request = widget.initialRequest!;
        _priceController.text = _request.budget.toStringAsFixed(2);
        _deliveryDays = _request.deliveryDays;
      } else {
        _request = BuyerRequest(
          id: 'br_default',
          clientName: FirebaseConfig.instance.isInitialized ? 'Vedant' : 'Sarah Jenkins',
          clientCountry: 'United States',
          clientBadge: 'VERIFIED BUYER',
          clientRating: 5.0,
          clientOrdersCount: 14,
          title: 'Need complete Flutter mobile app UI design for FinTech wallet with 8 screens',
          description:
              'Looking for an expert designer to create modern, clean Figma/code mockups for our crypto wallet application.',
          category: 'Mobile Design',
          skills: ['Figma', 'Flutter', 'FinTech Wallet', 'Mobile UI'],
          budget: 650.00,
          deliveryDays: 5,
          offersSent: 6,
          timeAgo: 'Posted 2 hours ago',
        );
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _pitchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _enforceFreelancerRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Clients cannot submit custom offers.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    });
  }

  double get _totalOfferAmount {
    if (_paymentType == 'milestone') {
      return _milestones.fold(0.0, (sum, m) => sum + (m['amount'] as double));
    }
    return double.tryParse(_priceController.text) ?? 0.0;
  }

  double get _serviceFee => _totalOfferAmount * 0.20;
  double get _netEarnings => _totalOfferAmount - _serviceFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Client Context Card
                    _buildClientContextCard(),
                    const SizedBox(height: 18),

                    // 2. Associated Gig Selector
                    _buildGigSelector(),
                    const SizedBox(height: 18),

                    // 3. Payment Type Switcher (Single vs Milestones)
                    _buildPaymentTypeSwitcher(),
                    const SizedBox(height: 18),

                    // 4. Milestone Builder (if milestones selected)
                    if (_paymentType == 'milestone') ...[
                      _buildMilestonesManager(),
                      const SizedBox(height: 18),
                    ],

                    // 5. Proposal Pitch & Scope (Cover Letter)
                    _buildProposalPitchSection(),
                    const SizedBox(height: 18),

                    // 6. Pricing & Delivery Duration (Single Payment Mode)
                    if (_paymentType == 'single') ...[
                      _buildPricingAndDeliveryGrid(),
                      const SizedBox(height: 18),
                    ],

                    // 7. Revisions Selection
                    _buildRevisionsSection(),
                    const SizedBox(height: 18),

                    // 8. Deliverables Included Grid
                    _buildDeliverablesGrid(),
                    const SizedBox(height: 18),

                    // 9. Offer Expiration Banner
                    _buildExpirationBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 10. Sticky Bottom Fee Breakdown & Action Footer
            _buildStickyFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Submit Proposal',
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
              'OFFER',
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
          icon: const Icon(LucideIcons.helpCircle, size: 20, color: AppColors.textSecondary),
          tooltip: 'Proposal Guidelines',
          onPressed: _showProposalTipsModal,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CLIENT CONTEXT CARD (BENTO STYLE)
  // ---------------------------------------------------------------------------
  Widget _buildClientContextCard() {
    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BUYER REQUEST',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Client',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      _request.clientName.isNotEmpty
                          ? _request.clientName.substring(0, 1).toUpperCase()
                          : 'C',
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
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                    Text(
                      _request.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _request.clientName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Text(
                          'Budget: \$${_request.budget.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ASSOCIATED GIG SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildGigSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Associated Gig',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            GestureDetector(
              onTap: _showGigPickerSheet,
              child: Text(
                'Change Gig',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showGigPickerSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    _selectedGig['icon'] as IconData? ?? LucideIcons.smartphone,
                    color: AppColors.primaryDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedGig['title'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.star, size: 12, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(
                                  '${_selectedGig['rating']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '(${_selectedGig['reviews']})',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedGig['level'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showGigPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Matching Gig',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_availableGigs.length, (index) {
                final gig = _availableGigs[index];
                final isSelected = gig['title'] == _selectedGig['title'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        gig['icon'] as IconData? ?? LucideIcons.layers,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      gig['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                    ),
                    subtitle: Text(
                      '★ ${gig['rating']} (${gig['reviews']}) • ${gig['level']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(LucideIcons.check, size: 18, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedGig = gig);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. PAYMENT TYPE SWITCHER
  // ---------------------------------------------------------------------------
  Widget _buildPaymentTypeSwitcher() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Type',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  title: 'Single Payment',
                  icon: LucideIcons.badgeCheck,
                  isSelected: _paymentType == 'single',
                  onTap: () => setState(() => _paymentType = 'single'),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildTypeButton(
                  title: 'Milestones',
                  icon: LucideIcons.flag,
                  isSelected: _paymentType == 'milestone',
                  onTap: () => setState(() => _paymentType = 'milestone'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: AppColors.border) : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MILESTONES MANAGER
  // ---------------------------------------------------------------------------
  Widget _buildMilestonesManager() {
    return Container(
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
                'Project Milestones (${_milestones.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: _addMilestoneDialog,
                child: Text(
                  '+ Add Milestone',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_milestones.length, (index) {
            final m = _milestones[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${m['days']} Days delivery',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(m['amount'] as double).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_milestones.length > 1)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _milestones.removeAt(index));
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _addMilestoneDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '150');
    final daysCtrl = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Add New Milestone',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Milestone Title / Scope',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Delivery (Days)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final amt = double.tryParse(amountCtrl.text) ?? 100.0;
                final dys = int.tryParse(daysCtrl.text) ?? 2;
                setState(() {
                  _milestones.add({
                    'title': titleCtrl.text.trim(),
                    'amount': amt,
                    'days': dys,
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Milestone'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PROPOSAL PITCH & SCOPE SECTION
  // ---------------------------------------------------------------------------
  Widget _buildProposalPitchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Proposal Pitch & Scope',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${_pitchController.text.length} / 1200',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _pitchController,
                maxLines: 7,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe your tailored approach, deliverables, and timeline...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textDisabled,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _showAiRefinementOptions,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.sparkles, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Refine with AI',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showAddSamplesDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.paperclip, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Add Portfolio Samples',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_attachedSamples.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _attachedSamples.map((sample) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.fileCheck, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            sample,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() => _attachedSamples.remove(sample));
                            },
                            child: const Icon(LucideIcons.x, size: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAiRefinementOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'AI Proposal Assistant',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAiOptionTile(
                title: 'Professional & Comprehensive',
                subtitle: 'Structured deliverables, atomic Figma system, and developer handoff',
                onTap: () {
                  setState(() {
                    _pitchController.text =
                        'Hi ${_request.clientName}, I specialize in building enterprise-grade Flutter & Figma experiences!\n\n'
                        'Tailored deliverables for this project:\n'
                        '• Full responsive Figma design system (Tokens, dark/light modes, auto-layout)\n'
                        '• High-fidelity interactive prototype for stakeholder & user testing\n'
                        '• Clean, production-ready SVG assets and comprehensive technical handoff\n\n'
                        'I have 5+ years building FinTech products and can guarantee delivery in $_deliveryDays days.';
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposal updated to Professional & Comprehensive!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildAiOptionTile(
                title: 'Concise & Fast Turnaround',
                subtitle: 'Direct, high-impact bulleted summary focused on immediate start',
                onTap: () {
                  setState(() {
                    _pitchController.text =
                        'Hi ${_request.clientName}, ready to jump in immediately!\n\n'
                        'Key Deliverables:\n'
                        '1. Modern, pixel-perfect wallet UI in Figma and Flutter specs\n'
                        '2. Clickable interactive prototype with micro-animations\n'
                        '3. Daily updates with immediate revisions as needed\n\n'
                        'Estimated completion: $_deliveryDays days.';
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proposal updated to Concise & Fast Turnaround!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiOptionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        trailing: const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.primary),
        onTap: onTap,
      ),
    );
  }

  void _showAddSamplesDialog() {
    final sampleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Attach Portfolio Sample',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: sampleCtrl,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. Dribbble link, Figma URL, or doc.pdf',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (sampleCtrl.text.trim().isNotEmpty) {
                  setState(() => _attachedSamples.add(sampleCtrl.text.trim()));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Attach'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 6. PRICING & DELIVERY GRID (Single Payment)
  // ---------------------------------------------------------------------------
  Widget _buildPricingAndDeliveryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offer Pricing & Timeline',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Offer Price
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Price (\$)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '\$',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client sees full total',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Delivery Duration
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Duration',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '$_deliveryDays Day${_deliveryDays > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildStepperButton(
                              icon: LucideIcons.minus,
                              onTap: () {
                                if (_deliveryDays > 1) {
                                  setState(() => _deliveryDays--);
                                }
                              },
                            ),
                            const SizedBox(width: 4),
                            _buildStepperButton(
                              icon: LucideIcons.plus,
                              onTap: () {
                                if (_deliveryDays < 30) {
                                  setState(() => _deliveryDays++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Faster delivery attracts buyers',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textSecondary,
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

  Widget _buildStepperButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 13, color: AppColors.textDark),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. REVISIONS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildRevisionsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                'Client Revisions',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Recommended: Unlimited',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _revisionOptions.map((rev) {
              final isSelected = _selectedRevision == rev;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRevision = rev),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        rev,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. DELIVERABLES INCLUSION GRID
  // ---------------------------------------------------------------------------
  Widget _buildDeliverablesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deliverables Included in this Offer',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInclusionCard(
                title: 'Source Files',
                icon: LucideIcons.folderArchive,
                isChecked: _includeSourceFiles,
                onChanged: (val) => setState(() => _includeSourceFiles = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInclusionCard(
                title: 'Commercial Use',
                icon: LucideIcons.shieldCheck,
                isChecked: _includeCommercialUse,
                onChanged: (val) => setState(() => _includeCommercialUse = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInclusionCard(
                title: 'High Res',
                icon: LucideIcons.image,
                isChecked: _includeHighRes,
                onChanged: (val) => setState(() => _includeHighRes = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInclusionCard(
                title: 'Prototype',
                icon: LucideIcons.monitorSmartphone,
                isChecked: _includePrototype,
                onChanged: (val) => setState(() => _includePrototype = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInclusionCard({
    required String title,
    required IconData icon,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isChecked ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isChecked ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked ? AppColors.primary : AppColors.border,
                ),
              ),
              child: isChecked
                  ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. EXPIRATION BANNER
  // ---------------------------------------------------------------------------
  Widget _buildExpirationBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.timer, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Offer Expiration',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _showExpirationPicker,
            child: Row(
              children: [
                Text(
                  'Expires in $_expirationDays Days',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.pencil, size: 13, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExpirationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Offer Expiration',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...[1, 3, 7, 14].map((days) {
                final isSelected = _expirationDays == days;
                return ListTile(
                  title: Text(
                    '$days Day${days > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check, size: 18, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _expirationDays = days);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 10. STICKY ACTION FOOTER WITH REAL-TIME FEE BREAKDOWN
  // ---------------------------------------------------------------------------
  Widget _buildStickyFooter() {
    final clientTotal = _totalOfferAmount;
    final fee = _serviceFee;
    final net = _netEarnings;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fee Breakdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Client Total: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${clientTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fee (20%): -\$${fee.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'You Earn: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${net.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Primary Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleOfferSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sending Custom Offer...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit Custom Offer',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 16),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUBMISSION LOGIC & SUCCESS CONFIRMATION
  // ---------------------------------------------------------------------------
  Future<void> _handleOfferSubmission() async {
    if (_pitchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a proposal pitch explaining your approach.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_totalOfferAmount < 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum offer amount must be at least \$5.00.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (FirebaseConfig.instance.isInitialized) {
        final currentUid = FirebaseService.instance.currentUser?.uid ?? 'siddhant';
        final userProfile = await FirebaseService.instance.getUserProfile(currentUid);
        final freelancerName = userProfile?['fullName'] ??
            FirebaseService.instance.currentUser?.displayName ??
            'Siddhant';

        // Fetch task to get clientId if available
        final task = await FirebaseService.instance.taskRepository.getTask(_request.id);
        final clientId = task?.clientId ?? '';

        final proposal = ProposalModel(
          id: '',
          taskId: _request.id,
          taskTitle: _request.title,
          clientId: clientId,
          freelancerId: currentUid,
          freelancerName: freelancerName,
          proposedPrice: _totalOfferAmount,
          deliveryTimeDays: _deliveryDays,
          coverLetter: _pitchController.text.trim(),
          milestones: _paymentType == 'milestone' ? _milestones : [],
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await FirebaseService.instance.proposalRepository.submitProposal(proposal);
        await FirebaseService.instance.taskRepository.incrementOffersCount(_request.id);

        if (clientId.isNotEmpty) {
          await NotificationService.instance.notifyNewProposal(
            clientUserId: clientId,
            freelancerName: freelancerName,
            taskTitle: _request.title,
            taskId: _request.id,
          );
        }
      }
    } catch (e) {
      debugPrint('Proposal submission notice: $e');
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Update passed request state
    _request.hasSubmittedOffer = true;
    _request.offersSent += 1;
    _request.submittedAmount = _totalOfferAmount;
    _request.submittedDays = _deliveryDays;
    _request.submittedPitch = _pitchController.text.trim();

    _showSuccessBottomSheet();
  }

  void _showSuccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.badgeCheck, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'Custom Offer Sent!',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your proposal has been delivered directly to ${_request.clientName}. You will be notified as soon as they respond.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Offer Amount',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$${_totalOfferAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    Column(
                      children: [
                        Text(
                          'Delivery',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$_deliveryDays Days',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    Column(
                      children: [
                        Text(
                          'You Will Earn',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$${_netEarnings.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Return to Opportunities',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _showProposalTipsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Winning Proposal Checklist',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTipRow('Address the client by name and reference their specific project requirements.'),
              _buildTipRow('Highlight your past relevant experience with links or case study attachments.'),
              _buildTipRow('Provide a realistic timeline and clear milestone breakdown.'),
              _buildTipRow('Keep your pricing transparent without hidden fees or scope ambiguities.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Got It',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
