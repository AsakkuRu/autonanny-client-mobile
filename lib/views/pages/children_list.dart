import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/pages/children_list_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class ChildrenListView extends StatefulWidget {
  const ChildrenListView({super.key});

  @override
  State<ChildrenListView> createState() => _ChildrenListViewState();
}

class _ChildrenListViewState extends State<ChildrenListView> {
  late ChildrenListVM vm;

  @override
  void initState() {
    super.initState();
    vm = ChildrenListVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        hasBackButton: true,
        title: "Мои дети",
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, data) {
          if (!data) {
            return const ErrorView(
              errorText: "Не удалось загрузить данные!\nПовторите попытку",
            );
          }

          if (vm.children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.child_care,
                    size: 80,
                    color: NannyTheme.neutral300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'У вас пока нет добавленных детей',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NannyTheme.neutral600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: vm.addChild,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить ребенка'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NannyTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.children.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final child = vm.children[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: NannyTheme.shadow.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: ProfileImage(
                          url: NannyConsts.buildFileUrl(child.photoPath) ?? '',
                          radius: 52,
                          initials: child.fullName.isNotEmpty
                              ? child.fullName[0]
                              : 'Р',
                        ),
                        title: Text(
                          child.fullName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              child.ageDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: NannyTheme.neutral600,
                                  ),
                            ),
                            if (child.schoolClass != null &&
                                child.schoolClass!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                child.schoolClass!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: NannyTheme.neutral500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => vm.editChild(child),
                              icon: const Icon(Icons.edit, size: 20),
                              color: NannyTheme.primary,
                              splashRadius: 20,
                            ),
                            IconButton(
                              onPressed: () => vm.deleteChild(child),
                              icon: const Icon(Icons.delete, size: 20),
                              color: NannyTheme.danger,
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: NannyTheme.shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: vm.addChild,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить ребенка'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }
}
