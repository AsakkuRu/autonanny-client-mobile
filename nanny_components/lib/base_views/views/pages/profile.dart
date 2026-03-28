import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pages/profile_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class ProfileView extends StatefulWidget {
  final Widget logoutView;
  final bool persistState;

  const ProfileView({
    super.key,
    required this.logoutView,
    this.persistState = false,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin {
  late ProfileVM vm;

  @override
  void initState() {
    super.initState();
    vm = ProfileVM(
        context: context, update: setState, logoutView: widget.logoutView);

    vm.firstName = NannyUser.userInfo!.name;
    vm.lastName = NannyUser.userInfo!.surname;
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      appBar: NannyAppBar(
        title: "Профиль",
        color: NannyTheme.secondary,
        isTransparent: false,
        hasBackButton: false,
        actions: [
          IconButton(
            onPressed: vm.logout,
            icon: const Icon(Icons.exit_to_app_rounded),
            splashRadius: 30,
          )
        ],
      ),
      body: AdaptBuilder(
        builder: (context, size) {
          final user = NannyUser.userInfo!;
          final initials =
              '${user.name.isNotEmpty ? user.name[0] : ''}${user.surname.isNotEmpty ? user.surname[0] : ''}'
                  .toUpperCase();
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: vm.changeProfilePhoto,
                      child: AutonannyAvatar(
                        imageUrl:
                            NannyConsts.buildFileUrl(user.photoPath),
                        initials: initials,
                        size: size.shortestSide * .6,
                        borderRadius: BorderRadius.circular(
                          size.shortestSide * .3,
                        ),
                      ),
                    ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 5,
                              children: [
                                Text(
                                  user.name,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  user.surname,
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            Text(
                              TextMasks.phoneMask().maskText(
                                  user.phone.substring(1)),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: NannyBottomSheet(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              labelText: "Имя",
                              initialValue: vm.firstName,
                              onChanged: (text) => vm.firstName = text.trim(),
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              labelText: "Фамилия",
                              initialValue: vm.lastName,
                              onChanged: (text) => vm.lastName = text.trim(),
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              readOnly: true,
                              labelText: "Пароль",
                              initialValue: "••••••••",
                              onTap: vm.changePassword,
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              readOnly: true,
                              labelText: "Пин-код",
                              initialValue: "••••",
                              onTap: vm.changePincode,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: vm.saveChanges,
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                minimumSize: const WidgetStatePropertyAll(
                                  Size(double.infinity, 60),
                                ),
                              ),
                              child: const Text("Сохранить"),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}
