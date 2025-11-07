import 'package:easy_localization/easy_localization.dart';
import '../utils/locale_keys.dart';

/// Строковые константы приложения с поддержкой локализации
class AppStrings {
  // Общие строки
  static String get appName => LocaleKeys.appName.tr();
  static String get appDescription => LocaleKeys.appDescription.tr();

  // Навигация
  static String get home => LocaleKeys.navHome.tr();
  static String get projects => LocaleKeys.navProjects.tr();
  static String get tasks => LocaleKeys.navTasks.tr();
  static String get calendar => LocaleKeys.navCalendar.tr();
  static String get notes => LocaleKeys.navNotes.tr();
  static String get calculator => LocaleKeys.navCalculator.tr();
  static String get guides => LocaleKeys.navGuides.tr();
  static String get settings => LocaleKeys.navSettings.tr();
  static String get loans => LocaleKeys.navLoans.tr();

  // Проекты
  static String get projectList => LocaleKeys.projectsList.tr();
  static String get createProject => LocaleKeys.projectsCreate.tr();
  static String get editProject => LocaleKeys.projectsEdit.tr();
  static String get projectDetails => LocaleKeys.projectsDetails.tr();
  static String get projectName => LocaleKeys.projectsName.tr();
  static String get projectDescription => LocaleKeys.projectsDescription.tr();
  static String get startDate => LocaleKeys.datesStart.tr();
  static String get endDate => LocaleKeys.datesEnd.tr();
  static String get projectImage => LocaleKeys.projectsImage.tr();
  static String get noProjects => LocaleKeys.projectsNoProjects.tr();
  static String get addFirstProject => LocaleKeys.projectsAddFirst.tr();

  // Задачи
  static String get taskList => LocaleKeys.tasksList.tr();
  static String get createTask => LocaleKeys.tasksCreate.tr();
  static String get editTask => LocaleKeys.tasksEdit.tr();
  static String get taskDetails => LocaleKeys.tasksDetails.tr();
  static String get taskTitle => LocaleKeys.tasksTaskTitle.tr();
  static String get taskDescription => LocaleKeys.tasksDescription.tr();
  static String get deadline => LocaleKeys.datesDeadline.tr();
  static String get taskTag => LocaleKeys.tasksTag.tr();
  static String get priority => LocaleKeys.priorityLabel.tr();
  static String get quickTask => LocaleKeys.tasksQuickTask.tr();
  static String get noTasks => LocaleKeys.tasksNoTasks.tr();
  static String get addFirstTask => LocaleKeys.tasksAddFirst.tr();

  // Приоритеты
  static String get lowPriority => LocaleKeys.priorityLow.tr();
  static String get mediumPriority => LocaleKeys.priorityMedium.tr();
  static String get highPriority => LocaleKeys.priorityHigh.tr();
  static String get urgentPriority => LocaleKeys.priorityUrgent.tr();

  // Статусы
  static String get pending => LocaleKeys.statusPending.tr();
  static String get inProgress => LocaleKeys.statusInProgress.tr();
  static String get completed => LocaleKeys.statusCompleted.tr();
  static String get cancelled => LocaleKeys.statusCancelled.tr();

  // Теги
  static String get planningTag => LocaleKeys.tagsPlanning.tr();
  static String get materialsTag => LocaleKeys.tagsMaterials.tr();
  static String get constructionTag => LocaleKeys.tagsConstruction.tr();
  static String get finishingTag => LocaleKeys.tagsFinishing.tr();
  static String get inspectionTag => LocaleKeys.tagsInspection.tr();
  static String get otherTag => LocaleKeys.tagsOther.tr();

  // Заметки
  static String get noteList => LocaleKeys.notesList.tr();
  static String get createNote => LocaleKeys.notesCreate.tr();
  static String get editNote => LocaleKeys.notesEdit.tr();
  static String get noteTitle => LocaleKeys.notesNoteTitle.tr();
  static String get noteContent => LocaleKeys.notesContent.tr();
  static String get attachToTask => LocaleKeys.notesAttachToTask.tr();
  static String get attachments => LocaleKeys.attachmentsLabel.tr();
  static String get noNotes => LocaleKeys.notesNoNotes.tr();
  static String get addFirstNote => LocaleKeys.notesAddFirst.tr();

  // Калькулятор
  static String get volumeCalculator => LocaleKeys.calculatorVolume.tr();
  static String get areaCalculator => LocaleKeys.calculatorArea.tr();
  static String get materialCalculator => LocaleKeys.calculatorMaterials.tr();
  static String get length => LocaleKeys.calculatorLength.tr();
  static String get width => LocaleKeys.calculatorWidth.tr();
  static String get height => LocaleKeys.calculatorHeight.tr();
  static String get radius => LocaleKeys.calculatorRadius.tr();
  static String get result => LocaleKeys.calculatorResult.tr();
  static String get calculate => LocaleKeys.calculatorCalculate.tr();
  static String get clear => LocaleKeys.calculatorClear.tr();

  // Настройки
  static String get themeSettings => LocaleKeys.settingsTheme.tr();
  static String get languageSettings => LocaleKeys.settingsLanguage.tr();
  static String get notificationSettings =>
      LocaleKeys.settingsNotifications.tr();
  static String get securitySettings => LocaleKeys.settingsSecurity.tr();
  static String get dataSettings => LocaleKeys.settingsData.tr();
  static String get aboutApp => LocaleKeys.settingsAbout.tr();
  static String get lightTheme => LocaleKeys.settingsLightTheme.tr();
  static String get darkTheme => LocaleKeys.settingsDarkTheme.tr();
  static String get systemTheme => LocaleKeys.settingsSystemTheme.tr();
  static String get russian => LocaleKeys.settingsRussian.tr();
  static String get english => LocaleKeys.settingsEnglish.tr();

  // Уведомления
  static String get enableNotifications => LocaleKeys.notificationsEnable.tr();
  static String get deadlineReminders =>
      LocaleKeys.notificationsDeadlineReminders.tr();
  static String get dailyReminders =>
      LocaleKeys.notificationsDailyReminders.tr();
  static String get quietHours => LocaleKeys.notificationsQuietHours.tr();
  static String get from => LocaleKeys.notificationsFrom.tr();
  static String get to => LocaleKeys.notificationsTo.tr();

  // Безопасность
  static String get biometricAuth => LocaleKeys.securityBiometricAuth.tr();
  static String get pinCode => LocaleKeys.securityPinCode.tr();
  static String get fingerprint => LocaleKeys.securityFingerprint.tr();
  static String get faceId => LocaleKeys.securityFaceId.tr();
  static String get enableSecurity => LocaleKeys.securityEnable.tr();
  static String get changePin => LocaleKeys.securityChangePin.tr();

  // Действия
  static String get save => LocaleKeys.actionsSave.tr();
  static String get cancel => LocaleKeys.actionsCancel.tr();
  static String get delete => LocaleKeys.actionsDelete.tr();
  static String get edit => LocaleKeys.actionsEdit.tr();
  static String get add => LocaleKeys.actionsAdd.tr();
  static String get remove => LocaleKeys.actionsRemove.tr();
  static String get confirm => LocaleKeys.actionsConfirm.tr();
  static String get back => LocaleKeys.actionsBack.tr();
  static String get next => LocaleKeys.actionsNext.tr();
  static String get finish => LocaleKeys.actionsFinish.tr();
  static String get search => LocaleKeys.actionsSearch.tr();
  static String get filter => LocaleKeys.actionsFilter.tr();
  static String get sort => LocaleKeys.actionsSort.tr();
  static String get refresh => LocaleKeys.actionsRefresh.tr();
  static String get share => LocaleKeys.actionsShare.tr();
  static String get export => LocaleKeys.actionsExport.tr();
  static String get import => LocaleKeys.actionsImport.tr();

  // Сообщения
  static String get success => LocaleKeys.messagesSuccess.tr();
  static String get error => LocaleKeys.messagesError.tr();
  static String get warning => LocaleKeys.messagesWarning.tr();
  static String get info => LocaleKeys.messagesInfo.tr();
  static String get loading => LocaleKeys.messagesLoading.tr();
  static String get noData => LocaleKeys.messagesNoData.tr();
  static String get noInternet => LocaleKeys.messagesNoInternet.tr();
  static String get tryAgain => LocaleKeys.messagesTryAgain.tr();

  // Валидация
  static String get requiredField => LocaleKeys.validationRequired.tr();
  static String get invalidEmail => LocaleKeys.validationInvalidEmail.tr();
  static String get invalidDate => LocaleKeys.validationInvalidDate.tr();
  static String get dateInPast => LocaleKeys.validationDateInPast.tr();
  static String get endDateBeforeStart =>
      LocaleKeys.validationEndBeforeStart.tr();

  // Подтверждения
  static String get deleteProjectConfirm =>
      LocaleKeys.projectsDeleteConfirmTitle.tr();
  static String get deleteTaskConfirm =>
      LocaleKeys.tasksDeleteConfirmTitle.tr();
  static String deleteNoteConfirm(String name) =>
      LocaleKeys.projectsDeleteConfirmMessage.tr(namedArgs: {'name': name});
  static String get unsavedChanges => LocaleKeys.messagesUnsavedChanges.tr();

  // Гайды
  static String get constructionGuides => LocaleKeys.guidesTitle.tr();
  static String get electricalWork => LocaleKeys.guidesElectrical.tr();
  static String get plumbingWork => LocaleKeys.guidesPlumbing.tr();
  static String get finishingWork => LocaleKeys.guidesFinishing.tr();
  static String get safetyTips => LocaleKeys.guidesSafety.tr();
  static String get materialSelection =>
      LocaleKeys.guidesMaterialSelection.tr();
  static String get toolsAndEquipment => LocaleKeys.guidesTools.tr();

  // Размеры и единицы
  static String get meters => LocaleKeys.unitsMeters.tr();
  static String get centimeters => LocaleKeys.unitsCentimeters.tr();
  static String get millimeters => LocaleKeys.unitsMillimeters.tr();
  static String get squareMeters => LocaleKeys.unitsSquareMeters.tr();
  static String get cubicMeters => LocaleKeys.unitsCubicMeters.tr();
  static String get kilograms => LocaleKeys.unitsKilograms.tr();
  static String get pieces => LocaleKeys.unitsPieces.tr();
  static String get liters => LocaleKeys.unitsLiters.tr();

  // Статистика
  static String get totalProjects => LocaleKeys.statisticsTotalProjects.tr();
  static String get totalTasks => LocaleKeys.statisticsTotalTasks.tr();
  static String get completedTasks => LocaleKeys.statisticsCompletedTasks.tr();
  static String get pendingTasks => LocaleKeys.statisticsPendingTasks.tr();
  static String get overdueTasks => LocaleKeys.statisticsOverdueTasks.tr();
  static String get completionRate => LocaleKeys.statisticsCompletionRate.tr();

  // Экспорт/Импорт
  static String get exportData => LocaleKeys.dataExport.tr();
  static String get importData => LocaleKeys.dataImport.tr();
  static String get backupData => LocaleKeys.dataBackup.tr();
  static String get restoreData => LocaleKeys.dataRestore.tr();
  static String get selectFile => LocaleKeys.dataSelectFile.tr();
  static String get dataExported => LocaleKeys.dataExported.tr();
  static String get dataImported => LocaleKeys.dataImported.tr();

  // О приложении
  static String get version => LocaleKeys.aboutVersion.tr();
  static String get build => LocaleKeys.aboutBuild.tr();
  static String get developer => LocaleKeys.aboutDeveloper.tr();
  static String get privacyPolicy => LocaleKeys.aboutPrivacyPolicy.tr();
  static String get termsOfService => LocaleKeys.aboutTerms.tr();
  static String get support => LocaleKeys.aboutSupport.tr();
  static String get feedback => LocaleKeys.aboutFeedback.tr();

  // Получение названия приоритета
  static String getPriorityName(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriority;
      case 'medium':
        return mediumPriority;
      case 'high':
        return highPriority;
      case 'urgent':
        return urgentPriority;
      default:
        return mediumPriority;
    }
  }

  // Получение названия статуса
  static String getStatusName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'in_progress':
      case 'inprogress':
        return inProgress;
      case 'completed':
        return completed;
      case 'cancelled':
        return cancelled;
      default:
        return pending;
    }
  }

  // Получение названия тега
  static String getTagName(String tag) {
    switch (tag.toLowerCase()) {
      case 'planning':
        return planningTag;
      case 'materials':
        return materialsTag;
      case 'construction':
        return constructionTag;
      case 'finishing':
        return finishingTag;
      case 'inspection':
        return inspectionTag;
      case 'other':
        return otherTag;
      default:
        return otherTag;
    }
  }
}
