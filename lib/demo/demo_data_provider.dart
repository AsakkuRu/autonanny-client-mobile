/// B-012 TASK-B12: Провайдер демо-данных для клиентского приложения
/// Содержит статические данные для основных клиентских экранов
class DemoDataProvider {
  static const Map<String, dynamic> _responses = {
    '/users/get_me': {
      'id': 101,
      'name': 'Мария',
      'surname': 'Демо',
      'phone': '79009876543',
      'role': ['client'],
      'photo_path': '',
      'video_path': '',
      'money': 5000.0,
      'is_blocked': false,
    },
    '/users/children': {
      'children': [
        {
          'id': 1,
          'name': 'Алиса',
          'age': 8,
          'class': '2А',
          'school': 'Школа №42',
          'photo_path': '',
        },
        {
          'id': 2,
          'name': 'Петя',
          'age': 6,
          'class': '1Б',
          'school': 'Школа №42',
          'photo_path': '',
        },
      ],
    },
    '/orders/history': {
      'orders': [
        {
          'id': 1001,
          'date': '2026-03-04T08:30:00Z',
          'from': 'ул. Ленина, 15',
          'to': 'Школа №42',
          'price': 450.0,
          'status': 'completed',
          'driver_name': 'Алексей П.',
          'rating': 5,
        },
        {
          'id': 1002,
          'date': '2026-03-03T08:25:00Z',
          'from': 'ул. Ленина, 15',
          'to': 'Школа №42',
          'price': 435.0,
          'status': 'completed',
          'driver_name': 'Алексей П.',
          'rating': 5,
        },
        {
          'id': 1003,
          'date': '2026-03-01T14:00:00Z',
          'from': 'Школа №42',
          'to': 'ул. Ленина, 15',
          'price': 420.0,
          'status': 'completed',
          'driver_name': 'Сергей К.',
          'rating': 4,
        },
      ],
    },
    '/users/balance': {
      'balance': 5000.0,
      'pending': 0.0,
    },
    '/orders/tariffs': {
      'tariffs': [
        {
          'id': 1,
          'name': 'Эконом',
          'price_per_km': 25.0,
          'base_price': 150.0,
          'description': 'Комфортная поездка по доступной цене',
        },
        {
          'id': 2,
          'name': 'Комфорт',
          'price_per_km': 40.0,
          'base_price': 200.0,
          'description': 'Просторный автомобиль и опытный водитель',
        },
        {
          'id': 3,
          'name': 'Бизнес',
          'price_per_km': 65.0,
          'base_price': 300.0,
          'description': 'Премиальный автомобиль',
        },
      ],
    },
  };

  /// Возвращает демо-данные для заданного URL или null если не найдено
  static Map<String, dynamic>? getResponse(String path) {
    for (final key in _responses.keys) {
      if (path.contains(key)) {
        return _responses[key];
      }
    }
    return null;
  }
}
