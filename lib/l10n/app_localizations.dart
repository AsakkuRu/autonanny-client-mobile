import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'АвтоНяня'**
  String get appTitle;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @map.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get map;

  /// No description provided for @schedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get schedule;

  /// No description provided for @balance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get balance;

  /// No description provided for @children.
  ///
  /// In ru, this message translates to:
  /// **'Дети'**
  String get children;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @themeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тема оформления'**
  String get themeTitle;

  /// No description provided for @themeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeDark;

  /// No description provided for @themeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get themeAuto;

  /// No description provided for @languageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get languageTitle;

  /// No description provided for @tripHistory.
  ///
  /// In ru, this message translates to:
  /// **'История поездок'**
  String get tripHistory;

  /// No description provided for @tripExportPdf.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт поездок PDF'**
  String get tripExportPdf;

  /// No description provided for @spendingAnalytics.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика расходов'**
  String get spendingAnalytics;

  /// No description provided for @supportChat.
  ///
  /// In ru, this message translates to:
  /// **'Техподдержка'**
  String get supportChat;

  /// No description provided for @faq.
  ///
  /// In ru, this message translates to:
  /// **'Частые вопросы'**
  String get faq;

  /// No description provided for @sharedRides.
  ///
  /// In ru, this message translates to:
  /// **'Совместные поездки'**
  String get sharedRides;

  /// No description provided for @referralProgram.
  ///
  /// In ru, this message translates to:
  /// **'Реферальная программа'**
  String get referralProgram;

  /// No description provided for @submitComplaint.
  ///
  /// In ru, this message translates to:
  /// **'Подать жалобу'**
  String get submitComplaint;

  /// No description provided for @noData.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get noData;

  /// No description provided for @from.
  ///
  /// In ru, this message translates to:
  /// **'Откуда'**
  String get from;

  /// No description provided for @to.
  ///
  /// In ru, this message translates to:
  /// **'Куда'**
  String get to;

  /// No description provided for @price.
  ///
  /// In ru, this message translates to:
  /// **'Стоимость'**
  String get price;

  /// No description provided for @driver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get driver;

  /// No description provided for @date.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get date;

  /// No description provided for @status.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get status;

  /// No description provided for @completed.
  ///
  /// In ru, this message translates to:
  /// **'Завершена'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменена'**
  String get cancelled;

  /// No description provided for @active.
  ///
  /// In ru, this message translates to:
  /// **'Активна'**
  String get active;

  /// No description provided for @rating.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг'**
  String get rating;

  /// No description provided for @reviews.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get reviews;

  /// No description provided for @sendMessage.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get sendMessage;

  /// No description provided for @typeMessage.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение...'**
  String get typeMessage;

  /// No description provided for @complaintReason.
  ///
  /// In ru, this message translates to:
  /// **'Причина жалобы'**
  String get complaintReason;

  /// No description provided for @complaintDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get complaintDescription;

  /// No description provided for @promoCode.
  ///
  /// In ru, this message translates to:
  /// **'Промокод'**
  String get promoCode;

  /// No description provided for @applyPromo.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get applyPromo;

  /// No description provided for @copyCode.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get copyCode;

  /// No description provided for @shareCode.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get shareCode;

  /// No description provided for @invitedCount.
  ///
  /// In ru, this message translates to:
  /// **'Приглашено'**
  String get invitedCount;

  /// No description provided for @bonusEarned.
  ///
  /// In ru, this message translates to:
  /// **'Заработано бонусов'**
  String get bonusEarned;

  /// No description provided for @totalSpent.
  ///
  /// In ru, this message translates to:
  /// **'Общие расходы'**
  String get totalSpent;

  /// No description provided for @tripsCount.
  ///
  /// In ru, this message translates to:
  /// **'Поездок'**
  String get tripsCount;

  /// No description provided for @averageCost.
  ///
  /// In ru, this message translates to:
  /// **'Средняя стоимость'**
  String get averageCost;

  /// No description provided for @period.
  ///
  /// In ru, this message translates to:
  /// **'Период'**
  String get period;

  /// No description provided for @week.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get week;

  /// No description provided for @month.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get month;

  /// No description provided for @quarter.
  ///
  /// In ru, this message translates to:
  /// **'Квартал'**
  String get quarter;

  /// No description provided for @year.
  ///
  /// In ru, this message translates to:
  /// **'Год'**
  String get year;

  /// No description provided for @search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get search;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @offlineMode.
  ///
  /// In ru, this message translates to:
  /// **'Оффлайн-режим'**
  String get offlineMode;

  /// No description provided for @offlineHint.
  ///
  /// In ru, this message translates to:
  /// **'Нет подключения к интернету. Отображаются кэшированные данные.'**
  String get offlineHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
