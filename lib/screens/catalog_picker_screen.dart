import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../widgets/ui.dart';
import 'add_edit_screen.dart';

class CatalogPickerScreen extends StatefulWidget {
  const CatalogPickerScreen({super.key});

  @override
  State<CatalogPickerScreen> createState() => _CatalogPickerScreenState();
}

class _CatalogPickerScreenState extends State<CatalogPickerScreen> {
  String _query = '';
  String? _category; // null = all

  void _open(CatalogItem? item) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => AddEditScreen(template: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final items = catalog
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q))
        .where((c) => _category == null || c.category == _category)
        .toList();
    final usedCategories =
        categories.where((cat) => catalog.any((c) => c.category == cat)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Subscription')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
            sliver: SliverList.list(
              children: [
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search_rounded, color: cs.primary),
                      hintText: 'Search for a service…',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: 14),
                // Custom subscription
                GradientCard(
                  padding: EdgeInsets.zero,
                  radius: 22,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    onTap: () => _open(q.isEmpty
                        ? null
                        : CatalogItem(_query.trim(), 'Other', palette.first)),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                    title: Text(
                      q.isEmpty ? 'Custom Subscription' : 'Add "${_query.trim()}"',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Add any service manually',
                        style: TextStyle(color: Colors.white70)),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final cat in [null, ...usedCategories])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat ?? 'All'),
                            selected: _category == cat,
                            showCheckmark: false,
                            selectedColor: cs.primary,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _category == cat ? Colors.white : null,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            onSelected: (_) => setState(() => _category = cat),
                          ),
                        ),
                    ],
                  ),
                ),
                SectionHeader(
                  q.isNotEmpty
                      ? 'Results (${items.length})'
                      : _category == null
                          ? 'Popular Services (${items.length})'
                          : '$_category (${items.length})',
                  icon: Icons.star_rounded,
                ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Not in the list. Use "Add" above.',
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverGrid.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 76,
              ),
              itemBuilder: (context, i) => _ServiceCard(
                item: items[i],
                onTap: () => _open(items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal service card: icon on the left, big bold name on the right.
/// The name does the work a real logo would, so it gets the spotlight.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final accent = Color(item.color);

    return Container(
      decoration: BoxDecoration(
        color: light ? Colors.white : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: light ? Brand.shadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Soft glow of the service color in the corner.
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ServiceAvatar(name: item.name, color: item.color, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: cs.primary,
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
        ),
      ),
    );
  }
}
