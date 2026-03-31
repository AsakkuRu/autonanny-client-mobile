# 📱 AutoNanny Client Mobile

**Git:** эта папка (`autonanny-client-mobile-wc/`) — отдельный репозиторий. Корень родительской директории `AutoNanny/` не является git-репозиторием; рядом — отдельные репозитории `admin-frontend`, `autonanny-backend`, `autonanny-driver-mobile-wc`.

Мобильное приложение для родителей - безопасная перевозка детей.

## 🎯 Описание

Client Mobile - это Flutter приложение для родителей, которое позволяет:
- 👶 Управлять профилями детей
- 📅 Создавать графики поездок
- 🚗 Заказывать разовые поездки
- 💰 Управлять балансом и платежами
- 📍 Отслеживать поездки в реальном времени
- 💳 Управлять картами и кэшбэком

## 🚀 Быстрый старт

### Требования

- Flutter SDK 3.24.0+
- Dart SDK 3.1.4+
- Android Studio / Xcode
- Android SDK (для Android)
- Xcode (для iOS)

### Установка

```bash
# 1. Клонировать репозиторий
cd client-mobile

# 2. Установить зависимости
flutter pub get

# 3. Запустить на эмуляторе/устройстве
flutter run
```

### Настройка окружения

Создайте файл `.env` в корне `client-mobile/`:

```env
API_BASE_URL=http://10.0.2.2:8000/api/v1.0
# Для iOS используйте: http://localhost:8000/api/v1.0
# Для реального устройства: http://YOUR_IP:8000/api/v1.0
```

## 📁 Структура проекта

```
client-mobile/
├── lib/
│   ├── main.dart                    # Точка входа
│   ├── views/                       # UI экраны
│   │   ├── home.dart               # Главный экран с табами
│   │   ├── pages/                  # Страницы приложения
│   │   └── reg.dart                # Регистрация
│   ├── view_models/                # ViewModels (бизнес-логика)
│   │   └── pages/                  # ViewModels для страниц
│   └── firebase_options.dart       # Firebase конфигурация
│
├── nanny_components/               # UI компоненты
│   ├── lib/
│   │   ├── widgets/               # Переиспользуемые виджеты
│   │   ├── base_views/            # Базовые view и view models
│   │   └── dialogs/               # Диалоги
│   └── assets/                    # Ресурсы (шрифты, изображения)
│
├── nanny_core/                    # Бизнес-логика
│   └── lib/
│       ├── models/                # Модели данных
│       ├── api/                   # API клиенты
│       └── nanny_core.dart        # Экспорты
│
├── test/                          # Unit тесты
├── integration_test/              # Integration тесты
└── android/ios/                   # Нативные конфигурации
```

## 🔧 Разработка

### Запуск на разных платформах

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Конкретное устройство
flutter devices                    # Список устройств
flutter run -d <device_id>
```

### Hot Reload

Во время разработки используйте:
- `r` - Hot reload (быстрая перезагрузка)
- `R` - Hot restart (полная перезагрузка)
- `q` - Выход

### Сборка

```bash
# Debug APK (Android)
flutter build apk --debug

# Release APK (Android)
flutter build apk --release

# iOS
flutter build ios --release
```

## 🧪 Тестирование

```bash
# Unit тесты
flutter test

# Unit тесты с покрытием
flutter test --coverage

# Integration тесты (требуется эмулятор)
flutter test integration_test

# Анализ кода
flutter analyze

# Форматирование
flutter format lib/ test/
```

**Подробнее:** См. [docs/frontend/testing/CLIENT_TESTING.md](../docs/frontend/testing/CLIENT_TESTING.md)

## 📦 Основные зависимости

- **flutter_svg** - SVG изображения
- **qr_flutter** - Генерация QR-кодов
- **nanny_components** - UI компоненты (локальный пакет)
- **nanny_core** - Бизнес-логика (локальный пакет)

### Dev зависимости

- **flutter_test** - Тестирование
- **integration_test** - Integration тесты
- **mockito** - Моки для тестов
- **flutter_lints** - Линтер

## 🎨 UI/UX

### Шрифты
- **Nunito** - Основной шрифт
- **Fregat** - Дополнительный шрифт

### Цветовая схема
Определена в `nanny_components/lib/constants.dart`

### Компоненты
- `ProfileImage` - Аватары с обработкой ошибок
- `NetImage` - Сетевые изображения с fallback
- `NannyTextForm` - Кастомные поля ввода
- `ChildrenListView` - Список детей
- `ScheduleEditor` - Редактор графиков

## 🔐 Авторизация

Приложение использует:
- SMS авторизацию
- JWT токены
- Автоматический логин
- Хранение в `NannyStorage`

## 🌐 API Integration

Backend API: `http://10.0.2.2:8000/api/v1.0` (для эмулятора)

Основные endpoints:
- `/auth/*` - Авторизация
- `/users/*` - Пользователи
- `/children/*` - Дети
- `/schedules/*` - Графики
- `/payments/*` - Платежи

**Подробнее:** См. [docs/backend/reference/API_ENDPOINTS.md](../docs/backend/reference/API_ENDPOINTS.md)

## 🐛 Отладка

### Логи

```bash
# Просмотр логов
flutter logs

# Очистка и пересборка
flutter clean
flutter pub get
flutter run
```

### Частые проблемы

**Проблема:** Gradle build failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Проблема:** Не подключается к API
- Для Android эмулятора используйте `10.0.2.2:8000`
- Для iOS симулятора используйте `localhost:8000`
- Для реального устройства используйте IP вашего компьютера

**Проблема:** Hot reload не работает
```bash
# Полная перезагрузка
flutter run
```

## 📚 Документация

- [Полная документация](../docs/README.md)
- [Frontend Setup](../docs/frontend/setup/FLUTTER_SETUP.md)
- [Local Development](../docs/frontend/setup/LOCAL_DEVELOPMENT.md)
- [Testing Guide](../docs/frontend/testing/CLIENT_TESTING.md)
- [Frontend Tasks](../docs/FRONTEND_TASKS.md)

## 🤝 Contribution

1. Создайте feature branch
2. Сделайте изменения
3. Запустите тесты: `flutter test`
4. Проверьте код: `flutter analyze`
5. Создайте Pull Request

**Правила коммитов:** См. [docs/setup/COMMIT_GUIDE.md](../docs/setup/COMMIT_GUIDE.md)

## 📄 Лицензия

Proprietary - AutoNanny Team

---

**Версия:** 0.2.0  
**Последнее обновление:** 31 октября 2025
