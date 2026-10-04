import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/firebase/firebase_config.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';
import '../models/conversation_model.dart';
import 'individual_chat_screen.dart';

/// Contact data model for active tray and conversations
class ChatContactData {
  final String id;
  final String fullName;
  final String displayName;
  final String initials;
  final String role; // 'Client' or 'Freelancer'
  final bool isOnline;
  final String? projectTitle;
  final double projectBudget;
  final double projectEscrow;

  const ChatContactData({
    required this.id,
    required this.fullName,
    required this.displayName,
    required this.initials,
    required this.role,
    this.isOnline = true,
    this.projectTitle,
    this.projectBudget = 1200.0,
    this.projectEscrow = 800.0,
  });
}

/// Conversation list item data model
class ConversationFeedItem {
  final String id;
  final ChatContactData contact;
  final String lastMessage;
  final String timestamp;
  int unreadCount;
  bool isStarred;
  bool isArchived;
  final bool isDelivered;
  final bool isRead;
  final String? projectTag;

  ConversationFeedItem({
    required this.id,
    required this.contact,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isStarred = false,
    this.isArchived = false,
    this.isDelivered = false,
    this.isRead = false,
    this.projectTag,
  });
}

/// Messages / Inbox screen showcasing multi-user messaging list,
/// active collaborators horizontal tray, real-time search & filter pills,
/// and end-to-end escrow security guarantee.
class MessagesInboxScreen extends StatefulWidget {
  final int initialTabIndex;

  const MessagesInboxScreen({
    super.key,
    this.initialTabIndex = 3,
  });

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // 'all', 'unread', 'starred', 'archived'
  String _searchQuery = '';
  int _currentNavIndex = 3;

  // Active online contacts tray data
  List<ChatContactData> _activeContacts = const [
    ChatContactData(
      id: 'contact-sarah',
      fullName: 'Sarah Johnson',
      displayName: 'Sarah',
      initials: 'SJ',
      role: 'Client',
      isOnline: true,
      projectTitle: 'E-commerce Mobile App MVP',
      projectBudget: 1200.0,
      projectEscrow: 800.0,
    ),
    ChatContactData(
      id: 'contact-michael',
      fullName: 'Michael Chen',
      displayName: 'Michael',
      initials: 'MC',
      role: 'Freelancer',
      isOnline: true,
      projectTitle: 'Fintech Flutter App',
      projectBudget: 2400.0,
      projectEscrow: 1600.0,
    ),
    ChatContactData(
      id: 'contact-emma',
      fullName: 'Emma Williams',
      displayName: 'Emma',
      initials: 'EW',
      role: 'Freelancer',
      isOnline: true,
      projectTitle: 'Brand Guidelines & 3D Assets',
      projectBudget: 950.0,
      projectEscrow: 950.0,
    ),
    ChatContactData(
      id: 'contact-david',
      fullName: 'David Chen',
      displayName: 'David',
      initials: 'DC',
      role: 'Freelancer',
      isOnline: true,
      projectTitle: 'Backend Architecture & API',
      projectBudget: 1800.0,
      projectEscrow: 1200.0,
    ),
    ChatContactData(
      id: 'contact-elena',
      fullName: 'Elena Rostova',
      displayName: 'Elena',
      initials: 'ER',
      role: 'Freelancer',
      isOnline: true,
      projectTitle: 'Design System & Mobile UI',
      projectBudget: 1500.0,
      projectEscrow: 1000.0,
    ),
  ];

  late List<ConversationFeedItem> _conversations;
  StreamSubscription<List<ConversationModel>>? _conversationsSub;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialTabIndex;
    _initConversations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _listenToConversations() {
    if (!FirebaseConfig.instance.isInitialized) return;
    final uid = FirebaseService.instance.currentUser?.uid;
    if (uid == null) return;
    final currentRole = FirebaseService.instance.currentRole;

    try {
      _conversationsSub = FirebaseService.instance.messageRepository
          .streamUserConversations(uid)
          .listen((convList) {
        if (!mounted) return;
        setState(() {
          _conversations = convList.map((conv) {
            final otherUid = conv.participantIds.firstWhere(
              (id) => id != uid,
              orElse: () => '',
            );
            final otherName = conv.participantNames[otherUid] ??
                (currentRole == 'client' ? 'Siddhant' : 'Vedant');
            final otherRole = currentRole == 'client' ? 'Freelancer' : 'Client';
            final otherInitials =
                otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U';

            DateTime messageTime = conv.lastMessageTime;
            final now = DateTime.now();
            final diff = now.difference(messageTime);
            String timeStr;
            if (diff.inDays == 0) {
              timeStr =
                  '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
            } else if (diff.inDays == 1) {
              timeStr = 'Yesterday';
            } else {
              timeStr = '${diff.inDays}d ago';
            }

            return ConversationFeedItem(
              id: conv.id,
              contact: ChatContactData(
                id: otherUid,
                fullName: otherName,
                displayName: otherName.split(' ').first,
                initials: otherInitials,
                role: otherRole,
                isOnline: true,
                projectTitle: 'Active Workspace',
                projectBudget: 0.0,
                projectEscrow: 0.0,
              ),
              lastMessage: conv.lastMessage.isNotEmpty
                  ? conv.lastMessage
                  : 'Conversation started',
              timestamp: timeStr,
              unreadCount: conv.unreadCounts[uid] ?? 0,
              isStarred: false,
              projectTag: 'Active Contract',
            );
          }).toList();
        });
      }, onError: (e) {
        debugPrint('Error streaming conversations: $e');
      });
    } catch (e) {
      debugPrint('Notice streaming conversations: $e');
    }
  }

  void _initConversations() {
    if (FirebaseConfig.instance.isInitialized) {
      _conversations = [];
      final currentRole = FirebaseService.instance.currentRole;
      if (currentRole == 'client') {
        _activeContacts = const [
          ChatContactData(
            id: 'siddhant-freelancer',
            fullName: 'Siddhant Jadhav',
            displayName: 'Siddhant',
            initials: 'SJ',
            role: 'Freelancer',
            isOnline: true,
            projectTitle: 'Mobile App MVP',
            projectBudget: 1500.0,
            projectEscrow: 1500.0,
          ),
        ];
      } else {
        _activeContacts = const [
          ChatContactData(
            id: 'vedant-client',
            fullName: 'Vedant',
            displayName: 'Vedant',
            initials: 'V',
            role: 'Client',
            isOnline: true,
            projectTitle: 'Mobile App MVP',
            projectBudget: 1500.0,
            projectEscrow: 1500.0,
          ),
        ];
      }
      _listenToConversations();
      return;
    }
    _conversations = [
      ConversationFeedItem(
        id: 'conv-1',
        contact: const ChatContactData(
          id: 'sarah-j',
          fullName: 'Sarah Johnson',
          displayName: 'Sarah',
          initials: 'SJ',
          role: 'Client',
          isOnline: true,
          projectTitle: 'E-Commerce Mobile App MVP',
          projectBudget: 1200.0,
          projectEscrow: 800.0,
        ),
        lastMessage: "I've submitted the updated proposal for review...",
        timestamp: '10:42 AM',
        unreadCount: 2,
        isStarred: true,
        projectTag: 'E-Commerce Mobile App',
      ),
      ConversationFeedItem(
        id: 'conv-2',
        contact: const ChatContactData(
          id: 'michael-c',
          fullName: 'Michael Chen',
          displayName: 'Michael',
          initials: 'MC',
          role: 'Freelancer',
          isOnline: true,
          projectTitle: 'Fintech Flutter App',
          projectBudget: 2400.0,
          projectEscrow: 1600.0,
        ),
        lastMessage: 'Can we discuss the project timeline before the next milestone?',
        timestamp: 'Yesterday',
        unreadCount: 1,
        isStarred: false,
        projectTag: 'Fintech Flutter App',
      ),
      ConversationFeedItem(
        id: 'conv-3',
        contact: const ChatContactData(
          id: 'emma-w',
          fullName: 'Emma Williams',
          displayName: 'Emma',
          initials: 'EW',
          role: 'Freelancer',
          isOnline: false,
          projectTitle: 'Brand Guidelines & 3D Assets',
          projectBudget: 950.0,
          projectEscrow: 950.0,
        ),
        lastMessage: "Thanks, I'll review the Figma specs and share the updated wireframes.",
        timestamp: 'Monday',
        unreadCount: 0,
        isStarred: true,
        isDelivered: true,
        isRead: true,
        projectTag: 'Brand Guidelines & 3D Assets',
      ),
      ConversationFeedItem(
        id: 'conv-4',
        contact: const ChatContactData(
          id: 'david-c',
          fullName: 'David Chen',
          displayName: 'David',
          initials: 'DC',
          role: 'Freelancer',
          isOnline: false,
          projectTitle: 'Backend Architecture',
          projectBudget: 1800.0,
          projectEscrow: 1200.0,
        ),
        lastMessage: 'Escrow payment for Milestone 2 has been confirmed. Working on the API now.',
        timestamp: 'Oct 22',
        unreadCount: 0,
        isStarred: false,
        isDelivered: true,
        isRead: false,
      ),
      ConversationFeedItem(
        id: 'conv-5',
        contact: const ChatContactData(
          id: 'alex-r',
          fullName: 'Alex Rivera',
          displayName: 'Alex',
          initials: 'AR',
          role: 'Client',
          isOnline: true,
          projectTitle: 'Design System Audit',
          projectBudget: 600.0,
          projectEscrow: 600.0,
        ),
        lastMessage: "Let's schedule a 15-min sync call tomorrow morning.",
        timestamp: 'Oct 19',
        unreadCount: 0,
        isStarred: false,
      ),
    ];
  }

  List<ConversationFeedItem> get _filteredConversations {
    return _conversations.where((conv) {
      // Filter tab logic
      if (_selectedFilter == 'unread' && conv.unreadCount == 0) {
        return false;
      }
      if (_selectedFilter == 'starred' && !conv.isStarred) {
        return false;
      }
      if (_selectedFilter == 'archived' && !conv.isArchived) {
        return false;
      }

      // Search query logic
      if (_searchQuery.isNotEmpty) {
        final nameMatch = conv.contact.fullName.toLowerCase().contains(_searchQuery);
        final msgMatch = conv.lastMessage.toLowerCase().contains(_searchQuery);
        final tagMatch = conv.projectTag?.toLowerCase().contains(_searchQuery) ?? false;
        if (!nameMatch && !msgMatch && !tagMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get _unreadTotalCount {
    return _conversations.fold<int>(0, (sum, item) => sum + item.unreadCount);
  }

  void _openChat(ChatContactData contact, {String? conversationId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IndividualChatScreen(
          conversationId: conversationId,
          contactName: contact.fullName,
          contactRole: contact.role,
          contactInitials: contact.initials,
          isOnline: contact.isOnline,
          projectTitle: contact.projectTitle ?? 'FreelanceHub Project',
          projectBudget: contact.projectBudget,
          projectInEscrow: contact.projectEscrow,
        ),
      ),
    ).then((_) {
      // Refresh unread if needed
      setState(() {});
    });
  }

  void _toggleStarred(ConversationFeedItem item) {
    setState(() {
      item.isStarred = !item.isStarred;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredConversations;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildTopHeaderAppBar(),
      body: CustomScrollView(
        slivers: [
          // Search & Filter Pills Bar (Sticky)
          SliverToBoxAdapter(
            child: _buildSearchAndFilters(),
          ),

          // Active Contacts Tray
          SliverToBoxAdapter(
            child: _buildActiveContactsTray(),
          ),

          // Divider Section Track
          const SliverToBoxAdapter(
            child: Divider(
              height: 8,
              thickness: 8,
              color: Color(0xFFF4F3F8),
            ),
          ),

          // Conversation Feed List or Empty State
          if (filteredList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredList[index];
                  final isLast = index == filteredList.length - 1;
                  return Column(
                    children: [
                      _buildConversationRow(item),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.only(left: 72, right: 16),
                          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEDF2)),
                        ),
                    ],
                  );
                },
                childCount: filteredList.length,
              ),
            ),

          // End-of-Inbox Escrow Protection Guarantee
          SliverToBoxAdapter(
            child: _buildEscrowProtectionFooter(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildTopHeaderAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
              children: [
                const TextSpan(text: 'FreelanceHub'),
                TextSpan(
                  text: '.',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell, size: 22, color: AppColors.textDark),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All notifications are up to date.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          tooltip: 'Notifications',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 2),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening user profile...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
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
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations or messages...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(LucideIcons.search, size: 19, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill(
                  id: 'all',
                  label: 'All (12)',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  id: 'unread',
                  label: 'Unread',
                  badgeCount: '$_unreadTotalCount',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  id: 'starred',
                  label: 'Starred',
                  icon: LucideIcons.star,
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  id: 'archived',
                  label: 'Archived',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String id,
    required String label,
    String? badgeCount,
    IconData? icon,
  }) {
    final isSelected = _selectedFilter == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = id;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF4F3F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContactsTray() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE CONTACTS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${_activeContacts.length} online now',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _activeContacts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final contact = _activeContacts[index];
                return InkWell(
                  onTap: () => _openChat(contact),
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEDF2),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 0.75),
                            ),
                            child: Center(
                              child: Text(
                                contact.initials,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                          if (contact.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        contact.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationRow(ConversationFeedItem item) {
    final isUnread = item.unreadCount > 0;

    return InkWell(
      onTap: () {
        setState(() {
          item.unreadCount = 0;
        });
        _openChat(item.contact, conversationId: item.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isUnread ? const Color(0xFFFAF9FE) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Avatar with Online Dot
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEDF2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      item.contact.initials,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                if (item.contact.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
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

            // Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Name, Role Badge, Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.contact.fullName,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E7EC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.contact.role,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D4A40),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.timestamp,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          color: isUnread ? AppColors.primaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Project Tag Badge
                  if (item.projectTag != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEDF2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.folderOpen, size: 12, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.projectTag!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D4A40),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 5),

                  // Preview Text, Read Checkmark, and Badge / Star
                  Row(
                    children: [
                      if (item.isRead) ...[
                        const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                      ] else if (item.isDelivered) ...[
                        const Icon(LucideIcons.check, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.unreadCount > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${item.unreadCount}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _toggleStarred(item),
                          child: Icon(
                            item.isStarred ? LucideIcons.star : LucideIcons.star,
                            size: 16,
                            color: item.isStarred ? const Color(0xFFFFB800) : const Color(0xFFBBCABD),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F3F8),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(LucideIcons.messageSquareDashed, size: 28, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No conversations found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your filter or search query to find previous client interactions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscrowProtectionFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'END-TO-END ESCROW PROTECTED',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF3D4A40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keep all payments and contract communications on FreelanceHub to ensure financial security and project dispute coverage.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() => _currentNavIndex = index);
        if (index == 0) {
          Navigator.of(context).pushReplacementNamed('/client-home');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/project-workspace');
        } else if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Explore talent and project listings.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (index == 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client Profile and preferences.'),
              behavior: SnackBarBehavior.floating,
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
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.house, size: 24),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.compass, size: 24),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.briefcase, size: 24),
          label: 'Projects',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.messageSquare, size: 24),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(LucideIcons.user, size: 24),
          label: 'Profile',
        ),
      ],
    );
  }
}
