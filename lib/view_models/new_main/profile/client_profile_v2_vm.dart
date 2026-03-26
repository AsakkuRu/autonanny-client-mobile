import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:nanny_client/main.dart' show localeNotifier, themeNotifier;
import 'package:nanny_client/views/history/trip_history_view.dart';
import 'package:nanny_client/views/pages/child_edit.dart';
import 'package:nanny_client/views/pages/children_list.dart';
import 'package:nanny_client/views/referral/referral_view.dart';
import 'package:nanny_client/views/support/complaint_view.dart';
import 'package:nanny_client/views/support/faq_view.dart';
import 'package:nanny_client/views/support/support_chat_view.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_components/text_masks.dart';
import 'package:nanny_components/widgets/nanny_text_forms.dart';
import 'package:nanny_core/api/api_models/update_me_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_core/nanny_local_auth.dart';

class ClientProfileV2Vm extends ViewModelBase {
  ClientProfileV2Vm({
    required super.context,
    required super.update,
    required this.logoutView,
  });

  final Widget logoutView;

  bool isChildrenLoading = true;

  List<Child> children = [];
  int _tripHistoryCount = 0;

  bool pushEnabled = true;
  bool smsEnabled = false;
  bool useBiometrics = false;
  bool canUseBiometrics = false;
  bool bioAuthEnabled = false;

  Future<void> init() async {
    await _loadChildren();
    await _loadSettings();
    await _loadTripHistoryCount();
    update(() {});
  }

  String get fullName {
    final user = NannyUser.userInfo;
    return '${user?.name ?? ''} ${user?.surname ?? ''}'.trim();
  }

  String get phoneMasked {
    final raw = NannyUser.userInfo?.phone ?? '';
    final numeric = raw.startsWith('+') ? raw.substring(1) : raw;
    if (numeric.length < 10) return raw;
    return TextMasks.phoneMask().maskText(numeric.substring(1));
  }

  String get email {
    final userEmail = NannyUser.userInfo?.jsonData['email']?.toString();
    if (userEmail == null || userEmail.isEmpty) return 'Не указан';
    return userEmail;
  }

  String get address {
    final userAddress = NannyUser.userInfo?.jsonData['address']?.toString();
    if (userAddress == null || userAddress.isEmpty) return 'Не указан';
    return userAddress;
  }

  String get tripsCount {
    return _tripHistoryCount.toString();
  }

  String get contractsCount {
    final raw = NannyUser.userInfo?.jsonData['contracts_count'];
    if (raw == null) return '${children.length}';
    return raw.toString();
  }

  String get ratingValue {
    final raw = NannyUser.userInfo?.jsonData['rating'];
    if (raw == null) return '4.9';
    return raw.toString();
  }

  String get monthsWithUs {
    final dateRaw = NannyUser.userInfo?.dateReg;
    if (dateRaw == null || dateRaw.isEmpty) return '8 мес';
    try {
      final regDate = DateTime.parse(dateRaw);
      final now = DateTime.now();
      final months = (now.year - regDate.year) * 12 + now.month - regDate.month;
      final normalized = months < 1 ? 1 : months;
      return '$normalized мес';
    } catch (_) {
      return '8 мес';
    }
  }

  String get userInitials {
    final name = NannyUser.userInfo?.name ?? '';
    final surname = NannyUser.userInfo?.surname ?? '';
    final first = name.isNotEmpty ? name.characters.first.toUpperCase() : '';
    final second =
        surname.isNotEmpty ? surname.characters.first.toUpperCase() : '';
    return (first + second).isEmpty ? 'A' : first + second;
  }

  ThemeMode get themeMode => themeNotifier.value;
  Locale get locale => localeNotifier.value;

  Future<void> _loadChildren() async {
    isChildrenLoading = true;
    update(() {});

    final result = await NannyChildrenApi.getChildren();
    if (result.success && result.response != null) {
      children = result.response!;
    } else {
      children = [];
    }

    isChildrenLoading = false;
    update(() {});
  }

  Future<void> _loadSettings() async {
    final settings = await NannyStorage.getSettingsData();
    pushEnabled = settings?.pushNotificationsEnabled ?? true;
    smsEnabled = settings?.smsNotificationsEnabled ?? false;
    useBiometrics = settings?.useBiometrics ?? false;

    canUseBiometrics = await NannyLocalAuth.canUseBiometrics();
    bioAuthEnabled = await NannyLocalAuth.isBiometricsEnabled();
    if (!canUseBiometrics || !bioAuthEnabled) {
      useBiometrics = false;
    }
  }

  Future<void> _loadTripHistoryCount() async {
    final result = await NannyOrdersApi.getTripHistory();
    if (result.success && result.response != null) {
      _tripHistoryCount = result.response!.length;
    } else {
      _tripHistoryCount = 0;
    }
  }

  Future<void> changeProfilePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    final upload = NannyFilesApi.uploadFiles([file]);
    final uploaded = await DioRequest.handleRequest(context, upload);
    if (!uploaded) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);
    final updated = await DioRequest.handleRequest(
      context,
      NannyUsersApi.updateMe(
        UpdateMeRequest(
          photoPath: (await upload).response!.paths.first,
        ),
      ),
    );
    if (!updated) return;

    await NannyUser.getMe();
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    update(() {});
  }

  Future<void> editFullName() async {
    final firstNameController =
        TextEditingController(text: NannyUser.userInfo?.name ?? '');
    final lastNameController =
        TextEditingController(text: NannyUser.userInfo?.surname ?? '');

    final confirmed = await NannyDialogs.showModalDialog(
      context: context,
      title: 'Изменить имя',
      child: Column(
        children: [
          NannyTextForm(
            isExpanded: true,
            labelText: 'Имя',
            initialValue: firstNameController.text,
            onChanged: (v) => firstNameController.text = v,
          ),
          const SizedBox(height: 10),
          NannyTextForm(
            isExpanded: true,
            labelText: 'Фамилия',
            initialValue: lastNameController.text,
            onChanged: (v) => lastNameController.text = v,
          ),
        ],
      ),
    );

    if (!confirmed) return;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Имя и фамилия не могут быть пустыми');
      }
      return;
    }

    await _updateProfile(
        UpdateMeRequest(firstName: firstName, lastName: lastName));
  }

  Future<void> changePassword() async {
    String? password;

    final checked = await _checkOldPassword();
    if (checked == null) return;
    if (!checked) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(context, 'Ошибка', 'Пароли не совпали');
      }
      return;
    }

    if (!context.mounted) return;
    password = await _promptNewPassword();
    if (password == null) return;

    if (password.isEmpty || password.length < 8) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Пароль должен быть не меньше 8 символов');
      }
      return;
    }

    final success = await DioRequest.handleRequest(
      context,
      NannyUsersApi.updateMe(UpdateMeRequest(password: password)),
    );
    if (!success) return;

    final data = await NannyStorage.getLoginData();
    if (data != null) {
      await NannyStorage.updateLoginData(
        LoginStorageData(login: data.login, password: password),
      );
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    NannyDialogs.showMessageBox(context, 'Успех', 'Пароль успешно изменён');
  }

  Future<bool?> _checkOldPassword() async {
    String password = '';
    final keepGoing = await NannyDialogs.showModalDialog(
      context: context,
      title: 'Введите старый пароль',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: NannyPasswordForm(
            onChanged: (text) => password = text,
          ),
        ),
      ),
    );
    if (!keepGoing) return null;

    final loginData = await NannyStorage.getLoginData();
    if (loginData == null) return false;
    return Md5Converter.convert(password) == loginData.password;
  }

  Future<String?> _promptNewPassword() async {
    String? password;
    final keepGoing = await NannyDialogs.showModalDialog(
      context: context,
      title: 'Введите новый пароль',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: NannyPasswordForm(
            onChanged: (text) => password = text,
          ),
        ),
      ),
    );
    if (!keepGoing) return null;
    return password;
  }

  Future<void> changePin() async {
    String code = '';
    final proceed = await NannyDialogs.showModalDialog(
      context: context,
      title: 'Введите старый пин-код',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: NannyPasswordForm(
          onChanged: (text) => code = text,
          keyType: TextInputType.number,
          formatters: [
            MaskTextInputFormatter(
              mask: '####',
              filter: {'#': RegExp(r'[0-9]')},
            ),
          ],
        ),
      ),
    );
    if (!proceed) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);
    final checked = await DioRequest.handleRequest(
        context, NannyAuthApi.checkPinCode(code));
    if (!checked) return;
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    code = '';
    final confirm = await NannyDialogs.showModalDialog(
      context: context,
      title: 'Введите новый пин-код',
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: NannyPasswordForm(
          onChanged: (text) => code = text,
          keyType: TextInputType.number,
          formatters: [
            MaskTextInputFormatter(
              mask: '####',
              filter: {'#': RegExp(r'[0-9]')},
            ),
          ],
        ),
      ),
    );
    if (!confirm) return;
    if (code.length < 4) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Пин-код должен состоять из 4-х цифр');
      }
      return;
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, true);
    final changed =
        await DioRequest.handleRequest(context, NannyAuthApi.setPinCode(code));
    if (!changed) return;
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    NannyDialogs.showMessageBox(context, 'Успех', 'Пин-код изменён');
  }

  Future<void> setBiometrics(bool value) async {
    if (!canUseBiometrics || !bioAuthEnabled) return;
    useBiometrics = value;
    await _saveSettings();
    update(() {});
  }

  Future<void> setPushNotifications(bool value) async {
    pushEnabled = value;
    await _saveSettings();
    update(() {});
  }

  Future<void> setSmsNotifications(bool value) async {
    smsEnabled = value;
    await _saveSettings();
    update(() {});
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await themeNotifier.setThemeMode(mode);
    update(() {});
  }

  Future<void> setLocale(String localeCode) async {
    await localeNotifier.setLocale(localeCode);
    update(() {});
  }

  Future<void> _saveSettings() async {
    final current = await NannyStorage.getSettingsData();
    await NannyStorage.updateSettingsData(
      SettingsStorageData(
        useBiometrics: useBiometrics,
        themeMode: current?.themeMode ?? 'system',
        locale: current?.locale ?? 'ru',
        pushNotificationsEnabled: pushEnabled,
        smsNotificationsEnabled: smsEnabled,
      ),
    );
  }

  Future<void> _updateProfile(UpdateMeRequest request) async {
    if (!context.mounted) return;
    LoadScreen.showLoad(context, true);

    final success = await DioRequest.handleRequest(
        context, NannyUsersApi.updateMe(request));
    if (!success) return;

    await NannyUser.getMe();
    if (!context.mounted) return;

    LoadScreen.showLoad(context, false);
    update(() {});
  }

  Future<void> openChildren() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildrenListView()),
    );
    await _loadChildren();
  }

  Future<void> openChildEdit(Child child) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChildEditView(child: child)),
    );
    await _loadChildren();
  }

  Future<void> openAddChild() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildEditView()),
    );
    await _loadChildren();
  }

  void openTripHistory() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const TripHistoryView()));
  }

  void openReferral() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ReferralView()));
  }

  void openFaq() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqView()));
  }

  void openSupportChat() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const SupportChatView()));
  }

  void openComplaint() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ComplaintView()));
  }

  Future<void> callHotline() async {
    final uri = Uri.parse('tel:88005553535');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Не удалось открыть телефон');
      }
    }
  }

  void openUserAgreement() {
    NannyDialogs.showMessageBox(context, 'Информация',
        'Пользовательское соглашение скоро будет доступно');
  }

  void openPrivacyPolicy() {
    NannyDialogs.showMessageBox(context, 'Информация',
        'Политика конфиденциальности скоро будет доступна');
  }

  Future<void> logout() async {
    final confirmed = await NannyDialogs.confirmAction(
      context,
      'Вы действительно хотите выйти из аккаунта?',
      title: 'Выход из аккаунта',
      confirmText: 'Выйти',
    );
    if (!confirmed) return;

    final success = await DioRequest.handleRequest(context, NannyUser.logout());
    if (!success) return;
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => logoutView),
      (route) => false,
    );
  }
}
