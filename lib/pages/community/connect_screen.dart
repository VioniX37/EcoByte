import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/about/about_page.dart';
import 'package:e_waste/pages/community/add_post.dart';
import 'package:e_waste/pages/buy_sell/buy_screen.dart';
import 'package:e_waste/pages/buy_sell/my_products.dart';
import 'package:e_waste/pages/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;
  dynamic _communityChannel;
  bool _showInfoPanel = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    _communityChannel = SupabaseRepository.client.channel('community-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => setState(() {
          _messagesFuture = _loadMessages();
        }),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'message_likes',
        callback: (_) => setState(() {
          _messagesFuture = _loadMessages();
        }),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (_) => setState(() {
          _messagesFuture = _loadMessages();
        }),
      )
      .subscribe();
  }

  @override
  void dispose() {
    if (_communityChannel != null) {
      SupabaseRepository.client.removeChannel(_communityChannel);
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMessages() async {
    final userId = SupabaseRepository.currentUserId;
    return SupabaseRepository.fetchMessages(currentUserId: userId);
  }

  Future<void> _toggleLike(Map<String, dynamic> message) async {
    final user = SupabaseRepository.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await SupabaseRepository.toggleMessageLike(
      messageId: message['id'].toString(),
      userId: user.id,
      isLiked: message['is_liked'] == true,
    );

    if (mounted) {
      setState(() {
        _messagesFuture = _loadMessages();
      });
    }
  }

  Future<void> _deleteMessage(Map<String, dynamic> message) async {
    final id = message['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm != true) return;

    await SupabaseRepository.deleteMessage(id);
    if (mounted) {
      setState(() {
        _messagesFuture = _loadMessages();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumShell(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showInfoPanel = !_showInfoPanel),
            tooltip: 'Community info',
            icon: Icon(_showInfoPanel ? Icons.info : Icons.info_outline),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _messagesFuture = _loadMessages();
              });
            },
            tooltip: 'Refresh community',
            icon: const Icon(Icons.refresh),
          ),
          const ThemeToggleIconButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                  );
                  break;
                case 'marketplace':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const BuyScreen()),
                  );
                  break;
                case 'my_products':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const MyProducts()),
                  );
                  break;
                case 'about':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const AboutPage()),
                  );
                  break;
                case 'logout':
                  SupabaseRepository.client.auth.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (ctx) => LoginScreen()),
                    (route) => false,
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'marketplace', child: Text('Marketplace')),
              PopupMenuItem(value: 'my_products', child: Text('My products')),
              PopupMenuItem(value: 'about', child: Text('About')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            premiumPageRoute(const AddPost()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showInfoPanel
                  ? Padding(
                      key: const ValueKey('community-info-panel'),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: SingleChildScrollView(
                        child: PremiumHeroBanner(
                          title: 'Share, ask, and inspire',
                          subtitle: 'Post repair wins, recycling ideas, and community updates.',
                          icon: Icons.forum,
                          inlineIconOnMobile: true,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('community-info-hidden')),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: PremiumSectionHeader(
                title: 'Latest posts',
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _messagesFuture = _loadMessages();
                  });
                  await _messagesFuture;
                },
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: const [SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))],
                      );
                    }

                    if (snapshot.hasError) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: PremiumEmptyState(
                              icon: Icons.cloud_off_outlined,
                              title: 'Community feed unavailable',
                              subtitle: 'Try again in a moment while the feed reconnects.',
                              compact: true,
                            ),
                          ),
                        ],
                      );
                    }

                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 96),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: PremiumEmptyState(
                              icon: Icons.chat_bubble_outline,
                              title: 'No posts yet',
                              subtitle: 'Start the conversation with a repair story, giveaway, or recycling tip.',
                              compact: true,
                              action: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(premiumPageRoute(const AddPost()));
                                },
                                child: const Text('Create post'),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                      itemCount: messages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _buildMessageItem(message);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final user = SupabaseRepository.client.auth.currentUser;
    final isMe = user?.id == message['user_id']?.toString();
    final likeCount = (message['like_count'] as num?)?.toInt() ?? 0;
    final isLiked = message['is_liked'] == true;
    final createdAtRaw = message['created_at'];
    final createdAt = createdAtRaw is String ? DateTime.parse(createdAtRaw) : createdAtRaw as DateTime?;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: PremiumSurface(
          gradient: LinearGradient(
            colors: [
              isDark ? scheme.surfaceContainerHighest.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.96),
              isDark ? scheme.surfaceContainerLow.withValues(alpha: 0.88) : const Color(0xFFF3FBF7),
            ],
          ),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: (message['profile_url'] ?? '').toString().isEmpty
                        ? Icon(Icons.person_outline, size: 24, color: scheme.primary)
                        : ClipOval(
                            child: Image.network(
                              message['profile_url'].toString(),
                              height: 42,
                              width: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender_name']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          createdAt == null ? '' : DateFormat('MMMM d, yyyy').format(createdAt),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : scheme.primary,
                    ),
                    onPressed: () => _toggleLike(message),
                  ),
                  if (isMe)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteMessage(message),
                      tooltip: 'Delete post',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message['description']?.toString() ?? '',
                style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurface),
              ),
              if ((message['image_url'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    message['image_url'].toString(),
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$likeCount likes',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
