# Документация API Pulse Backend

## 🔗 Базовые настройки

### Base URL
- **Production сервер:** `http://176.118.221.246:8081`
- **Локальная разработка (iOS/Web):** `http://localhost:8080`
- **Android эмулятор:** `http://10.0.2.2:8081` (⚠️ используйте порт 8081, не 8080!)

### Заголовки запросов
- **Content-Type:** `application/json` (для всех POST/PUT запросов)
- **Authorization:** `Bearer {firebase_id_token}` (для защищенных эндпоинтов)

---

## 🔐 1. Авторизация (Firebase)

### ⚠️ ВАЖНО: Настройка Firebase на клиенте

Перед использованием API необходимо настроить Firebase Authentication на клиенте:

#### iOS (Swift)
1. Добавьте `GoogleService-Info.plist` в проект
2. Установите Firebase SDK:
```swift
// Podfile
pod 'Firebase/Auth'
```

3. Инициализация:
```swift
import FirebaseCore
import FirebaseAuth

// В AppDelegate или App
FirebaseApp.configure()
```

4. Получение ID токена после входа:
```swift
Auth.auth().signIn(withEmail: email, password: password) { result, error in
    if let user = result?.user {
        user.getIDToken { token, error in
            if let token = token {
                // Используйте этот token в заголовке Authorization
                // Authorization: Bearer {token}
            }
        }
    }
}
```

#### Android (Kotlin)
1. Добавьте `google-services.json` в `app/` директорию
2. Добавьте зависимости в `build.gradle`:
```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth-ktx'
}
```

3. Инициализация:
```kotlin
import com.google.firebase.Firebase
import com.google.firebase.initialize
import com.google.firebase.auth.auth

Firebase.initialize(context)
```

4. Получение ID токена после входа:
```kotlin
Firebase.auth.signInWithEmailAndPassword(email, password)
    .addOnSuccessListener { result ->
        result.user?.getIdToken(true)?.addOnSuccessListener { token ->
            // Используйте этот token в заголовке Authorization
            // Authorization: Bearer {token}
        }
    }
```

---

### POST /api/auth/register

**Описание:** Регистрация нового пользователя. Создает пользователя в Firebase и в базе данных бэкенда.

**URL:** `POST http://176.118.221.246:8081/api/auth/register`

**Заголовки:**
```
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "displayName": "Имя пользователя"  // опционально
}
```

**Успешный ответ (200 OK):**
```json
{
  "token": "eyJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "displayName": "Имя пользователя"
  }
}
```

**⚠️ ВАЖНО:** Токен в ответе - это Firebase Custom Token. На клиенте его нужно обменять на ID Token:

**iOS:**
```swift
Auth.auth().signIn(withCustomToken: customToken) { result, error in
    result?.user.getIDToken { idToken, error in
        // Используйте idToken для последующих запросов
    }
}
```

**Android:**
```kotlin
Firebase.auth.signInWithCustomToken(customToken)
    .addOnSuccessListener { result ->
        result.user?.getIdToken(true)?.addOnSuccessListener { idToken ->
            // Используйте idToken для последующих запросов
        }
    }
```

**Ошибки:**
- `400 Bad Request` - пользователь уже существует или некорректные данные
- `422 Unprocessable Entity` - ошибка валидации (неверный формат email и т.д.)

**Пример ошибки:**
```json
{
  "message": "Validation failed",
  "error": "VALIDATION_ERROR",
  "details": {
    "email": "Invalid email format",
    "password": "Password is required"
  }
}
```

---

### POST /api/auth/login

**Описание:** Авторизация существующего пользователя.

**URL:** `POST http://176.118.221.246:8081/api/auth/login`

**⚠️ РЕКОМЕНДАЦИЯ:** Используйте Firebase SDK напрямую для входа, а не этот эндпоинт. Этот эндпоинт возвращает Custom Token, который нужно обменивать.

**Заголовки:**
```
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Успешный ответ (200 OK):**
```json
{
  "token": "eyJhbGciOiJSUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "displayName": "Имя пользователя"
  }
}
```

**Ошибки:**
- `401 Unauthorized` - неверные учетные данные
- `400 Bad Request` - некорректные данные

---

### ⚠️ ПРАВИЛЬНЫЙ СПОСОБ ВХОДА (рекомендуется)

Используйте Firebase SDK напрямую на клиенте:

**iOS:**
```swift
Auth.auth().signIn(withEmail: email, password: password) { result, error in
    if let user = result?.user {
        user.getIDToken { token, error in
            // Сохраните token и используйте в заголовках
            // Authorization: Bearer {token}
        }
    }
}
```

**Android:**
```kotlin
Firebase.auth.signInWithEmailAndPassword(email, password)
    .addOnSuccessListener { result ->
        result.user?.getIdToken(true)?.addOnSuccessListener { token ->
            // Сохраните token и используйте в заголовках
            // Authorization: Bearer {token}
        }
    }
```

После получения ID Token от Firebase, используйте его для всех защищенных эндпоинтов.

---

### POST /api/auth/reset-password

**Описание:** Отправка инструкций по восстановлению пароля на email.

**URL:** `POST http://176.118.221.246:8081/api/auth/reset-password`

**Заголовки:**
```
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "email": "user@example.com"
}
```

**Успешный ответ (200 OK):**
```json
{
  "message": "Инструкции по восстановлению пароля отправлены на email"
}
```

**Ошибки:**
- `400 Bad Request` - некорректный email
- `404 Not Found` - пользователь с таким email не найден

**Примечание:**
- Firebase отправляет письмо с ссылкой для сброса пароля
- Ссылка действительна в течение 1 часа
- Пользователь должен перейти по ссылке и установить новый пароль

---

## 📋 2. Задачи (Tasks)

Все эндпоинты задач требуют авторизации через заголовок `Authorization: Bearer {firebase_id_token}`.

### GET /api/tasks

**Описание:** Получить все задачи текущего пользователя (из команд, в которых он состоит).

**URL:** `GET http://176.118.221.246:8081/api/tasks`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Реализовать авторизацию",
    "description": "Описание задачи",
    "status": "BACKLOG",
    "assigneeId": 2,
    "assigneeName": "Иван Иванов",
    "projectId": 1,
    "sprintId": null,
    "deadline": "2024-12-31",
    "createdAt": "2024-01-01T10:00:00Z",
    "updatedAt": "2024-01-02T15:30:00Z"
  }
]
```

**Ошибки:**
- `401 Unauthorized` - не авторизован (неверный или отсутствующий токен)

**Пример запроса:**
```swift
// iOS
let url = URL(string: "http://176.118.221.246:8081/api/tasks")!
var request = URLRequest(url: url)
request.setValue("Bearer \(firebaseIdToken)", forHTTPHeaderField: "Authorization")
```

```kotlin
// Android
val url = "http://176.118.221.246:8081/api/tasks"
val request = Request.Builder()
    .url(url)
    .addHeader("Authorization", "Bearer $firebaseIdToken")
    .build()
```

---

### GET /api/tasks/{id}

**Описание:** Получить задачу по ID.

**URL:** `GET http://176.118.221.246:8081/api/tasks/{id}`

**Параметры пути:**
- `id` - ID задачи (число)

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
{
  "id": 1,
  "title": "Реализовать авторизацию",
  "description": "Описание задачи",
  "status": "BACKLOG",
  "assigneeId": 2,
  "assigneeName": "Иван Иванов",
  "projectId": 1,
  "sprintId": null,
  "deadline": "2024-12-31",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-02T15:30:00Z"
}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `404 Not Found` - задача не найдена или нет доступа

---

### POST /api/tasks

**Описание:** Создать новую задачу.

**URL:** `POST http://176.118.221.246:8081/api/tasks`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "title": "Новая задача",
  "description": "Описание задачи",  // опционально
  "status": "BACKLOG",
  "assigneeId": 2,  // опционально, ID участника команды
  "projectId": 1,  // опционально, ID команды/проекта
  "sprintId": 1,  // опционально
  "deadline": "2024-12-31"  // опционально, формат YYYY-MM-DD
}
```

**Обязательные поля:**
- `title` - название задачи
- `status` - статус (BACKLOG, IN_PROGRESS, REVIEW, DONE)

**Успешный ответ (201 Created):**
```json
{
  "id": 1,
  "title": "Новая задача",
  "description": "Описание задачи",
  "status": "BACKLOG",
  "assigneeId": 2,
  "assigneeName": "Иван Иванов",
  "projectId": 1,
  "sprintId": null,
  "deadline": "2024-12-31",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": null
}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `400 Bad Request` - некорректные данные
- `404 Not Found` - assigneeId не найден в команде пользователя

---

### PUT /api/tasks/{id}

**Описание:** Обновить задачу.

**URL:** `PUT http://176.118.221.246:8081/api/tasks/{id}`

**Параметры пути:**
- `id` - ID задачи (число)

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
```

**Тело запроса (все поля опциональны, отправляйте только те, что нужно изменить):**
```json
{
  "title": "Обновленное название",
  "description": "Обновленное описание",
  "status": "IN_PROGRESS",
  "assigneeId": 3,
  "sprintId": 1,
  "deadline": "2024-12-31"
}
```

**Успешный ответ (200 OK):**
```json
{
  "id": 1,
  "title": "Обновленное название",
  "description": "Обновленное описание",
  "status": "IN_PROGRESS",
  "assigneeId": 3,
  "assigneeName": "Петр Петров",
  "projectId": 1,
  "sprintId": 1,
  "deadline": "2024-12-31",
  "createdAt": "2024-01-01T10:00:00Z",
  "updatedAt": "2024-01-02T15:30:00Z"
}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `400 Bad Request` - некорректные данные
- `404 Not Found` - задача не найдена или assigneeId не найден

---

### DELETE /api/tasks/{id}

**Описание:** Удалить задачу.

**URL:** `DELETE http://176.118.221.246:8081/api/tasks/{id}`

**Параметры пути:**
- `id` - ID задачи (число)

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
{}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `404 Not Found` - задача не найдена
- `403 Forbidden` - нет прав на удаление

---

### GET /api/tasks/status/{status}

**Описание:** Получить задачи по статусу.

**URL:** `GET http://176.118.221.246:8081/api/tasks/status/{status}`

**Параметры пути:**
- `status` - один из: `BACKLOG`, `IN_PROGRESS`, `REVIEW`, `DONE`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Задача",
    "status": "BACKLOG",
    ...
  }
]
```

---

### GET /api/tasks/assigned-to-me

**Описание:** Получить задачи, назначенные на текущего пользователя.

**URL:** `GET http://176.118.221.246:8081/api/tasks/assigned-to-me`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Моя задача",
    "status": "IN_PROGRESS",
    "assigneeId": 2,
    "assigneeName": "Иван Иванов",
    ...
  }
]
```

---

## 👥 3. Команды (Teams)

Все эндпоинты команд требуют авторизации через заголовок `Authorization: Bearer {firebase_id_token}`.

### GET /api/teams

**Описание:** Получить все команды текущего пользователя.

**URL:** `GET http://176.118.221.246:8081/api/teams`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Команда разработки",
    "description": "Описание команды",
    "createdAt": "2024-01-01T10:00:00Z",
    "members": [
      {
        "id": 1,
        "userId": 2,
        "userName": "Иван Иванов",
        "userEmail": "ivan@example.com",
        "role": "DEVELOPER"
      }
    ]
  }
]
```

**Ошибки:**
- `401 Unauthorized` - не авторизован

---

### GET /api/teams/{id}

**Описание:** Получить команду по ID.

**URL:** `GET http://176.118.221.246:8081/api/teams/{id}`

**Параметры пути:**
- `id` - ID команды (число)

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
{
  "id": 1,
  "name": "Команда разработки",
  "description": "Описание команды",
  "createdAt": "2024-01-01T10:00:00Z",
  "members": [
    {
      "id": 1,
      "userId": 2,
      "userName": "Иван Иванов",
      "userEmail": "ivan@example.com",
      "role": "DEVELOPER"
    }
  ]
}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `404 Not Found` - команда не найдена или нет доступа

---

### POST /api/teams

**Описание:** Создать новую команду. Создатель автоматически добавляется как ADMIN.

**URL:** `POST http://176.118.221.246:8081/api/teams`

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
Content-Type: application/json
```

**Тело запроса:**
```json
{
  "name": "Новая команда",
  "description": "Описание команды"  // опционально
}
```

**Обязательные поля:**
- `name` - название команды

**Успешный ответ (201 Created):**
```json
{
  "id": 1,
  "name": "Новая команда",
  "description": "Описание команды",
  "createdAt": "2024-01-01T10:00:00Z",
  "members": [
    {
      "id": 1,
      "userId": 1,
      "userName": "Текущий пользователь",
      "userEmail": "user@example.com",
      "role": "ADMIN"
    }
  ]
}
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `400 Bad Request` - некорректные данные

---

### GET /api/teams/{teamId}/members

**Описание:** Получить список участников команды.

**URL:** `GET http://176.118.221.246:8081/api/teams/{teamId}/members`

**Параметры пути:**
- `teamId` - ID команды (число)

**Заголовки:**
```
Authorization: Bearer {firebase_id_token}
```

**Успешный ответ (200 OK):**
```json
[
  {
    "id": 1,
    "userId": 2,
    "userName": "Иван Иванов",
    "userEmail": "ivan@example.com",
    "role": "DEVELOPER"
  }
]
```

**Ошибки:**
- `401 Unauthorized` - не авторизован
- `404 Not Found` - команда не найдена или нет доступа

---

## 📊 Форматы данных

### Статусы задач (TaskStatus)
- `BACKLOG` - Задача в бэклоге
- `IN_PROGRESS` - В работе
- `REVIEW` - На проверке
- `DONE` - Выполнена

### Роли участников (TeamMemberRole)
- `ADMIN` - Администратор команды
- `MANAGER` - Менеджер
- `DEVELOPER` - Разработчик
- `DESIGNER` - Дизайнер
- `QA` - Тестировщик

### Формат дат
- **Дата:** `YYYY-MM-DD` (например: `2024-12-31`)
- **Дата-время:** ISO 8601 (например: `2024-01-01T10:00:00Z`)

---

## ⚠️ Обработка ошибок

Все ошибки возвращаются в формате:
```json
{
  "message": "Описание ошибки",
  "error": "ERROR_CODE",  // опционально
  "details": {}  // опционально, может содержать детали валидации
}
```

### Коды статусов HTTP
- `200 OK` - Успешный запрос
- `201 Created` - Ресурс создан
- `400 Bad Request` - Некорректные данные
- `401 Unauthorized` - Не авторизован (неверный или отсутствующий токен)
- `403 Forbidden` - Нет доступа
- `404 Not Found` - Ресурс не найден
- `422 Unprocessable Entity` - Ошибка валидации
- `500 Internal Server Error` - Ошибка сервера

### Примеры ошибок

**401 Unauthorized (нет токена):**
```json
{
  "message": "Access denied",
  "error": "ACCESS_DENIED"
}
```

**422 Validation Error:**
```json
{
  "message": "Validation failed",
  "error": "VALIDATION_ERROR",
  "details": {
    "email": "Invalid email format",
    "password": "Password is required"
  }
}
```

**404 Not Found:**
```json
{
  "message": "Task not found",
  "error": "TASK_NOT_FOUND"
}
```

---

## 🔧 Настройка на клиенте (мобильное приложение)

### 1. Обновите Base URL

#### iOS (Swift)
```swift
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8080"  // для симулятора
    #else
    static let baseURL = "http://176.118.221.246:8081"  // для реального устройства
    #endif
}
```

#### Android (Kotlin)
```kotlin
object ApiConfig {
    const val BASE_URL = if (BuildConfig.DEBUG) {
        "http://10.0.2.2:8081"  // для эмулятора
    } else {
        "http://176.118.221.246:8081"  // для реального устройства
    }
}
```

**⚠️ ВАЖНО:** Для Android эмулятора используйте `10.0.2.2` вместо `localhost` и порт `8081`, не `8080`!

### 2. Настройка Firebase

#### iOS
1. Скачайте `GoogleService-Info.plist` из Firebase Console
2. Добавьте в Xcode проект
3. Установите Firebase SDK через CocoaPods или SPM
4. Инициализируйте в `AppDelegate` или `App`

#### Android
1. Скачайте `google-services.json` из Firebase Console
2. Поместите в `app/` директорию
3. Добавьте зависимости в `build.gradle`
4. Инициализируйте Firebase

### 3. Работа с токенами

#### Сохранение токена после входа
```swift
// iOS
UserDefaults.standard.set(firebaseIdToken, forKey: "auth_token")
```

```kotlin
// Android
val prefs = getSharedPreferences("auth", Context.MODE_PRIVATE)
prefs.edit().putString("auth_token", firebaseIdToken).apply()
```

#### Добавление токена в запросы
```swift
// iOS
var request = URLRequest(url: url)
if let token = UserDefaults.standard.string(forKey: "auth_token") {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```

```kotlin
// Android
val token = getSharedPreferences("auth", Context.MODE_PRIVATE)
    .getString("auth_token", null)
    
val request = Request.Builder()
    .url(url)
    .addHeader("Authorization", "Bearer $token")
    .build()
```

### 4. Обновление токена

Firebase ID токены действительны 1 час. Реализуйте автоматическое обновление:

```swift
// iOS
Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
    // Обновите сохраненный токен
}
```

```kotlin
// Android
Firebase.auth.currentUser?.getIdToken(true)?.addOnSuccessListener { token ->
    // Обновите сохраненный токен
}
```

### 5. Обработка ошибок 401

При получении 401 Unauthorized:
1. Попробуйте обновить токен
2. Если не помогло - перенаправьте на экран входа

```swift
// iOS пример
if response.statusCode == 401 {
    // Попробовать обновить токен
    Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { token, error in
        if token != nil {
            // Повторить запрос с новым токеном
        } else {
            // Перенаправить на экран входа
        }
    }
}
```

### 6. CORS и безопасность

- API поддерживает CORS для всех источников
- Используйте HTTPS в production (настройте reverse proxy с nginx)
- Никогда не храните токены в открытом виде
- Используйте Keychain (iOS) или EncryptedSharedPreferences (Android) для хранения токенов

---

## 📝 Примеры использования

### Полный цикл работы с API

1. **Регистрация пользователя:**
```swift
// iOS
let url = URL(string: "\(APIConfig.baseURL)/api/auth/register")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try? JSONEncoder().encode([
    "email": "user@example.com",
    "password": "password123",
    "displayName": "Имя пользователя"
])

URLSession.shared.dataTask(with: request) { data, response, error in
    // Обработка ответа
}.resume()
```

2. **Вход через Firebase SDK:**
```swift
Auth.auth().signIn(withEmail: email, password: password) { result, error in
    result?.user.getIDToken { token, error in
        // Сохранить token и использовать для запросов
    }
}
```

3. **Получение задач:**
```swift
let url = URL(string: "\(APIConfig.baseURL)/api/tasks")!
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

URLSession.shared.dataTask(with: request) { data, response, error in
    // Обработка списка задач
}.resume()
```

---

## ✅ Чеклист для интеграции

- [ ] Обновлен Base URL на `http://176.118.221.246:8081`
- [ ] Для Android эмулятора используется `http://10.0.2.2:8081`
- [ ] Firebase SDK установлен и настроен
- [ ] `GoogleService-Info.plist` (iOS) или `google-services.json` (Android) добавлен в проект
- [ ] Реализовано получение Firebase ID Token после входа
- [ ] Токен добавляется в заголовок `Authorization: Bearer {token}` для всех защищенных запросов
- [ ] Реализовано обновление токена при истечении (каждый час)
- [ ] Обработаны ошибки 401 (перенаправление на экран входа)
- [ ] Все эндпоинты протестированы

---

**Последнее обновление:** 2025-12-04  
**Версия API:** 1.0.0  
**Статус:** ✅ Production Ready

