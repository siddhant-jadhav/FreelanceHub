import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/task_model.dart';

/// Screen 02 — Post a Task
/// Built according to FreelanceHub Design System (docs/design.md, .agents/rules/ui-design.md)
/// Matches Stitch Screen `02 — Post a Task` with live Firestore DB integration,
/// Lucide iconography, escrow protection workflows, and responsive layout.
class PostTaskScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialTitle;
  final String? initialDescription;
  final double? initialBudget;

  const PostTaskScreen({
    super.key,
    this.initialCategory,
    this.initialTitle,
    this.initialDescription,
    this.initialBudget,
  });

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  final TextEditingController _skillInputController = TextEditingController();

  // State Variables
  late String _selectedCategory;
  String _budgetType = 'fixed'; // 'fixed' or 'hourly'
  String _deadlineType = 'fast'; // 'fast' (2 weeks) or 'custom'
  DateTime _customDeadline = DateTime.now().add(const Duration(days: 45));
  String _experienceLevel = 'Mid (3-5 yrs)';
  bool _isPublishing = false;
  bool _showSuccessToast = false;

  // Skills
  final List<String> _skills = ['Flutter', 'Firebase', 'Figma'];
  final List<String> _suggestedSkills = ['React', 'Node.js', 'UI/UX', 'REST API', 'Dart'];

  // Attachments
  final List<Map<String, String>> _attachments = [
    {
      'name': 'marketplace_app_spec_v2.pdf',
      'size': '1.8 MB',
    }
  ];

  final List<String> _categories = [
    'App Development (Mobile & Tablet)',
    'UI/UX & Product Design',
    'Web Development & Full-Stack',
    'Backend & Cloud Architecture',
    'AI & Machine Learning',
    'Content & Copywriting',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? 'Build iOS & Android Marketplace App in Flutter',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDescription ??
          'Looking for an experienced Flutter developer to build a modern mobile marketplace app with real-time chat, escrow payments, and auth.',
    );
    _budgetController = TextEditingController(
      text: widget.initialBudget != null
          ? widget.initialBudget!.toStringAsFixed(2)
          : '1,200.00',
    );
    _selectedCategory = widget.initialCategory ?? _categories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  void _addSkill(String skill) {
    final clean = skill.trim();
    if (clean.isEmpty) return;
    if (!_skills.any((s) => s.toLowerCase() == clean.toLowerCase())) {
      setState(() {
        _skills.add(clean);
        _skillInputController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _addAttachmentMock() {
    setState(() {
      _attachments.add({
        'name': 'design_tokens_wireframe.png',
        'size': '2.4 MB',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attached design_tokens_wireframe.png (2.4 MB)'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDeadline.isAfter(now) ? _customDeadline : now.add(const Duration(days: 14)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDeadline = picked;
        _deadlineType = 'custom';
      });
    }
  }

  DateTime get _effectiveDeadline {
    if (_deadlineType == 'fast') {
      return DateTime.now().add(const Duration(days: 14));
    }
    return _customDeadline;
  }

  Future<void> _handlePostTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your task requirements.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawBudget = _budgetController.text.replaceAll(',', '').replaceAll('\$', '').trim();
    final budget = double.tryParse(rawBudget) ?? 1200.0;

    setState(() => _isPublishing = true);

    String? createdTaskId;
    TaskModel? createdTask;

    try {
      if (FirebaseConfig.instance.isInitialized) {
        createdTaskId = await FirebaseService.instance.clientService.postTask(
          title: title,
          description: description,
          category: _selectedCategory,
          budget: budget,
          budgetType: _budgetType,
          deadline: _effectiveDeadline,
          requiredSkills: _skills,
          experienceLevel: _experienceLevel,
          attachments: _attachments.map((a) => a['name'] ?? '').toList(),
        );

        createdTask = await FirebaseService.instance.clientService.getTask(createdTaskId);
      }
    } catch (e) {
      debugPrint('Error publishing task: $e');
    }

    // Baseline fallback if offline or no DB
    createdTask ??= TaskModel(
      id: createdTaskId ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      clientId: FirebaseService.instance.currentUser?.uid ?? 'client_apex_solutions',
      clientName: FirebaseService.instance.currentUser?.displayName ?? 'Apex Solutions',
      title: title,
      description: description,
      category: _selectedCategory,
      budget: budget,
      budgetType: _budgetType,
      deadline: _effectiveDeadline,
      requiredSkills: _skills,
      experienceLevel: _experienceLevel,
      attachments: _attachments.map((a) => a['name'] ?? '').toList(),
      status: 'open',
      offersCount: 0,
      createdAt: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _isPublishing = false;
      _showSuccessToast = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "$title" Published! Top vetted pros are preparing proposals.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    // After brief celebration, navigate to Task Details & Proposals
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/task-details',
      arguments: createdTask,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Post Task',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 14,
              bottom: 120, // space for sticky bottom bar
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Hint Banner
                  _buildQuickHintBanner(),

                  const SizedBox(height: 16),

                  // SECTION 1: Task Overview
                  _buildSection1TaskOverview(),

                  const SizedBox(height: 16),

                  // SECTION 2: Required Skills
                  _buildSection2RequiredSkills(),

                  const SizedBox(height: 16),

                  // SECTION 3: Budget & Payment Type
                  _buildSection3Budget(),

                  const SizedBox(height: 16),

                  // SECTION 4: Timeline & Attachments
                  _buildSection4TimelineAndAttachments(),

                  const SizedBox(height: 16),

                  // SECTION 5: Experience & Protection
                  _buildSection5ExperienceAndProtection(),
                ],
              ),
            ),
          ),

          // Floating Success Toast (if triggered)
          if (_showSuccessToast)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Task Published!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Freelancers are reviewing your task specifications.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishing ? null : _handlePostTask,
                        icon: _isPublishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(LucideIcons.send, size: 18, color: Colors.white),
                        label: Text(
                          _isPublishing ? 'Publishing Task...' : 'Post Task Now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circleCheck, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Free to post • Get proposals in minutes',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Sparkle / Quick Hint Banner
  Widget _buildQuickHintBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.zap,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post in 2 minutes',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Receive tailored proposals from verified pros today.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
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

  /// SECTION 1: Task Overview
  Widget _buildSection1TaskOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildSectionHeader('1. Task Overview'),
          const SizedBox(height: 12),

          // Task Title
          Text(
            'Task Title',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'e.g. Build iOS & Android Marketplace App in Flutter',
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
          const SizedBox(height: 4),
          Text(
            'Be clear and specific so top talent immediately recognizes your scope.',
            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 14),

          // Category Selector
          Text(
            'Category',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Detailed Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detailed Description',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _descriptionController,
                builder: (context, value, _) {
                  return Text(
                    '${value.text.length}/1000',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 1000,
            style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
            decoration: InputDecoration(
              hintText: 'Describe your project goals, key features, and deliverables...',
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
        ],
      ),
    );
  }

  /// SECTION 2: Required Skills
  Widget _buildSection2RequiredSkills() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('2. Required Skills'),
              Text(
                '${_skills.length} added',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Tags Container
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Container(
                padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skill,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _removeSkill(skill),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(LucideIcons.x, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Add Skill Search Input
          TextField(
            controller: _skillInputController,
            onSubmitted: _addSkill,
            decoration: InputDecoration(
              hintText: 'Search or add skill...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textDisabled),
              prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
                onPressed: () => _addSkill(_skillInputController.text),
              ),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          const SizedBox(height: 12),

          // Suggested for this role
          Text(
            'SUGGESTED FOR THIS ROLE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedSkills.map((suggested) {
              final isAdded = _skills.contains(suggested);
              return InkWell(
                onTap: isAdded ? null : () => _addSkill(suggested),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAdded ? AppColors.surfaceSecondary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdded ? AppColors.border : AppColors.primaryLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdded ? LucideIcons.check : LucideIcons.plus,
                        size: 13,
                        color: isAdded ? AppColors.textDisabled : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        suggested,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isAdded ? AppColors.textDisabled : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// SECTION 3: Budget & Payment Type
  Widget _buildSection3Budget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildSectionHeader('3. Budget & Payment Type'),
          const SizedBox(height: 12),

          // Segmented Toggle: Fixed Price vs Hourly Rate
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _budgetType = 'fixed';
                        if (_budgetController.text.contains('/hr')) {
                          _budgetController.text = '1,200.00';
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _budgetType == 'fixed' ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.badgeCheck,
                            size: 16,
                            color: _budgetType == 'fixed' ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fixed Price',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _budgetType == 'fixed' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _budgetType = 'hourly';
                        if (!_budgetController.text.contains('/hr')) {
                          _budgetController.text = '45.00/hr';
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _budgetType == 'hourly' ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: _budgetType == 'hourly' ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hourly Rate',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _budgetType == 'hourly' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Budget Amount Field
          Text(
            _budgetType == 'fixed' ? 'Budget Amount (USD)' : 'Hourly Rate (USD/hr)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
          const SizedBox(height: 6),

          // Insights banner
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Average budget for app development tasks is \$800 - \$2,500',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SECTION 4: Timeline & Attachments
  Widget _buildSection4TimelineAndAttachments() {
    final customFormatted = '${_customDeadline.month}/${_customDeadline.day}/${_customDeadline.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildSectionHeader('4. Timeline & Attachments'),
          const SizedBox(height: 12),

          // Delivery Deadline Selection
          Text(
            'Delivery Deadline',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _deadlineType = 'fast'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _deadlineType == 'fast' ? AppColors.primaryLight : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _deadlineType == 'fast' ? AppColors.primary : AppColors.border,
                        width: _deadlineType == 'fast' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Within 2 weeks',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _deadlineType == 'fast' ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Quick delivery',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickCustomDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _deadlineType == 'custom' ? AppColors.primaryLight : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _deadlineType == 'custom' ? AppColors.primary : AppColors.border,
                        width: _deadlineType == 'custom' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _deadlineType == 'custom' ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Custom target',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Project Brief & Documents Dropzone
          Text(
            'Project Brief & Documents',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _addAttachmentMock,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.cloudUpload,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload project brief, wireframes, or assets',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PDF, PNG, JPG, or ZIP up to 25MB',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Uploaded Files List
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: _attachments.asMap().entries.map((entry) {
                final idx = entry.key;
                final file = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileText, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${file['name']} (${file['size']})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _removeAttachment(idx),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// SECTION 5: Experience & Protection
  Widget _buildSection5ExperienceAndProtection() {
    const levels = ['Junior (1-2 yrs)', 'Mid (3-5 yrs)', 'Expert (5+ yrs)'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildSectionHeader('5. Experience & Protection'),
          const SizedBox(height: 12),

          // Experience Level Preference
          Text(
            'Experience Level',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: levels.map((lvl) {
              final isSelected = _experienceLevel == lvl;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _experienceLevel = lvl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.textPrimary : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.textPrimary : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          lvl,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Escrow Security Guarantee Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
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
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Escrow Protection',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your payment is held safely in escrow until you inspect, test, and approve the completed work.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
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

  /// Section Header with emerald circular indicator
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
