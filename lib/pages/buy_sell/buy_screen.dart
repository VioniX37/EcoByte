import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:e_waste/pages/buy_sell/product_screen.dart';
import 'package:e_waste/pages/buy_sell/sell_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final TextEditingController searchController = TextEditingController();
  final List<String> selectedTopics = [];
  late Future<List<Map<String, dynamic>>> _productsFuture;
  dynamic _marketChannel;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    _marketChannel = SupabaseRepository.client.channel('marketplace-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (_) => setState(() => _productsFuture = fetchProducts()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (_) => setState(() => _productsFuture = fetchProducts()),
      )
      .subscribe();
  }

  @override
  void dispose() {
    searchController.dispose();
    if (_marketChannel != null) {
      SupabaseRepository.client.removeChannel(_marketChannel);
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _filterProducts(List<Map<String, dynamic>> source) {
    return source.where((product) {
      final topics = (product['topics'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList();
      final matchesTopic = selectedTopics.isEmpty ||
          selectedTopics.any((topic) => topics.contains(topic));
      final name = (product['name'] ?? '').toString().toLowerCase();
      final description = (product['description'] ?? '').toString().toLowerCase();
      final matchesSearch = _query.isEmpty ||
          name.contains(_query.toLowerCase()) ||
          description.contains(_query.toLowerCase());
      return matchesTopic && matchesSearch;
    }).toList();
  }

  double _estimateDiversionTons(List<Map<String, dynamic>> products) {
    const categoryWeightsKg = {
      'IT equipment': 8.0,
      'Telecommunication': 3.0,
      'Domestic equipments': 12.0,
      'Industrial Components': 20.0,
    };

    var totalKg = 0.0;
    for (final product in products) {
      final topics = (product['topics'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList();
      final category = topics.isNotEmpty ? topics.first : '';
      totalKg += categoryWeightsKg[category] ?? 6.0;
    }

    return totalKg / 1000.0;
  }

  int _countActiveUsers(List<Map<String, dynamic>> products) {
    final userIds = <String>{};
    for (final product in products) {
      final userId = product['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        userIds.add(userId);
      }
    }
    return userIds.length;
  }

  @override
  Widget build(BuildContext context) {
    return PremiumModeShell(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _productsFuture = fetchProducts()),
            tooltip: 'Refresh marketplace',
            icon: const Icon(Icons.refresh),
          ),
          const ThemeToggleIconButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sell') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => SellScreen()),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'sell', child: Text('Upload product')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A5269),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => SellScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _productsFuture = fetchProducts());
          await _productsFuture;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search products, parts, and devices',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF12171D)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFF1A5269).withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'IT equipment',
                  'Telecommunication',
                  'Domestic equipments',
                  'Industrial Components',
                ].map((topic) {
                  final selected = selectedTopics.contains(topic);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      selected: selected,
                      label: Text(topic),
                      onSelected: (_) {
                        setState(() {
                          if (selected) {
                            selectedTopics.remove(topic);
                          } else {
                            selectedTopics.add(topic);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF2C8C6B).withValues(alpha: 0.18),
                      checkmarkColor: const Color(0xFF1A5269),
                      side: BorderSide(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFF1A5269).withValues(alpha: 0.12),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            const PremiumModeSectionHeader(
              title: 'Listings',
              subtitle: 'Tap a card for full details, seller contact, and location.',
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return PremiumModeSurface(
                    child: Column(
                      children: [
                        const Icon(Icons.storefront_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Marketplace is loading slowly.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Please refresh to try again.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(() => _productsFuture = fetchProducts()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allProducts = snapshot.data ?? [];
                final products = _filterProducts(allProducts);
                final stats = _MarketplaceMetrics(
                  reusableItems: allProducts.length,
                  activeUsers: _countActiveUsers(allProducts),
                  divertedTons: _estimateDiversionTons(allProducts),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumModeSurface(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A5269), Color(0xFF2C8C6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Curated marketplace',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Discover reusable devices, parts, and materials with cleaner listings and direct seller contact.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MarketplaceStatCard(
                                  label: 'Reusable items',
                                  value: '${stats.reusableItems}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MarketplaceStatCard(
                                  label: 'Active users',
                                  value: '${stats.activeUsers}',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MarketplaceStatCard(
                                  label: 'E-waste diverted',
                                  value: '${stats.divertedTons.toStringAsFixed(1)}t',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (snapshot.hasError)
                      PremiumModeSurface(
                        child: Column(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              'Marketplace is loading slowly.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Please refresh to try again.'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => setState(() => _productsFuture = fetchProducts()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (products.isEmpty)
                      PremiumModeSurface(
                        child: Column(
                          children: [
                            const Icon(Icons.search_off, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              'No matching listings.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Clear the filters or use a broader search term.'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  selectedTopics.clear();
                                  _query = '';
                                  searchController.clear();
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => ProductScreen(productInfo: product),
                                ),
                              );
                            },
                            child: PremiumModeSurface(
                              padding: EdgeInsets.zero,
                              borderRadius: 28,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                                    child: Image.network(
                                      product['image_url'] ?? product['imageUrl'] ?? '',
                                      width: 124,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if ((product['seller_name'] ?? '').toString().isNotEmpty) ...[
                                            Text(
                                              product['seller_name'].toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          Text(
                                            product['name'] ?? '',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            product['description'] ?? '',
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  height: 1.35,
                                                ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2C8C6B).withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  '₹ ${product['price']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF2C8C6B),
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              const Icon(Icons.arrow_forward_ios, size: 16),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceMetrics {
  const _MarketplaceMetrics({
    required this.reusableItems,
    required this.activeUsers,
    required this.divertedTons,
  });

  final int reusableItems;
  final int activeUsers;
  final double divertedTons;
}

class _MarketplaceStatCard extends StatelessWidget {
  const _MarketplaceStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchProducts() {
  return SupabaseRepository.fetchProducts();
}
