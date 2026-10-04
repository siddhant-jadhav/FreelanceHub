import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/message_model.dart';
import '../services/notification_service.dart';

/// Interactive Chat Message data model
class ChatBubbleData {
  final String id;
  final String text;
  final String timestamp;
  final bool isOutgoing;
  final bool isRead;
  final bool isDelivered;
  final ChatFileAttachment? attachment;
  final ChatPreviewCard? previewCard;

  const ChatBubbleData({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    this.isRead = true,
    this.isDelivered = true,
    this.attachment,
    this.previewCard,
  });
}

class ChatFileAttachment {
  final String fileName;
  final String fileSize;
  final String fileType;
  final String uploadTime;

  const ChatFileAttachment({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadTime,
  });
}

class ChatPreviewCard {
  final String title;
  final String subtitle;
  final String tag;
  final String? previewImageUrl;

  const ChatPreviewCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    this.previewImageUrl,
  });
}

/// Individual Chat screen connecting client and freelancer with pinned
/// contract context, escrow protection badges, deliverable previews,
/// and instant messaging capabilities.
class IndividualChatScreen extends StatefulWidget {
  final String? conversationId;
  final String contactName;
  final String contactRole;
  final String? contactPhotoUrl;
  final String contactInitials;
  final bool isOnline;
  final String projectTitle;
  final String projectStatus;
  final double projectBudget;
  final double projectInEscrow;
  final String? projectId;

  const IndividualChatScreen({
    super.key,
    this.conversationId,
    this.contactName = 'Sarah Johnson',
    this.contactRole = 'Client',
    this.contactPhotoUrl,
    this.contactInitials = 'SJ',
    this.isOnline = true,
    this.projectTitle = 'E-commerce Mobile App MVP',
    this.projectStatus = 'Active',
    this.projectBudget = 1200.0,
    this.projectInEscrow = 800.0,
    this.projectId,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSarahTyping = true;

  late List<ChatBubbleData> _messages;

  StreamSubscription<List<MessageModel>>? _messagesSub;
  String? _activeConversationId;
  String? _recipientUid;

  late String _displayContactName;
  late String _displayContactInitials;

  @override
  void initState() {
    super.initState();
    _displayContactName = widget.contactName;
    _displayContactInitials = widget.contactInitials;
    if (FirebaseConfig.instance.isInitialized) {
      final role = FirebaseService.instance.currentRole;
      if (widget.contactName == 'Sarah Johnson') {
        _displayContactName = role == 'client' ? 'Siddhant Jadhav' : 'Vedant';
        _displayContactInitials = role == 'client' ? 'SJ' : 'V';
      }
      _messages = [];
      _showSarahTyping = false;
      _setupLiveFirebaseChat();
    } else {
      _initDefaultConversation();
    }
  }

  void _setupLiveFirebaseChat() async {
    if (!FirebaseConfig.instance.isInitialized) return;
    final currentUid = FirebaseService.instance.currentUser?.uid;
    if (currentUid == null) return;
    final role = FirebaseService.instance.currentRole;
    final isClient = role == 'client';

    // 1. Resolve recipient UID if not provided
    String? recipientUid;
    String recipientName = _displayContactName;

    try {
      final otherRole = isClient ? 'freelancer' : 'client';
      final usersQuery = await FirebaseService.instance.firestore
          .collection('users')
          .where('role', isEqualTo: otherRole)
          .limit(1)
          .get();

      if (usersQuery.docs.isNotEmpty) {
        recipientUid = usersQuery.docs.first.id;
        recipientName = (usersQuery.docs.first.data()['fullName'] as String?) ??
            (isClient ? 'Siddhant Jadhav' : 'Vedant');
        if (mounted) {
          setState(() {
            _displayContactName = recipientName;
            _displayContactInitials = recipientName.trim().isNotEmpty
                ? (recipientName.trim().split(' ').length > 1
                    ? '${recipientName.trim().split(' ')[0][0]}${recipientName.trim().split(' ')[1][0]}'.toUpperCase()
                    : recipientName.trim()[0].toUpperCase())
                : 'U';
          });
        }
      }
    } catch (_) {}

    recipientUid ??= (isClient ? 'siddhant_user' : 'vedant_user');
    _recipientUid = recipientUid;

    // 2. Resolve or create conversation
    String convId = widget.conversationId ?? '';
    if (convId.isEmpty) {
      try {
        final currentProfile =
            await FirebaseService.instance.getUserProfile(currentUid);
        final currentName = currentProfile?['fullName'] ??
            FirebaseService.instance.currentUser?.displayName ??
            (isClient ? 'Vedant' : 'Siddhant');

        convId = await FirebaseService.instance.messageRepository
            .getOrCreateConversation(
          currentUserId: currentUid,
          currentUserName: currentName,
          recipientUserId: recipientUid,
          recipientUserName: recipientName,
          projectId: widget.projectId,
        );
      } catch (e) {
        debugPrint('Notice getting or creating conversation: $e');
      }
    }

    _activeConversationId = convId;

    if (convId.isNotEmpty) {
      _messagesSub = FirebaseService.instance.messageRepository
          .streamMessages(convId)
          .listen((messages) {
        if (!mounted) return;
        setState(() {
          _messages = messages.map((m) {
            return ChatBubbleData(
              id: m.id,
              text: m.message,
              timestamp: _formatTime(m.createdAt),
              isOutgoing: m.senderId == currentUid,
              isDelivered: true,
              isRead: m.isRead,
            );
          }).toList();
          _showSarahTyping = false;
        });
        _scrollToBottom();
      }, onError: (e) {
        debugPrint('Error streaming messages: $e');
      });
    }
  }

  void _initDefaultConversation() {
    _messages = [
      const ChatBubbleData(
        id: 'msg-1',
        text: "Hi! I've reviewed your proposal and I'd like to discuss the project timeline.",
        timestamp: '10:35 AM',
        isOutgoing: false,
      ),
      const ChatBubbleData(
        id: 'msg-2',
        text: 'Sure. I can start working on it from Monday.',
        timestamp: '10:38 AM',
        isOutgoing: true,
        isDelivered: true,
        isRead: true,
      ),
      const ChatBubbleData(
        id: 'msg-3',
        text: "Perfect. I'll share the final requirements today.",
        timestamp: '10:40 AM',
        isOutgoing: false,
      ),
      const ChatBubbleData(
        id: 'msg-4',
        text: '',
        timestamp: '10:41 AM',
        isOutgoing: false,
        attachment: ChatFileAttachment(
          fileName: 'ecommerce_requirements_v3.pdf',
          fileSize: '2.4 MB',
          fileType: 'PDF document',
          uploadTime: '10:41 AM',
        ),
      ),
      const ChatBubbleData(
        id: 'msg-5',
        text: "Sounds good. I'll review them once you send them.",
        timestamp: '10:42 AM',
        isOutgoing: true,
        isDelivered: true,
        isRead: true,
      ),
      const ChatBubbleData(
        id: 'msg-6',
        text: '',
        timestamp: '10:44 AM',
        isOutgoing: true,
        isDelivered: true,
        isRead: true,
        previewCard: ChatPreviewCard(
          title: 'Design_System_Components_v1.fig',
          subtitle: 'Figma Project • Shared preview',
          tag: 'Design Draft',
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr = _formatTime(now);

    final currentUid =
        FirebaseService.instance.currentUser?.uid ?? 'current-user';

    final newMsg = ChatBubbleData(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      timestamp: timeStr,
      isOutgoing: true,
      isDelivered: true,
      isRead: false,
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
      _showSarahTyping = false;
    });

    _scrollToBottom();

    // Persist to Firebase if connected
    final convId = _activeConversationId ?? widget.conversationId;
    if (FirebaseConfig.instance.isInitialized &&
        convId != null &&
        convId.isNotEmpty) {
      try {
        final message = MessageModel(
          id: '',
          conversationId: convId,
          senderId: currentUid,
          receiverId: _recipientUid ?? '',
          message: text,
          createdAt: now,
        );
        await FirebaseService.instance.messageRepository.sendMessage(message);

        if (_recipientUid != null && _recipientUid!.isNotEmpty) {
          final user = FirebaseService.instance.currentUser;
          final senderName = user?.displayName ??
              (FirebaseService.instance.currentRole == 'client'
                  ? 'Vedant'
                  : 'Siddhant');
          await NotificationService.instance.notifyNewMessage(
            recipientUserId: _recipientUid!,
            senderName: senderName,
            messageSnippet: text,
            conversationId: convId,
          );
        }
      } catch (e) {
        debugPrint('Error persisting message to Firestore: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Attachment',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.fileText, color: Color(0xFFA23D33), size: 22),
                ),
              ),
              title: Text(
                'Document / Specifications (PDF)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Attach requirements, specs, or contract files',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _attachSampleDocument();
              },
            ),
            const Divider(height: 16, color: AppColors.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.image, color: AppColors.primary, size: 22),
                ),
              ),
              title: Text(
                'Design Draft / Figma Preview',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Share Figma link or UI preview screenshot',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _attachSampleFigmaPreview();
              },
            ),
            const Divider(height: 16, color: AppColors.border),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDF2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(LucideIcons.handshake, color: AppColors.primaryDark, size: 22),
                ),
              ),
              title: Text(
                'Custom Milestone Proposal',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Propose custom budget or milestone amendment',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/send-offer');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  void _attachSampleDocument() {
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    setState(() {
      _messages.add(
        ChatBubbleData(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          text: '',
          timestamp: timeStr,
          isOutgoing: true,
          isDelivered: true,
          isRead: false,
          attachment: ChatFileAttachment(
            fileName: 'client_brand_guidelines_2026.pdf',
            fileSize: '3.8 MB',
            fileType: 'PDF document',
            uploadTime: timeStr,
          ),
        ),
      );
    });
    _scrollToBottom();
  }

  void _attachSampleFigmaPreview() {
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    setState(() {
      _messages.add(
        ChatBubbleData(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          text: '',
          timestamp: timeStr,
          isOutgoing: true,
          isDelivered: true,
          isRead: false,
          previewCard: const ChatPreviewCard(
            title: 'Checkout_Flow_Mockups_v2.fig',
            subtitle: 'Figma Project • Interactive preview',
            tag: 'Design Review',
          ),
        ),
      );
    });
    _scrollToBottom();
  }

  void _showAudioCallDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.phone, color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Call $_displayContactName',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'End-to-end encrypted voice session on FreelanceHub Secure VoIP network.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling $_displayContactName...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Start Call',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenuOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.briefcase, color: AppColors.textDark, size: 20),
              title: Text('View Project Workspace', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/project-workspace');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
              title: Text('Escrow Protection Terms', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamed('/escrow-payments');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bellOff, color: AppColors.textDark, size: 20),
              title: Text('Mute Notifications', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications muted for this conversation.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: AppColors.error, size: 20),
              title: Text('Report or Dispute', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dispute resolution center opened.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FE),
      appBar: _buildHeaderAppBar(),
      body: Column(
        children: [
          _buildPinnedProjectContextBar(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildDateBadge(),
                const SizedBox(height: 12),
                _buildEscrowSecurityBanner(),
                const SizedBox(height: 16),
                if (_messages.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.messageSquareDashed, size: 36, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send a message to $_displayContactName to get started.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ..._messages.map((msg) => _buildMessageRow(msg)),
                ],
                if (_showSarahTyping) ...[
                  const SizedBox(height: 8),
                  _buildTypingIndicatorRow(),
                ],
                const SizedBox(height: 16),
                _buildQuickActionOfferPrompt(),
                const SizedBox(height: 14),
                _buildEscrowFootnote(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          _buildBottomMessageInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildHeaderAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 22),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6ECC5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    _displayContactInitials,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E5033),
                    ),
                  ),
                ),
              ),
              if (widget.isOnline)
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayContactName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: widget.isOnline ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.phone, size: 20, color: AppColors.textDark),
          onPressed: _showAudioCallDialog,
        ),
        IconButton(
          icon: const Icon(LucideIcons.moreVertical, size: 20, color: AppColors.textDark),
          onPressed: _showMoreMenuOptions,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.user, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedProjectContextBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEDF2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFB6ECC5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(LucideIcons.archive, size: 18, color: Color(0xFF1E5033)),
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
                        widget.projectTitle,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6ECC5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.projectStatus.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E5033),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: '\$${widget.projectBudget.toStringAsFixed(0)} Fixed • '),
                      TextSpan(
                        text: 'In Escrow (\$${widget.projectInEscrow.toStringAsFixed(0)})',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/project-workspace');
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Workspace',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(LucideIcons.chevronRight, size: 15, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E7EC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Today, October 24',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEscrowSecurityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFB6ECC5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Payments and conversations are secured by '),
                  TextSpan(
                    text: 'Escrow Protection',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '. Keep all transactions on platform.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatBubbleData msg) {
    if (msg.isOutgoing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (msg.previewCard != null)
              _buildDeliverablePreviewBubble(msg.previewCard!)
            else if (msg.attachment != null)
              _buildAttachmentBubble(msg.attachment!, isOutgoing: true)
            else
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.white,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.timestamp,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.primary),
                  if (msg.isRead) ...[
                    const SizedBox(width: 3),
                    Text(
                      'Read',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Incoming message from Sarah Johnson
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E7EC),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Center(
                child: Text(
                  _displayContactInitials,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.attachment != null)
                    _buildAttachmentBubble(msg.attachment!, isOutgoing: false)
                  else
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEEDF2),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      msg.timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildAttachmentBubble(ChatFileAttachment att, {required bool isOutgoing}) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(LucideIcons.fileText, color: Color(0xFFA23D33), size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      att.fileName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${att.fileSize} • ${att.fileType}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF4F3F8)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening ${att.fileName}...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.download, size: 15, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Download / Preview',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Uploaded ${att.uploadTime}',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverablePreviewBubble(ChatPreviewCard card) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mockup banner container
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F8F1), Color(0xFFEEEDF2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.layout, size: 36, color: AppColors.primaryDark),
                      const SizedBox(height: 6),
                      Text(
                        'Mobile App Screens & Design System',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      card.tag,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        card.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening ${card.title} Figma file...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F3F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.externalLink, size: 16, color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicatorRow() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E7EC),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Center(
            child: Text(
              widget.contactInitials,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFEEEDF2),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionOfferPrompt() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 1)),
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
                  const Icon(LucideIcons.handshake, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Propose Milestone / Scope Change',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Official Contract',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ready to define milestone 2 or revise the delivery budget? Submit an official amendment directly into $_displayContactName\'s review queue.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/project-workspace');
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F3F8),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'View Milestones',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/send-offer');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    'Create Custom Offer',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
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

  Widget _buildEscrowFootnote() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '100% Escrow Protection active on this contract',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMessageInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEDF2), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.paperclip, size: 21, color: AppColors.textSecondary),
            onPressed: _showAttachmentPicker,
            tooltip: 'Attach file or preview',
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F3F8),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x201DBF73),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }
}
