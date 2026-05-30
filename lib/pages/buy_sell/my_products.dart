import 'package:e_waste/app/data/supabase_repository.dart';
import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/pages/buy_sell/product_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({super.key});

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  dynamic _productsChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    _productsChannel = SupabaseRepository.client.channel('my-products-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (_) {
          if (mounted) setState(() {});
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (_) {
          if (mounted) setState(() {});
        },
      )
      .subscribe();
  }

  @override
  void dispose() {
    if (_productsChannel != null) {
      SupabaseRepository.client.removeChannel(_productsChannel);
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadProducts() async {
    final userId = SupabaseRepository.currentUserId;
    if (userId == null) {
      return [];
    }

    return SupabaseRepository.fetchMyProducts(userId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PremiumModeShell(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: scheme.onPrimary.withValues(alpha: 0.22),
          ),
        ),
        title: const Text('My Products'),
        actions: [
          IconButton(
            onPressed: () {
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh my products',
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('No data found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => ProductScreen(productInfo: product),
                          ),
                        );
                      },
                      child: PremiumModeSurface(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product['image_url'] ?? product['imageUrl'] ?? '',
                                height: 110,
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹ ${product['price']}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      showPopup(context, product['id'].toString());
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void showPopup(BuildContext context, String docid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: const Text('Are you sure you want to delete'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await SupabaseRepository.deleteProduct(docid);
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
