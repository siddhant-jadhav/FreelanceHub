import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/payment_model.dart';
import '../models/project_model.dart';
import '../services/client_service.dart';

/// Screen 05 — Escrow & Payments
/// Built according to FreelanceHub Design System (docs/design.md, .agents/rules/ui-design.md)
/// Matches Stitch Screen `05 — Escrow & Payments` with 2x2 Escrow Bento,
/// Milestone release and deposit flows, FDIC protection banners, dispute handling,
/// and live transaction history.
class EscrowPaymentsScreen extends StatefulWidget {
  final double? initialEscrowAmount;
  final String? projectId;

  const EscrowPaymentsScreen({
    super.key,
    this.initialEscrowAmount,
    this.projectId,
  });

  @override
  State<EscrowPaymentsScreen> createState() => _EscrowPaymentsScreenState();
}

class _EscrowPaymentsScreenState extends State<EscrowPaymentsScreen> {
  // Escrow Balances
  late double _inEscrow;
  double _totalFunded = 2400.00;
  double _released = 1600.00;
  double _inReview = 0.00;

  // Milestone 1 (Elena) state
  bool _elenaPaymentReleased = false;
  bool _isProcessingElena = false;

  // Dynamic project & milestone context
  List<PaymentModel> _realPayments = [];
  ProjectModel? _activeProject;
  String _activeFreelancerName = 'Elena Rostova';
  double _activeMilestoneAmount = 400.0;
  String _activeMilestoneTitle = 'Mobile App MVP — Milestone 2';

  // Milestone 2 (David) state
  bool _davidMilestoneFunded = false;
  bool _isProcessingDavid = false;

  // Transactions list
  late List<Map<String, dynamic>> _transactions;

  // Payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'Visa',
      'last4': '4291',
      'isDefault': true,
      'expiry': '09/27',
      'bank': 'Chase Bank',
    }
  ];

  StreamSubscription<List<PaymentModel>>? _paymentsSub;

  @override
  void initState() {
    super.initState();
    _inEscrow = widget.initialEscrowAmount ?? 800.00;
    _initTransactions();
    _loadActiveProject();
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveProject() async {
    if (!FirebaseConfig.instance.isInitialized) return;
    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) return;
      final isClient = FirebaseService.instance.currentRole == 'client';

      List<ProjectModel> projects = [];
      if (widget.projectId != null && widget.projectId!.isNotEmpty) {
        final cleanId = widget.projectId!.replaceFirst('FH-', '');
        final p = await FirebaseService.instance.projectRepository.getProject(cleanId) ??
            await FirebaseService.instance.projectRepository.getProject(widget.projectId!);
        if (p != null) projects = [p];
      }
      if (projects.isEmpty) {
        projects = isClient
            ? await FirebaseService.instance.projectRepository.getProjectsForClient(uid)
            : await FirebaseService.instance.projectRepository.getProjectsForFreelancer(uid);
      }

      if (projects.isNotEmpty && mounted) {
        final p = projects.first;
        setState(() {
          _activeProject = p;
          if (p.freelancerName.isNotEmpty) {
            _activeFreelancerName = p.freelancerName;
          } else {
            _activeFreelancerName = isClient ? 'Siddhant Jadhav' : 'Vedant (Client)';
          }
          if (p.budget > 0) {
            _activeMilestoneAmount = p.budget;
          }
          _activeMilestoneTitle = p.title;

          if (p.status == 'completed') {
            _elenaPaymentReleased = true;
            if (_released == 0) {
              _released = p.budget;
              _totalFunded = _inEscrow + _released;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Notice loading active project in escrow: $e');
    }
  }

  void _listenToPayments() {
    if (!FirebaseConfig.instance.isInitialized) return;
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    final isClient = FirebaseService.instance.currentRole == 'client';

    Stream<List<PaymentModel>> stream;
    if (widget.projectId != null && widget.projectId!.isNotEmpty) {
      stream = FirebaseService.instance.paymentRepository
          .streamPaymentsForProject(widget.projectId!);
    } else {
      stream = FirebaseService.instance.paymentRepository
          .streamUserPayments(uid, isClient: isClient);
    }

    try {
      _paymentsSub = stream.listen((payments) {
        if (!mounted) return;
        _realPayments = payments;
        double inEscrow = 0.0;
        double released = 0.0;
        for (final p in payments) {
          if (p.status == 'held_in_escrow') {
            inEscrow += p.amount;
          } else if (p.status == 'released') {
            released += p.amount;
          }
        }
        setState(() {
          _inEscrow = inEscrow;
          _released = released;
          _totalFunded = inEscrow + released;
          if (released > 0) {
            _elenaPaymentReleased = true;
          }
          if (payments.isNotEmpty) {
            _transactions = payments.map((p) {
              final isReleased = p.status == 'released';
              return {
                'id': p.id,
                'title': isReleased ? 'Escrow Payment Released' : 'Escrow Deposit Funded',
                'subtitle': 'Project #${p.projectId.length > 5 ? p.projectId.substring(0, 5).toUpperCase() : p.projectId.toUpperCase()}',
                'amount': isReleased ? p.netAmount : p.amount,
                'status': isReleased ? 'Completed' : 'Held in Escrow',
                'isPositive': !isClient,
                'icon': isReleased ? LucideIcons.arrowUpRight : LucideIcons.lock,
                'iconColor': isReleased ? AppColors.primary : AppColors.textDark,
                'iconBg': isReleased ? AppColors.primaryLight : AppColors.surfaceContainer,
              };
            }).toList();
          }
        });
      }, onError: (e) {
        debugPrint('Error streaming payments: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming payments: $e');
    }
  }

  void _initTransactions() {
    if (FirebaseConfig.instance.isInitialized) {
      _transactions = [];
      _listenToPayments();
      return;
    }

    _transactions = [
      {
        'id': 'tx-1',
        'title': 'Milestone 1 Payment Released',
        'subtitle': 'Elena Rostova • Nov 12',
        'amount': -400.00,
        'status': 'Completed',
        'isPositive': false,
        'icon': LucideIcons.arrowUpRight,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      },
      {
        'id': 'tx-2',
        'title': 'Escrow Deposit — Task #4829',
        'subtitle': 'Funded to Escrow • Nov 08',
        'amount': -800.00,
        'status': 'Held in Escrow',
        'isPositive': false,
        'icon': LucideIcons.lock,
        'iconColor': AppColors.textDark,
        'iconBg': AppColors.surfaceContainer,
      },
      {
        'id': 'tx-3',
        'title': 'Refund Processed — Task #4120',
        'subtitle': 'Returned to Card • Oct 28',
        'amount': 150.00,
        'status': 'Refunded',
        'isPositive': true,
        'icon': LucideIcons.rotateCcw,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      },
    ];
  }

  // --- Actions ---

  void _handleReleaseElenaPayment() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Release Escrow Payment',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Release \$${_activeMilestoneAmount.toStringAsFixed(2)} from Escrow to $_activeFreelancerName for $_activeMilestoneTitle?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.lock, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Escrow Guarantee. This will mark the milestone as completed and transfer \$${_activeMilestoneAmount.toStringAsFixed(2)} to the freelancer.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeElenaRelease();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Confirm & Release (\$${_activeMilestoneAmount.toStringAsFixed(0)})',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeElenaRelease() async {
    setState(() => _isProcessingElena = true);

    // Live Firebase call if configured
    if (FirebaseConfig.instance.isInitialized) {
      try {
        PaymentModel? escrowPayment;
        try {
          escrowPayment = _realPayments.firstWhere(
            (p) => p.status == 'held_in_escrow',
          );
        } catch (_) {}

        if (escrowPayment == null && widget.projectId != null) {
          final payments = await FirebaseService.instance.paymentRepository
              .getPaymentsForProject(widget.projectId!);
          try {
            escrowPayment = payments.firstWhere(
              (p) => p.status == 'held_in_escrow',
            );
          } catch (_) {}
        }

        if (escrowPayment != null) {
          await ClientService.instance.releaseMilestoneEscrow(escrowPayment.id);
          if (escrowPayment.projectId.isNotEmpty) {
            final cleanId = escrowPayment.projectId.replaceFirst('FH-', '');
            await FirebaseService.instance.projectRepository
                .updateProjectStatus(cleanId, 'completed').catchError((_) {});
            await FirebaseService.instance.projectRepository
                .updateProjectStatus(escrowPayment.projectId, 'completed').catchError((_) {});
          }
        } else {
          final prj = _activeProject;
          final pId = prj?.id ?? widget.projectId ?? 'active_project';
          final fId = prj?.freelancerId ?? 'dGHpEXlNcJVaQkV9pQfXuSvAl0y2';
          await ClientService.instance.reviewMilestoneDeliverable(
            projectId: pId,
            milestoneId: 'm-final',
            freelancerId: fId,
            milestoneTitle: _activeMilestoneTitle,
            amount: _activeMilestoneAmount,
            approved: true,
          );
        }
      } catch (e) {
        debugPrint('Release notice: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final amountReleased = _activeMilestoneAmount;

    setState(() {
      _isProcessingElena = false;
      _elenaPaymentReleased = true;
      _inEscrow = (_inEscrow - amountReleased).clamp(0.0, 999999.0);
      _released += amountReleased;

      _transactions.insert(0, {
        'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Milestone Payment Released',
        'subtitle': '$_activeFreelancerName • Just now',
        'amount': -amountReleased,
        'status': 'Completed',
        'isPositive': false,
        'icon': LucideIcons.arrowUpRight,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payment of \$${amountReleased.toStringAsFixed(2)} released successfully to $_activeFreelancerName!',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleDispute() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.shieldAlert, size: 22, color: AppColors.warning),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mediation & Dispute Request',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Funds for Milestone 2 remain safely locked in Escrow. A dedicated FreelanceHub dispute specialist will review deliverables and contact both parties within 4 hours.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _inReview += 400.00;
                    _inEscrow = (_inEscrow - 400.00).clamp(0.0, 999999.0);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dispute opened. Mediation team alerted.'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Submit Dispute for Mediation',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleFundDavidMilestone() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lock, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Deposit & Fund Milestone',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deposit \$400.00 into Escrow for David Chen: Landing Page Redesign — Final Delivery.',
                style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: AppColors.textDark),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.creditCard, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Charge to Chase Visa •••• 4291',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Funds held safely in escrow until you approve delivery.',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeDavidFunding();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Deposit \$400.00',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDavidFunding() async {
    setState(() => _isProcessingDavid = true);

    if (FirebaseConfig.instance.isInitialized && widget.projectId != null) {
      try {
        await ClientService.instance.fundMilestoneEscrow(
          projectId: widget.projectId!,
          milestoneId: 'm-david-final',
          freelancerId: 'f-2',
          amount: 400.00,
        );
      } catch (e) {
        debugPrint('Funding notice: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isProcessingDavid = false;
      _davidMilestoneFunded = true;
      _inEscrow += 400.00;
      _totalFunded += 400.00;

      _transactions.insert(0, {
        'id': 'tx-${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Escrow Deposit — Landing Page Redesign',
        'subtitle': 'Funded to Escrow • Just now',
        'amount': -400.00,
        'status': 'Held in Escrow',
        'isPositive': false,
        'icon': LucideIcons.lock,
        'iconColor': AppColors.textDark,
        'iconBg': AppColors.surfaceContainer,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Milestone Funded! \$400.00 deposited safely into Escrow.',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleAddPaymentMethod() {
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                const SizedBox(height: 20),
                Text(
                  'Add Payment Method',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Saved securely for seamless milestone funding and escrow deposits.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    hintText: '4000 1234 5678 9010',
                    prefixIcon: const Icon(LucideIcons.creditCard, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryController,
                        decoration: InputDecoration(
                          labelText: 'Expires (MM/YY)',
                          hintText: '12/28',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Security Code (CVV)',
                          hintText: '123',
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final raw = cardNumberController.text.trim();
                    final last4 = raw.length >= 4 ? raw.substring(raw.length - 4) : '8834';
                    Navigator.pop(ctx);
                    setState(() {
                      _paymentMethods.add({
                        'type': 'Mastercard',
                        'last4': last4,
                        'isDefault': false,
                        'expiry': expiryController.text.isNotEmpty ? expiryController.text : '12/28',
                        'bank': 'Citibank',
                      });
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Card ending in •••• $last4 added successfully.'),
                        backgroundColor: AppColors.primaryDark,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Save Payment Method',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDownloadStatements() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.fileText, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Financial Statements',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'Exporting monthly escrow transactions and invoices for 2024 (PDF & CSV).',
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppColors.textDark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Statements exported! Check your Downloads folder.'),
                    backgroundColor: AppColors.primaryDark,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(LucideIcons.download, size: 16, color: Colors.white),
              label: const Text('Download PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Escrow Protection Trust Banner
              _buildTrustBanner(),
              const SizedBox(height: 14),

              // 2. Escrow Summary Cards (2x2 Grid)
              _buildSummary2x2Grid(),
              const SizedBox(height: 20),

              // 3. Active Milestones Section
              _buildActiveMilestonesSection(),
              const SizedBox(height: 20),

              // 4. Payment Methods Section
              _buildPaymentMethodsSection(),
              const SizedBox(height: 14),

              // 5. FDIC Trust Banner Card
              _buildFdicBannerCard(),
              const SizedBox(height: 20),

              // 6. Recent Transactions Section
              _buildRecentTransactionsSection(),
              const SizedBox(height: 14),

              // 7. Download Statements Action
              _buildDownloadStatementsCard(),
              const SizedBox(height: 16),

              // 8. Footer Guarantee
              _buildFooterGuarantee(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final role = FirebaseService.instance.currentRole;
    final isFreelancer = role == 'freelancer';

    if (isFreelancer) {
      return BottomNavigationBar(
        currentIndex: 4, // Earnings tab
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/buyer-requests');
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/orders');
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

    return BottomNavigationBar(
      currentIndex: 4, // Escrow tab
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).pushReplacementNamed('/client-home');
        } else if (index == 1) {
          Navigator.of(context).pushNamed('/post-task');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/project-workspace');
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
          icon: Icon(LucideIcons.house, size: 22),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.circlePlus, size: 22),
          label: 'Post Task',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.briefcase, size: 22),
          label: 'Projects',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.messageSquare, size: 22),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.shieldCheck, size: 22),
          label: 'Escrow',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, size: 22, color: AppColors.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'FreelanceHub'),
                TextSpan(
                  text: '.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Escrow Payments',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Messages',
          icon: const Icon(LucideIcons.messageSquare, size: 20, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pushNamed('/messages'),
        ),
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(LucideIcons.logOut, size: 20, color: AppColors.textSecondary),
          onPressed: () async {
            await FirebaseService.instance.signOut();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'FreelanceHub Escrow Protection',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Funds are securely held and only released to freelancers once you thoroughly review and approve completed deliverables.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrustStripItem(LucideIcons.lock, '256-bit Encrypted'),
              _buildTrustStripItem(LucideIcons.scale, 'Dispute Mediation'),
              _buildTrustStripItem(LucideIcons.refreshCcw, 'Money-Back Guarantee'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustStripItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.primaryDark),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '\$$intPart.${parts[1]}';
  }

  Widget _buildSummary2x2Grid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        // Card 1: In Escrow (Highlighted)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IN ESCROW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Icon(LucideIcons.shield, size: 16, color: AppColors.primary),
                ],
              ),
              Text(
                _formatCurrency(_inEscrow),
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.primaryDark,
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
                    'Protected & Safe',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card 2: Total Funded
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                    'TOTAL FUNDED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Icon(LucideIcons.wallet, size: 16, color: AppColors.textSecondary),
                ],
              ),
              Text(
                _formatCurrency(_totalFunded),
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Across 2 projects',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Card 3: Released
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                    'RELEASED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Icon(LucideIcons.circleCheck, size: 16, color: AppColors.textSecondary),
                ],
              ),
              Text(
                _formatCurrency(_released),
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Paid out cleanly',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Card 4: In Review
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                    'IN REVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Icon(LucideIcons.hourglass, size: 16, color: AppColors.textSecondary),
                ],
              ),
              Text(
                _formatCurrency(_inReview),
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _inReview > 0 ? '1 claim pending' : 'No pending claims',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Milestones',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '2 Active',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Milestone 1 (Elena Rostova)
        _buildElenaMilestoneCard(),
        const SizedBox(height: 12),

        // Milestone 2 (David Chen)
        _buildDavidMilestoneCard(),
      ],
    );
  }

  Widget _buildElenaMilestoneCard() {
    final initials = _activeFreelancerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'SJ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Freelancer',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        _activeFreelancerName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _elenaPaymentReleased ? AppColors.surfaceContainer : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _elenaPaymentReleased ? 'Paid' : 'Held in Escrow',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _elenaPaymentReleased ? AppColors.textSecondary : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeMilestoneTitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scope: High-fidelity screens and interaction prototypes',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'Due Nov 24',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      '\$${_activeMilestoneAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_elenaPaymentReleased) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment of \$${_activeMilestoneAmount.toStringAsFixed(2)} released successfully to $_activeFreelancerName!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessingElena ? null : _handleReleaseElenaPayment,
              icon: _isProcessingElena
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.banknote, size: 16, color: Colors.white),
              label: Text(
                'Release Payment',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _handleDispute,
                icon: const Icon(LucideIcons.shieldAlert, size: 14, color: AppColors.textSecondary),
                label: Text(
                  'Dispute / Request Revision',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDavidMilestoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'DC',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Freelancer',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        'David Chen',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _davidMilestoneFunded ? AppColors.primaryLight : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _davidMilestoneFunded ? 'Held in Escrow' : 'Unfunded',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _davidMilestoneFunded ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Landing Page Redesign — Final Delivery',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Scope: Responsive Tailwind markup and deployment',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'Due Dec 02',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      '\$400.00',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessingDavid || _davidMilestoneFunded ? null : _handleFundDavidMilestone,
            icon: _isProcessingDavid
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    _davidMilestoneFunded ? LucideIcons.check : LucideIcons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
            label: Text(
              _davidMilestoneFunded ? 'Milestone Funded ✓' : 'Deposit & Fund Milestone',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _davidMilestoneFunded ? AppColors.primaryDark : AppColors.textDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_paymentMethods.length} on file',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ..._paymentMethods.map((pm) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Icon(LucideIcons.creditCard, size: 17, color: AppColors.textDark),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${pm['type']} ending in •••• ${pm['last4']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (pm['isDefault'] == true) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                'Expires ${pm['expiry']} • ${pm['bank']}',
                                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textSecondary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: _handleAddPaymentMethod,
                icon: const Icon(LucideIcons.plus, size: 15, color: AppColors.textDark),
                label: Text(
                  'Add New Payment Method',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFdicBannerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.landmark, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FDIC-Insured Partner Trust Accounts',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your funds are kept separate from operational accounts at regulated financial institutions.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Past 30 Days',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.receiptText,
                  size: 40,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(height: 10),
                Text(
                  'No transactions recorded yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Escrow deposits and released payments will appear here.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
            separatorBuilder: (ctx, index) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (ctx, index) {
              final tx = _transactions[index];
              final amount = tx['amount'] as double;
              final isPositive = tx['isPositive'] as bool;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tx['iconBg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(tx['icon'] as IconData, size: 17, color: tx['iconColor'] as Color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx['subtitle'] as String,
                            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isPositive ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? AppColors.primaryLight
                                : (tx['status'] == 'Held in Escrow'
                                    ? AppColors.surfaceContainer
                                    : AppColors.primaryLight),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx['status'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPositive
                                  ? AppColors.primaryDark
                                  : (tx['status'] == 'Held in Escrow'
                                      ? AppColors.textDark
                                      : AppColors.primaryDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadStatementsCard() {
    return InkWell(
      onTap: _handleDownloadStatements,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.receipt, size: 18, color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Tax Invoices & Statements',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF, CSV statement exports for 2024',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(LucideIcons.arrowRight, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterGuarantee() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          'Protected by FreelanceHub Guarantee · 100% Secure Checkout',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
