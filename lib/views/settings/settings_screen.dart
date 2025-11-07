import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../services/settings_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';

/// Экран настроек приложения
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.settingsTitle.tr())),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          return ListView(
            children: [
              // Секция: Внешний вид
              _buildSectionHeader(context, LocaleKeys.settingsAppearance.tr()),

              // Тема приложения
              ListTile(
                leading: Icon(
                  _getThemeIcon(settingsService.themeMode),
                  color: AppColors.primary,
                ),
                title: Text(LocaleKeys.settingsTheme.tr()),
                subtitle: Text(
                  _getThemeName(context, settingsService.themeMode),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showThemeDialog(context, settingsService),
              ),

              const Divider(height: 1),

              // Язык интерфейса
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.primary),
                title: Text(LocaleKeys.settingsLanguage.tr()),
                subtitle: Text(_getLanguageName(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context, settingsService),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Секция: О приложении
              _buildSectionHeader(context, LocaleKeys.settingsAbout.tr()),

              // Версия приложения
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: Text(LocaleKeys.aboutVersion.tr()),
                subtitle: const Text('1.0.0'),
              ),

              const Divider(height: 1),

              // Разработчик
              ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
                title: Text(LocaleKeys.aboutDeveloper.tr()),
                subtitle: const Text('Nibus Team'),
              ),

              const SizedBox(height: 24),

              // Секция: Дополнительно
              _buildSectionHeader(context, LocaleKeys.settingsOther.tr()),

              // Сброс настроек
              ListTile(
                leading: const Icon(Icons.restore, color: AppColors.warning),
                title: Text(LocaleKeys.settingsResetSettings.tr()),
                subtitle: Text(LocaleKeys.settingsResetDescription.tr()),
                onTap: () => _showResetDialog(context, settingsService),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Построение заголовка секции
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Получить иконку для темы
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Получить название темы
  String _getThemeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return LocaleKeys.settingsLightTheme.tr();
      case ThemeMode.dark:
        return LocaleKeys.settingsDarkTheme.tr();
      case ThemeMode.system:
        return LocaleKeys.settingsSystemTheme.tr();
    }
  }

  /// Получить название языка
  String _getLanguageName(BuildContext context) {
    final locale = context.locale;
    switch (locale.languageCode) {
      case 'ru':
        return LocaleKeys.settingsRussian.tr();
      case 'en':
        return LocaleKeys.settingsEnglish.tr();
      default:
        return LocaleKeys.settingsSystemLanguage.tr();
    }
  }

  /// Диалог выбора темы
  void _showThemeDialog(BuildContext context, SettingsService service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsChooseTheme.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              dialogContext,
              service,
              ThemeMode.system,
              Icons.brightness_auto,
              LocaleKeys.settingsSystemTheme.tr(),
            ),
            _buildThemeOption(
              context,
              dialogContext,
              service,
              ThemeMode.light,
              Icons.light_mode,
              LocaleKeys.settingsLightTheme.tr(),
            ),
            _buildThemeOption(
              context,
              dialogContext,
              service,
              ThemeMode.dark,
              Icons.dark_mode,
              LocaleKeys.settingsDarkTheme.tr(),
            ),
          ],
        ),
      ),
    );
  }

  /// Построение опции темы
  Widget _buildThemeOption(
    BuildContext context,
    BuildContext dialogContext,
    SettingsService service,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = service.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () async {
        await service.setThemeMode(mode);
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
        if (context.mounted) {
          Helpers.showSnackBar(
            context,
            LocaleKeys.settingsThemeChanged.tr(),
            backgroundColor: AppColors.success,
          );
        }
      },
    );
  }

  /// Диалог выбора языка
  void _showLanguageDialog(BuildContext context, SettingsService service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsChooseLanguage.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              dialogContext,
              service,
              'ru',
              '🇷🇺',
              LocaleKeys.settingsRussian.tr(),
            ),
            _buildLanguageOption(
              context,
              dialogContext,
              service,
              'en',
              '🇬🇧',
              LocaleKeys.settingsEnglish.tr(),
            ),
          ],
        ),
      ),
    );
  }

  /// Построение опции языка
  Widget _buildLanguageOption(
    BuildContext context,
    BuildContext dialogContext,
    SettingsService service,
    String languageCode,
    String flag,
    String label,
  ) {
    final isSelected = context.locale.languageCode == languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.grey,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () async {
        // Меняем язык
        await context.setLocale(Locale(languageCode));
        await service.setLanguage(languageCode);

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }

        if (context.mounted) {
          Helpers.showSnackBar(
            context,
            LocaleKeys.settingsLanguageChanged.tr(),
            backgroundColor: AppColors.success,
          );
        }
      },
    );
  }

  // Удалены функции тихих часов

  /// Диалог подтверждения сброса настроек
  void _showResetDialog(BuildContext context, SettingsService service) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsResetConfirmTitle.tr()),
        content: Text(LocaleKeys.settingsResetConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await service.resetSettings();

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              if (context.mounted) {
                // Сбрасываем язык на системный
                await context.resetLocale();

                if (context.mounted) {
                  Helpers.showSnackBar(
                    context,
                    LocaleKeys.settingsResetSuccess.tr(),
                    backgroundColor: AppColors.success,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(LocaleKeys.actionsConfirm.tr()),
          ),
        ],
      ),
    );
  }
}
