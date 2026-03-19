import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pages/chats_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';

class ChatsView extends StatefulWidget {
  final bool persistState;
  /// Вызывается после возврата из чата (для сброса бейджа непрочитанных в нижнем баре)
  final VoidCallback? onReturnFromChat;

  const ChatsView({
    super.key,
    this.persistState = false,
    this.onReturnFromChat,
  });

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView>
    with AutomaticKeepAliveClientMixin {
  late ChatsVM vm;

  @override
  void initState() {
    super.initState();
    vm = ChatsVM(
      context: context,
      update: setState,
      onReturnFromChat: widget.onReturnFromChat,
    );
  }

  @override
  void dispose() {
    super.dispose();
    vm.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        hasBackButton: false,
        title: "Сообщения",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            NannyTextForm(
              node: vm.node,
              hintText: 'Поиск по чатам',
              onChanged: vm.chatSearch,
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: NannyTheme.neutral400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NannyTheme.neutral50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => vm.chatsSwitch(switchToChats: false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: vm.chatsSelected
                              ? Colors.transparent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: vm.chatsSelected
                              ? []
                              : [
                                  BoxShadow(
                                    color: NannyTheme.shadow
                                        .withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(
                            "Заявки",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: vm.chatsSelected
                                      ? NannyTheme.neutral500
                                      : NannyTheme.neutral900,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => vm.chatsSwitch(switchToChats: true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: vm.chatsSelected
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: vm.chatsSelected
                              ? [
                                  BoxShadow(
                                    color: NannyTheme.shadow
                                        .withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            "Чаты",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: vm.chatsSelected
                                      ? NannyTheme.neutral900
                                      : NannyTheme.neutral500,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StatefulBuilder(
                builder: (context, update) {
                  vm.updateList = () => update(() {});

                  return vm.chatsSelected
                      ? RequestLoader(
                          request: vm.getChats,
                          completeView: (context, data) {
                            if (data == null) {
                              return Center(
                                child: Text(
                                  "У вас пока нет чатов.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: NannyTheme.neutral500,
                                      ),
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.only(bottom: 20),
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                var e = data.chats[index];
                                return InkWell(
                                  onTap: () {
                                    vm.navigateToDirect(e);
                                    if (vm.node.hasFocus) {
                                      vm.node.unfocus();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ProfileImage(
                                          url: e.photoPath,
                                          radius: 44,
                                          showOnlineDot: false,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.username,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                e.message == null
                                                    ? "Нет сообщений"
                                                    : e.message!.msg,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          NannyTheme.neutral500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          e.message != null
                                              ? DateFormat("HH:mm").format(
                                                  DateTime
                                                      .fromMillisecondsSinceEpoch(
                                                    e.message!.time * 1000,
                                                  ),
                                                )
                                              : "",
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color:
                                                    NannyTheme.neutral400,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                thickness: 1,
                                height: 1,
                                color: NannyTheme.neutral100,
                              ),
                              itemCount: data.chats.length,
                            );
                          },
                          errorView: (context, error) =>
                              ErrorView(errorText: error.toString()),
                        )
                      : RequestLoader(
                          request: vm.getRequests,
                          completeView: (context, data) {
                            if ((data ?? []).isEmpty) {
                              return Center(
                                child: Text(
                                  "У вас нет заявок.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: NannyTheme.neutral500,
                                      ),
                                ),
                              );
                            }

                            return ListView(
                              padding:
                                  const EdgeInsets.only(bottom: 12, top: 4),
                              children: [
                                requestItem(
                                  data: data!
                                      .where((e) => e.fullTime)
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                requestItem(
                                  data: data
                                      .where((e) => !e.fullTime)
                                      .toList(),
                                ),
                              ],
                            );
                          },
                          errorView: (context, error) =>
                              ErrorView(errorText: error.toString()),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget requestItem({required List<ScheduleResponsesData> data}) {
    return Container(
      padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            data.any((e) => e.fullTime)
                ? 'Заявки на полную занятость'
                : 'Заявки на частичную занятость',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                var e = data[index];
                return InkWell(
                  onTap: () => vm.checkScheduleRequest(e),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileImage(url: e.photoPath, radius: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (e.schedule != null) ...[
                                    Text(
                                      e.schedule!.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: NannyTheme.neutral600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    '${e.data.length} маршрутов • ${e.fullTime ? 'полная занятость' : 'частичная'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: NannyTheme.neutral500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: NannyTheme.neutral400,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(
                  thickness: 1, height: 1, color: NannyTheme.grey),
              itemCount: data.length),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}
