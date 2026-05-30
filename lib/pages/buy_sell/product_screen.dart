import 'package:e_waste/app/widgets/premium_mode_ui.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';
import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.productInfo});

  final Map<String, dynamic> productInfo;

  @override
  Widget build(BuildContext context) {
    final price = productInfo['price'];

    return PremiumModeShell(
      appBar: AppBar(
        title: const Text('Listing details'),
        actions: const [ThemeToggleIconButton()],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          PremiumModeSurface(
            padding: EdgeInsets.zero,
            borderRadius: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Image.network(
                      productInfo['imageUrl'] ?? productInfo['image_url'] ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productInfo['name'] ?? 'Product',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C8C6B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '₹$price',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C8C6B),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Reusable listing',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if ((productInfo['seller_name'] ?? '').toString().isNotEmpty) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: (productInfo['seller_profile_url'] ?? '').toString().isEmpty
                                  ? null
                                  : NetworkImage(productInfo['seller_profile_url'].toString()),
                              child: (productInfo['seller_profile_url'] ?? '').toString().isEmpty
                                  ? const Icon(Icons.person_outline, size: 18)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productInfo['seller_name']?.toString() ?? 'Seller',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    'Posted by the product owner',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                      Text(
                        productInfo['description'] ?? '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if ((productInfo['topics'] as List<dynamic>? ?? const []).isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (productInfo['topics'] as List<dynamic>)
                              .map(
                                (topic) => Chip(
                                  label: Text(topic.toString()),
                                  side: BorderSide.none,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const PremiumModeSectionHeader(
            title: 'Seller contact',
            subtitle: 'Reach out directly for pickup, delivery, or item questions.',
          ),
          const SizedBox(height: 12),
          PremiumModeSurface(
            child: Column(
              children: [
                _infoRow(context, Icons.phone_outlined, 'Phone', productInfo['phone'] ?? ''),
                const Divider(),
                _infoRow(context, Icons.email_outlined, 'Email', productInfo['email'] ?? ''),
                const Divider(),
                _infoRow(context, Icons.location_on_outlined, 'Address', productInfo['address'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1A5269)),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value.toString().isEmpty ? 'Not provided' : value.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
