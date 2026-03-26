import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/children_list_vm.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/nanny_core.dart';

class ChildrenListView extends StatefulWidget {
  const ChildrenListView({super.key});

  @override
  State<ChildrenListView> createState() => _ChildrenListViewState();
}

class _ChildrenListViewState extends State<ChildrenListView> {
  late final ChildrenListVM vm;

  @override
  void initState() {
    super.initState();
    vm = ChildrenListVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'Мои дети',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      header: _buildHeader(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.xl,
            0,
            AutonannySpacing.xl,
            AutonannySpacing.lg,
          ),
          child: AutonannyButton(
            label: 'Добавить ребёнка',
            onPressed: vm.addChild,
            leading: const AutonannyIcon(
              AutonannyIcons.add,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем профили детей.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить данные',
              description:
                  snapshot.error?.toString() ?? 'Повторите попытку чуть позже.',
              actionLabel: 'Повторить',
              onAction: () => vm.reloadPage(),
            );
          }

          if (vm.children.isEmpty) {
            return AutonannyEmptyState(
              title: 'У вас пока нет добавленных детей',
              description:
                  'Добавьте профиль ребёнка, чтобы использовать его в поездках и расписаниях.',
              actionLabel: 'Добавить ребёнка',
              onAction: vm.addChild,
              icon: AutonannyIcon(
                AutonannyIcons.child,
                size: 44,
                color: context.autonannyColors.textTertiary,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => vm.reloadPage(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: vm.children.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AutonannySpacing.md),
              itemBuilder: (context, index) =>
                  _buildChildCard(vm.children[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Профили детей',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Управляйте детскими профилями и держите важную информацию под рукой.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: const AutonannyIcon(
              AutonannyIcons.child,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Child child) {
    final imageUrl = (child.photoPath?.isNotEmpty ?? false)
        ? NannyConsts.buildFileUrl(child.photoPath)
        : null;
    final image =
        imageUrl == null || imageUrl.isEmpty ? null : NetworkImage(imageUrl);
    final subtitleParts = <String>[
      child.ageDisplay,
      if (child.schoolClass?.isNotEmpty ?? false) child.schoolClass!,
    ];

    return AutonannyCard(
      child: Row(
        children: [
          AutonannyAvatar(
            image: image,
            initials: child.fullName.isNotEmpty ? child.fullName[0] : 'Р',
            size: 56,
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: AutonannyTypography.labelL(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  subtitleParts.join(' · '),
                  style: AutonannyTypography.bodyS(
                    color: context.autonannyColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          AutonannyIconButton(
            icon: const AutonannyIcon(AutonannyIcons.edit),
            onPressed: () => vm.editChild(child),
            variant: AutonannyIconButtonVariant.ghost,
            size: 40,
          ),
          const SizedBox(width: AutonannySpacing.xs),
          AutonannyIconButton(
            icon: const AutonannyIcon(AutonannyIcons.close),
            onPressed: () => vm.deleteChild(child),
            variant: AutonannyIconButtonVariant.ghost,
            size: 40,
          ),
        ],
      ),
    );
  }
}
