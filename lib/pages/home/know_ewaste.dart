import 'package:e_waste/pages/map/map.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/home/widgets/dashboard_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:e_waste/app/widgets/theme_toggle_icon_button.dart';

class EWasteApp extends StatelessWidget {
  const EWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const EWasteHomePage();
  }
}

class EWasteHomePage extends StatefulWidget {
  const EWasteHomePage({super.key});

  @override
  State<EWasteHomePage> createState() => _EWasteHomePageState();
}

class _EWasteHomePageState extends State<EWasteHomePage> {
  final List<EWasteCategory> categories = [
    EWasteCategory(
      id: 1,
      title: "Temperature exchange equipment",
      description:
          "More commonly referred to as cooling and freezing equipment. Typical equipment includes refrigerators, freezers, air conditioners, and heat pumps.",
      iconData: Icons.ac_unit,
      color: Colors.lightBlue,
      items: ["Refrigerators", "Freezers", "Air conditioners", "Heat pumps"],
    ),
    EWasteCategory(
      id: 2,
      title: "Screens and monitors",
      description:
          "Typical equipment includes televisions, monitors, laptops, notebooks, and tablets.",
      iconData: Icons.tv,
      color: Colors.indigo,
      items: ["Televisions", "Monitors", "Laptops", "Notebooks", "Tablets"],
    ),
    EWasteCategory(
      id: 3,
      title: "Lamps",
      description:
          "Typical equipment includes fluorescent lamps, high intensity discharge lamps, and LED lamps.",
      iconData: Icons.lightbulb_outline,
      color: Colors.amber,
      items: [
        "Fluorescent lamps",
        "High intensity discharge lamps",
        "LED lamps"
      ],
    ),
    EWasteCategory(
      id: 4,
      title: "Large equipment",
      description:
          "Typical equipment includes washing machines, clothes dryers, dishwashing machines, electric stoves, large printing machines, copying equipment, and photovoltaic panels.",
      iconData: Icons.wash,
      color: Colors.red,
      items: [
        "Washing machines",
        "Clothes dryers",
        "Dishwashing machines",
        "Electric stoves",
        "Large printing machines",
        "Copying equipment",
        "Photovoltaic panels"
      ],
    ),
    EWasteCategory(
      id: 5,
      title: "Small equipment",
      description:
          "Typical equipment includes vacuum cleaners, microwaves, ventilation equipment, toasters, electric kettles, electric shavers, scales, calculators, radio sets, video cameras, electrical and electronic toys, small electrical and electronic tools, small medical devices, small monitoring and control instruments.",
      iconData: Icons.devices_other,
      color: Colors.teal,
      items: [
        "Vacuum cleaners",
        "Microwaves",
        "Toasters",
        "Electric kettles",
        "Electric shavers",
        "Scales",
        "Calculators",
        "Radio sets",
        "Video cameras",
        "Electronic toys",
        "Small tools",
        "Small medical devices"
      ],
    ),
    EWasteCategory(
      id: 6,
      title: "Small IT and Telecommunication equipment",
      description:
          "Typical equipment includes mobile phones, Global Positioning System (GPS) devices, pocket calculators, routers, personal computers, printers, and telephones.",
      iconData: Icons.smartphone,
      color: Colors.purple,
      items: [
        "Mobile phones",
        "GPS devices",
        "Pocket calculators",
        "Routers",
        "Personal computers",
        "Printers",
        "Telephones"
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('E-Waste Groups'),
        elevation: 0,
        actions: const [ThemeToggleIconButton()],
        leading: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          tooltip: 'About E-Waste',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: const Text(
                  'About E-Waste',
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'Electronic waste or e-waste describes discarded electrical or electronic devices. Proper disposal and recycling of e-waste is important for environmental and health reasons.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    child: Text('Close', style: TextStyle(color: scheme.primary)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: DashboardBottomNavigationWidget(
        onDestinationSelected: (value) {
          // Navigate back to main screen and set selected index
          dashboardIndexNotifier.value = value;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const MainScreen()),
            (route) => false,
          );
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildCategoriesGrid(),
          const SizedBox(height: 20),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Know Your E-Waste',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Learn about different categories of electronic waste and how to properly dispose of them.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: scheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.74, // Reduced from 0.85 to give more height
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryDetailPage(category: category),
              ),
            );
          },
          child: CategoryCard(category: category),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why Recycle E-Waste?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoItem(Icons.warning, 'Prevents toxic elements from polluting the environment', scheme),
            _buildInfoItem(Icons.recycling, 'Recovers valuable materials that can be reused', scheme),
            _buildInfoItem(Icons.energy_savings_leaf, 'Saves energy compared to mining raw materials', scheme),
            _buildInfoItem(Icons.health_and_safety, 'Protects human health from hazardous substances', scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: scheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final EWasteCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surfaceContainerHighest : scheme.surface;
    return Card(
      elevation: isDark ? 10 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.7) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark
                  ? category.color.withValues(alpha: 0.7)
                  : category.color.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Icon(
                category.iconData,
                size: 50,
                color: scheme.onPrimary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.id}. ${category.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailPage extends StatelessWidget {
  final EWasteCategory category;

  const CategoryDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onPrimary),
        title: Text(
          category.title,
          style: TextStyle(color: scheme.onPrimary),
        ),
        backgroundColor: scheme.primary,
      ),
      bottomNavigationBar: DashboardBottomNavigationWidget(
        onDestinationSelected: (value) {
          dashboardIndexNotifier.value = value;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const MainScreen()),
            (route) => false,
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(context),
            const SizedBox(height: 24),
            _buildCommonItems(context),
            const SizedBox(height: 24),
            _buildDisposalGuidelines(context),
            const SizedBox(height: 24),
            _buildEnvironmentalImpact(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surfaceContainerHighest : scheme.surface;
    return Card(
      elevation: isDark ? 10 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.7) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: category.color.withValues(alpha: 0.2),
                  child: Icon(
                    category.iconData,
                    size: 30,
                    color: category.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category ${category.id}',
                        style: TextStyle(
                          color: category.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              category.description,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonItems(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surfaceContainerHighest : scheme.surface;
    return Card(
      elevation: isDark ? 10 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.7) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: category.items.map((item) {
                return Chip(
                  label: Text(item, style: TextStyle(color: scheme.onSurface)),
                  backgroundColor: category.color.withValues(alpha: 0.1),
                  side: BorderSide(color: category.color.withValues(alpha: 0.3)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisposalGuidelines(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surfaceContainerHighest : scheme.surface;
    return Card(
      elevation: isDark ? 10 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.7) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disposal Guidelines',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuidelineStep('1', 'Remove personal data', 'For devices with storage, ensure all personal data is securely erased.', scheme),
            _buildGuidelineStep('2', 'Check with manufacturer', 'Many manufacturers offer take-back or recycling programs.', scheme),
            _buildGuidelineStep('3', 'Find a certified e-waste recycler', 'Locate a certified recycling center near you using our map.', scheme),
            _buildGuidelineStep('4', 'Handle with care', 'Some components may contain hazardous materials - avoid breaking them.', scheme),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (ctx) => EWasteMapPage()));
              },
              icon: Icon(Icons.map, color: scheme.onPrimary),
              label: Text('Find Recycling Centers Near Me', style: TextStyle(color: scheme.onPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidelineStep(String number, String title, String description, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: category.color,
            child: Text(
              number,
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpact(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? scheme.surfaceContainerHighest : scheme.surface;
    return Card(
      elevation: isDark ? 10 : 4,
      shadowColor: isDark ? Colors.black.withValues(alpha: 0.7) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Impact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEnvironmentalImpactText(),
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEnvironmentalImpactText() {
    switch (category.id) {
      case 1:
        return 'Temperature exchange equipment often contains refrigerants that can be harmful greenhouse gases if released into the atmosphere. Proper recycling helps prevent ozone depletion and reduces climate change impact.';
      case 2:
        return 'Screens and monitors contain materials like lead, mercury, and flame retardants. Recycling these devices prevents these toxic substances from leaching into soil and water systems.';
      case 3:
        return 'Lamps, especially fluorescent types, contain mercury which is highly toxic. LED lamps contain valuable materials that can be recovered through proper recycling processes.';
      case 4:
        return 'Large equipment contains significant amounts of metals and plastics that can be recovered and reused. Recycling reduces the need for mining raw materials and the associated environmental damage.';
      case 5:
        return 'Small equipment, though individually smaller in impact, collectively contributes significant volumes to e-waste. These devices often contain precious metals and rare earth elements that are valuable to recover.';
      case 6:
        return 'IT equipment contains precious metals like gold, silver, and palladium. One ton of circuit boards contains 40-800 times the amount of gold in one ton of ore. Recycling these metals reduces mining impacts.';
      default:
        return 'Electronic waste contains valuable materials that can be recovered, as well as potentially hazardous substances that need proper handling to prevent environmental contamination.';
    }
  }
}

class EWasteCategory {
  final int id;
  final String title;
  final String description;
  final IconData iconData;
  final Color color;
  final List<String> items;

  EWasteCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.iconData,
    required this.color,
    required this.items,
  });
}
