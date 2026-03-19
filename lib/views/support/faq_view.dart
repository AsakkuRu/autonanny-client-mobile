import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/faq_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  late FaqVM vm;

  @override
  void initState() {
    super.initState();
    vm = FaqVM(context: context, update: setState);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = vm.groupedFaq;

    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Частые вопросы',
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: vm.searchController,
                  onChanged: vm.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Поиск по вопросам',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: vm.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: vm.clearSearch,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: NannyTheme.neutral50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: FaqVM.categories.map((cat) {
                      final isSelected = vm.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? Colors.white
                                  : NannyTheme.neutral700,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => vm.selectCategory(cat),
                          backgroundColor: NannyTheme.neutral100,
                          selectedColor: NannyTheme.primary,
                          checkmarkColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: NannyTheme.neutral300),
                        const SizedBox(height: 12),
                        Text(
                          'Ничего не найдено',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcon(entry.key),
                                  size: 18,
                                  color: NannyTheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ],
                            ),
                          ),
                          ...entry.value.map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  title: Text(
                                    item.question,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  children: [
                                    Text(
                                      item.answer,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: NannyTheme.neutral600,
                                            height: 1.5,
                                          ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Регистрация':
        return Icons.person_add;
      case 'Поездки':
        return Icons.directions_car;
      case 'Оплата':
        return Icons.payment;
      case 'Безопасность':
        return Icons.security;
      case 'Техподдержка':
        return Icons.support_agent;
      default:
        return Icons.help_outline;
    }
  }
}
