# Интеграция с Backend API

## Структура проекта

```
lib/
├── config/
│   └── api_config.dart      # Конфигурация API (URL, токен)
├── core/
│   └── api_client.dart      # Базовый HTTP клиент
├── models/
│   ├── team_response.dart   # Модели для API (TeamResponse, CreateTeamRequest)
│   ├── team_data.dart       # Модель для UI (совместима с API)
│   ├── team_member.dart     # Модель участника команды
│   └── task.dart            # Модель задачи
├── services/
│   └── team_service.dart    # Сервис для работы с API команд
└── screens/
    ├── main_screen.dart     # Главный экран с навигацией
    ├── team_screen.dart     # Экран команды
    └── create_team_screen.dart  # Экран создания команды
```

## Настройка API

### 1. Базовый URL

Откройте `lib/config/api_config.dart` и при необходимости измените URL:

```dart
static const String baseUrl = 'http://localhost:8080';
```

**Важно:** Для Android эмулятора используйте `http://10.0.2.2:8080` вместо `localhost`.

### 2. Токен авторизации

Если требуется авторизация, установите токен:

```dart
ApiConfig.setAuthToken('your-firebase-token');
```

## Использование API

### Создание команды

Экран создания команды (`CreateTeamScreen`) автоматически отправляет данные на сервер при нажатии кнопки "Создать команду".

**Endpoint:** `POST /api/teams`

**Тело запроса:**
```json
{
  "name": "string",
  "description": "string"  // опционально
}
```

**Ответ:**
```json
{
  "id": 1,
  "name": "string",
  "description": "string",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### Получение команды

Для получения команды используйте `TeamService`:

```dart
final apiClient = ApiClient();
final teamService = TeamService(apiClient);

// Получить все команды
final teams = await teamService.getAllTeams();

// Получить команду по ID
final team = await teamService.getTeam(1);
```

## Важные замечания

1. **Поля goal и members** - эти поля не поддерживаются API, они хранятся только локально в приложении.

2. **Обработка ошибок** - все ошибки API отображаются пользователю через SnackBar.

3. **Индикатор загрузки** - при создании команды показывается индикатор загрузки.

4. **Авторизация** - если требуется токен, установите его через `ApiConfig.setAuthToken()`.

## Тестирование

1. Убедитесь, что backend сервер запущен на `http://localhost:8080`
2. Для Android эмулятора используйте `http://10.0.2.2:8080`
3. Создайте команду через экран "Создать"
4. Проверьте, что команда отображается на главном экране



