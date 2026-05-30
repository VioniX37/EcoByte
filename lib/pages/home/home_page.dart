import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/about/about_page.dart';
import 'package:e_waste/pages/buy_sell/buy_screen.dart';
import 'package:e_waste/pages/buy_sell/my_products.dart';
import 'package:e_waste/pages/buy_sell/product_screen.dart';
import 'package:e_waste/pages/buy_sell/sell_screen.dart';
import 'package:e_waste/pages/home/know_ewaste.dart';
import 'package:e_waste/pages/profile/profile.dart';
import 'package:e_waste/pages/profile/rewards.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<Map<String, dynamic>>> fetchProducts() async {
  return SupabaseRepository.fetchProducts();
}

void logout(BuildContext context) async {
  await SupabaseRepository.client.auth.signOut();
  if (!context.mounted) {
    return;
  }
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (ctx) => LoginScreen()),
    (route) => false,
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<_DashboardData> _dashboardFuture;
  dynamic _dashboardChannel;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    _dashboardChannel = SupabaseRepository.client.channel('home-dashboard-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (_) => _refreshDashboard(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (_) => _refreshDashboard(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (_) => _refreshDashboard(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'rewards',
        callback: (_) => _refreshDashboard(),
      )
      .subscribe();
  }

  Future<_DashboardData> _loadDashboardData() async {
    final userId = SupabaseRepository.currentUserId;
    final results = await Future.wait([
      SupabaseRepository.fetchProducts(),
      SupabaseRepository.fetchMessages(currentUserId: userId),
      SupabaseRepository.fetchCurrentRewardPoints(),
      userId == null
          ? Future.value(<Map<String, dynamic>>[])
          : SupabaseRepository.fetchMyProducts(userId),
    ]);

    final products = results[0] as List<Map<String, dynamic>>;
    final messages = results[1] as List<Map<String, dynamic>>;
    final points = results[2] as int;
    final myProducts = results[3] as List<Map<String, dynamic>>;

    return _DashboardData(
      products: products,
      myProducts: myProducts,
      communityPosts: messages.length,
      points: points,
    );
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _loadDashboardData();
    });
  }

  @override
  void dispose() {
    if (_dashboardChannel != null) {
      SupabaseRepository.client.removeChannel(_dashboardChannel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        final dashboard = snapshot.data;
        final products = dashboard?.products ?? <Map<String, dynamic>>[];
        final myProducts = dashboard?.myProducts ?? <Map<String, dynamic>>[];
        final listingCount = products.length;
        final communityPosts = dashboard?.communityPosts ?? 0;
        final points = dashboard?.points ?? 0;
        final featuredProducts = products.take(5).toList();
        final totalListingValue = myProducts.fold<double>(
          0,
          (sum, product) => sum + ((product['price'] as num?)?.toDouble() ?? 0),
        );

        return PremiumModeShell(
          appBar: AppBar(
            title: const Text('EcoByte'),
            actions: [
              IconButton(
                onPressed: _refreshDashboard,
                tooltip: 'Refresh dashboard',
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
                      logout(context);
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
          child: RefreshIndicator(
            onRefresh: () async {
              _refreshDashboard();
              await _dashboardFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
              PremiumModeSurface(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reduce\nE-waste\nBuild Value.',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sell reusable devices, discover listings, and keep every item in circulation for longer.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/waste.png',
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _HeroStat(label: 'Listings', value: 'Live'),
                        _HeroStat(label: 'Reuse impact', value: 'Premium'),
                        _HeroStat(label: 'Actions', value: 'Fast'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const PremiumModeSectionHeader(
                title: 'Quick access',
                subtitle: 'Jump straight to the parts of the app people use most.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tileWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: tileWidth,
                        child: PremiumModeActionTile(
                          label: 'Marketplace',
                          subtitle: 'Browse reusable items',
                          icon: Icons.storefront_outlined,
                          accent: const Color(0xFF1A5269),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const BuyScreen()),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: PremiumModeActionTile(
                          label: 'Upload product',
                          subtitle: 'Create a listing',
                          icon: Icons.upload_outlined,
                          accent: const Color(0xFF2C8C6B),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => SellScreen()),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: PremiumModeActionTile(
                          label: 'Rewards',
                          subtitle: 'View available perks',
                          icon: Icons.emoji_events_outlined,
                          accent: const Color(0xFFF59E0B),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const Rewards()),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: tileWidth,
                        child: PremiumModeActionTile(
                          label: 'Profile',
                          subtitle: 'Edit your account',
                          icon: Icons.person_outline,
                          accent: const Color(0xFF6D5BD0),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              PremiumModeSurface(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A5269).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1A5269)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'View your listings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Open your published items and track what you have on sale right now.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const MyProducts()),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DashboardMiniStat(
                      label: 'My listings',
                      value: myProducts.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DashboardMiniStat(
                      label: 'Total value',
                      value: '₹${totalListingValue.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              PremiumModeSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PremiumModeSectionHeader(
                      title: 'Impact snapshot',
                      subtitle: 'A cleaner view of how the app pushes reuse and recycling forward.',
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        final metricWidth = isWide
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: metricWidth,
                              child: PremiumModeMetricCard(
                                label: 'Live listings',
                                value: listingCount.toString(),
                                icon: Icons.inventory_2_outlined,
                                accent: const Color(0xFF1A5269),
                              ),
                            ),
                            SizedBox(
                              width: metricWidth,
                              child: PremiumModeMetricCard(
                                label: 'Community posts',
                                value: communityPosts.toString(),
                                icon: Icons.forum_outlined,
                                accent: const Color(0xFF2C8C6B),
                              ),
                            ),
                            SizedBox(
                              width: metricWidth,
                              child: PremiumModeMetricCard(
                                label: 'Your points',
                                value: points.toString(),
                                icon: Icons.emoji_events_outlined,
                                accent: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const PremiumModeSectionHeader(
                title: 'Featured listings',
                subtitle: 'A quick preview of the newest reusable items in the marketplace.',
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                PremiumModeSurface(
                  child: Column(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 42),
                      const SizedBox(height: 10),
                      const Text('We could not load featured listings right now.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _refreshDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (featuredProducts.isEmpty)
                PremiumModeSurface(
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 42),
                      const SizedBox(height: 10),
                      const Text('No listings available yet.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => SellScreen()),
                          );
                        },
                        child: const Text('Upload first item'),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 208,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredProducts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final product = featuredProducts[index];
                      return SizedBox(
                        width: 240,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(26),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => ProductScreen(productInfo: product),
                              ),
                            );
                          },
                          child: PremiumModeSurface(
                            padding: EdgeInsets.zero,
                            borderRadius: 26,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                                  child: Image.network(
                                    product['image_url'] ?? product['imageUrl'] ?? '',
                                    height: 102,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '₹ ${product['price']}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFF2C8C6B),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_ios, size: 14),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 18),
              const PremiumModeSectionHeader(
                title: 'Impact goals',
                subtitle: 'The goals are shown as premium image cards instead of a simple logo strip.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 24) / 3
                      : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/3.png')),
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/9.png')),
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/11.png')),
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/12.png')),
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/13.png')),
                      SizedBox(width: cardWidth, child: const _GoalCard(asset: 'assets/17.png')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              PremiumModeSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Know your\nE-waste',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open the guide to understand device categories and safer disposal methods.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.appColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => const EWasteApp()),
                          );
                        },
                        child: const Text('Open guide'),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 12)),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return PremiumModeSurface(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          asset,
          height: 156,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.products,
    required this.myProducts,
    required this.communityPosts,
    required this.points,
  });

  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> myProducts;
  final int communityPosts;
  final int points;
}

class _DashboardMiniStat extends StatelessWidget {
  const _DashboardMiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
