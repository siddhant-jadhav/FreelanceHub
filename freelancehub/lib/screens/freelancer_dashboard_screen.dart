import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/payment_model.dart';
import '../models/project_model.dart';

/// Contract Status definition
enum ContractStatus {
  inProgress,
  needsRevision,
  delivered,
  completed,
}

/// Data model representing a Freelancer Client Contract / Order
class FreelancerContract {
  final String id;
  final String orderNumber;
  final String title;
  final String clientName;
  final double amount;
  final String deliveryTimeText;
  final ContractStatus status;
  final String? revisionReason;

  const FreelancerContract({
    required this.id,
    required this.orderNumber,
    required this.title,
    required this.clientName,
    required this.amount,
    required this.deliveryTimeText,
    required this.status,
    this.revisionReason,
  });

  FreelancerContract copyWith({
    String? id,
    String? orderNumber,
    String? title,
    String? clientName,
    double? amount,
    String? deliveryTimeText,
    ContractStatus? status,
    String? revisionReason,
  }) {
    return FreelancerContract(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      deliveryTimeText: deliveryTimeText ?? this.deliveryTimeText,
      status: status ?? this.status,
      revisionReason: revisionReason ?? this.revisionReason,
    );
  }
}

/// Freelancer Dashboard & Performance Screen
/// Conforms strictly to FreelanceHub Design System (design.md & agent rules).
/// Fixed color inconsistencies (no harsh purples/neons, unified green & neutral tokens).
/// Dynamic contract data model with real interactions.
class FreelancerDashboardScreen extends StatefulWidget {
  const FreelancerDashboardScreen({super.key});

  @override
  State<FreelancerDashboardScreen> createState() =>
      _FreelancerDashboardScreenState();
}

class _FreelancerDashboardScreenState extends State<FreelancerDashboardScreen> {
  int _currentBottomNavIndex = 0;
  String _selectedContractFilter = 'All';
  bool _isAvailableForWork = true;

  double _availableWithdrawal = 1280.00;
  double _earnedThisMonth = 3450.00;
  double _pendingClearance = 940.00;
  String _freelancerName = 'Siddhant Jadhav';

  late List<FreelancerContract> _contracts;
  List<ProjectModel> _firebaseProjects = [];
  List<PaymentModel> _firebasePayments = [];
  StreamSubscription<List<ProjectModel>>? _projectsSub;
  StreamSubscription<List<PaymentModel>>? _paymentsSub;

  @override
  void initState() {
    super.initState();
    _initializeContracts();
    _loadFreelancerProfile();
  }

  void _loadFreelancerProfile() async {
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        if (mounted) setState(() => _freelancerName = user.displayName!.trim());
      }
      try {
        final profile = await FirebaseService.instance.getUserProfile(user.uid);
        final name = (profile?['fullName'] as String?)?.trim() ??
            (profile?['name'] as String?)?.trim();
        if (name != null && name.isNotEmpty) {
          if (mounted) setState(() => _freelancerName = name);
          user.updateDisplayName(name).catchError((_) {});
          return;
        }
      } catch (_) {}
      if (user.email != null && user.email!.contains('siddhant')) {
        if (mounted) setState(() => _freelancerName = 'Siddhant Jadhav');
      }
    }
  }

  @override
  void dispose() {
    _projectsSub?.cancel();
    _paymentsSub?.cancel();
    super.dispose();
  }

  void _recalculateEarnings() {
    double released = 0.0;
    double pending = 0.0;
    final Set<String> projectsWithReleasedPayments = {};

    for (final p in _firebasePayments) {
      if (p.status == 'released') {
        released += p.amount;
        final cleanId = p.projectId.replaceFirst('FH-', '').toLowerCase().trim();
        if (cleanId.isNotEmpty) {
          projectsWithReleasedPayments.add(cleanId);
        }
      } else if (p.status == 'held_in_escrow') {
        pending += p.amount;
      }
    }

    for (final prj in _firebaseProjects) {
      final cleanId = prj.id.replaceFirst('FH-', '').toLowerCase().trim();
      if (prj.status == 'completed') {
        if (!projectsWithReleasedPayments.contains(cleanId)) {
          released += prj.budget;
          projectsWithReleasedPayments.add(cleanId);
        }
      } else if (prj.status == 'in_progress' || prj.status == 'delivered' || prj.status == 'review') {
        final hasPending = _firebasePayments.any((p) =>
            p.status == 'held_in_escrow' &&
            p.projectId.replaceFirst('FH-', '').toLowerCase().trim() == cleanId);
        if (!hasPending && prj.budget > 0) {
          pending += prj.budget;
        }
      }
    }

    setState(() {
      _availableWithdrawal = released;
      _earnedThisMonth = released;
      _pendingClearance = pending;
    });
  }

  void _listenToFreelancerProjects() {
    if (!FirebaseConfig.instance.isInitialized) return;
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      _projectsSub = FirebaseService.instance.projectRepository
          .streamProjectsForFreelancer(uid)
          .listen((projects) {
        if (!mounted) return;
        _firebaseProjects = projects;
        setState(() {
          _contracts = projects.map((p) {
            final dueDiff = p.dueDate.difference(DateTime.now()).inDays;
            return FreelancerContract(
              id: p.id,
              orderNumber: 'Order #${p.id.length > 5 ? p.id.substring(0, 5).toUpperCase() : p.id.toUpperCase()}',
              title: p.title,
              clientName: p.clientName.isNotEmpty ? p.clientName : 'Client',
              amount: p.budget,
              deliveryTimeText: dueDiff > 0 ? 'Delivery in ${dueDiff}d' : 'Due today',
              status: p.status == 'completed'
                  ? ContractStatus.completed
                  : (p.status == 'review'
                      ? ContractStatus.delivered
                      : (p.status == 'revision'
                          ? ContractStatus.needsRevision
                          : ContractStatus.inProgress)),
              revisionReason: p.status == 'revision' ? 'Client requested adjustments' : null,
            );
          }).toList();
        });
        _recalculateEarnings();
      }, onError: (e) {
        debugPrint('Error streaming freelancer projects: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming freelancer projects: $e');
    }
  }

  void _listenToFreelancerPayments() {
    if (!FirebaseConfig.instance.isInitialized) return;
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      _paymentsSub = FirebaseService.instance.paymentRepository
          .streamUserPayments(uid, isClient: false)
          .listen((payments) {
        if (!mounted) return;
        _firebasePayments = payments;
        _recalculateEarnings();
      }, onError: (e) {
        debugPrint('Error streaming payments: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming payments: $e');
    }
  }

  void _initializeContracts() {
    if (FirebaseConfig.instance.isInitialized) {
      _contracts = [];
      _availableWithdrawal = 0.0;
      _earnedThisMonth = 0.0;
      _pendingClearance = 0.0;
      _listenToFreelancerProjects();
      _listenToFreelancerPayments();
    } else {
      // In standalone widget tests where Firebase is uninitialized
      _contracts = [
        const FreelancerContract(
          id: 'ord_1',
          orderNumber: 'Order #FH-8821',
          title: 'TechCorp SaaS Brand Identity',
          clientName: 'TechCorp Inc.',
          amount: 450.00,
          deliveryTimeText: 'Delivery in 1d 14h',
          status: ContractStatus.inProgress,
        ),
        const FreelancerContract(
          id: 'ord_2',
          orderNumber: 'Order #FH-9154',
          title: 'Mobile UI Kit Components',
          clientName: 'Apex Labs',
          amount: 380.00,
          deliveryTimeText: 'Buyer requested adjustments',
          status: ContractStatus.needsRevision,
          revisionReason:
              'Please update dark mode tokens and add 3 additional checkout state variants.',
        ),
      ];
    }
  }

  /// Calculates total active queue valuation dynamically from open contracts
  double get _queueValuation {
    return _contracts
        .where((c) => c.status != ContractStatus.completed)
        .fold<double>(0.0, (sum, c) => sum + c.amount);
  }

  int get _activeContractsCount {
    return _contracts
        .where((c) => c.status != ContractStatus.completed)
        .length;
  }

  List<FreelancerContract> get _filteredContracts {
    if (_selectedContractFilter == 'In Progress') {
      return _contracts
          .where((c) => c.status == ContractStatus.inProgress)
          .toList();
    } else if (_selectedContractFilter == 'Revisions') {
      return _contracts
          .where((c) => c.status == ContractStatus.needsRevision)
          .toList();
    }
    return _contracts;
  }

  void _handleQuickDeliver(FreelancerContract contract) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.send, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Deliver Order',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contract.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${contract.orderNumber} • \$${contract.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add an optional note or download link for the client...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
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
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed(
                '/order-delivery',
                arguments: contract,
              );
            },
            child: Text(
              'Full Delivery Studio',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (FirebaseConfig.instance.isInitialized) {
                try {
                  await FirebaseService.instance.projectRepository
                      .updateProjectStatus(contract.id, 'review');
                } catch (e) {
                  debugPrint('Notice updating project status: $e');
                }
              }
              if (!mounted) return;
              setState(() {
                final index = _contracts.indexWhere((c) => c.id == contract.id);
                if (index != -1) {
                  _contracts[index] = _contracts[index].copyWith(
                    status: ContractStatus.delivered,
                    deliveryTimeText: 'Delivered • Awaiting client review',
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deliverables submitted for ${contract.orderNumber}!'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit Delivery',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRespondToRevision(FreelancerContract contract) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.rotateCcw, color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Client Revision Request',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                contract.revisionReason ?? 'Buyer requested adjustments.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF92400E),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain the adjustments made in this revision...',
                hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (FirebaseConfig.instance.isInitialized) {
                try {
                  await FirebaseService.instance.projectRepository
                      .updateProjectStatus(contract.id, 'review');
                } catch (e) {
                  debugPrint('Notice updating revision delivery status: $e');
                }
              }
              if (!mounted) return;
              setState(() {
                final index = _contracts.indexWhere((c) => c.id == contract.id);
                if (index != -1) {
                  _contracts[index] = _contracts[index].copyWith(
                    status: ContractStatus.delivered,
                    deliveryTimeText: 'Revised delivery submitted',
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Revised work submitted for ${contract.orderNumber}!'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit Revisions',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageClient(FreelancerContract contract) {
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: {
        'contactName': contract.clientName,
        'otherUserName': contract.clientName,
        'otherUserRole': 'Client',
        'projectTitle': contract.title,
        'projectBudget': contract.amount,
        'projectId': contract.id,
      },
    );
  }

  void _showWithdrawModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdraw Earnings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available for Withdrawal',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      '\$${_availableWithdrawal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transfer Destination',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(LucideIcons.building2, size: 20, color: AppColors.textPrimary),
                ),
                title: Text(
                  'Direct Bank Transfer (USD)',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Account ending in •••• 4912',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(LucideIcons.check, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _availableWithdrawal = 0.00;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payout initiated successfully! Arrives in 1-2 business days.'),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Confirm Payout',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _buildNotificationItem(
                icon: LucideIcons.rotateCcw,
                iconColor: AppColors.warning,
                title: 'Revision requested for #FH-9154',
                time: '2 hours ago',
              ),
              const Divider(height: 16),
              _buildNotificationItem(
                icon: LucideIcons.badgeCheck,
                iconColor: AppColors.primary,
                title: 'TechCorp SaaS contract milestones funded',
                time: 'Yesterday',
              ),
              const Divider(height: 16),
              _buildNotificationItem(
                icon: LucideIcons.dollarSign,
                iconColor: AppColors.primary,
                title: 'Cleared funds of \$650.00 ready for payout',
                time: '3 days ago',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildTopHeader(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Summary Card
              _buildProfileSummaryCard(),

              const SizedBox(height: 18),

              // 2. Seller Performance KPIs (2x2 Grid)
              _buildSellerPerformanceSection(),

              const SizedBox(height: 18),

              // 3. Earnings Snapshot Card
              _buildEarningsSnapshotCard(),

              const SizedBox(height: 22),

              // 4. Active Orders / Contracts Section
              _buildActiveOrdersSection(),

              const SizedBox(height: 22),

              // 5. Growth & Toolkit (2x2 Quick Tiles)
              _buildGrowthToolkitSection(),

              const SizedBox(height: 22),

              // 6. 30-Day Gig Funnel Analytics Card
              _buildGigFunnelCard(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Top App Bar: Brand mark, "SELLER HUB", Mode switcher, Notification Bell, User Avatar
  PreferredSizeWidget _buildTopHeader(BuildContext context) {
    final String initial = _freelancerName.isNotEmpty
        ? _freelancerName[0].toUpperCase()
        : 'S';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FreelanceHub',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                width: 4.5,
                height: 4.5,
                margin: const EdgeInsets.only(left: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Text(
              'SELLER HUB',
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
        // Mode switch (Freelancer <-> Client switch)
        IconButton(
          tooltip: 'Switch to Client View',
          icon: const Icon(
            LucideIcons.arrowLeftRight,
            size: 19,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            FirebaseService.instance.setCurrentRole('client');
            Navigator.of(context).pushReplacementNamed('/client-home');
          },
        ),

        // Messages
        IconButton(
          tooltip: 'Messages',
          icon: const Icon(
            LucideIcons.messageSquare,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pushNamed('/messages');
          },
        ),

        // Notifications
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(
                LucideIcons.bell,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: _showNotificationsSheet,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),

        // User Avatar Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: _showProfileSheet,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initial,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ),

        // Sign Out Button
        IconButton(
          tooltip: 'Sign Out ($_freelancerName)',
          icon: const Icon(
            LucideIcons.logOut,
            size: 19,
            color: AppColors.textSecondary,
          ),
          onPressed: _showLogoutConfirmDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleLogout() async {
    await FirebaseService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.logOut, color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of $_freelancerName?',
          style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet() {
    final user = FirebaseService.instance.currentUser;
    final email = user?.email ?? 'siddhant@gmail.com';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  _freelancerName.isNotEmpty ? _freelancerName[0].toUpperCase() : 'S',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _freelancerName,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Freelancer Account',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(LucideIcons.arrowLeftRight, color: AppColors.textPrimary, size: 20),
                title: Text('Switch to Client View', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  FirebaseService.instance.setCurrentRole('client');
                  Navigator.of(context).pushReplacementNamed('/client-home');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.wallet, color: AppColors.textPrimary, size: 20),
                title: Text('Escrow Earnings & Payments', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed('/escrow-payments');
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
                title: Text('Sign Out', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  _showLogoutConfirmDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Profile Summary Card
  Widget _buildProfileSummaryCard() {
    final userName = _freelancerName;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surfaceSecondary,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
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
                    Row(
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            'Level 2 Seller',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFB800)),
                        const SizedBox(width: 3),
                        Text(
                          '4.9',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' (142)',
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

              // Online Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Two Stat Pills: Response Time & Active Queue
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Response Time',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 Hour',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Queue',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_activeContractsCount Orders (\$${_queueValuation.toStringAsFixed(0)})',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }

  /// 2. Seller Performance KPIs (2x2 Grid)
  Widget _buildSellerPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seller Performance',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  'Level Overview',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  LucideIcons.arrowRight,
                  size: 13,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          children: [
            _buildKpiCard(
              title: 'Response Rate',
              value: '100%',
              target: 'Target 90%',
              progress: 1.0,
              icon: LucideIcons.zap,
            ),
            _buildKpiCard(
              title: 'Order Completion',
              value: '98%',
              target: 'Target 90%',
              progress: 0.98,
              icon: LucideIcons.circleCheck,
            ),
            _buildKpiCard(
              title: 'On-Time Delivery',
              value: '97%',
              target: 'Target 90%',
              progress: 0.97,
              icon: LucideIcons.clock,
            ),
            _buildKpiCard(
              title: 'Positive Rating',
              value: '4.9',
              target: 'Target 4.7',
              progress: 0.98,
              icon: LucideIcons.star,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String target,
    required double progress,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 15, color: AppColors.primary),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                target,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Earnings Snapshot Card
  Widget _buildEarningsSnapshotCard() {
    return Container(
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
              Row(
                children: [
                  const Icon(LucideIcons.wallet, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Earnings Snapshot',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'October 2026',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Earnings & Available for Withdrawal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earned in Oct',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      text: '\$${_earnedThisMonth.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: '.00',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Available for Withdrawal',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${_availableWithdrawal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: _showWithdrawModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                      label: Text(
                        'Withdraw',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Secondary Sub-metrics: Pending clearance & Active Queue
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.hourglass, size: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Clearance',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${_pendingClearance.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(LucideIcons.layers, size: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Queue Valuation',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '\$${_queueValuation.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
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

  /// 4. Active Orders / Contracts Section
  Widget _buildActiveOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Active Orders',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$_activeContractsCount',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/orders'),
              child: Text(
                'View All ($_activeContractsCount)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Pills
        Row(
          children: ['All', 'In Progress', 'Revisions'].map((filter) {
            final isSelected = _selectedContractFilter == filter;
            return GestureDetector(
              onTap: () => setState(() => _selectedContractFilter = filter),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.border,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Contracts Cards
        if (_filteredContracts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No contracts under "$_selectedContractFilter"',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          )
        else
          ..._filteredContracts.map((contract) => _buildContractCard(contract)),
      ],
    );
  }

  Widget _buildContractCard(FreelancerContract contract) {
    final bool isRevision = contract.status == ContractStatus.needsRevision;
    final bool isDelivered = contract.status == ContractStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRevision ? const Color(0xFFFDE68A) : AppColors.border,
          width: isRevision ? 1.5 : 1,
        ),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    contract.clientName[0],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${contract.orderNumber} • ${contract.clientName}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contract.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${contract.amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Status & Delivery Timer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRevision
                        ? LucideIcons.alertCircle
                        : isDelivered
                            ? LucideIcons.badgeCheck
                            : LucideIcons.clock,
                    size: 14,
                    color: isRevision
                        ? AppColors.warning
                        : isDelivered
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    contract.deliveryTimeText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isRevision ? FontWeight.w600 : FontWeight.w500,
                      color: isRevision ? AppColors.warning : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isRevision
                      ? const Color(0xFFFEF3C7)
                      : isDelivered
                          ? AppColors.primaryLight
                          : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRevision
                      ? 'Needs Revision'
                      : isDelivered
                          ? 'Delivered'
                          : 'In Progress',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isRevision
                        ? const Color(0xFFB45309)
                        : isDelivered
                            ? AppColors.primaryDark
                            : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: Message + Quick Deliver / Respond to Revision
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleMessageClient(contract),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(LucideIcons.messageSquare, size: 14),
                    label: Text(
                      'Message',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: isRevision
                        ? () => _handleRespondToRevision(contract)
                        : () => _handleQuickDeliver(contract),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRevision
                          ? const Color(0xFFD97706)
                          : isDelivered
                              ? AppColors.surfaceSecondary
                              : AppColors.primary,
                      foregroundColor: isDelivered ? AppColors.textPrimary : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      isRevision
                          ? LucideIcons.rotateCcw
                          : isDelivered
                              ? LucideIcons.checkCheck
                              : LucideIcons.send,
                      size: 14,
                    ),
                    label: Text(
                      isRevision
                          ? 'Respond to Revision'
                          : isDelivered
                              ? 'Delivered'
                              : 'Deliver Work',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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

  /// 5. Growth & Toolkit (2x2 Quick Tiles)
  Widget _buildGrowthToolkitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Growth & Toolkit',
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.8,
          children: [
            _buildToolkitCard(
              title: 'Buyer Requests',
              subtitle: 'Submit project bids',
              icon: LucideIcons.inbox,
              badgeText: '12 New',
              badgeColor: AppColors.primary,
              onTap: () {
                Navigator.of(context).pushNamed('/buyer-requests');
              },
            ),
            _buildToolkitCard(
              title: 'Promote Gigs',
              subtitle: 'Boost search reach',
              icon: LucideIcons.sparkles,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gig promotion manager loaded.')),
                );
              },
            ),
            _buildToolkitCard(
              title: 'Share Profile',
              subtitle: 'Copy showcase link',
              icon: LucideIcons.share2,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile link copied to clipboard!')),
                );
              },
            ),
            _buildToolkitCard(
              title: 'Availability',
              subtitle: _isAvailableForWork ? 'Accepting new work' : 'Vacation mode',
              icon: LucideIcons.calendar,
              badgeText: _isAvailableForWork ? 'Active' : 'Away',
              badgeColor: _isAvailableForWork ? AppColors.primary : AppColors.textSecondary,
              onTap: () {
                setState(() => _isAvailableForWork = !_isAvailableForWork);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _isAvailableForWork
                          ? 'Profile is now Active for new orders!'
                          : 'Vacation mode enabled.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolkitCard({
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.textDark),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 6. 30-Day Gig Funnel Analytics Card
  Widget _buildGigFunnelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '30-Day Gig Funnel',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Across your 3 active services',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Icon(LucideIcons.trendingUp, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Metric Blocks
          Row(
            children: [
              _buildFunnelMetricBlock('Impressions', '24.8k', '+14%'),
              const SizedBox(width: 8),
              _buildFunnelMetricBlock('Clicks', '1,420', '+8%'),
              const SizedBox(width: 8),
              _buildFunnelMetricBlock('Orders', '38', '+23%'),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversion Trend',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '2.68% conversion rate',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mini Custom Painted Trend Chart
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrendChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelMetricBlock(String label, String value, String growth) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(LucideIcons.arrowUp, size: 10, color: AppColors.primary),
                const SizedBox(width: 2),
                Text(
                  growth,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 7. Bottom Navigation Bar (5 tabs: Dashboard, Requests, Orders, Inbox, Earnings)
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: (index) {
        if (index == 1) {
          Navigator.of(context).pushNamed('/buyer-requests');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/orders');
        } else if (index == 3) {
          Navigator.of(context).pushNamed('/messages').then((_) {
            if (mounted) setState(() => _currentBottomNavIndex = 0);
          });
        } else if (index == 4) {
          Navigator.of(context).pushNamed('/escrow-payments');
        } else {
          setState(() => _currentBottomNavIndex = index);
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
    );
  }
}

/// Custom painter for smooth 30-day conversion trend wave
class _TrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.18, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.52, size.height * 0.45),
      Offset(size.width * 0.70, size.height * 0.75),
      Offset(size.width * 0.88, size.height * 0.25),
      Offset(size.width, size.height * 0.40),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
