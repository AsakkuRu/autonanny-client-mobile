import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class FaqVM {
  FaqVM({
    required this.context,
    required this.update,
  });

  final BuildContext context;
  final void Function(void Function()) update;

  String searchQuery = '';
  String? selectedCategory;

  final TextEditingController searchController = TextEditingController();

  static const List<String> categories = [
    'Регистрация',
    'Поездки',
    'Оплата',
    'Безопасность',
    'Техподдержка',
  ];

  static const List<FaqItem> _allFaq = [
    // Регистрация
    FaqItem(
      category: 'Регистрация',
      question: 'Как зарегистрироваться в приложении?',
      answer: 'Скачайте приложение АвтоНяня, нажмите "Регистрация", введите номер телефона и подтвердите SMS-кодом. Затем заполните имя и придумайте пароль.',
    ),
    FaqItem(
      category: 'Регистрация',
      question: 'Можно ли сменить номер телефона?',
      answer: 'Для смены номера телефона обратитесь в техподдержку через чат в приложении. Мы поможем привязать новый номер к вашему аккаунту.',
    ),
    FaqItem(
      category: 'Регистрация',
      question: 'Как восстановить пароль?',
      answer: 'На экране входа нажмите "Забыли пароль?". Введите номер телефона, получите SMS-код и установите новый пароль.',
    ),

    // Поездки
    FaqItem(
      category: 'Поездки',
      question: 'Как заказать поездку?',
      answer: 'Откройте вкладку "Карта", укажите адрес отправления и назначения, выберите тариф и нажмите "Заказать". Система найдёт ближайшего свободного водителя.',
    ),
    FaqItem(
      category: 'Поездки',
      question: 'Как создать постоянное расписание?',
      answer: 'Перейдите во вкладку "Расписание", нажмите "Создать расписание". Укажите маршруты, дни недели и время. Минимум 4 поездки в месяц. Водители увидят ваше расписание и подадут заявки.',
    ),
    FaqItem(
      category: 'Поездки',
      question: 'Можно ли отменить поездку?',
      answer: 'Да, вы можете отменить поездку в любой момент до начала движения. Если водитель уже выехал, может взиматься частичная плата за вызов.',
    ),
    FaqItem(
      category: 'Поездки',
      question: 'Сколько детей можно отправить одновременно?',
      answer: 'Максимум 4 ребёнка на одного водителя. Это ограничение связано с безопасностью и комфортом перевозки.',
    ),
    FaqItem(
      category: 'Поездки',
      question: 'Как отследить поездку ребёнка?',
      answer: 'После начала поездки вы будете получать push-уведомления о статусе: водитель выехал, прибыл, ребёнок в машине, поездка завершена. На карте отображается текущее положение автомобиля.',
    ),

    // Оплата
    FaqItem(
      category: 'Оплата',
      question: 'Какие способы оплаты доступны?',
      answer: 'Оплата производится с внутреннего баланса. Пополнить баланс можно банковской картой (Visa, MasterCard, Мир) или через СБП. Минимальная сумма пополнения — 100 рублей.',
    ),
    FaqItem(
      category: 'Оплата',
      question: 'Как настроить автоплатёж?',
      answer: 'В разделе "Баланс" → "Настройки автоплатежа" вы можете заранее выбрать карту и включить автосписание. Сейчас автоплатёж работает в тестовом режиме и не запускает реальные списания без вашего подтверждения — перед продуктивным запуском мы сообщим об этом отдельно.',
    ),
    FaqItem(
      category: 'Оплата',
      question: 'Что если баланс отрицательный?',
      answer: 'При отрицательном или нулевом балансе создание новых заказов блокируется. Пополните баланс, чтобы продолжить пользоваться сервисом.',
    ),

    // Безопасность
    FaqItem(
      category: 'Безопасность',
      question: 'Как проверить водителя при встрече?',
      answer: 'Используйте QR-код в карточке водителя. Покажите его водителю для сканирования — это подтверждает, что перед вами именно назначенный водитель.',
    ),
    FaqItem(
      category: 'Безопасность',
      question: 'Что делать в экстренной ситуации?',
      answer: 'Нажмите красную кнопку SOS на экране активной поездки. Ваши координаты будут немедленно отправлены в службу безопасности. Мы свяжемся с вами в кратчайшие сроки.',
    ),
    FaqItem(
      category: 'Безопасность',
      question: 'Как добавить экстренные контакты ребёнка?',
      answer: 'В профиле ребёнка нажмите "Экстренные контакты" и добавьте контакты с именем, телефоном и степенью родства. Водитель увидит их перед поездкой.',
    ),

    // Техподдержка
    FaqItem(
      category: 'Техподдержка',
      question: 'Как связаться с поддержкой?',
      answer: 'Откройте профиль и нажмите "Техподдержка". Напишите сообщение — обычно мы отвечаем в течение часа в рабочее время.',
    ),
    FaqItem(
      category: 'Техподдержка',
      question: 'Как подать жалобу на водителя?',
      answer: 'В профиле нажмите "Подать жалобу" или откройте историю поездок, выберите поездку и нажмите "Подать жалобу". Укажите причину и приложите доказательства. Мы рассмотрим жалобу в течение 24 часов.',
    ),
    FaqItem(
      category: 'Техподдержка',
      question: 'Как оценить водителя?',
      answer: 'После завершения поездки автоматически откроется экран оценки. Поставьте от 1 до 5 звёзд, отметьте критерии и по желанию оставьте текстовый отзыв.',
    ),
  ];

  List<FaqItem> get filteredFaq {
    var items = _allFaq.toList();

    if (selectedCategory != null) {
      items = items.where((f) => f.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      items = items.where((f) =>
        f.question.toLowerCase().contains(q) ||
        f.answer.toLowerCase().contains(q)
      ).toList();
    }

    return items;
  }

  Map<String, List<FaqItem>> get groupedFaq {
    final map = <String, List<FaqItem>>{};
    for (final item in filteredFaq) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  void onSearchChanged(String query) {
    update(() => searchQuery = query);
  }

  void selectCategory(String? category) {
    update(() {
      selectedCategory = selectedCategory == category ? null : category;
    });
  }

  void clearSearch() {
    searchController.clear();
    update(() => searchQuery = '');
  }

  void dispose() {
    searchController.dispose();
  }
}
