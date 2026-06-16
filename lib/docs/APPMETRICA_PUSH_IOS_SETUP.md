# AppMetrica Push — iOS: Delivered + Opened

## NSE — что это и что у нас в проекте

**NSE (Notification Service Extension)** — системное расширение iOS, которое запускается **до показа push в шторке**.

В этом проекте NSE — это target **`PushNotificationServiceExtension`** и файл:

```
ios/PushNotificationServiceExtension/NotificationService.swift
```

Он встраивается в приложение как `PushNotificationServiceExtension.appex`.

| Метрика | Где считается | Компонент |
|---------|---------------|-----------|
| **Delivered** | Push пришёл в шторку (NSE перехватил доставку) | `PushNotificationServiceExtension` (NSE) |
| **Opened** | Пользователь тапнул по push | `AppDelegate` + delegate AppMetrica Push SDK |

Без NSE AppMetrica на iOS **не видит Delivered** (только Opened).

---

## Что уже сделано в коде

1. **NSE** (`PushNotificationServiceExtension`) — `AppMetricaPush.handleDidReceive` + App Group.
2. **AppDelegate** — delegate AppMetrica для учёта **Opened**.
3. **App Group** — `group.com.kredit7.dney.appmetrica` в entitlements Runner и NSE.
4. **Embed** — extension встроен в Runner (см. ниже про Embed Without Signing).
5. **Инициализация** — AppMetrica до FCM в `main.dart`.

---

## Обязательно в Xcode и Apple Developer

### 1. Pods

```bash
cd ios && pod install
open Runner.xcworkspace
```

### 2. Проверить target `PushNotificationServiceExtension`

В Project Navigator:

- Target **PushNotificationServiceExtension** существует
- Файлы: `NotificationService.swift`, `Info.plist`, entitlements
- **Signing**: Team `5422A5W952`, Bundle ID `com.kredit7.dney.PushNotificationServiceExtension`

### 3. App Group (Apple Developer Portal)

1. [developer.apple.com](https://developer.apple.com) → Identifiers → **App Groups** → `group.com.kredit7.dney.appmetrica`
2. В App IDs **`com.kredit7.dney`** и **`com.kredit7.dney.PushNotificationServiceExtension`** включить App Groups и отметить эту группу
3. Обновить **Provisioning Profiles**

### 4. Capabilities в Xcode

**Runner:**

- Push Notifications
- App Groups → `group.com.kredit7.dney.appmetrica`

**PushNotificationServiceExtension:**

- App Groups → `group.com.kredit7.dney.appmetrica`

### 5. Embed extension (важно)

**Runner → General → Frameworks, Libraries, and Embedded Content**

Для `.appex` (extension) Xcode часто показывает только два варианта:

- **Embed Without Signing** — нормально, **оставьте так**
- **Do Not Embed** — нельзя, extension не попадёт в приложение

Почему нет **Embed & Sign**: extension подписывается **своим target** `PushNotificationServiceExtension` при сборке, а Runner только копирует `.appex` в `PlugIns/`. Это стандартное поведение Xcode для Notification Service Extension.

Проверьте также **Runner → Build Phases → Embed Foundation Extensions** — там должен быть `PushNotificationServiceExtension.appex`.

**Не выбирайте «Do Not Embed».** «Embed Without Signing» — правильный вариант.

---

## Кабинет AppMetrica

### Настройки приложения → Push-уведомления

Здесь **нет** отдельного переключателя «Сбор статистики push». Нужно:

- APNs Auth Key (production)
- Firebase Server Key
- (рекомендуется) **«Актуализировать токены с помощью Silent Push-уведомлений»**

### «Сбор статистики» — это код + кампания

**1. В коде (уже сделано):** NSE + App Group + `AppMetricaPush.handleDidReceive` — это и есть техническая «настройка сбора статистики» из документации AppMetrica.

**2. В каждой push-кампании:** при создании уведомления для **iOS** в конструкторе есть переключатель **«Отслеживать доставку»** — он **включён по умолчанию**. Не выключайте его.

Если «Отслеживать доставку» выключить, в отчётах Delivered ≈ Opened (доставки отдельно не считаются).

Кампании запускать **только из AppMetrica** (не из Firebase Console).

> При отправке через конструктор AppMetrica добавляет `mutable-content: 1` — без этого iOS не вызовет NSE.

---

## Проверка Delivered + Opened

1. Собрать **Release** / TestFlight (production APNS).
2. Установить, разрешить push, открыть app 1 раз.
3. Отправить кампанию из AppMetrica.
4. **Delivered:** получить push, **не тапать**, подождать 1–2 мин.
5. **Opened:** тапнуть по push.
6. Отчёт обновится через несколько часов.

---

## Частые проблемы

| Симптом | Причина |
|---------|---------|
| Delivered = 0 | NSE не в билде / нет App Group / в кампании выключено «Отслеживать доставку» |
| Opened = 0 | Не тот delegate / кампания не из AppMetrica |
| NSE не вызывается | Нет `mutable-content: 1` (для AppMetrica-кампаний должно быть автоматически) |
| Debug vs Production | TestFlight = production APNS |
