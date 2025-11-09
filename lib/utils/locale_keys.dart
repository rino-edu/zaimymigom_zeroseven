/// Ключи для доступа к переводам
/// Генерируется на основе структуры JSON файлов локализации
class LocaleKeys {
  // App
  static const appName = 'app.name';
  static const appDescription = 'app.description';

  // Navigation
  static const navHome = 'navigation.home';
  static const navProjects = 'navigation.projects';
  static const navTasks = 'navigation.tasks';
  static const navCalendar = 'navigation.calendar';
  static const navNotes = 'navigation.notes';
  static const navCalculator = 'navigation.calculator';
  static const navGuides = 'navigation.guides';
  static const navSettings = 'navigation.settings';
  static const navLoans = 'navigation.loans';
  static const navPscCalculator = 'navigation.psc_calculator';
  static const navBudget = 'navigation.budget';
  static const navGoals = 'navigation.goals';
  static const navUserLoans = 'navigation.user_loans';

  // Calendar
  static const calendarTitle = 'calendar.title';
  static const calendarToday = 'calendar.today';
  static const calendarTomorrow = 'calendar.tomorrow';
  static const calendarYesterday = 'calendar.yesterday';
  static const calendarNoTasksForDate = 'calendar.no_tasks_for_date';
  static const calendarSelectDate = 'calendar.select_date';
  static const calendarFilterByProjects = 'calendar.filter_by_projects';

  // Projects
  static const projectsTitle = 'projects.title';
  static const projectsList = 'projects.list';
  static const projectsCreate = 'projects.create';
  static const projectsEdit = 'projects.edit';
  static const projectsDetails = 'projects.details';
  static const projectsName = 'projects.name';
  static const projectsDescription = 'projects.description';
  static const projectsImage = 'projects.image';
  static const projectsNoProjects = 'projects.no_projects';
  static const projectsAddFirst = 'projects.add_first';
  static const projectsNotFound = 'projects.not_found';
  static const projectsTryChangeFilters = 'projects.try_change_filters';
  static const projectsCreatedSuccessfully = 'projects.created_successfully';
  static const projectsUpdatedSuccessfully = 'projects.updated_successfully';
  static const projectsDeletedSuccessfully = 'projects.deleted_successfully';

  // Reports
  static const reportsTitle = 'reports.title';
  static const reportsMenu1 = 'reports.menu_1';
  static const reportsMenu2 = 'reports.menu_2';
  static const reportsMenu3 = 'reports.menu_3';
  static const reportsType = 'reports.type';
  static const reportsTypeIncome = 'reports.types.income_certificate';
  static const reportsTypeUsn = 'reports.types.usn_sample';
  static const reportsTypeBank = 'reports.types.bank_certificate';
  static const reportsPeriod = 'reports.period';
  static const reportsSelectPeriod = 'reports.select_period';
  static const reportsFieldName = 'reports.fields.name';
  static const reportsFieldInn = 'reports.fields.inn';
  static const reportsFieldAmount = 'reports.fields.amount';
  static const reportsGeneratePdf = 'reports.generate_pdf';
  static const reportsGenerateCsv = 'reports.generate_csv';
  static const reportsTemplates = 'reports.templates.title';
  static const reportsSelectTemplate = 'reports.templates.select';
  static const reportsSaveTemplate = 'reports.templates.save';
  static const reportsDeleteTemplate = 'reports.templates.delete';
  static const reportsTemplateSaved = 'reports.templates.saved';
  static const reportsTemplateDeleted = 'reports.templates.deleted';
  static const reportsOpenFile = 'reports.open_file';
  static const reportsSavedTo = 'reports.saved_to';
  static const reportsGeneratedBy = 'reports.generated_by';

  // Validation extension
  static const validationEnterPeriod = 'validation.enter_period';
  static const projectsDeleteConfirmTitle = 'projects.delete_confirm_title';
  static const projectsDeleteConfirmMessage = 'projects.delete_confirm_message';
  static const projectsDatesTitle = 'projects.dates_title';
  static const projectsAddPhoto = 'projects.add_photo';
  static const projectsOptional = 'projects.optional';
  static const projectsRequiredFieldsInfo = 'projects.required_fields_info';

  // Tasks
  static const tasksTitle = 'tasks.title';
  static const tasksList = 'tasks.list';
  static const tasksCreate = 'tasks.create';
  static const tasksEdit = 'tasks.edit';
  static const tasksDetails = 'tasks.details';
  static const tasksTaskTitle = 'tasks.task_title';
  static const tasksDescription = 'tasks.description';
  static const tasksTag = 'tasks.tag';
  static const tasksTagFilter = 'tasks.tag_filter';
  static const tasksQuickTask = 'tasks.quick_task';
  static const tasksNoTasks = 'tasks.no_tasks';
  static const tasksAddFirst = 'tasks.add_first';
  static const tasksNotFound = 'tasks.not_found';
  static const tasksTryChangeFilters = 'tasks.try_change_filters';
  static const tasksCreatedSuccessfully = 'tasks.created_successfully';
  static const tasksUpdatedSuccessfully = 'tasks.updated_successfully';
  static const tasksDeletedSuccessfully = 'tasks.deleted_successfully';
  static const tasksDeleteConfirmTitle = 'tasks.delete_confirm_title';
  static const tasksDeleteConfirmMessage = 'tasks.delete_confirm_message';
  static const tasksMarkComplete = 'tasks.mark_complete';
  static const tasksMarkIncomplete = 'tasks.mark_incomplete';
  static const tasksOverdue = 'tasks.overdue';
  static const tasksDatesTitle = 'tasks.dates_title';
  static const tasksHistoryTitle = 'tasks.history_title';
  static const tasksCreated = 'tasks.created';
  static const tasksUpdated = 'tasks.updated';
  static const tasksCompletedMessage = 'tasks.completed_message';
  static const tasksReturnedMessage = 'tasks.returned_message';
  static const tasksCount = 'tasks.count';

  // Dates
  static const datesStart = 'dates.start';
  static const datesEnd = 'dates.end';
  static const datesDeadline = 'dates.deadline';
  static const datesNotSet = 'dates.not_set';

  // Priority
  static const priorityLabel = 'priority.label';
  static const priorityLow = 'priority.low';
  static const priorityMedium = 'priority.medium';
  static const priorityHigh = 'priority.high';
  static const priorityUrgent = 'priority.urgent';

  // Status
  static const statusAll = 'status.all';
  static const statusLabel = 'status.label';
  static const statusPending = 'status.pending';
  static const statusInProgress = 'status.in_progress';
  static const statusCompleted = 'status.completed';
  static const statusCancelled = 'status.cancelled';
  static const statusPlanning = 'status.planning';
  static const statusOnHold = 'status.on_hold';

  // Tags
  static const tagsPlanning = 'tags.planning';
  static const tagsMaterials = 'tags.materials';
  static const tagsConstruction = 'tags.construction';
  static const tagsFinishing = 'tags.finishing';
  static const tagsInspection = 'tags.inspection';
  static const tagsOther = 'tags.other';

  // Notes
  static const notesTitle = 'notes.title';
  static const notesList = 'notes.list';
  static const notesCreate = 'notes.create';
  static const notesEdit = 'notes.edit';
  static const notesNoteTitle = 'notes.note_title';
  static const notesContent = 'notes.content';
  static const notesAttachToTask = 'notes.attach_to_task';
  static const notesNoNotes = 'notes.no_notes';
  static const notesAddFirst = 'notes.add_first';
  static const notesNotFound = 'notes.not_found';
  static const notesTryChangeFilters = 'notes.try_change_filters';
  static const notesAllNotes = 'notes.all_notes';
  static const notesFilterByTask = 'notes.filter_by_task';
  static const notesNoTask = 'notes.no_task';
  static const notesCreatedSuccessfully = 'notes.created_successfully';
  static const notesUpdatedSuccessfully = 'notes.updated_successfully';
  static const notesDeletedSuccessfully = 'notes.deleted_successfully';
  static const notesDeleteConfirmTitle = 'notes.delete_confirm_title';
  static const notesDeleteConfirmMessage = 'notes.delete_confirm_message';
  static const notesTitleHint = 'notes.title_hint';
  static const notesContentHint = 'notes.content_hint';
  static const notesCreateHint = 'notes.create_hint';
  static const notesEditHint = 'notes.edit_hint';
  static const notesAttachFiles = 'notes.attach_files';
  static const notesAttachMoreFiles = 'notes.attach_more_files';
  static const notesProjectNotSelected = 'notes.project_not_selected';
  static const notesErrorLoadingTasks = 'notes.error_loading_tasks';
  static const notesErrorSaving = 'notes.error_saving';
  static const notesErrorAttaching = 'notes.error_attaching';
  static const notesLinkedToTask = 'notes.linked_to_task';

  // Calculator
  static const calculatorTitle = 'calculator.title';
  static const calculatorVolume = 'calculator.volume';
  static const calculatorArea = 'calculator.area';
  static const calculatorMaterials = 'calculator.materials';
  static const calculatorLength = 'calculator.length';
  static const calculatorWidth = 'calculator.width';
  static const calculatorHeight = 'calculator.height';
  static const calculatorRadius = 'calculator.radius';
  static const calculatorResult = 'calculator.result';
  static const calculatorCalculate = 'calculator.calculate';
  static const calculatorClear = 'calculator.clear';

  // Settings
  static const settingsTitle = 'settings.title';
  static const settingsTheme = 'settings.theme';
  static const settingsLanguage = 'settings.language';
  static const settingsNotifications = 'settings.notifications';
  static const settingsSecurity = 'settings.security';
  static const settingsData = 'settings.data';
  static const settingsAbout = 'settings.about';
  static const settingsAppearance = 'settings.appearance';
  static const settingsOther = 'settings.other';
  static const settingsLightTheme = 'settings.light_theme';
  static const settingsDarkTheme = 'settings.dark_theme';
  static const settingsSystemTheme = 'settings.system_theme';
  static const settingsSystemLanguage = 'settings.system_language';
  static const settingsRussian = 'settings.russian';
  static const settingsEnglish = 'settings.english';
  static const settingsChooseTheme = 'settings.choose_theme';
  static const settingsChooseLanguage = 'settings.choose_language';
  static const settingsThemeChanged = 'settings.theme_changed';
  static const settingsLanguageChanged = 'settings.language_changed';
  static const settingsResetSettings = 'settings.reset_settings';
  static const settingsResetDescription = 'settings.reset_description';
  static const settingsResetConfirmTitle = 'settings.reset_confirm_title';
  static const settingsResetConfirmMessage = 'settings.reset_confirm_message';
  static const settingsResetSuccess = 'settings.reset_success';
  static const settingsResetPersonalData = 'settings.reset_personal_data';
  static const settingsResetPersonalConfirmTitle = 'settings.reset_personal_confirm_title';
  static const settingsResetPersonalConfirmMessage = 'settings.reset_personal_confirm_message';
  static const settingsResetPersonalSuccess = 'settings.reset_personal_success';
  static const settingsPersonalData = 'settings.personal_data';
  static const settingsPersonalDataDescription = 'settings.personal_data_description';
  static const settingsFirstName = 'settings.first_name';
  static const settingsLastName = 'settings.last_name';
  static const settingsEmail = 'settings.email';
  static const settingsPhone = 'settings.phone';
  static const settingsDateOfBirth = 'settings.date_of_birth';
  static const settingsEnterFirstName = 'settings.enter_first_name';
  static const settingsEnterLastName = 'settings.enter_last_name';
  static const settingsEnterEmail = 'settings.enter_email';
  static const settingsEnterPhone = 'settings.enter_phone';
  static const settingsEnterDateOfBirth = 'settings.enter_date_of_birth';
  static const settingsSavePersonalData = 'settings.save_personal_data';
  static const settingsPersonalDataSaved = 'settings.personal_data_saved';
  static const settingsPinCodeSet = 'settings.pin_code_set';
  static const settingsPinCodeRemoved = 'settings.pin_code_removed';
  static const settingsSetPinCode = 'settings.set_pin_code';
  static const settingsRemovePinCode = 'settings.remove_pin_code';
  static const settingsEnterPinCode = 'settings.enter_pin_code';
  static const settingsConfirmPinCode = 'settings.confirm_pin_code';
  static const settingsPinCodesNotMatch = 'settings.pin_codes_not_match';
  static const settingsPinCodeMustBe4Digits = 'settings.pin_code_must_be_4_digits';
  static const settingsBiometricNotAvailable = 'settings.biometric_not_available';
  static const settingsEnableBiometricFirst = 'settings.enable_biometric_first';
  static const settingsEnableSecurity = 'settings.enable_security';
  static const settingsDisableSecurity = 'settings.disable_security';

  // Notifications
  static const notificationsEnable = 'notifications.enable';
  static const notificationsEnabled = 'notifications.enabled';
  static const notificationsDeadlineReminders =
      'notifications.deadline_reminders';
  static const notificationsDeadlineDescription =
      'notifications.deadline_description';
  static const notificationsDailyReminders = 'notifications.daily_reminders';
  static const notificationsDailyDescription =
      'notifications.daily_description';
  static const notificationsQuietHours = 'notifications.quiet_hours';
  static const notificationsQuietHoursDescription =
      'notifications.quiet_hours_description';
  static const notificationsQuietHoursUpdated =
      'notifications.quiet_hours_updated';
  static const notificationsChangeQuietHours =
      'notifications.change_quiet_hours';
  static const notificationsFrom = 'notifications.from';
  static const notificationsTo = 'notifications.to';
  static const notificationsTaskReminder = 'notifications.task_reminder';
  static const notificationsDeadlineInHour = 'notifications.deadline_in_hour';
  static const notificationsDeadlineTomorrow =
      'notifications.deadline_tomorrow';
  static const notificationsDeadlineIn3Days = 'notifications.deadline_in_3days';
  static const notificationsDailyReminderTitle =
      'notifications.daily_reminder_title';
  static const notificationsDailyReminderBody =
      'notifications.daily_reminder_body';
  static const notificationsTasksForToday = 'notifications.tasks_for_today';
  static const notificationsTitle = 'notifications.title';
  static const notificationsRemindBefore = 'notifications.remind_before';
  static const notifications1HourBefore = 'notifications.1_hour_before';
  static const notifications1DayBefore = 'notifications.1_day_before';
  static const notifications3DaysBefore = 'notifications.3_days_before';
  static const notificationsDisabled = 'notifications.disabled';
  static const notificationsScheduled = 'notifications.scheduled';
  static const notificationsNoScheduled = 'notifications.no_scheduled';

  // Security
  static const securityBiometricAuth = 'security.biometric_auth';
  static const securityPinCode = 'security.pin_code';
  static const securityFingerprint = 'security.fingerprint';
  static const securityFaceId = 'security.face_id';
  static const securityEnable = 'security.enable';
  static const securityChangePin = 'security.change_pin';

  // Actions
  static const actionsSave = 'actions.save';
  static const actionsCancel = 'actions.cancel';
  static const actionsDelete = 'actions.delete';
  static const actionsEdit = 'actions.edit';
  static const actionsAdd = 'actions.add';
  static const actionsRemove = 'actions.remove';
  static const actionsConfirm = 'actions.confirm';
  static const actionsBack = 'actions.back';
  static const actionsNext = 'actions.next';
  static const actionsFinish = 'actions.finish';
  static const actionsSearch = 'actions.search';
  static const actionsFilter = 'actions.filter';
  static const actionsSort = 'actions.sort';
  static const actionsRefresh = 'actions.refresh';
  static const actionsShare = 'actions.share';
  static const actionsExport = 'actions.export';
  static const actionsImport = 'actions.import';
  static const actionsClearFilters = 'actions.clear_filters';
  static const actionsCreateProject = 'actions.create_project';
  static const actionsRetry = 'actions.retry';
  static const actionsAll = 'actions.all';
  static const actionsMarkPaid = 'actions.mark_paid';
  static const actionsMarkUnpaid = 'actions.mark_unpaid';
  static const actionsApply = 'actions.apply';

  // Common
  static const commonChars = 'common.chars';

  // Messages
  static const messagesSuccess = 'messages.success';
  static const messagesError = 'messages.error';
  static const messagesWarning = 'messages.warning';
  static const messagesInfo = 'messages.info';
  static const messagesLoading = 'messages.loading';
  static const messagesNoData = 'messages.no_data';
  static const messagesNoInternet = 'messages.no_internet';
  static const messagesTryAgain = 'messages.try_again';
  static const messagesFeatureInDevelopment = 'messages.feature_in_development';
  static const messagesUnsavedChanges = 'messages.unsaved_changes';

  // Validation
  static const validationRequired = 'validation.required';
  static const validationInvalidEmail = 'validation.invalid_email';
  static const validationInvalidDate = 'validation.invalid_date';
  static const validationDateInPast = 'validation.date_in_past';
  static const validationEndBeforeStart = 'validation.end_before_start';
  static const validationEnterNoteTitle = 'validation.enter_note_title';
  static const validationEnterNoteContent = 'validation.enter_note_content';
  static const validationMinLength = 'validation.min_length';
  static const validationOptional = 'validation.optional';
  static const validationSelectDate = 'validation.select_date';
  static const validationEnterNumber = 'validation.enter_number';
  static const validationNotSet = 'validation.not_set';

  // Attachments
  static const attachmentsLabel = 'attachments.label';

  // Guides
  static const guidesTitle = 'guides.title';
  static const guidesElectrical = 'guides.electrical';
  static const guidesPlumbing = 'guides.plumbing';
  static const guidesFinishing = 'guides.finishing';
  static const guidesSafety = 'guides.safety';
  static const guidesMaterialSelection = 'guides.material_selection';
  static const guidesTools = 'guides.tools';
  static const guidesPreparation = 'guides.preparation';
  static const guidesConcrete = 'guides.concrete';
  static const guidesInsulation = 'guides.insulation';
  static const guidesRoofing = 'guides.roofing';
  static const guidesNotFound = 'guides.not_found';
  static const guidesGeneral = 'guides.general';
  static const guidesTechnical = 'guides.technical';
  static const guidesFinishingCategory = 'guides.finishing_category';
  static const guidesSafetyCategory = 'guides.safety_category';
  static const guidesElectricalCategory = 'guides.electrical_category';
  static const guidesPlumbingCategory = 'guides.plumbing_category';
  static const guidesMaterialsCategory = 'guides.materials_category';
  static const guidesToolsCategory = 'guides.tools_category';
  static const guidesPreparationCategory = 'guides.preparation_category';
  static const guidesConcreteCategory = 'guides.concrete_category';
  static const guidesInsulationCategory = 'guides.insulation_category';
  static const guidesRoofingCategory = 'guides.roofing_category';
  static const guidesAllCategories = 'guides.all_categories';
  static const guidesMinutes = 'guides.minutes';
  static const guidesAddedToFavorites = 'guides.added_to_favorites';
  static const guidesRemovedFromFavorites = 'guides.removed_from_favorites';
  static const guidesAddToFavorites = 'guides.add_to_favorites';
  static const guidesRemoveFromFavorites = 'guides.remove_from_favorites';
  static const guidesCopiedToClipboard = 'guides.copied_to_clipboard';
  static const guidesCopyContent = 'guides.copy_content';
  static const guidesCannotOpenLink = 'guides.cannot_open_link';

  // Units
  static const unitsMeters = 'units.meters';
  static const unitsCentimeters = 'units.centimeters';
  static const unitsMillimeters = 'units.millimeters';
  static const unitsSquareMeters = 'units.square_meters';
  static const unitsCubicMeters = 'units.cubic_meters';
  static const unitsKilograms = 'units.kilograms';
  static const unitsPieces = 'units.pieces';
  static const unitsLiters = 'units.liters';

  // Statistics
  static const statisticsTotalProjects = 'statistics.total_projects';
  static const statisticsTotalTasks = 'statistics.total_tasks';
  static const statisticsCompletedTasks = 'statistics.completed_tasks';
  static const statisticsPendingTasks = 'statistics.pending_tasks';
  static const statisticsOverdueTasks = 'statistics.overdue_tasks';
  static const statisticsInProgressTasks = 'statistics.in_progress_tasks';
  static const statisticsCompletionRate = 'statistics.completion_rate';
  static const statisticsTaskStatistics = 'statistics.task_statistics';
  static const statisticsTotal = 'statistics.total';
  static const statisticsCompleted = 'statistics.completed';
  static const statisticsInProgress = 'statistics.in_progress';
  static const statisticsOverdue = 'statistics.overdue';

  // Data
  static const dataExport = 'data.export';
  static const dataImport = 'data.import';
  static const dataBackup = 'data.backup';
  static const dataRestore = 'data.restore';
  static const dataSelectFile = 'data.select_file';
  static const dataExported = 'data.exported';
  static const dataImported = 'data.imported';

  // About
  static const aboutVersion = 'about.version';
  static const aboutBuild = 'about.build';
  static const aboutDeveloper = 'about.developer';
  static const aboutPrivacyPolicy = 'about.privacy_policy';
  static const aboutTerms = 'about.terms';
  static const aboutSupport = 'about.support';
  static const aboutFeedback = 'about.feedback';

  // Sorting
  static const sortingByCreated = 'sorting.by_created';
  static const sortingByUpdated = 'sorting.by_updated';
  static const sortingByTitle = 'sorting.by_title';
  static const sortingByPriority = 'sorting.by_priority';
  static const sortingByStatus = 'sorting.by_status';
  static const sortingByDeadline = 'sorting.by_deadline';
  static const sortingSort = 'sorting.sort';
  static const sortingByDate = 'sorting.by_date';
  static const sortingByAmount = 'sorting.by_amount';

  // Image Picker
  static const imagePickerCamera = 'image_picker.camera';
  static const imagePickerGallery = 'image_picker.gallery';
  static const imagePickerChooseSource = 'image_picker.choose_source';

  // Placeholders
  static const placeholdersInDevelopment = 'placeholders.in_development';
  static const placeholdersProjectNameHint = 'placeholders.project_name_hint';
  static const placeholdersProjectDescriptionHint =
      'placeholders.project_description_hint';
  static const placeholdersTaskTitleHint = 'placeholders.task_title_hint';
  static const placeholdersTaskDescriptionHint =
      'placeholders.task_description_hint';
  static const placeholdersNoAttachments = 'placeholders.no_attachments';
  static const placeholdersQuickTaskInfo = 'placeholders.quick_task_info';
  static const placeholdersTaskRequiredInfo = 'placeholders.task_required_info';
  static const placeholdersSelectProjectFirst =
      'placeholders.select_project_first';
  static const placeholdersSelectProject = 'placeholders.select_project';
  static const placeholdersTagLabel = 'placeholders.tag_label';
  static const placeholdersFileLabel = 'placeholders.file_label';

  // File Errors
  static const fileErrorsFileNotFound = 'file_errors.file_not_found';
  static const fileErrorsNoAppToOpen = 'file_errors.no_app_to_open';
  static const fileErrorsPermissionDenied = 'file_errors.permission_denied';
  static const fileErrorsErrorOpeningFile = 'file_errors.error_opening_file';

  // CompareTax
  static const compareTitle = 'compare.title';
  static const compareMenu1 = 'compare.menu_1';
  static const compareMenu2 = 'compare.menu_2';
  static const compareMenu3 = 'compare.menu_3';
  static const compareInputIncome = 'compare.input.income';
  static const compareInputOutcome = 'compare.input.outcome';
  static const compareFiltersTax = 'compare.filters.tax';
  static const compareFiltersBookkeeping = 'compare.filters.bookkeeping';
  static const compareFiltersCash = 'compare.filters.cash';
  static const compareFiltersExpenses = 'compare.filters.expenses';
  static const compareTableTitle = 'compare.table.title';
  static const compareResultTax = 'compare.result.tax';
  static const compareResultDetails = 'compare.result.details';
  static const compareInfoUsnIncome = 'compare.info.usn_income';
  static const compareInfoUsnIncomeOutcome = 'compare.info.usn_income_outcome';
  static const compareInfoPatent = 'compare.info.patent';
  static const compareInfoOsno = 'compare.info.osno';
  static const compareInfoNpd = 'compare.info.npd';

  static const compareRegimesUsnIncome = 'compare.regimes.usn_income';
  static const compareRegimesUsnIncomeOutcome =
      'compare.regimes.usn_income_outcome';
  static const compareRegimesPatent = 'compare.regimes.patent';
  static const compareRegimesOsno = 'compare.regimes.osno';
  static const compareRegimesNpd = 'compare.regimes.npd';

  // Tax History
  static const taxHistoryTitle = 'tax_history.title';
  static const taxHistoryAdd = 'tax_history.add';
  static const taxHistoryEdit = 'tax_history.edit';
  static const taxHistoryEmpty = 'tax_history.empty';
  static const taxHistoryEmptyHint = 'tax_history.empty_hint';
  static const taxHistoryAddFirst = 'tax_history.add_first';
  static const taxHistoryFilters = 'tax_history.filters';
  static const taxHistoryFilterType = 'tax_history.filter_type';
  static const taxHistoryType = 'tax_history.type';
  static const taxHistoryTypePayment = 'tax_history.type_payment';
  static const taxHistoryTypeReport = 'tax_history.type_report';
  static const taxHistoryTypeOverdue = 'tax_history.type_overdue';
  static const taxHistoryTypePenalty = 'tax_history.type_penalty';
  static const taxHistoryTaxType = 'tax_history.tax_type';
  static const taxHistoryAmount = 'tax_history.amount';
  static const taxHistoryDate = 'tax_history.date';
  static const taxHistoryDueDate = 'tax_history.due_date';
  static const taxHistoryDueDateOptional = 'tax_history.due_date_optional';
  static const taxHistoryStatus = 'tax_history.status';
  static const taxHistoryStatusPaid = 'tax_history.status_paid';
  static const taxHistoryStatusPending = 'tax_history.status_pending';
  static const taxHistoryStatusOverdue = 'tax_history.status_overdue';
  static const taxHistoryIsPaid = 'tax_history.is_paid';
  static const taxHistoryDescription = 'tax_history.description';
  static const taxHistoryDescriptionOptional = 'tax_history.description_optional';
  static const taxHistoryNotes = 'tax_history.notes';
  static const taxHistoryNotesOptional = 'tax_history.notes_optional';
  static const taxHistoryDeleteConfirm = 'tax_history.delete_confirm';
  static const taxHistoryMenu1 = 'tax_history.menu_1';
  static const taxHistoryMenu2 = 'tax_history.menu_2';
  static const taxHistoryMenu3 = 'tax_history.menu_3';

  // PSC Calculator
  static const pscCalculatorTitle = 'psc_calculator.title';
  static const pscCalculatorPlaceholder = 'psc_calculator.placeholder';
  static const pscCalculatorDescription = 'psc_calculator.description';
  static const pscCalculatorFormula = 'psc_calculator.formula';
  static const pscCalculatorAmount = 'psc_calculator.amount';
  static const pscCalculatorAnnualRate = 'psc_calculator.annual_rate';
  static const pscCalculatorTermMonths = 'psc_calculator.term_months';
  static const pscCalculatorPaymentType = 'psc_calculator.payment_type';
  static const pscCalculatorPaymentTypeAnnuity = 'psc_calculator.payment_type_annuity';
  static const pscCalculatorPaymentTypeDifferentiated = 'psc_calculator.payment_type_differentiated';
  static const pscCalculatorUpfrontFee = 'psc_calculator.upfront_fee';
  static const pscCalculatorMonthlyFee = 'psc_calculator.monthly_fee';
  static const pscCalculatorInsuranceMonthly = 'psc_calculator.insurance_monthly';
  static const pscCalculatorMaxRateError = 'psc_calculator.max_rate_error';
  static const pscCalculatorResultTitle = 'psc_calculator.result_title';
  static const pscCalculatorResultPsk = 'psc_calculator.result_psk';
  static const pscCalculatorResultTotalPayment = 'psc_calculator.result_total_payment';
  static const pscCalculatorResultOverpayment = 'psc_calculator.result_overpayment';
  static const pscCalculatorScheduleTitle = 'psc_calculator.schedule_title';
  static const pscCalculatorColMonth = 'psc_calculator.col_month';
  static const pscCalculatorColPrincipal = 'psc_calculator.col_principal';
  static const pscCalculatorColInterest = 'psc_calculator.col_interest';
  static const pscCalculatorColFees = 'psc_calculator.col_fees';
  static const pscCalculatorColTotal = 'psc_calculator.col_total';
  static const pscCalculatorColBalance = 'psc_calculator.col_balance';

  // Budget
  static const budgetTitle = 'budget.title';
  static const budgetPlaceholder = 'budget.placeholder';

  // Goals
  static const goalsTitle = 'goals.title';
  static const goalsPlaceholder = 'goals.placeholder';

  // User Loans
  static const userLoansTitle = 'user_loans.title';
  static const userLoansPlaceholder = 'user_loans.placeholder';
}

// Ключи для Базы знаний (knowledge)
class KnowledgeKeys {
  static const title = 'knowledge.title';
  static const menu1 = 'knowledge.menu_1';
  static const menu2 = 'knowledge.menu_2';
  static const menu3 = 'knowledge.menu_3';
  static const searchPlaceholder = 'knowledge.search_placeholder';

  static const filtersAll = 'knowledge.filters.all';
  static const filtersTags = 'knowledge.filters.tags';
  static const filtersComplexity = 'knowledge.filters.complexity';
  static const filtersImportance = 'knowledge.filters.importance';

  static const complexityBeginner = 'knowledge.complexity.beginner';
  static const complexityIntermediate = 'knowledge.complexity.intermediate';
  static const complexityAdvanced = 'knowledge.complexity.advanced';

  static const importanceLow = 'knowledge.importance.low';
  static const importanceMedium = 'knowledge.importance.medium';
  static const importanceHigh = 'knowledge.importance.high';

  static const articleIntro = 'knowledge.article.intro';
  static const articleForBeginners = 'knowledge.article.for_beginners';
  static const articleForPros = 'knowledge.article.for_pros';
  static const articleLinks = 'knowledge.article.links';
  static const articleReadTime = 'knowledge.article.read_time';

  // Примерные статьи (для демо-данных)
  static const sampleNpdTitle = 'knowledge.sample.npd_basics.title';
  static const sampleNpdIntro = 'knowledge.sample.npd_basics.intro';
  static const sampleNpdBeginners = 'knowledge.sample.npd_basics.beginners';
  static const sampleNpdPros = 'knowledge.sample.npd_basics.pros';

  static const sampleUsnPatentTitle = 'knowledge.sample.usn_vs_patent.title';
  static const sampleUsnPatentIntro = 'knowledge.sample.usn_vs_patent.intro';
  static const sampleUsnPatentBeginners = 'knowledge.sample.usn_vs_patent.beginners';
  static const sampleUsnPatentPros = 'knowledge.sample.usn_vs_patent.pros';
}
