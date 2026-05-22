# Источник флага показа боевого онбординга (`onboardingSource`)

Документ описывает поля в Firestore/на сервере, флаг в Varioqub и логику в приложении для A/B теста «с онбордингом / без».

Связанные файлы:

| Компонент | Путь |
|-----------|------|
| Резолвер | `lib/features/combat_onboarding/services/onboarding_visibility_resolver.dart` |
| Varioqub SDK | `lib/services/varioqub_service.dart` |
| Гейт | `lib/features/combat_onboarding/ui/combat_onboarding_gate.dart` |
| Модель настроек | `lib/models/firebase_settings.dart` |
| Enum источника | `lib/models/onboarding_source.dart` |

Интеграция Varioqub: [документация Yandex](https://yandex.ru/support/varioqub-app/ru/sdk/plugins/flutter/integration).

---

## 1. Поля на сервере и в Firestore

**Коллекция / документ:** `settings` / `general` (как у остальных настроек).

| Поле | Тип | Допустимые значения | По умолчанию в приложении |
|------|-----|---------------------|---------------------------|
| `showOnboarding` | `bool` | `true` / `false` | `false` |
| `onboardingSource` | `string` | `server` / `varioqub` | `server` |

**Приоритет загрузки** (без изменений): сначала ответ сервера `ServerDataService.fetchAllData()`, при отсутствии — Firestore `FirebaseService.getSettings()`.

### 1.1. `showOnboarding` (master)

- `false` — онбординг **не показывается**, независимо от `onboardingSource` и Varioqub (экстренное отключение).
- `true` — онбординг **может** показываться; дальше решает источник.

### 1.2. `onboardingSource`

| Значение | Поведение |
|----------|-----------|
| `server` | Показ = `showOnboarding` с сервера/Firestore (после master: при `true` → показываем). |
| `varioqub` | Показ = флаг Varioqub `showOnboarding` (`"true"` / `"false"`). Если Varioqub недоступен — **fallback** на `showOnboarding` с сервера. |

Неизвестное значение трактуется как `server`.

---

## 2. Varioqub

### 2.1. Настройка в коде

В `lib/services/varioqub_service.dart` задайте **`VarioqubService.clientId`** в формате `appmetrica.XXXXXX`, где `XXXXXX` — **ID приложения** из AppMetrica (Настройки → Общие → ID приложения).

Инициализация в `main.dart` **после** `AppMetricaService.initialize()`:

- `initVarioqubWithAppMetricaAdapter`
- `setDefaults({ showOnboarding: "false" })`
- `activateConfig()` — флаги текущей сессии
- `fetchConfig()` в фоне — конфиг для **следующего** запуска (без `activateConfig` в середине сессии)

### 2.2. Флаг в эксперименте / конфиге

| Ключ | Тип в Varioqub | Значения | В приложении |
|------|----------------|----------|--------------|
| `showOnboarding` | string | `"true"`, `"false"` | конвертация в `bool` (без учёта регистра) |

Пустая строка или другое значение → флаг считается **недоступным**, используется fallback на сервер.

### 2.3. Проверка доступности Varioqub

`VarioqubService.tryGetShowOnboarding()` возвращает `null`, если:

- не удалась инициализация / `activateConfig`;
- исключение при `getString`;
- значение флага пустое или не `"true"` / `"false"`.

В этом случае `OnboardingVisibilityResolver` использует `settings.showOnboarding` с сервера.

---

## 3. Логика в приложении

```text
1. settings.showOnboarding == false  →  не показываем (master OFF)
2. onboardingSource == server        →  показываем (master уже true)
3. onboardingSource == varioqub:
     - Varioqub.showOnboarding доступен  →  его bool
     - иначе                             →  settings.showOnboarding (fallback)
```

Дополнительно (как раньше): если `combat_onboarding_was_shown == true` — онбординг не показывается повторно (`CombatOnboardingGate`).

---

## 4. Сценарии A/B

### Во время эксперимента

На сервере / в Firestore:

```json
{
  "showOnboarding": true,
  "onboardingSource": "varioqub"
}
```

В Varioqub: эксперимент с вариантами флага `showOnboarding` = `"true"` / `"false"`.

### После эксперимента

```json
{
  "showOnboarding": true,
  "onboardingSource": "server"
}
```

Дальше управление только полем `showOnboarding` без Varioqub.

### Экстренное отключение

```json
{
  "showOnboarding": false,
  "onboardingSource": "varioqub"
}
```

Онбординг выключен для всех, эксперимент не переопределяет master.

---

## 5. Пример JSON на сервере

Фрагмент `settings` в ответе `/api/client/get-all` (структура как у Firestore `settings/general`):

```json
{
  "checkInternet": true,
  "checkLocation": true,
  "checkSIM": false,
  "checkVPN": true,
  "location": "RU",
  "showOnboarding": true,
  "onboardingSource": "varioqub"
}
```

Тот же объект в Firestore: документ `settings/general`.

---

## 6. Отладка

В debug-логах:

- `VarioqubService:` — инициализация, чтение флага, недоступность
- `OnboardingVisibilityResolver:` — итоговое решение и fallback
- `CombatSettingsResolver:` — источник settings и значения полей

---

*Последнее обновление: `onboardingSource`, Varioqub `showOnboarding` (string), fallback на сервер.*
