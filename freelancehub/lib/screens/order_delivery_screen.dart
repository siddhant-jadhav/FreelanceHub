import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/order_model.dart';

/// Detailed Order Delivery & Fulfillment Screen.
/// Strictly implements FreelanceHub Design System (docs/design.md and .agents/rules/ui-design.md).
/// Features:
/// - Clean header with order options dropdown.
/// - Live ticking countdown timer and order status progress bar.
/// - Client & Order summary bento card with verified badges.
/// - Downloadable client brief requirements and assets.
/// - Interactive order activity timeline.
/// - Full delivery workbench: file uploader, delivery preview thumbnail, customizable delivery note, watermark toggle.
/// - Live "Deliver Completed Work" submission with success confirmation bottom sheet.
/// - Seller actions: Request extension, contact client, and order protection guarantee.
class OrderDeliveryScreen extends StatefulWidget {
  final FreelanceOrder? initialOrder;

  const OrderDeliveryScreen({super.key, this.initialOrder});

  @override
  State<OrderDeliveryScreen> createState() => _OrderDeliveryScreenState();
}

class _OrderDeliveryScreenState extends State<OrderDeliveryScreen> {
  late FreelanceOrder _order;
  bool _initialized = false;

  // Live countdown timer state
  late int _remainingSeconds;
  Timer? _countdownTimer;

  // Delivery form controllers
  late TextEditingController _deliveryNoteController;
  bool _watermarkEnabled = true;
  bool _isDelivering = false;

  // Uploaded files list
  late List<Map<String, String>> _uploadedFiles;

  @override
  void initState() {
    super.initState();
    _enforceFreelancerRole();

    // Default countdown: 1 day, 13 hours, 48 minutes, 22 seconds
    _remainingSeconds = (1 * 86400) + (13 * 3600) + (48 * 60) + 22;
    _startCountdownTimer();

    _deliveryNoteController = TextEditingController(
      text:
          'Here is your completed delivery! Includes all Figma source files, exported SVG icons, and interactive prototype link with seamless mobile interaction flows.',
    );

    _uploadedFiles = [
      {
        'name': 'FinTech_UI_v1.0_Final.zip',
        'size': '24.5 MB',
        'status': 'Ready',
      },
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is FreelanceOrder) {
        _order = args;
      } else if (widget.initialOrder != null) {
        _order = widget.initialOrder!;
      } else {
        _order = _createDefaultOrder();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  void _enforceFreelancerRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Clients cannot view seller delivery screens.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    });
  }

  FreelanceOrder _createDefaultOrder() {
    final now = DateTime.now();
    return FreelanceOrder(
      id: 'FH-9821',
      clientName: 'Sarah Jenkins',
      clientCompany: 'FinTech Corp • Top Buyer',
      clientCountry: 'United States',
      isClientVerified: true,
      clientRating: 5.0,
      gigTitle: 'Modern FinTech Wallet UI & Design System',
      gigTier: 'Tier: Premium Full App UI (12 Screens + Prototypes)',
      budget: 450.00,
      startedDate: now.subtract(const Duration(days: 3)),
      dueDate: now.add(const Duration(days: 1, hours: 13, minutes: 48)),
      totalDays: 5,
      progressPercent: 0.72,
      status: OrderStatus.inProgress,
      clientBrief:
          'Need clean neo-banking screens matching our brand typography. Focus on the cards carousel, send money modal, and multi-currency exchange sheet.',
      briefFiles: const [
        OrderRequirementFile(
          fileName: 'FinTechCorp_Brand_Guidelines_v2.pdf',
          fileSize: '14.2 MB',
          fileType: 'pdf',
        ),
        OrderRequirementFile(
          fileName: 'LowFi_Sketched_Wireframes.png',
          fileSize: '4.8 MB',
          fileType: 'image',
        ),
      ],
      timeline: const [
        OrderTimelineEvent(
          title: 'Order started by Sarah Jenkins',
          time: 'Oct 24 • 10:14 AM',
        ),
        OrderTimelineEvent(
          title: 'You sent project kickoff confirmation',
          time: 'Oct 24 • 11:30 AM',
        ),
        OrderTimelineEvent(
          title: 'Client feedback message',
          time: 'Today • 1:45 PM',
          isClientMessage: true,
          senderName: 'Sarah Jenkins',
          description:
              'Looking great so far! Please ensure all icon components are set to auto-layout so our iOS team can swap them seamlessly.',
        ),
      ],
      deliveredFileName: 'FinTech_UI_v1.0_Final.zip',
      deliveredFileSize: '24.5 MB • Ready',
      deliveryNote:
          'Here is your completed delivery! Includes all Figma source files, exported SVG icons, and interactive prototype link with seamless mobile interaction flows.',
    );
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedCountdown {
    final days = _remainingSeconds ~/ 86400;
    final hours = (_remainingSeconds % 86400) ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;

    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(days)}d ${pad(hours)}h ${pad(minutes)}m ${pad(seconds)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Order Sub-header Pill Bar
              _buildOrderSubHeader(),
              const SizedBox(height: 14),

              // 2. Order Status Banner & Live Countdown
              _buildCountdownBanner(),
              const SizedBox(height: 16),

              // 3. Client & Order Summary Bento Card
              _buildClientSummaryCard(),
              const SizedBox(height: 16),

              // 4. Client Brief & Assets Accordion
              _buildClientBriefSection(),
              const SizedBox(height: 16),

              // 5. Order Activity Timeline
              _buildTimelineSection(),
              const SizedBox(height: 18),

              // 6. DELIVER WORK SECTION (Primary Action Container)
              _buildDeliverWorkSection(),
              const SizedBox(height: 16),

              // 7. Quick Seller Actions (Request Extension, Contact Buyer)
              _buildQuickActionsRow(),
              const SizedBox(height: 16),

              // 8. Order Protection & Escrow Guarantee Footer
              _buildProtectionFooter(),
              const SizedBox(height: 24),
            ],
          ),
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
            'Order Details',
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
              'DELIVERY',
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
          icon: const Icon(LucideIcons.moreVertical, size: 20, color: AppColors.textSecondary),
          tooltip: 'Order Options',
          onPressed: _showOrderOptionsModal,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. ORDER SUB-HEADER BAR
  // ---------------------------------------------------------------------------
  Widget _buildOrderSubHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Order #${_order.id}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'FreelanceHub Pro',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Escrow: \$${_order.budget.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ORDER STATUS BANNER & LIVE COUNTDOWN
  // ---------------------------------------------------------------------------
  Widget _buildCountdownBanner() {
    final isDelivered = _order.status == OrderStatus.delivered;
    final isRevision = _order.status == OrderStatus.inRevision;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isRevision ? AppColors.warning : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _order.status.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isRevision ? AppColors.warning : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Standard Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Countdown numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TIME REMAINING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDelivered ? 'Delivered' : _formattedCountdown,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Due Date',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tomorrow, 11:59 PM',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Step Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isDelivered ? 1.0 : _order.progressPercent,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started (Oct 24)',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                isDelivered ? 'Delivered 100%' : 'Delivery Phase (72%)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                'Completed',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. CLIENT & ORDER SUMMARY BENTO CARD
  // ---------------------------------------------------------------------------
  Widget _buildClientSummaryCard() {
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
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          _order.clientName.substring(0, 1),
                          style: GoogleFonts.inter(
                            fontSize: 15,
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
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _order.clientName,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.badgeCheck, size: 14, color: AppColors.primary),
                        ],
                      ),
                      Text(
                        _order.clientCompany,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Budget',
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    Text(
                      '\$${_order.budget.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gig Pill Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.wallet, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order.gigTitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _order.gigTier,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. CLIENT BRIEF & ASSETS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildClientBriefSection() {
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
              Row(
                children: [
                  const Icon(LucideIcons.archive, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Client Brief & Assets',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${_order.briefFiles.length} Files',
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
          Text(
            '"${_order.clientBrief}"',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textDark,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),

          // Attached requirement files
          ..._order.briefFiles.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    file.fileType == 'pdf' ? LucideIcons.fileText : LucideIcons.image,
                    size: 16,
                    color: file.fileType == 'pdf' ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          file.fileSize,
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.download, size: 16, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading ${file.fileName}...'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
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

  // ---------------------------------------------------------------------------
  // 5. ORDER TIMELINE
  // ---------------------------------------------------------------------------
  Widget _buildTimelineSection() {
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
              Row(
                children: [
                  const Icon(LucideIcons.history, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Order Timeline',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Today',
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vertical timeline list
          ..._order.timeline.map((event) {
            if (event.isClientMessage) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          event.senderName ?? 'Client',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          event.time,
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textDark,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          event.time,
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. DELIVER WORK SECTION (PRIMARY ACTION ENGINE)
  // ---------------------------------------------------------------------------
  Widget _buildDeliverWorkSection() {
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.rocket, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver Completed Work',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Hand off final project source files & preview',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Upload Work Dropzone
          InkWell(
            onTap: _showAddDeliveryFileDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.uploadCloud, size: 20, color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload Work (ZIP, PNG, Figma Link)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Max size 5 GB • Drag files or tap to browse',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Uploaded Files Pills
          ..._uploadedFiles.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.folderArchive, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${file['size']} • ${file['status']}',
                          style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (_uploadedFiles.length > 1)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 14, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _uploadedFiles.remove(file));
                      },
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Visual Preview Card / Delivery Mockup
          Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.layoutTemplate, size: 36, color: AppColors.textDisabled),
                      const SizedBox(width: 10),
                      Text(
                        '12 FinTech Wallet Mobile Screens\n+ Figma Prototype Package Ready',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.eye, size: 11, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Portfolio Delivery Thumbnail',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Delivery Note
          Text(
            'Delivery Note to Buyer',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _deliveryNoteController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Client will review before releasing escrow',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${_deliveryNoteController.text.length} chars',
                      style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Watermark switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Add FreelanceHub Watermark',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.helpCircle, size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                      Text(
                        'Protects image previews until Sarah approves delivery',
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _watermarkEnabled,
                  activeTrackColor: AppColors.primaryLight,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _watermarkEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Deliver Work Primary Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDelivering ? null : _handleDeliverWorkSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isDelivering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(LucideIcons.send, size: 16),
              label: Text(
                _isDelivering ? 'Delivering Completed Work...' : 'Deliver Completed Work',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Sarah will have 3 days to approve or ask for revisions',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeliveryFileDialog() {
    final nameCtrl = TextEditingController(text: 'FinTech_Prototype_V2.fig');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Add Delivery File',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: nameCtrl,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'File Name or Shareable Link',
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
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _uploadedFiles.add({
                      'name': nameCtrl.text.trim(),
                      'size': '15.2 MB',
                      'status': 'Ready',
                    });
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add File'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 7. QUICK SELLER ACTIONS
  // ---------------------------------------------------------------------------
  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showRequestExtensionDialog,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(LucideIcons.clockPlus, size: 15, color: AppColors.textSecondary),
            label: Text(
              'Request Extension',
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showContactClientDialog,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(LucideIcons.messageSquare, size: 15, color: AppColors.primary),
            label: Text(
              'Contact Sarah',
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 8. PROTECTION FOOTER
  // ---------------------------------------------------------------------------
  Widget _buildProtectionFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order protection active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Escrow secured by FreelanceHub Guarantee',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: _showFaqDialog,
            child: Text(
              'FAQ',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERACTION HANDLERS & MODALS
  // ---------------------------------------------------------------------------
  Future<void> _handleDeliverWorkSubmission() async {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one deliverable file or link.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isDelivering = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _isDelivering = false;
      _order.status = OrderStatus.delivered;
    });

    _showDeliverySuccessModal();
  }

  void _showDeliverySuccessModal() {
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
                  'Delivered Successfully!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your final delivery package has been submitted to ${_order.clientName}. The client has 3 days to review or request revisions before payment is released automatically.',
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
                          Text('Order Total', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                          Text('\$${_order.budget.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Container(width: 1, height: 24, color: AppColors.border),
                      Column(
                        children: [
                          Text('Status', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                          Text('Delivered', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Container(width: 1, height: 24, color: AppColors.border),
                      Column(
                        children: [
                          Text('Files', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                          Text('${_uploadedFiles.length} Attached', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
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
                      Navigator.pop(context, true); // return true to refresh listing
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Back to Orders List',
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

  void _showOrderOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.scale, size: 20, color: AppColors.textPrimary),
                title: Text('Resolution Center', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening FreelanceHub Resolution Center...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.clockPlus, size: 20, color: AppColors.textPrimary),
                title: Text('Request Extension', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRequestExtensionDialog();
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.externalLink, size: 20, color: AppColors.textPrimary),
                title: Text('View Live Gig Listing', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening published gig details...')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRequestExtensionDialog() {
    int selectedDays = 2;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text(
                'Request Delivery Extension',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select how many additional days you need:',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [1, 2, 3, 5].map((d) {
                      final isSelected = selectedDays == d;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedDays = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '+$d Days',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    setState(() {
                      _remainingSeconds += selectedDays * 86400;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Extension request for $selectedDays days sent to Sarah!'),
                      ),
                    );
                  },
                  child: const Text('Send Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContactClientDialog() {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Message ${_order.clientName}',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: msgCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Type your message...',
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
                if (msgCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message delivered to ${_order.clientName}!'),
                    ),
                  );
                }
              },
              child: const Text('Send Message'),
            ),
          ],
        );
      },
    );
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Order Protection Guarantee',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Escrow Release: Once you deliver, the client has 3 days to approve. If no action is taken, funds are automatically released to your earnings.\n\n'
                '2. Revision Protection: If revisions are requested, the order timer pauses while you make necessary adjustments.\n\n'
                '3. Resolution Center: If you encounter disputes or unresponsive buyers, FreelanceHub support mediates the escrow directly.',
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
