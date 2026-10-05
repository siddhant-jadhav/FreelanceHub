import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/message_model.dart';
import '../models/proposal_model.dart';
import '../models/task_model.dart';

/// Screen 03 — Task Details & Proposals
/// Built according to FreelanceHub Design System (docs/design.md, .agents/rules/ui-design.md)
/// Matches Stitch Screen `03 — Task Details & Proposals` with live Firestore DB integration,
/// Lucide iconography, escrow protection workflows, and responsive layout.
class TaskDetailsProposalsScreen extends StatefulWidget {
  final TaskModel? initialTask;
  final String? taskId;

  const TaskDetailsProposalsScreen({
    super.key,
    this.initialTask,
    this.taskId,
  });

  @override
  State<TaskDetailsProposalsScreen> createState() => _TaskDetailsProposalsScreenState();
}

class _TaskDetailsProposalsScreenState extends State<TaskDetailsProposalsScreen> {
  TaskModel? _task;
  List<ProposalModel> _proposals = [];
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;
  StreamSubscription<List<ProposalModel>>? _proposalsSub;

  // Filter state: 'all', 'shortlisted', 'top_rated'
  String _activeFilter = 'all';

  // Sort state: 'highest_rating', 'price_low', 'price_high', 'newest'
  String _activeSort = 'highest_rating';

  @override
  void initState() {
    super.initState();
    _loadTaskAndProposals();
  }

  @override
  void dispose() {
    _proposalsSub?.cancel();
    super.dispose();
  }

  void _listenToProposals(String taskId) {
    _proposalsSub?.cancel();
    if (!FirebaseConfig.instance.isInitialized) return;
    try {
      _proposalsSub = FirebaseService.instance.proposalRepository
          .streamProposalsForTask(taskId)
          .listen((props) {
        if (!mounted) return;
        setState(() {
          _proposals = props;
        });
      }, onError: (e) {
        debugPrint('Error streaming proposals: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming proposals: $e');
    }
  }

  /// Calculates human-friendly relative time (e.g. '3h ago')
  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  /// Default baseline task matching Stitch specs when DB is freshly initialized
  TaskModel _buildDefaultTask() {
    return TaskModel(
      id: 'task_stitch_flutter_mvp',
      clientId: FirebaseService.instance.currentUser?.uid ?? 'client_apex_solutions',
      clientName: 'Apex Solutions',
      title: 'Flutter Mobile App UI Implementation for Freelance Marketplace',
      description:
          'We have finalized comprehensive Figma designs and need a production-ready Flutter frontend with clean state management (BLoC or Riverpod preferred). Must support adaptive layouts, fluid transitions, and modular folder structure compatible with existing RESTful APIs.',
      category: 'Mobile Apps',
      requiredSkills: const ['Flutter', 'Dart', 'Firebase', 'UI Kit', 'Figma to Code'],
      budget: 1200.0,
      budgetType: 'fixed',
      deadline: DateTime.now().add(const Duration(days: 14)),
      status: 'open',
      offersCount: 8,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    );
  }

  /// Default baseline proposals matching Stitch Elena Rostova & Marcus Vance
  List<ProposalModel> _buildDefaultProposals(String taskId, String taskTitle) {
    final now = DateTime.now();
    return [
      ProposalModel(
        id: 'prop_elena_rostova',
        taskId: taskId,
        taskTitle: taskTitle,
        freelancerId: 'freelancer_elena_rostova',
        freelancerName: 'Elena Rostova',
        freelancerTitle: 'Top Rated Plus Flutter & Dart Expert',
        freelancerRating: 4.98,
        reviewsCount: 142,
        jobSuccessScore: 100,
        clientId: _task?.clientId ?? 'client_apex_solutions',
        proposedPrice: 1150.0,
        deliveryTimeDays: 10,
        revisionsCount: 3,
        coverLetter:
            'Hi! I reviewed your Figma specs. I\'ve built 12+ production Flutter apps with clean BLoC architecture. I can deliver pixel-perfect screens, 60fps micro-animations, and full mock services in under 10 days.',
        skills: const ['Flutter', 'Dart', 'BLoC / Riverpod', 'Custom Animations'],
        isShortlisted: true,
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 1)),
        portfolioItems: const [
          {
            'title': 'CryptoWallet Mobile UI',
            'subtitle': 'Flutter • 4.9 Rating',
            'tag': 'Mobile',
          },
          {
            'title': 'ShopGig Platform App',
            'subtitle': 'Full Stack App • 2024',
            'tag': 'Marketplace',
          },
        ],
      ),
      ProposalModel(
        id: 'prop_marcus_vance',
        taskId: taskId,
        taskTitle: taskTitle,
        freelancerId: 'freelancer_marcus_vance',
        freelancerName: 'Marcus Vance',
        freelancerTitle: 'Full-Stack Mobile Engineer',
        freelancerRating: 4.90,
        reviewsCount: 67,
        jobSuccessScore: 96,
        clientId: _task?.clientId ?? 'client_apex_solutions',
        proposedPrice: 1200.0,
        deliveryTimeDays: 14,
        revisionsCount: 2,
        coverLetter:
            'Available to start immediately. I specialize in integrating Firebase auth, real-time messaging, and custom UI components directly derived from design tokens. Let\'s sync today!',
        skills: const ['Flutter', 'Firebase Auth', 'Cloud Firestore'],
        isShortlisted: false,
        status: 'pending',
        createdAt: now.subtract(const Duration(hours: 2)),
        portfolioItems: const [
          {
            'title': 'SaaS Dashboard App',
            'subtitle': 'Flutter + Firebase',
            'tag': 'Enterprise',
          },
        ],
      ),
    ];
  }

  /// Load task and proposal data from Cloud Firestore with graceful fallback
  Future<void> _loadTaskAndProposals() async {
    setState(() => _isLoading = true);

    try {
      TaskModel? loadedTask = widget.initialTask;

      if (loadedTask == null && widget.taskId != null && FirebaseConfig.instance.isInitialized) {
        loadedTask = await FirebaseService.instance.clientService.getTask(widget.taskId!);
      }

      // If still null, query client's latest task from DB
      if (loadedTask == null && FirebaseConfig.instance.isInitialized) {
        final currentUid = FirebaseService.instance.currentUser?.uid;
        if (currentUid != null) {
          final clientTasks = await FirebaseService.instance.taskRepository.getClientTasks(currentUid);
          if (clientTasks.isNotEmpty) {
            loadedTask = clientTasks.first;
          }
        }
      }

      // Fallback baseline
      loadedTask ??= _buildDefaultTask();

      List<ProposalModel> loadedProposals = [];
      if (FirebaseConfig.instance.isInitialized && loadedTask.id.isNotEmpty) {
        loadedProposals = await FirebaseService.instance.clientService.getTaskProposals(loadedTask.id);
        _listenToProposals(loadedTask.id);
      } else {
        // Only seed default baseline proposals in standalone tests where Firebase is uninitialized
        loadedProposals = _buildDefaultProposals(loadedTask.id, loadedTask.title);
      }

      if (mounted) {
        setState(() {
          _task = loadedTask;
          _proposals = loadedProposals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading task details: $e');
      if (mounted) {
        final defaultTask = _buildDefaultTask();
        setState(() {
          _task = defaultTask;
          _proposals = _buildDefaultProposals(defaultTask.id, defaultTask.title);
          _isLoading = false;
        });
      }
    }
  }

  /// Get filtered and sorted list of candidate proposals
  List<ProposalModel> get _filteredProposals {
    List<ProposalModel> list = List.from(_proposals);

    // Apply Filter Tab
    if (_activeFilter == 'shortlisted') {
      list = list.where((p) => p.isShortlisted).toList();
    } else if (_activeFilter == 'top_rated') {
      list = list.where((p) => p.freelancerRating >= 4.90).toList();
    }

    // Apply Sort
    switch (_activeSort) {
      case 'highest_rating':
        list.sort((a, b) => b.freelancerRating.compareTo(a.freelancerRating));
        break;
      case 'price_low':
        list.sort((a, b) => a.proposedPrice.compareTo(b.proposedPrice));
        break;
      case 'price_high':
        list.sort((a, b) => b.proposedPrice.compareTo(a.proposedPrice));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  /// Toggle bookmark / shortlisted status for a proposal
  Future<void> _toggleShortlist(ProposalModel proposal) async {
    final newStatus = !proposal.isShortlisted;
    setState(() {
      final index = _proposals.indexWhere((p) => p.id == proposal.id);
      if (index != -1) {
        _proposals[index] = proposal.copyWith(isShortlisted: newStatus);
      }
    });

    try {
      if (FirebaseConfig.instance.isInitialized) {
        await FirebaseService.instance.clientService.toggleShortlistProposal(
          proposalId: proposal.id,
          isShortlisted: newStatus,
        );
      }
    } catch (e) {
      debugPrint('Shortlist toggle notice: $e');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? '${proposal.freelancerName} added to Shortlist.'
              : '${proposal.freelancerName} removed from Shortlist.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show Message dialog / bottom sheet
  void _showMessageModal(ProposalModel proposal) {
    final msgCtrl = TextEditingController(
      text: 'Hi ${proposal.freelancerName.split(' ').first}, thanks for your proposal! I\'d like to discuss the scope with you.',
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message ${proposal.freelancerName}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          proposal.freelancerTitle ?? 'Flutter Specialist',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
              TextField(
                controller: msgCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final note = msgCtrl.text.trim();

                    String? activeConvId;
                    try {
                      if (FirebaseConfig.instance.isInitialized) {
                        final currentUid = FirebaseService.instance.currentUser?.uid;
                        final currentName = FirebaseService.instance.currentUser?.displayName ?? 'Client';
                        if (currentUid != null) {
                          final convId = await FirebaseService.instance.messageRepository.getOrCreateConversation(
                            currentUserId: currentUid,
                            currentUserName: currentName,
                            recipientUserId: proposal.freelancerId,
                            recipientUserName: proposal.freelancerName,
                            projectId: widget.taskId,
                          );
                          activeConvId = convId;
                          await FirebaseService.instance.messageRepository.sendMessage(
                            MessageModel(
                              id: '',
                              conversationId: convId,
                              senderId: currentUid,
                              receiverId: proposal.freelancerId,
                              message: note,
                              createdAt: DateTime.now(),
                            ),
                          );
                          await FirebaseService.instance.notificationService.notifyNewMessage(
                            recipientUserId: proposal.freelancerId,
                            senderName: currentName,
                            messageSnippet: note,
                            conversationId: convId,
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error sending message: $e');
                    }

                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Message sent to ${proposal.freelancerName}!'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Open Chat',
                          textColor: Colors.white,
                          onPressed: () {
                            try {
                              Navigator.of(context).pushNamed(
                                '/chat',
                                arguments: {
                                  'conversationId': activeConvId ?? 'conv_${proposal.freelancerId}',
                                  'otherUserName': proposal.freelancerName,
                                  'otherUserRole': 'Freelancer',
                                  'otherUserId': proposal.freelancerId,
                                  'projectTitle': _task?.title ?? 'Proposal Discussion',
                                },
                              );
                            } catch (_) {}
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
                  label: Text(
                    'Send Message',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Accept Proposal & Escrow Confirmation Modal
  void _showAcceptProposalModal(ProposalModel proposal) {
    if (_task == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          LucideIcons.shieldCheck,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accept & Fund Escrow',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Secured by FreelanceHub Guarantee',
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
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Freelancer',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          proposal.freelancerName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Turnaround',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${proposal.deliveryTimeDays} Days',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Escrow Deposit',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        Text(
                          '\$${proposal.proposedPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.lock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funds remain safely locked in escrow and are only released when you approve completed milestones.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
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
                    Navigator.pop(ctx);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      if (FirebaseConfig.instance.isInitialized) {
                        await FirebaseService.instance.clientService.acceptProposal(
                          task: _task!,
                          proposal: proposal,
                        );
                      }
                      setState(() {
                        final index = _proposals.indexWhere((p) => p.id == proposal.id);
                        if (index != -1) {
                          _proposals[index] = proposal.copyWith(status: 'accepted');
                        }
                        _task = _task!.copyWith(status: 'in_progress');
                      });
                    } catch (e) {
                      debugPrint('Error accepting proposal: $e');
                    }

                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Offer accepted! \$${proposal.proposedPrice.toInt()} funded into escrow.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.circleCheck, size: 18, color: Colors.white),
                  label: Text(
                    'Fund Escrow & Accept Offer (\$${proposal.proposedPrice.toInt()})',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Decline proposal dialog
  void _showDeclineModal(ProposalModel proposal) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Decline Proposal?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to decline ${proposal.freelancerName}\'s offer? They will be notified that you selected other candidates.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  if (FirebaseConfig.instance.isInitialized) {
                    await FirebaseService.instance.clientService.declineProposal(proposalId: proposal.id);
                  }
                  setState(() {
                    _proposals.removeWhere((p) => p.id == proposal.id);
                  });
                } catch (e) {
                  debugPrint('Error declining proposal: $e');
                }

                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Declined proposal from ${proposal.freelancerName}.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: Text(
                'Decline Offer',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show Sort Options Modal
  void _showSortModal() {
    showModalBottomSheet(
      context: context,
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
              Text(
                'Sort Proposals By',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildSortOption(ctx, label: 'Highest Rating', value: 'highest_rating'),
              _buildSortOption(ctx, label: 'Price: Low to High', value: 'price_low'),
              _buildSortOption(ctx, label: 'Price: High to Low', value: 'price_high'),
              _buildSortOption(ctx, label: 'Newest First', value: 'newest'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext ctx, {required String label, required String value}) {
    final isSelected = _activeSort == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? LucideIcons.circleDot : LucideIcons.circle,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
      onTap: () {
        setState(() => _activeSort = value);
        Navigator.pop(ctx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, size: 24, color: AppColors.textPrimary),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            'Task Details',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final task = _task ?? _buildDefaultTask();
    final candidates = _filteredProposals;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 24, color: AppColors.textPrimary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Task Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(LucideIcons.messageSquare, size: 20, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pushNamed('/messages'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(
                LucideIcons.user,
                size: 18,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTaskAndProposals,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Task Summary Card
              _buildTaskSummaryCard(task),

              const SizedBox(height: 16),

              // Filter & Sort Bar
              _buildFilterAndSortBar(candidates.length),

              const SizedBox(height: 16),

              // Proposals List
              if (candidates.isEmpty)
                _buildEmptyProposalsState()
              else
                ...candidates.map((proposal) => _buildProposalCard(proposal)),

              const SizedBox(height: 14),

              // 100% Escrow Protection Card
              _buildEscrowTrustCard(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds Top Section: Task Summary Card
  Widget _buildTaskSummaryCard(TaskModel task) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.isOpen ? 'Active • Receiving Proposals' : task.status.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatRelativeTime(task.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            task.title,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          // Metrics Matrix (Budget, Timeline, Candidates)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Budget',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${task.budget.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.budgetType == 'hourly' ? 'Hourly Rate' : 'Fixed Price',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Timeline',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${task.deadline.difference(task.createdAt).inDays > 0 ? task.deadline.difference(task.createdAt).inDays : 14} Days',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Turnaround',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Candidates',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_proposals.length > task.offersCount ? _proposals.length : (task.offersCount > 0 ? task.offersCount : _proposals.length)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Received',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Description with toggle
          Text(
            task.description,
            maxLines: _isDescriptionExpanded ? null : 2,
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Show less' : 'Read more',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isDescriptionExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Skills Chip Cloud
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: task.requiredSkills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds Filter & Sort Bar
  Widget _buildFilterAndSortBar(int count) {
    final shortlistedCount = _proposals.where((p) => p.isShortlisted).length;
    final topRatedCount = _proposals.where((p) => p.freelancerRating >= 4.90).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Filter tabs
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All (${_proposals.length})', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('Shortlisted ($shortlistedCount)', 'shortlisted'),
                const SizedBox(width: 6),
                _buildFilterChip('Top Rated ($topRatedCount)', 'top_rated'),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Sort trigger
        InkWell(
          onTap: _showSortModal,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowUpDown, size: 14, color: AppColors.textPrimary),
                const SizedBox(width: 5),
                Text(
                  _activeSort == 'highest_rating'
                      ? 'Highest Rating'
                      : (_activeSort == 'price_low'
                          ? 'Lowest Bid'
                          : (_activeSort == 'price_high' ? 'Highest Bid' : 'Newest')),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Builds a single Proposal Card matching Elena Rostova & Marcus Vance in Stitch
  Widget _buildProposalCard(ProposalModel proposal) {
    final isTopMatch = proposal.jobSuccessScore >= 98 || proposal.freelancerRating >= 4.95;
    final nameParts = proposal.freelancerName.trim().split(' ');
    final initials = nameParts.length > 1
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : (proposal.freelancerName.isNotEmpty ? proposal.freelancerName[0].toUpperCase() : 'FL');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: proposal.isAccepted ? AppColors.primary : AppColors.border,
          width: proposal.isAccepted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top ribbon if Top Match or Accepted
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (proposal.isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.circleCheck, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'OFFER ACCEPTED & CONTRACT ACTIVE',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isTopMatch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.badgeCheck, size: 14, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'TOP MATCH • 99% COMPATIBLE',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              IconButton(
                icon: Icon(
                  proposal.isShortlisted ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                  size: 20,
                  color: proposal.isShortlisted ? AppColors.primary : AppColors.textSecondary,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => _toggleShortlist(proposal),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Freelancer Profile Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initials,
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
                      width: 12,
                      height: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          proposal.freelancerName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '${proposal.jobSuccessScore}% JSS',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      proposal.freelancerTitle ?? 'Flutter & Mobile Specialist',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 14, color: Color(0xFFFFB800)),
                        const SizedBox(width: 4),
                        Text(
                          proposal.freelancerRating.toStringAsFixed(2),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${proposal.reviewsCount} reviews)',
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
            ],
          ),

          const SizedBox(height: 14),

          // Terms Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '\$${proposal.proposedPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Bid Offer',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${proposal.deliveryTimeDays} Days',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Delivery',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${proposal.revisionsCount} Revisions',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Included Free',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Cover Letter Snippet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '“${proposal.coverLetter}”',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Relevant Skills
          if (proposal.skills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: proposal.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),

          // Mini Portfolio / Related Work Proof
          if (proposal.portfolioItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'RELATED WORK PROOF',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: proposal.portfolioItems.take(2).map((item) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              item['tag'] == 'Marketplace' ? LucideIcons.shoppingBag : LucideIcons.layoutGrid,
                              size: 22,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (item['title'] as String?) ?? 'Mobile Project',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          (item['subtitle'] as String?) ?? 'Flutter App',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons: Message & Accept
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () => _showMessageModal(proposal),
                    icon: const Icon(LucideIcons.messageSquare, size: 16, color: AppColors.textPrimary),
                    label: Text(
                      'Message',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surfaceSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: proposal.isAccepted ? null : () => _showAcceptProposalModal(proposal),
                    icon: const Icon(LucideIcons.circleCheck, size: 16, color: Colors.white),
                    label: Text(
                      proposal.isAccepted ? 'Accepted' : 'Accept (\$${proposal.proposedPrice.toInt()})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Decline Proposal Button
          if (!proposal.isAccepted) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: () => _showDeclineModal(proposal),
                icon: const Icon(LucideIcons.x, size: 14, color: AppColors.textSecondary),
                label: Text(
                  'Decline proposal',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Empty State when filter yields 0 candidates
  Widget _buildEmptyProposalsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.inbox, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'No proposals match the current filter.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try changing your filter to "All" to review all incoming bids.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  /// Escrow Trust Guarantee & Bottom Summary
  Widget _buildEscrowTrustCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.shieldCheck,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Escrow Protection',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Proposals close automatically when you accept an offer. Escrow funds are only transferred upon your milestone sign-off.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
