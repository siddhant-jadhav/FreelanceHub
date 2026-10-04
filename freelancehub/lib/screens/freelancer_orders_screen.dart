import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/order_model.dart';
import '../models/project_model.dart';

/// Freelancer Orders Listing Screen.
/// Lists all active and historical client deliveries/orders with filtering,
/// status tracking, and seamless drill-down to the detailed Order Delivery Page.
class FreelancerOrdersScreen extends StatefulWidget {
  const FreelancerOrdersScreen({super.key});

  @override
  State<FreelancerOrdersScreen> createState() => _FreelancerOrdersScreenState();
}

class _FreelancerOrdersScreenState extends State<FreelancerOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'In Progress', 'In Revision', 'Completed'
  late List<FreelanceOrder> _orders;
  StreamSubscription<List<ProjectModel>>? _ordersSub;

  @override
  void initState() {
    super.initState();
    _enforceFreelancerRole();
    _initializeOrders();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _enforceFreelancerRole() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = FirebaseService.instance.currentRole;
      if (role == 'client') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access restricted: Clients cannot view freelancer orders.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    });
  }

  void _listenToFreelancerOrders() {
    if (!FirebaseConfig.instance.isInitialized) return;
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      _ordersSub = FirebaseService.instance.projectRepository
          .streamProjectsForFreelancer(uid)
          .listen((projects) {
        if (!mounted) return;
        setState(() {
          _orders = projects.map((p) {
            final totalDuration = p.dueDate.difference(p.startedDate).inDays.clamp(1, 120);
            final progress = p.progress > 0 ? p.progress : (p.completedMilestones / (p.totalMilestones > 0 ? p.totalMilestones : 1));

            OrderStatus status = OrderStatus.inProgress;
            if (p.status == 'completed') {
              status = OrderStatus.completed;
            } else if (p.status == 'review') {
              status = OrderStatus.delivered;
            } else if (p.status == 'revision') {
              status = OrderStatus.inRevision;
            }

            return FreelanceOrder(
              id: p.id.startsWith('FH-') ? p.id : 'FH-${p.id.length > 5 ? p.id.substring(0, 5).toUpperCase() : p.id.toUpperCase()}',
              clientName: p.clientName.isNotEmpty ? p.clientName : 'Client',
              clientCompany: 'Verified Client',
              clientCountry: 'United States',
              isClientVerified: true,
              clientRating: 5.0,
              gigTitle: p.title,
              gigTier: 'Custom Contract',
              budget: p.budget,
              startedDate: p.startedDate,
              dueDate: p.dueDate,
              totalDays: totalDuration,
              progressPercent: progress.clamp(0.0, 1.0),
              status: status,
              clientBrief: 'Project active under Escrow Protection.',
              briefFiles: const [],
              timeline: [
                OrderTimelineEvent(
                  title: 'Order started by ${p.clientName.isNotEmpty ? p.clientName : 'Client'}',
                  time: 'Active',
                ),
              ],
            );
          }).toList();
        });
      }, onError: (e) {
        debugPrint('Error streaming freelancer orders: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming freelancer orders: $e');
    }
  }

  void _initializeOrders() {
    if (FirebaseConfig.instance.isInitialized) {
      _orders = [];
      _listenToFreelancerOrders();
      return;
    }
    final now = DateTime.now();
    _orders = [
      // Order 1: Sarah Jenkins (Matches Stitch reference screen!)
      FreelanceOrder(
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
      ),

      // Order 2: Marcus Vance (In Revision)
      FreelanceOrder(
        id: 'FH-9740',
        clientName: 'Marcus Vance',
        clientCompany: 'Vance Growth Labs',
        clientCountry: 'United Kingdom',
        isClientVerified: true,
        clientRating: 4.9,
        gigTitle: 'TechCorp SaaS Brand Identity & Design System',
        gigTier: 'Tier: Standard Brand Guidelines + Vector Assets',
        budget: 850.00,
        startedDate: now.subtract(const Duration(days: 4)),
        dueDate: now.add(const Duration(days: 2)),
        totalDays: 6,
        progressPercent: 0.85,
        status: OrderStatus.inRevision,
        clientBrief:
            'Please revise the dark-mode color tokens and provide 3 additional logo lockups for mobile header.',
        briefFiles: const [
          OrderRequirementFile(
            fileName: 'Client_Revision_Notes.pdf',
            fileSize: '2.1 MB',
            fileType: 'pdf',
          ),
        ],
        timeline: const [
          OrderTimelineEvent(
            title: 'Order started by Marcus Vance',
            time: 'Oct 21 • 09:00 AM',
          ),
          OrderTimelineEvent(
            title: 'Revision requested by Marcus Vance',
            time: 'Yesterday • 4:20 PM',
            isClientMessage: true,
            senderName: 'Marcus Vance',
            description:
                'We love the primary mark! Just need slight adjustment on the contrast ratio for accessibility compliance.',
          ),
        ],
        deliveredFileName: 'Brand_Identity_v1.1.zip',
        deliveredFileSize: '38.0 MB',
      ),

      // Order 3: Elena Rostova (In Progress)
      FreelanceOrder(
        id: 'FH-9620',
        clientName: 'Elena Rostova',
        clientCompany: 'Nordic Retail Group',
        clientCountry: 'Germany',
        isClientVerified: true,
        clientRating: 5.0,
        gigTitle: 'Mobile UI Kit Components & Interactive Prototyping',
        gigTier: 'Tier: Basic 8 Component Pack',
        budget: 650.00,
        startedDate: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 4)),
        totalDays: 5,
        progressPercent: 0.35,
        status: OrderStatus.inProgress,
        clientBrief:
            'Design 8 clean product display cards and checkout navigation sheet for our Nordic clothing catalog app.',
        briefFiles: const [
          OrderRequirementFile(
            fileName: 'Nordic_App_Wireframe_v1.pdf',
            fileSize: '8.4 MB',
            fileType: 'pdf',
          ),
        ],
        timeline: const [
          OrderTimelineEvent(
            title: 'Order started by Elena Rostova',
            time: 'Oct 23 • 02:15 PM',
          ),
        ],
      ),

      // Order 4: David Sterling (Completed)
      FreelanceOrder(
        id: 'FH-9510',
        clientName: 'David Sterling',
        clientCompany: 'Sterling Media',
        clientCountry: 'Canada',
        isClientVerified: true,
        clientRating: 4.8,
        gigTitle: 'E-Commerce Checkout & Micro-interactions',
        gigTier: 'Tier: Complete Conversion UX Audit',
        budget: 380.00,
        startedDate: now.subtract(const Duration(days: 10)),
        dueDate: now.subtract(const Duration(days: 2)),
        totalDays: 7,
        progressPercent: 1.0,
        status: OrderStatus.completed,
        clientBrief:
            'Streamline multi-step checkout into one-page express pay flow with Apple Pay and Google Pay integration.',
        briefFiles: const [
          OrderRequirementFile(
            fileName: 'Old_Checkout_Screens.zip',
            fileSize: '18.5 MB',
            fileType: 'zip',
          ),
        ],
        timeline: const [
          OrderTimelineEvent(
            title: 'Order delivered and approved',
            time: 'Oct 20 • 06:40 PM',
          ),
        ],
      ),
    ];
  }

  List<FreelanceOrder> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      // Category filter
      if (_selectedFilter == 'In Progress' && order.status != OrderStatus.inProgress) {
        return false;
      }
      if (_selectedFilter == 'In Revision' && order.status != OrderStatus.inRevision) {
        return false;
      }
      if (_selectedFilter == 'Completed' && order.status != OrderStatus.completed) {
        return false;
      }

      // Keyword search
      if (query.isNotEmpty) {
        final idMatch = order.id.toLowerCase().contains(query);
        final nameMatch = order.clientName.toLowerCase().contains(query);
        final titleMatch = order.gigTitle.toLowerCase().contains(query);
        final companyMatch = order.clientCompany.toLowerCase().contains(query);
        if (!idMatch && !nameMatch && !titleMatch && !companyMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final activeOrdersCount = _orders.where((o) => o.status == OrderStatus.inProgress || o.status == OrderStatus.inRevision).length;
    final totalActiveValue = _orders
        .where((o) => o.status == OrderStatus.inProgress || o.status == OrderStatus.inRevision)
        .fold(0.0, (sum, o) => sum + o.budget);

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
                    // 1. KPI Summary Banner
                    _buildKpiBanner(activeOrdersCount, totalActiveValue),
                    const SizedBox(height: 16),

                    // 2. Search Field
                    _buildSearchField(),
                    const SizedBox(height: 14),

                    // 3. Status Filter Chips
                    _buildFilterChips(),
                    const SizedBox(height: 16),

                    // 4. Headline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filtered.length} Orders',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$activeOrdersCount Active Deliveries',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Order Cards List
                    if (filtered.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Icon(
                              LucideIcons.packageOpen,
                              size: 44,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No orders found',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try selecting another filter or clear your search query.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filtered.map((order) => _buildOrderCard(order)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Orders tab active
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/buyer-requests');
          } else if (index != 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(index == 3 ? 'Opening Inbox...' : 'Opening Earnings...'),
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
            'Manage Orders',
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
          icon: const Icon(LucideIcons.layoutDashboard, size: 19, color: AppColors.textSecondary),
          tooltip: 'Dashboard',
          onPressed: () => Navigator.of(context).pushReplacementNamed('/freelancer-dashboard'),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.border, height: 1),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. KPI SUMMARY BANNER
  // ---------------------------------------------------------------------------
  Widget _buildKpiBanner(int activeCount, double activeValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Orders',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  '$activeCount Orders',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In Escrow',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${activeValue.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On-Time Rate',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '100%',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SEARCH FIELD
  // ---------------------------------------------------------------------------
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search by Order ID, client, or gig...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled),
          prefixIcon: const Icon(LucideIcons.search, size: 17, color: AppColors.textSecondary),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. FILTER CHIPS
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips() {
    final filters = ['All', 'In Progress', 'In Revision', 'Completed'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          int count = 0;
          if (filter == 'All') {
            count = _orders.length;
          } else if (filter == 'In Progress') {
            count = _orders.where((o) => o.status == OrderStatus.inProgress).length;
          } else if (filter == 'In Revision') {
            count = _orders.where((o) => o.status == OrderStatus.inRevision).length;
          } else if (filter == 'Completed') {
            count = _orders.where((o) => o.status == OrderStatus.completed).length;
          }

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
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
                '$filter ($count)',
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

  // ---------------------------------------------------------------------------
  // 4. ORDER CARD (Clickable to open Detail Screen)
  // ---------------------------------------------------------------------------
  Widget _buildOrderCard(FreelanceOrder order) {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.inProgress:
        statusColor = AppColors.primary;
        statusBg = AppColors.primaryLight;
        statusIcon = LucideIcons.clock;
        break;
      case OrderStatus.inRevision:
        statusColor = AppColors.warning;
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = LucideIcons.refreshCw;
        break;
      case OrderStatus.delivered:
        statusColor = AppColors.primaryDark;
        statusBg = AppColors.primaryLight;
        statusIcon = LucideIcons.badgeCheck;
        break;
      case OrderStatus.completed:
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = LucideIcons.checkCheck;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = LucideIcons.ban;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToOrderDetail(order),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              order.status.label,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${order.budget.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Client row
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      order.clientName.substring(0, 1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.clientName,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (order.isClientVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.badgeCheck, size: 13, color: AppColors.primary),
                  ],
                  const SizedBox(width: 6),
                  const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.clientCompany,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Gig Title
              Text(
                order.gigTitle,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                order.gigTier,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.status == OrderStatus.completed
                            ? 'Delivered & Accepted'
                            : 'Delivery Progress (${(order.progressPercent * 100).toInt()}%)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        order.status == OrderStatus.completed
                            ? 'Completed'
                            : 'Due Tomorrow, 11:59 PM',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: order.status == OrderStatus.completed
                              ? AppColors.textSecondary
                              : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: order.progressPercent,
                      backgroundColor: AppColors.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        order.status == OrderStatus.completed ? AppColors.primary : AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),

              // Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.paperclip, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${order.briefFiles.length} Brief files',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToOrderDetail(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: order.status == OrderStatus.completed
                          ? AppColors.surfaceSecondary
                          : AppColors.primary,
                      foregroundColor: order.status == OrderStatus.completed
                          ? AppColors.textDark
                          : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: order.status == OrderStatus.completed
                            ? const BorderSide(color: AppColors.border)
                            : BorderSide.none,
                      ),
                    ),
                    icon: Icon(
                      order.status == OrderStatus.inRevision
                          ? LucideIcons.refreshCw
                          : order.status == OrderStatus.completed
                              ? LucideIcons.eye
                              : LucideIcons.send,
                      size: 13,
                    ),
                    label: Text(
                      order.status == OrderStatus.inRevision
                          ? 'Respond to Revision'
                          : order.status == OrderStatus.completed
                              ? 'View Delivery'
                              : 'Deliver Work',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToOrderDetail(FreelanceOrder order) async {
    final result = await Navigator.pushNamed(
      context,
      '/order-delivery',
      arguments: order,
    );
    if (result == true) {
      setState(() {
        order.status = OrderStatus.delivered;
      });
    }
  }
}
