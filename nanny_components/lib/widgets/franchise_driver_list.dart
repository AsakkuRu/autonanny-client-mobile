import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/widgets/future_handlers/request_loader.dart';
import 'package:nanny_components/widgets/states/error_view.dart';
import 'package:nanny_core/api/nanny_franchise_api.dart';
import 'package:nanny_core/nanny_core.dart';

class FranchiseDriverList<T> extends StatefulWidget {
  final bool persistState;

  final List<T> filterItems;
  final String Function(T item) itemLabel;
  final void Function(T? item) onItemChanged;
  final void Function(UserInfo<void> user) onDriverTap;
  final bool showNewDrivers;

  const FranchiseDriverList({
    super.key,
    required this.filterItems,
    required this.itemLabel,
    required this.onItemChanged,
    required this.onDriverTap,
    required this.showNewDrivers,
    this.persistState = false,
  });

  @override
  State<FranchiseDriverList> createState() => _FranchiseDriverListState<T>();
}

class _FranchiseDriverListState<T> extends State<FranchiseDriverList<T>> with AutomaticKeepAliveClientMixin {
  // Future< ApiResponse<List<DriverUserData>> > request = 
  //   Future< ApiResponse<List<DriverUserData>> >(() => ApiResponse(
  //     response: [
  //       DriverUserData(
  //         driverData: Driver(
  //           city: 1, 
  //           description: "description", 
  //           age: 25, 
  //           refCode: "refCode", 
  //           driverLicense: null, 
  //           carData: null, 
  //           answers: null
  //         ),
  //         userData: UserInfo(
  //           surname: "surname", 
  //           name: "name", 
  //           phone: "78005553535", 
  //           role: [UserType.driver], 
  //           inn: "inn", 
  //           photoPath: "https://77.232.137.74:5000/api/v1.0/files/not_user_photo.png", 
  //           videoPath: "9z"
  //         )
  //       )
  //     ]
  //   ));

  // @override
  // void initState() {
  //   super.initState();
  //   request = widget.showNewDrivers ? NannyFranchiseApi.getNewDrivers() : NannyFranchiseApi.getDrivers();
  // }
  
  @override
  Widget build(BuildContext context) {
    if(wantKeepAlive) super.build(context);
    refreshWidget();
    
    return RefreshIndicator(
      onRefresh: () async => refreshWidget(),
      child: RequestLoader(
        request: request,
        completeView: (context, data) => Column(
          children: [
        
            if(widget.filterItems.isNotEmpty) DropdownButton<T>(
              items: widget.filterItems.map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(widget.itemLabel(e)),
                ),
              ).toList(),
              onChanged: widget.onItemChanged
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: data != null ? data.map(
                  (e) => ListTile(
                    leading: AutonannyAvatar(
                      imageUrl: NannyConsts.buildFileUrl(e.photoPath),
                      initials: _buildInitials(e.name, e.surname),
                      size: 50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    title: Text("${e.name} ${e.surname}"),
                    subtitle: Text(
                      "Статус: ${e.status.name}\n"
                      "Дата регистрации: ${DateFormat("dd.MM.yyyy HH:mm").format(DateTime.parse(e.dateReg))}"
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () => widget.onDriverTap(e),
                  ),
                ).toList()
                : const [
                  Center(child: Text("Нет новых заявок..."))
                ],
              ),
            ),
            
          ],
        ),
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }

  late Future< ApiResponse<List<UserInfo<void>>> > request;

  void refreshWidget() => setState(() {
    request = widget.showNewDrivers ? NannyFranchiseApi.getNewDrivers() : NannyFranchiseApi.getDrivers();
  });
  
  @override
  bool get wantKeepAlive => widget.persistState;

  String _buildInitials(String? name, String? surname) {
    final parts = [name, surname]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'В';
    }
    return parts
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
  }
}
