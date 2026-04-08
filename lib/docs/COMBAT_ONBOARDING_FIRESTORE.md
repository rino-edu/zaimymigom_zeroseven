# Боевой онбординг (combat) с контентом из Firestore/ServerDataService

Документ описывает задачу внедрения онбординга для **боевого режима** приложения, который:

- показывается **только на первом открытии** (локально на девайсе, через SharedPreferences; iOS тоже);
- показывается **только в режиме `AppMode.combat`**;
- управляется флагом **`settings/general.showOnboarding`**, причём **настройки берутся с сервера в приоритете** (аналогично существующим settings).

Также описаны:
- контракты Firestore (коллекции/документы/поля);
- схема файлов/классов/методов для реализации;
- алгоритмы навигации, валидации телефона, ретраев;
- правила записи `users/{installationId}` (merge по полям).

---

## 1) Источники данных и приоритеты

### 1.1. Откуда берём `showOnboarding`

Приоритет такой же, как у прочих настроек:

- **Источник 1 (приоритетный)**: `ServerDataService.fetchAllData()` → `settings` (аналог Firestore settings).
- **Источник 2 (fallback)**: Firestore `settings/general.showOnboarding` через `FirebaseService.getSettings()`.

Если оба источника недоступны/не содержат поле — считаем `showOnboarding = false`.

### 1.2. Откуда берём контент онбординга

Только Firestore:

- коллекция `onboarding` (документы `start`, `final`, `animation1`, `animation2`, и набор `pageX`).

Если загрузка контента не удалась:
- делаем **1 ретрай**;
- если снова не удалось — **переходим на `LoansScreen`** (в combat) и **ничего не пишем в `lastOnbordpage="Not shown"`**, потому что онбординг *должен был* показываться, но не смог загрузиться (см. раздел 4.5 — точное правило записи).

---

## 2) Правила показа онбординга (условия)

### 2.1. Условия показа (строго)

Онбординг показывается только если одновременно:

- `AppModeService().currentMode == AppMode.combat`
- `showOnboarding == true`
- это **первое открытие приложения** на девайсе (локально в SharedPreferences)

### 2.2. Первое открытие

- Первое открытие определяется **только локально**, через SharedPreferences.
- При переустановке приложения считается первым открытием снова (SharedPreferences очищается).

Рекомендуемые ключи в SharedPreferences:
- `combat_onboarding_first_open_at_iso` (String, ISO-8601 дата/время первого открытия)

---

## 3) Полная схема экранов онбординга

Все экраны имеют общие элементы:
- фон и цвета из темы (см. Firestore `onboarding/start.theme`);
- справа сверху кнопка закрытия (иконка `close`) — **на всех экранах, кроме анимационных**.

### 3.1. Экран 1: Start (`onboarding/start`)

Содержимое:
- заголовок `title`
- текст `body`
- кнопка `primaryButtonText` (например “Начать”)
- кнопка закрытия (крестик) → полностью закрывает онбординг и открывает `LoansScreen`

### 3.2. Экраны 2..(N+1): вопросы (`onboarding/pageX`)

Содержимое:
- заголовок-вопрос `question`
- **4** кнопки-варианта ответа (тексты из `options`)

Поведение:
- по нажатию на любой вариант:
  - сохранить ответ в `answersOnbord[question] = selectedOption`
  - перейти на следующий экран
- свайп/перелистывание назад **запрещены**
- крестик закрывает онбординг (см. раздел 4.4)

Примечание по нумерации:
- документы могут начинаться не с `page1`, а например с `page2`.
- порядок определяется **по числу в id** (`page2` перед `page10`).

### 3.3. Последний экран: Final (`onboarding/final`)

Содержимое:
- заголовок `title`
- текст `body`
- поле ввода телефона:
  - при фокусе/первом вводе номер начинается с **`+7`** (это не настраивается из Firestore)
- чекбокс с текстом `consentText`
- кнопка `primaryButtonText` (например “Продолжить”)
- крестик закрытия (как на других экранах)

Валидация:
- кнопка недоступна, пока:
  - номер **невалидный**, или
  - чекбокс не отмечен

Телефон:
- собираем **только РФ** номера.
- минимальная стратегия: хранить в Firestore нормализованный `+7XXXXXXXXXX`, если возможно гарантированно, иначе исходный (но всё равно желательно нормализовать).

### 3.4. Locked loading 1 (`onboarding/animation1`) и 2 (`onboarding/animation2`)

Содержимое:
- заголовок `title`
- `CircularProgressIndicator`

Поведение:
- отображаются последовательно
- каждая страница показывается ровно `durationSeconds` секунд
- закрыть/назад невозможно

После второй анимации:
- онбординг заканчивается успешно → открыть `LoansScreen`

---

## 4) Запись пользователя в Firestore (`users/{id}`)

### 4.1. Идентификатор пользователя

Документ пользователя создаётся/обновляется по id:
- **Firebase Installations ID** (FID)

Путь:
- `users/{installationId}`

### 4.2. Поля документа пользователя (контракт)

Коллекция: `users`

Поля:
- `id`: `string` — равен `installationId`
- `phone`: `string` — нормализованный номер (предпочтительно `+7XXXXXXXXXX`)
- `appmetricaId`: `string` — из `AppMetricaService.getDeviceIdHash()`
- `firstOpenDate`: `timestamp` — дата/время первого открытия (локально определяемая)
- `endOnbord`: `bool`
  - `true` — пользователь прошёл до конца (нажал продолжить на final, прошёл оба loading, дошёл до LoansScreen)
  - `false` — пользователь закрыл крестиком на любом экране
  - `false` — онбординг не показывался при первом открытии (см. `Not shown`)
- `lastOnbordpage`: `string`
  - формат: `"{current}/{total}"`
  - `total` = количество экранов: `start` + `pageX` + `final` (**без** animation1/2)
  - `current` = номер экрана (с 1), на котором пользователь закрыл крестиком **или** дошёл до конца
  - особое значение: `"Not shown"` — онбординг *вообще не показывался* при первом открытии (см. 4.5)
- `answersOnbord`: `map<string,string>`
  - ключ: `question` из страницы `pageX`
  - значение: выбранная строка из `options`

### 4.3. Запись: только merge по полям

Запись в Firestore должна выполняться как `set(data, SetOptions(merge: true))`, чтобы:
- не затереть потенциальные будущие поля;
- обновлять только необходимые поля.

#### Есть ли трудности у merge-подхода?

Да, 2 типовые:
- **Удаление значений**: merge не удаляет поля (для удаления нужен `FieldValue.delete()`).
- **Частичное обновление мапы**: если обновлять `answersOnbord` как целый map, можно затереть ответы при конкурентных апдейтах. Проще вести локальную map полностью и в конце записывать одним set(merge:true) (без параллельных апдейтов).

В рамках этой фичи это решаемо: писать документ **одним финальным апдейтом** при закрытии/успехе (и опционально писать промежуточно, если нужно — но ТЗ требует фиксации действий, см. 4.4).

### 4.4. Когда писать документ (события)

ТЗ: “при прохождении онбординга все действия пользователя должны записываться… при успешном прохождении или закрытии формируется заполненная модель User и данные отправляются”.

Чтобы это соответствовало буквально и при этом было безопасно, предлагаем стратегию:

- В течение онбординга собираем данные **локально** в контроллере:
  - `firstOpenDate`
  - `answersOnbord`
  - `lastOnbordpage` (текущий индекс)
- В Firestore пишем **в 2 случаях**:
  1) пользователь нажал крестик (закрытие)
  2) онбординг успешно завершён (после animation2)

При необходимости “логировать все действия” чаще — можно добавить промежуточные `merge`-апдейты после каждого ответа, но тогда нужно внимательно работать с merge `answersOnbord` (либо писать целиком).

### 4.5. Правило записи `"Not shown"`

Если это **первое открытие** и выполняется хотя бы одно:
- `showOnboarding == false`, или
- `AppMode != combat`

то:
- онбординг **не показываем**;
- создаём/обновляем документ `users/{id}` и пишем:
  - `lastOnbordpage = "Not shown"`
  - `endOnbord = false`
  - `firstOpenDate = <first open>`
  - `appmetricaId = ...`
  - `id = installationId`

Если это **НЕ** первое открытие и онбординг не показали — **ничего не пишем**.

---

## 5) `lastOnbordpage`: расчёт и нумерация

Экран 1 — `start`.
Далее — все `pageX` в порядке сортировки по числу в id.
Последний — `final`.

`current`:
- при закрытии крестиком на экране с индексом i (1-based) → `current = i`
- при полном завершении → `current = total`

`total`:
- `1 (start) + count(pageX) + 1 (final)`

Пример:
- `start` + `page2` + `page3` + `final` → total = 4
  - закрыл на `page3` → `lastOnbordpage = "3/4"`
  - прошёл полностью → `"4/4"`

---

## 6) Firestore контракт: коллекция `onboarding`

Коллекция: `onboarding`

Документы:
- `start`
- `final`
- `animation1`
- `animation2`
- `page{number}` (любые, например `page2`, `page3`, `page10`…)

### 6.1. Обязательные поля + дефолты

Требование: “предусмотреть дефолтные значения для всех экранов и полей”.

Если какое-то поле отсутствует в документе, приложение должно использовать дефолт (см. 6.4).

### 6.2. `onboarding/start`

Поля:
- `title`: string
- `body`: string
- `primaryButtonText`: string
- `theme`: map (см. 6.6) — единая тема для всех экранов

### 6.3. `onboarding/pageX`

Поля:
- `question`: string
- `options`: array<string> (ожидается 4)

Если `options` не 4:
- берём первые 4, если больше;
- если меньше — недостающие подставляем дефолтами (“Вариант 1..4”) или скрываем (выбрать одно поведение и зафиксировать в коде).

### 6.4. `onboarding/final`

Поля:
- `title`: string
- `body`: string
- `primaryButtonText`: string
- `consentText`: string

Телефон не настраивается по стране/маске из Firestore — всегда РФ, префикс `+7`.

### 6.5. `onboarding/animation1`, `onboarding/animation2`

Поля:
- `title`: string
- `durationSeconds`: number (int)

### 6.6. Тема (упрощённая: 6 цветов)

Требование: “упростить количество настроек цветов. Оставь только 6 цвета кнопок, цвета текста, цвет фона”.

Рекомендуемый контракт `theme` (ровно 6 цветов):
- `backgroundColor`: string — `RRGGBB` или `#RRGGBB`
- `titleTextColor`: string — `RRGGBB`/`#RRGGBB`
- `bodyTextColor`: string — `RRGGBB`/`#RRGGBB`
- `primaryButtonBgColor`: string — `RRGGBB`/`#RRGGBB`
- `primaryButtonTextColor`: string — `RRGGBB`/`#RRGGBB`
- `optionButtonBgColor`: string — `RRGGBB`/`#RRGGBB`

Примечания:
- Цвет текста опций можно брать как `titleTextColor` (чтобы не расширять контракт).
- Цвет крестика, индикатора, чекбокса, бордеров инпута можно производно вычислять (например использовать `titleTextColor` / `primaryButtonBgColor`), либо взять системные цвета.

Парсинг цвета:
- принимать `"FFFFFF"` и `"#FFFFFF"`;
- формат `#AARRGGBB` **не поддерживаем**.

---

## 7) UI/UX требования

### 7.1. Индикатор страниц

Нужно использовать `smooth_page_indicator` для отображения текущей страницы.

Особенности:
- индикатор отображает прогресс по **страницам pageView** (start + pages + final)
- свайп назад выключен (см. 7.2)

### 7.2. Запрет перелистывания назад

Требование: “убрать возможность перелистывать онбординг назад”.

Ожидаемое поведение:
- пользователь не может вернуться на предыдущий экран ни свайпом, ни системной кнопкой back (Android).
- допустимо оставить системный back как “закрыть онбординг” (но это нужно явно решить; по умолчанию лучше блокировать back полностью, кроме крестика).

### 7.3. Закрытие крестиком

На экранах `start`, `pageX`, `final`:
- крестик закрывает онбординг и открывает `LoansScreen`
- перед переходом сформировать payload пользователя и записать в Firestore (merge) с:
  - `endOnbord = false`
  - `lastOnbordpage = "{current}/{total}"`
  - `answersOnbord = ...`
  - `phone`:
    - **записываем**, только если пользователь **ввёл валидный номер** и **отметил чекбокс**
    - иначе **не записываем поле `phone`** (не обновляем его через merge)

На экранах `animation1/2`:
- крестика нет, закрыть нельзя.

---

## 8) Реализация: предлагаемые файлы/классы/методы

Ниже перечень, чтобы агент-реализатор быстро разложил всё по месту.

### 8.1. Модели

- `CombatOnboardingTheme`
  - `Color background`
  - `Color titleText`
  - `Color bodyText`
  - `Color primaryButtonBg`
  - `Color primaryButtonText`
  - `Color optionButtonBg`
  - `static CombatOnboardingTheme defaults()`
  - `factory CombatOnboardingTheme.fromMap(Map<String,dynamic>?)`

- `CombatOnboardingStartConfig`
  - `String title`
  - `String body`
  - `String primaryButtonText`
  - `CombatOnboardingTheme theme`

- `CombatOnboardingQuestionPageConfig`
  - `String question`
  - `List<String> options` (len 4)
  - `int pageNumber` (из id `pageX`)
  - `String docId` (например `page2`)

- `CombatOnboardingFinalConfig`
  - `String title`
  - `String body`
  - `String primaryButtonText`
  - `String consentText`

- `CombatOnboardingAnimationConfig`
  - `String title`
  - `int durationSeconds`

- `CombatOnboardingConfig`
  - `CombatOnboardingStartConfig start`
  - `List<CombatOnboardingQuestionPageConfig> pagesSorted`
  - `CombatOnboardingFinalConfig finalStep`
  - `CombatOnboardingAnimationConfig animation1`
  - `CombatOnboardingAnimationConfig animation2`
  - `int get totalPagesForLastOnbord` (= 1 + pagesSorted.length + 1)

- `CombatOnboardingUserPayload`
  - `String id`
  - `String? phone`
  - `String appmetricaId`
  - `DateTime firstOpenDate`
  - `bool endOnbord`
  - `String lastOnbordpage`
  - `Map<String,String> answersOnbord`
  - `Map<String,dynamic> toFirestoreMap()`

### 8.2. Сервисы

- `CombatOnboardingLocalState`
  - `Future<DateTime> getOrSetFirstOpenDate()`
  - `Future<bool> isFirstOpen()` (или derive from presence)

- `CombatOnboardingFirestoreService`
  - `Future<CombatOnboardingConfig> fetchConfig()`
    - читает `onboarding/start`, `final`, `animation1`, `animation2`
    - читает все `onboarding/pageX` (где id match `^page\\d+$`)
    - сортирует по X
    - подставляет дефолты для отсутствующих полей
  - `Future<void> upsertUser(CombatOnboardingUserPayload payload)`
    - `users/{installationId}.set(payload.toFirestoreMap(), merge:true)`

### 8.3. Контроллер/стейт

Без навязывания state management: можно `ChangeNotifier` (у вас есть provider).

- `CombatOnboardingController extends ChangeNotifier`
  - `CombatOnboardingConfig config`
  - `int currentIndex` (0-based)
  - `Map<String,String> answers`
  - `String phone`
  - `bool consentChecked`
  - `bool isPhoneValid`
  - `void onStartContinue()`
  - `void onAnswerSelected(page, option)`
  - `void onClosePressed()`
  - `Future<void> onFinalContinuePressed()`
    - валидирует телефон+checkbox
    - запускает animation1/2 (locked), затем завершает

### 8.4. UI

- `CombatOnboardingFlow` (экран-контейнер)
  - `PageView` с `NeverScrollableScrollPhysics`
  - `SmoothPageIndicator`
  - крестик (кроме animation)
  - навигация только вперёд (controller.jumpToPage / animateToPage)

Страницы:
- `StartPage`
- `QuestionPage`
- `FinalPhonePage`
- `LockedLoadingPage`

---

## 9) Изменения в существующем коде (куда встраивать)

### 9.1. `FirebaseSettings`

Добавить поле:
- `bool showOnboarding` (default false)

Источник:
- Firestore `settings/general.showOnboarding`
- серверный JSON settings (в `ServerDataService`, структура “json” уже парсится в `FirebaseSettings.fromFirestore`)

### 9.2. `AppModeWrapper` (`lib/main.dart`)

Текущее поведение:
- combat → `LoansScreen()`
- nonCombat → существующий `OnboardingScreen()` если не `settings.onboardingCompleted`, иначе `MainScreen()`

Новое требование:
- **полностью удалить/игнорировать текущий онбординг** (небоевой), и не использовать `SettingsService.onboardingCompleted`.

Ожидаемая логика:
- nonCombat → `MainScreen()` (или текущая логика приложения без онбординга)
- combat:
  - если **первый запуск** и `showOnboarding==true` → `CombatOnboardingFlow`
  - иначе → `LoansScreen`

При этом приоритет `showOnboarding` должен учитывать серверные settings.

---

## 10) Чеклист заполнения Firestore (минимальный)

### 10.1. settings/general

Добавить:
- `showOnboarding: true`

### 10.2. onboarding/start

Создать документ `onboarding/start`:
- `title`
- `body`
- `primaryButtonText`
- `theme` с 6 цветами (см. 6.6)

### 10.3. onboarding/pageX

Создать документы:
- `onboarding/page2`, `onboarding/page3`, … (или начинать с `page1`, как удобно)

В каждом:
- `question`
- `options`: массив из 4 строк

### 10.4. onboarding/final

Документ `onboarding/final`:
- `title`
- `body`
- `primaryButtonText`
- `consentText`

### 10.5. onboarding/animation1 и animation2

Документы:
- `onboarding/animation1`: `title`, `durationSeconds`
- `onboarding/animation2`: `title`, `durationSeconds`

---

## 11) План тестирования (рекомендуемый)

### 11.1. Локальные сценарии

- Первый запуск + combat + `showOnboarding=true` → показывается start.
- Закрытие крестиком на:
  - start → `lastOnbordpage="1/total"`, `endOnbord=false`
  - любой `pageX` → корректный `current/total`, ответы до этого сохранены
  - final → корректный `current/total`, `phone` пишется только если был валиден/введён (решить поведение)
- Прохождение до конца:
  - final (валидный телефон + checkbox) → animation1 N сек → animation2 M сек → LoansScreen
  - `endOnbord=true`, `lastOnbordpage="total/total"`, `phone` записан
- `showOnboarding=false` на первом запуске → онбординг не показывается, пишем `"Not shown"`, `endOnbord=false`
- nonCombat на первом запуске → онбординг не показывается, пишем `"Not shown"`, `endOnbord=false`
- Не первый запуск (prefs уже есть) → онбординг не показывается, **ничего не пишем**
- Ошибка загрузки onboarding:
  - 1 ретрай → если снова ошибка → LoansScreen

### 11.2. Smoke-тест сборки

Собрать и прогнать приложение на iOS симуляторе и Android эмуляторе, проверить:
- корректность `+7` префикса
- блокировку свайпа назад
- блокировку закрытия на animation экранах

---

## 12) Что уже сделано в рамках анализа (для трекинга)

- Прочитаны и учтены текущие точки старта приложения (`lib/main.dart`) и логика определения режима (`AppModeService`).
- Зафиксировано, что настройки `settings/general` уже читаются через `FirebaseService.getSettings()`, и в проекте есть приоритетный источник settings с сервера (`ServerDataService.fetchAllData()`).
- Уточнены требования: Firebase Installations ID как userId, merge-запись, ретрай 1 раз, удаление старого онбординга, запрет перелистывания назад, телефон только РФ с префиксом `+7`, ровно 2 loading-экрана, дефолты для всех полей, упрощённая тема из 6 цветов.

