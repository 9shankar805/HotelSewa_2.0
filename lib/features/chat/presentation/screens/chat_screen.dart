import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';
import '../widgets/conversation_list_widget.dart';
import '../widgets/chat_messages_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/new_message_widget.dart';
import '../../../../core/constants/app_constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showConversationList = true;
  String? _selectedConversationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await Future.wait([
      chatProvider.loadConversations(),
      chatProvider.getUnreadCount(),
      chatProvider.loadChatStats(),
    ]);
  }

  void _onConversationSelected(String conversationId) {
    setState(() {
      _selectedConversationId = conversationId;
      _showConversationList = false;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.selectConversation(conversationId);
    chatProvider.loadMessages(conversationId);
    chatProvider.markAsRead(conversationId);
  }

  void _onBackToList() {
    setState(() {
      _showConversationList = true;
      _selectedConversationId = null;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.selectConversation(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showConversationList ? 'Messages' : 'Chat',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: !_showConversationList
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _onBackToList,
              )
            : null,
        actions: [
          if (_showConversationList)
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                      onPressed: () {},
                    ),
                    if (chatProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            chatProvider.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_showConversationList)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: _showSearchDialog,
            ),
          if (!_showConversationList)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black),
              onPressed: _showConversationDetails,
            ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE60023)),
            );
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.gray[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.gray[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chatProvider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60023),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_showConversationList) {
            return Column(
              children: [
                // Stats Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Conversations',
                          chatProvider.conversations.length.toString(),
                          Icons.chat,
                          AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Unread Messages',
                          chatProvider.unreadCount.toString(),
                          Icons.mark_email_unread,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFE60023),
                  labelColor: const Color(0xFFE60023),
                  unselectedLabelColor: AppColors.gray[600],
                  tabs: const [
                    Tab(text: 'Active'),
                    Tab(text: 'Archived'),
                  ],
                ),
                // Conversation List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ConversationListWidget(
                        conversations: chatProvider.activeConversations,
                        onConversationSelected: _onConversationSelected,
                        onRefresh: _loadData,
                      ),
                      ConversationListWidget(
                        conversations: chatProvider.archivedConversations,
                        onConversationSelected: _onConversationSelected,
                        onRefresh: _loadData,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                // Conversation Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            const Color(0xFFE60023).withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: const Color(0xFFE60023),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chatProvider
                                      .selectedConversation?.participantName ??
                                  'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              chatProvider.selectedConversation
                                      ?.participantTypeDisplay ??
                                  'Guest',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (chatProvider.selectedConversation?.isOnline ?? false)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ChatMessagesWidget(
                    messages: chatProvider.selectedConversationMessages ?? [],
                    onRefresh: () async {
                      if (_selectedConversationId != null) {
                        await chatProvider
                            .loadMessages(_selectedConversationId!);
                      }
                    },
                  ),
                ),
                // New Message Input
                NewMessageWidget(
                  onSendMessage: (content, type) async {
                    if (_selectedConversationId != null) {
                      final success = await chatProvider.sendMessage(
                        conversationId: _selectedConversationId!,
                        content: content,
                        type: type,
                      );

                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to send message'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: _showConversationList
          ? FloatingActionButton(
              onPressed: _showNewConversationDialog,
              backgroundColor: const Color(0xFFE60023),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Conversations'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search by name or type...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (query) {
            // Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Participant Name',
                hintText: 'Enter participant name',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Participant Type',
              ),
              items: const [
                DropdownMenuItem(value: 'guest', child: Text('Guest')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'support', child: Text('Support')),
              ],
              onChanged: (value) {
                // Handle participant type change
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Create new conversation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60023),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showConversationDetails() {
    final conversation =
        Provider.of<ChatProvider>(context, listen: false).selectedConversation;

    if (conversation != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conversation Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Participant: ${conversation.participantName}'),
              Text('Type: ${conversation.participantTypeDisplay}'),
              Text('Status: ${conversation.isOnline ? "Online" : "Offline"}'),
              Text('Created: ${conversation.createdAt.toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
