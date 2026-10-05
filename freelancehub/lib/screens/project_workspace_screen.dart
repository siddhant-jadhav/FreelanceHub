import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/project_model.dart';
import '../services/client_service.dart';
import '../services/notification_service.dart';

/// Screen 04 — Project Workspace
/// Built according to FreelanceHub Design System (docs/design.md, .agents/rules/ui-design.md)
/// Matches Stitch Screen `04 — Project Workspace` with live Escrow management,
/// Milestone reviews, deliverable inspecting, activity timeline, and collaboration note dock.
class ProjectWorkspaceScreen extends StatefulWidget {
  final ProjectModel? project;
  final String? projectId;

  const ProjectWorkspaceScreen({
    super.key,
    this.project,
    this.projectId,
  });

  @override
  State<ProjectWorkspaceScreen> createState() => _ProjectWorkspaceScreenState();
}

class _ProjectWorkspaceScreenState extends State<ProjectWorkspaceScreen> {
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Active Project State
  late String _contractId;
  late String _projectTitle;
  late String _freelancerName;
  late String _freelancerRole;
  late double _rating;
  late String _sellerLevel;
  late double _totalValue;
  late double _inEscrow;
  late double _released;
  late double _progressPercent;
  late String _dueInfo;
  late int _completedMilestones;
  late int _totalMilestones;

  // Milestone 2 review state
  bool _milestone2Approved = false;
  bool _milestone2InRevision = false;
  int _revisionsRemaining = 2;
  String? _revisionNote;
  bool _isProcessingAction = false;

  // Activity Log
  late List<Map<String, dynamic>> _activities;
  ProjectModel? _activeProject;

  @override
  void initState() {
    super.initState();
    _activeProject = widget.project;
    _initWorkspaceData();
    _loadProjectIfNull();
  }

  Future<void> _loadProjectIfNull() async {
    if (!FirebaseConfig.instance.isInitialized) return;
    try {
      final uid = FirebaseService.instance.currentUser?.uid;
      if (uid == null) return;
      final isClient = FirebaseService.instance.currentRole == 'client';

      List<ProjectModel> projects = [];
      if (_activeProject != null) {
        projects = [_activeProject!];
      } else {
        projects = isClient
            ? await FirebaseService.instance.projectRepository.getProjectsForClient(uid)
            : await FirebaseService.instance.projectRepository.getProjectsForFreelancer(uid);
      }

      if (projects.isNotEmpty && mounted) {
        final p = projects.first;
        setState(() {
          _activeProject = p;
          _contractId = p.id.startsWith('FH-')
              ? p.id
              : 'FH-${p.id.length > 5 ? p.id.substring(0, 5).toUpperCase() : p.id.toUpperCase()}';
          _projectTitle = p.title;
          if (p.freelancerName.isNotEmpty) {
            _freelancerName = p.freelancerName;
          }
          if (p.budget > 0) {
            _totalValue = p.budget;
            _inEscrow = _totalValue - _released;
          }
          _completedMilestones = p.completedMilestones;
          _totalMilestones = p.totalMilestones > 0 ? p.totalMilestones : 3;
          _progressPercent = (_completedMilestones / _totalMilestones).clamp(0.0, 1.0);
          if (p.status == 'completed') {
            _milestone2Approved = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Notice loading project in workspace: $e');
    }
  }

  void _initWorkspaceData() {
    final p = widget.project;
    _contractId = p != null && p.id.isNotEmpty
        ? (p.id.startsWith('FH-') ? p.id : 'FH-${p.id.length > 5 ? p.id.substring(0, 5).toUpperCase() : p.id.toUpperCase()}')
        : 'FH-88492';
    _projectTitle = p?.title ?? 'FreelanceHub Mobile Flutter App';
    _freelancerName = p?.freelancerName.isNotEmpty == true
        ? p!.freelancerName
        : (FirebaseConfig.instance.isInitialized ? 'Siddhant Jadhav' : 'Elena Rostova');
    _freelancerRole = 'Senior Flutter Developer';
    _rating = 4.98;
    _sellerLevel = 'Level 2 Seller';

    _totalValue = p?.budget != null && p!.budget > 0 ? p.budget : 1200.00;
    _released = 400.00;
    _inEscrow = _totalValue - _released;
    _completedMilestones = p?.completedMilestones ?? 1;
    _totalMilestones = p?.totalMilestones != null && p!.totalMilestones > 0 ? p.totalMilestones : 3;
    _progressPercent = (_completedMilestones / _totalMilestones).clamp(0.0, 1.0);
    _dueInfo = 'Due Nov 24 (6 days left)';

    _activities = [
      {
        'type': 'upload',
        'title': '$_freelancerName uploaded deliverables for Milestone 2',
        'subtitle': '2 hours ago • Build v2.0 uploaded',
        'icon': LucideIcons.cloudUpload,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      },
      {
        'type': 'escrow',
        'title': 'Client (You) funded Milestone 2 (\$400 held in Escrow)',
        'subtitle': 'Yesterday at 4:15 PM',
        'icon': LucideIcons.wallet,
        'iconColor': AppColors.textDark,
        'iconBg': AppColors.surfaceContainer,
      },
      {
        'type': 'approved',
        'title': 'Milestone 1 marked as completed and funds were released',
        'subtitle': 'Nov 12 • \$400 processed',
        'icon': LucideIcons.checkCheck,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      },
    ];
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _handleApproveAndRelease() {
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
                  'Release Escrow Funds',
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
                'Are you sure you want to release \$400.00 from escrow to $_freelancerName for Milestone 2: Explore & Task Details Screens?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
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
                        '100% Escrow Protected. Once released, funds will be immediately deposited into the freelancer’s balance.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeApproval();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Confirm & Release (\$400)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeApproval() async {
    setState(() => _isProcessingAction = true);

    // Call service if live Firebase is initialized
    if (FirebaseConfig.instance.isInitialized) {
      try {
        final prj = _activeProject ?? widget.project;
        String projectId = prj?.id ?? '';
        String freelancerId = prj?.freelancerId ?? 'dGHpEXlNcJVaQkV9pQfXuSvAl0y2';
        String milestoneTitle = prj?.title ?? 'Project Delivery';
        double amount = (prj != null && prj.budget > 0) ? prj.budget : 400.0;
        String milestoneId = 'm-2';

        if (projectId.isNotEmpty) {
          try {
            final cleanId = projectId.replaceFirst('FH-', '');
            final milestones = await FirebaseService.instance.milestoneRepository
                .getMilestonesForProject(cleanId);
            if (milestones.isNotEmpty) {
              final activeMilestone = milestones.firstWhere(
                (m) => m.status != 'approved',
                orElse: () => milestones.first,
              );
              milestoneId = activeMilestone.id;
              milestoneTitle = activeMilestone.title;
              amount = activeMilestone.amount;
            }
          } catch (_) {}
        } else {
          final uid = FirebaseService.instance.currentUser?.uid;
          if (uid != null) {
            final clientProjects = await FirebaseService.instance.projectRepository.getProjectsForClient(uid);
            if (clientProjects.isNotEmpty) {
              final firstP = clientProjects.first;
              projectId = firstP.id;
              freelancerId = firstP.freelancerId;
              amount = firstP.budget > 0 ? firstP.budget : 400.0;
              milestoneTitle = firstP.title;
            }
          }
        }

        await ClientService.instance.reviewMilestoneDeliverable(
          projectId: projectId.isNotEmpty ? projectId : 'active_project',
          milestoneId: milestoneId,
          freelancerId: freelancerId,
          milestoneTitle: milestoneTitle,
          amount: amount,
          approved: true,
        );
      } catch (e) {
        debugPrint('Approval notice: $e');
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isProcessingAction = false;
      _milestone2Approved = true;
      _milestone2InRevision = false;
      _released += 400.0;
      _inEscrow -= 400.0;
      _completedMilestones = 2;
      _progressPercent = (2 / 3);

      _activities.insert(0, {
        'type': 'approved',
        'title': 'Milestone 2 approved and \$400.00 released to $_freelancerName',
        'subtitle': 'Just now • Escrow payout completed',
        'icon': LucideIcons.circleCheck,
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
                'Milestone 2 Approved! \$400 released to $_freelancerName.',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleRequestRevision() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Revision',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$_revisionsRemaining of 2 revisions left',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe the changes or refinements needed for Milestone 2 deliverables.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'e.g., Please adjust the contrast on dark mode screens and optimize the list scroll speed...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final note = textController.text.trim();
                          if (note.isEmpty) return;
                          Navigator.pop(ctx);
                          _submitRevision(note);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Send Revision',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitRevision(String note) {
    if (FirebaseConfig.instance.isInitialized && widget.project != null) {
      try {
        FirebaseService.instance.projectRepository
            .updateProjectStatus(widget.project!.id, 'revision');
        NotificationService.instance.notifyRevisionRequested(
          freelancerUserId: widget.project!.freelancerId,
          clientName: widget.project!.clientName,
          projectTitle: widget.project!.title,
          projectId: widget.project!.id,
          note: note,
        );
      } catch (e) {
        debugPrint('Notice requesting revision in Firestore: $e');
      }
    }

    setState(() {
      _milestone2InRevision = true;
      _revisionNote = note;
      if (_revisionsRemaining > 0) _revisionsRemaining--;

      _activities.insert(0, {
        'type': 'revision',
        'title': 'Client (You) requested revisions on Milestone 2',
        'subtitle': 'Just now • "$note"',
        'icon': LucideIcons.refreshCw,
        'iconColor': AppColors.warning,
        'iconBg': const Color(0xFFFEF3C7),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Revision request sent to $_freelancerName.'),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _sendProjectNote() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;

    setState(() {
      _activities.insert(0, {
        'type': 'note',
        'title': 'Client (You): $note',
        'subtitle': 'Just now • Project channel',
        'icon': LucideIcons.messageSquare,
        'iconColor': AppColors.primary,
        'iconBg': AppColors.primaryLight,
      });
      _noteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note sent to project channel: "$note"'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadDeliverable(String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.download, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Downloading $fileName... Build artifact ready.')),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _inspectPullRequest(String prUrl) {
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
                  const Icon(LucideIcons.gitPullRequest, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Pull Request #42',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Branch: feature/explore-and-task-details → main\nCommits: 14 • Changes: +1,240 / -180 lines\nStatus: Clean merge, 35 unit & widget tests passed.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.check, size: 16, color: Colors.white),
                label: const Text('Inspection Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFreelancerContactModal(String mode) {
    String title = mode == 'call' ? 'Call $_freelancerName' : (mode == 'chat' ? 'Direct Chat' : 'Contract Terms');
    String desc = mode == 'call'
        ? 'Voice & Video calls are available during agreed business hours (9:00 AM - 6:00 PM EST).'
        : (mode == 'chat'
            ? 'Open direct 1-on-1 encrypted messaging channel with $_freelancerName.'
            : 'Fixed price contract #$_contractId escrow agreement with 100% money-back escrow holding.');

    showModalBottomSheet(
      context: context,
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
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              if (mode == 'chat')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed(
                      '/chat',
                      arguments: {
                        'contactName': _freelancerName,
                        'contactRole': 'Freelancer',
                        'contactInitials': _freelancerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                        'projectTitle': _projectTitle,
                        'projectBudget': _totalValue,
                        'projectInEscrow': _inEscrow,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Open Chat', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
            ],
          ),
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
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Milestone Review Alert Banner
              if (!_milestone2Approved) _buildActionRequiredBanner(),

              // 2. Workspace Header & Meta Card
              _buildWorkspaceHeaderCard(),
              const SizedBox(height: 14),

              // 3. Freelancer Spotlight Card
              _buildFreelancerSpotlightCard(),
              const SizedBox(height: 14),

              // 4. Overall Project Progress & Budget Bento
              _buildProjectProgressBento(),
              const SizedBox(height: 20),

              // 5. Milestones & Deliverables Section
              _buildMilestonesSection(),
              const SizedBox(height: 20),

              // 6. Workspace Activity Timeline
              _buildActivityTimelineSection(),
              const SizedBox(height: 16),

              // 7. Quick Collaboration Note Input Dock
              _buildQuickNoteDock(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Workspace',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'Client Mode',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Messages',
          icon: const Icon(LucideIcons.messageSquare, size: 20, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pushNamed('/messages'),
        ),
        IconButton(
          icon: const Icon(LucideIcons.bell, size: 20, color: AppColors.textDark),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications: 1 new deliverable review request.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 14, left: 2),
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(LucideIcons.user, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRequiredBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.clipboardCheck, color: Colors.white, size: 18),
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
                        'Action Required: Milestone 2',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _milestone2InRevision ? 'In Revision' : 'Review Ready',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _milestone2InRevision
                      ? 'You requested changes for Milestone 2: "${_revisionNote ?? 'Please refine UI'}". $_freelancerName is working on updates.'
                      : '$_freelancerName has submitted deliverables for review. Please inspect the build or request changes.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeaderCard() {
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
              Text(
                'CONTRACT #$_contractId',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
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
                      _milestone2Approved ? 'In Progress • Milestone 3' : 'In Progress • Milestone 2',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _projectTitle,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    _dueInfo,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Escrow Protected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
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

  Widget _buildFreelancerSpotlightCard() {
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
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'ER',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
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
                      children: [
                        Flexible(
                          child: Text(
                            _freelancerName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                      ],
                    ),
                    Text(
                      _freelancerRole,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 13, color: Color(0xFFFFB800)),
                        const SizedBox(width: 3),
                        Text(
                          '$_rating',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' • $_sellerLevel',
                          style: GoogleFonts.inter(
                            fontSize: 12,
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
          // 3 Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildFreelancerActionButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  onTap: () => _showFreelancerContactModal('call'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFreelancerActionButton(
                  icon: LucideIcons.messageSquare,
                  label: 'Direct Chat',
                  onTap: () => _showFreelancerContactModal('chat'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFreelancerActionButton(
                  icon: LucideIcons.fileText,
                  label: 'Contract',
                  onTap: () => _showFreelancerContactModal('contract'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreelancerActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.textDark),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectProgressBento() {
    final percentInt = (_progressPercent * 100).toInt();

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
              Text(
                'Project Completion',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$percentInt%',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progressPercent,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_completedMilestones of $_totalMilestones Milestones Delivered',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Final Target: Nov 24',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 3-Metric Bento Grid
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Value',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_totalValue.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'In Escrow',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_inEscrow.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Released',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${_released.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
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

  Widget _buildMilestonesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Milestones & Deliverables',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '3 Milestones',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Milestone 1 (Approved & Paid)
        _buildMilestone1Card(),
        const SizedBox(height: 12),

        // Milestone 2 (Active, Review Required or Approved)
        _buildMilestone2Card(),
        const SizedBox(height: 12),

        // Milestone 3 (Upcoming)
        _buildMilestone3Card(),
      ],
    );
  }

  Widget _buildMilestone1Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.check, size: 15, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. UI Architecture & Auth Screens',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Approved & Released on Nov 12',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$400',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Paid',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestone2Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _milestone2Approved ? AppColors.border : AppColors.primary.withValues(alpha: 0.5),
          width: _milestone2Approved ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _milestone2Approved ? AppColors.primaryLight : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _milestone2Approved ? LucideIcons.check : LucideIcons.hourglass,
                    size: 15,
                    color: _milestone2Approved ? AppColors.primary : Colors.white,
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
                        Flexible(
                          child: Text(
                            '2. Explore & Task Details Screens',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _milestone2Approved
                                ? AppColors.primaryLight
                                : (_milestone2InRevision ? const Color(0xFFFEF3C7) : AppColors.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _milestone2Approved
                                ? 'Approved'
                                : (_milestone2InRevision ? 'In Revision' : 'Needs Approval'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _milestone2Approved
                                  ? AppColors.primaryDark
                                  : (_milestone2InRevision ? AppColors.warning : Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _milestone2Approved
                          ? 'Approved & Funds Released'
                          : (_milestone2InRevision
                              ? 'Revision requested • Waiting for updated build'
                              : 'Delivered 2 hours ago • Review window: 3 days'),
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$400',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _milestone2Approved ? 'Paid' : 'In Escrow',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _milestone2Approved ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Submitted Assets Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBMITTED ASSETS',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Asset 1: APK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.smartphone, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'freelancehub_screens_v2.apk',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '18.4 MB • Build 104',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _downloadDeliverable('freelancehub_screens_v2.apk'),
                        icon: const Icon(LucideIcons.download, size: 13, color: AppColors.textDark),
                        label: Text(
                          'Get',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Asset 2: Git PR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(LucideIcons.gitPullRequest, size: 16, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'github.com/org/repo/pull/42',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '14 commits • +1,240 / -180 lines',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _inspectPullRequest('github.com/org/repo/pull/42'),
                        icon: const Icon(LucideIcons.eye, size: 13, color: AppColors.textDark),
                        label: Text(
                          'Inspect',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons if not yet approved
          if (!_milestone2Approved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessingAction ? null : _handleApproveAndRelease,
                    icon: _isProcessingAction
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(LucideIcons.shieldCheck, size: 16, color: Colors.white),
                    label: Text(
                      'Approve & Release (\$400)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _handleRequestRevision,
                    icon: const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.textDark),
                    label: Text(
                      'Revision',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestone3Card() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.lock, size: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Payment & Escrow Flow',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upcoming • Starts after Milestone 2 approval',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$400',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Escrow Funded',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineSection() {
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
          Text(
            'Workspace Activity',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final act = _activities[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: act['iconBg'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(act['icon'] as IconData, size: 15, color: act['iconColor'] as Color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          act['subtitle'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteDock() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.paperclip, size: 19, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attach specs, log files, or mockups to project channel.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _noteController,
              onSubmitted: (_) => _sendProjectNote(),
              decoration: InputDecoration(
                hintText: 'Send project note or instructions...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textDisabled,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: _sendProjectNote,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.send, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: LucideIcons.home,
            label: 'Home',
            isActive: false,
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/client-home');
              }
            },
          ),
          _buildNavItem(
            icon: LucideIcons.compass,
            label: 'Explore',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Explore top verified talent and active services.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _buildNavItem(
            icon: LucideIcons.briefcase,
            label: 'Projects',
            isActive: true,
            onTap: () {},
          ),
          _buildNavItem(
            icon: LucideIcons.messageSquare,
            label: 'Messages',
            isActive: false,
            onTap: () => Navigator.of(context).pushNamed('/messages'),
          ),
          _buildNavItem(
            icon: LucideIcons.user,
            label: 'Profile',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Client Profile & Billing Settings.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
                if (isActive)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
