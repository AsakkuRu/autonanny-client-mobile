import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/support/faq_vm.dart';

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
    final colors = context.autonannyColors;

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'Частые вопросы',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AutonannySpacing.lg,
                AutonannySpacing.sm,
                AutonannySpacing.lg,
                0,
              ),
              child: AutonannySectionContainer(
                child: Column(
                  children: [
                    AutonannyTextField(
                      controller: vm.searchController,
                      onChanged: vm.onSearchChanged,
                      hintText: 'Поиск по вопросам',
                      prefix: const Padding(
                        padding: EdgeInsets.all(14),
                        child: AutonannyIcon(AutonannyIcons.search),
                      ),
                      suffix: vm.searchQuery.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: AutonannyIconButton(
                                size: 36,
                                icon: const AutonannyIcon(
                                  AutonannyIcons.close,
                                ),
                                onPressed: vm.clearSearch,
                                variant: AutonannyIconButtonVariant.ghost,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AutonannySpacing.md),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: FaqVM.categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AutonannySpacing.sm),
                        itemBuilder: (context, index) {
                          final category = FaqVM.categories[index];
                          return _CategoryChip(
                            label: category,
                            isSelected: vm.selectedCategory == category,
                            onTap: () => vm.selectCategory(category),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AutonannySpacing.md),
            Expanded(
              child: grouped.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AutonannySpacing.xl),
                      child: Center(
                            child: AutonannyEmptyState(
                              title: 'Ничего не найдено',
                              description:
                                  'Попробуйте изменить поисковый запрос или выбрать другую категорию.',
                              icon: const AutonannyIcon(AutonannyIcons.search),
                            ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AutonannySpacing.lg,
                        0,
                        AutonannySpacing.lg,
                        AutonannySpacing.xxl,
                      ),
                      children: grouped.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AutonannySpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: colors.statusInfoSurface,
                                      borderRadius: AutonannyRadii.brMd,
                                    ),
                                    child: Center(
                                      child: AutonannyIcon(
                                        _categoryIcon(entry.key),
                                        size: 18,
                                        color: colors.statusInfo,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AutonannySpacing.sm),
                                  Text(
                                    entry.key,
                                    style: AutonannyTypography.h3(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AutonannySpacing.sm),
                              ...entry.value.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AutonannySpacing.sm,
                                  ),
                                  child: _FaqTile(item: item),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  AutonannyIconAsset _categoryIcon(String category) {
    switch (category) {
      case 'Регистрация':
        return AutonannyIcons.profile;
      case 'Поездки':
        return AutonannyIcons.car;
      case 'Оплата':
        return AutonannyIcons.card;
      case 'Безопасность':
        return AutonannyIcons.shield;
      case 'Техподдержка':
        return AutonannyIcons.chat;
      default:
        return AutonannyIcons.help;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final components = context.autonannyComponents;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brFull,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? null : colors.surfaceSecondary,
            gradient: isSelected ? components.primaryActionGradient : null,
            borderRadius: AutonannyRadii.brFull,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colors.borderSubtle,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AutonannyTypography.labelM(
                color: isSelected ? colors.textInverse : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: colors.actionPrimary.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.lg,
            vertical: AutonannySpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            0,
            AutonannySpacing.lg,
            AutonannySpacing.lg,
          ),
          iconColor: colors.actionPrimary,
          collapsedIconColor: colors.textTertiary,
          title: Text(
            item.question,
            style: AutonannyTypography.bodyM(
              color: colors.textPrimary,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            Text(
              item.answer,
              style: AutonannyTypography.bodyS(
                color: colors.textSecondary,
              ).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
