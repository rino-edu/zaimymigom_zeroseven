import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/security_service.dart';
import '../../services/settings_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/locale_keys.dart';
import '../../utils/helpers.dart';
import 'policy_screen.dart';

/// Экран настроек приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final SecurityService _securityService = SecurityService();

  bool _profileInitialized = false;
  bool _isSavingProfile = false;
  bool _isCheckingBiometric = false;
  String? _selectedDateIso;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileInitialized) {
      final settingsService = context.read<SettingsService>();
      _applyProfile(settingsService.userProfile);
      _profileInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.settingsTitle.tr())),
      body: Consumer<SettingsService>(
        builder: (context, settingsService, _) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
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

              // Секция: Безопасность
              _buildSectionHeader(context, LocaleKeys.settingsSecurity.tr()),

              SwitchListTile.adaptive(
                value: settingsService.hasPinCode,
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.lock, color: AppColors.primary),
                title: Text(LocaleKeys.securityPinCode.tr()),
                subtitle: Text(
                  settingsService.hasPinCode
                      ? LocaleKeys.securityChangePin.tr()
                      : LocaleKeys.settingsEnableSecurity.tr(),
                ),
                onChanged: (enabled) => _onPinCodeToggle(context, settingsService, enabled),
              ),

              const Divider(height: 1),

              SwitchListTile.adaptive(
                value: settingsService.biometricEnabled,
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.fingerprint, color: AppColors.primary),
                title: Text(LocaleKeys.securityBiometricAuth.tr()),
                subtitle: Text(
                  settingsService.biometricEnabled
                      ? LocaleKeys.settingsDisableSecurity.tr()
                      : LocaleKeys.settingsEnableSecurity.tr(),
                ),
                onChanged: _isCheckingBiometric
                    ? null
                    : (enabled) => _onBiometricToggle(context, settingsService, enabled),
              ),

              if (_isCheckingBiometric)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),

              const SizedBox(height: 24),

              // Секция: Личные данные
              _buildSectionHeader(context, LocaleKeys.settingsPersonalData.tr()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  LocaleKeys.settingsPersonalDataDescription.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildPersonalDataForm(context, settingsService),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => _showResetPersonalDataDialog(context, settingsService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(LocaleKeys.settingsResetPersonalData.tr()),
                  ),
                ),
              ),

              const SizedBox(height: 32),

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
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.primary,
                ),
                title: Text(LocaleKeys.aboutPrivacyPolicy.tr()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PolicyScreen()),
                  );
                },
              ),
              // Секция: Дополнительно
              _buildSectionHeader(context, LocaleKeys.settingsOther.tr()),

              // Сброс настроек
              ListTile(
                leading: const Icon(Icons.restore_page_outlined, color: Colors.red),
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

  void _applyProfile(UserProfile profile) {
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';

    final storedDate = _tryParseStoredDate(profile.dateOfBirth);
    if (storedDate != null) {
      _selectedDateIso = storedDate.toIso8601String();
      _dateController.text = _formatDateForDisplay(storedDate, context.locale);
    } else {
      _selectedDateIso = profile.dateOfBirth;
      _dateController.text = profile.dateOfBirth ?? '';
    }
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

  /// Построение формы личных данных
  Widget _buildPersonalDataForm(
    BuildContext context,
    SettingsService settingsService,
  ) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _firstNameController,
                context: context,
                label: LocaleKeys.settingsFirstName.tr(),
                hint: LocaleKeys.settingsEnterFirstName.tr(),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _lastNameController,
                context: context,
                label: LocaleKeys.settingsLastName.tr(),
                hint: LocaleKeys.settingsEnterLastName.tr(),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                context: context,
                label: LocaleKeys.settingsEmail.tr(),
                hint: LocaleKeys.settingsEnterEmail.tr(),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final email = value.trim();
                  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                  if (!emailRegex.hasMatch(email)) {
                    return LocaleKeys.validationInvalidEmail.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                context: context,
                label: LocaleKeys.settingsPhone.tr(),
                hint: LocaleKeys.settingsEnterPhone.tr(),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.settingsDateOfBirth.tr(),
                  hintText: LocaleKeys.settingsEnterDateOfBirth.tr(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _pickDateOfBirth(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSavingProfile
                    ? null
                    : () => _savePersonalData(context, settingsService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSavingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(LocaleKeys.settingsSavePersonalData.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required BuildContext context,
    String? label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
    );
  }

  Future<void> _pickDateOfBirth(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final initialDate = _tryParseStoredDate(_selectedDateIso) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: context.locale,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateIso = pickedDate.toIso8601String();
        _dateController.text = _formatDateForDisplay(pickedDate, context.locale);
      });
    }
  }

  Future<void> _savePersonalData(
    BuildContext context,
    SettingsService settingsService,
  ) async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSavingProfile = true);

    final profile = UserProfile(
      firstName: _firstNameController.text.trim().isEmpty
          ? null
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      dateOfBirth: _selectedDateIso,
    );

    await settingsService.saveUserProfile(profile);

    if (mounted) {
      setState(() => _isSavingProfile = false);
      Helpers.showSnackBar(
        context,
        LocaleKeys.settingsPersonalDataSaved.tr(),
        backgroundColor: AppColors.success,
      );
    }
  }

  Future<void> _onPinCodeToggle(
    BuildContext context,
    SettingsService settingsService,
    bool enabled,
  ) async {
    if (enabled) {
      final newPin = await _showSetPinDialog(context);
      if (newPin == null || newPin.isEmpty) {
        if (mounted) setState(() {});
        return;
      }
      await settingsService.setPinCode(newPin);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          LocaleKeys.settingsPinCodeSet.tr(),
          backgroundColor: AppColors.success,
        );
      }
    } else {
      final confirmed = await _showRemovePinDialog(context);
      if (confirmed != true) {
        if (mounted) setState(() {});
        return;
      }
      await settingsService.setPinCode(null);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          LocaleKeys.settingsPinCodeRemoved.tr(),
          backgroundColor: AppColors.success,
        );
      }
    }
  }

  Future<void> _onBiometricToggle(
    BuildContext context,
    SettingsService settingsService,
    bool enabled,
  ) async {
    if (enabled) {
      if (!settingsService.hasPinCode) {
        Helpers.showSnackBar(
          context,
          LocaleKeys.settingsEnableBiometricFirst.tr(),
          backgroundColor: AppColors.warning,
        );
        return;
      }

      setState(() => _isCheckingBiometric = true);

      final isAvailable = await _securityService.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isCheckingBiometric = false);
          Helpers.showSnackBar(
            context,
            LocaleKeys.settingsBiometricNotAvailable.tr(),
            backgroundColor: AppColors.warning,
          );
        }
        return;
      }

      final authenticated = await _securityService.authenticate(
        localizedReason: LocaleKeys.securityBiometricAuth.tr(),
      );

      if (!authenticated) {
        if (mounted) {
          setState(() => _isCheckingBiometric = false);
        }
        return;
      }

      await settingsService.setBiometricEnabled(true);

      if (mounted) {
        setState(() => _isCheckingBiometric = false);
        Helpers.showSnackBar(
          context,
          LocaleKeys.settingsEnableSecurity.tr(),
          backgroundColor: AppColors.success,
        );
      }
    } else {
      await settingsService.setBiometricEnabled(false);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          LocaleKeys.settingsDisableSecurity.tr(),
          backgroundColor: AppColors.success,
        );
      }
    }
  }

  Future<String?> _showSetPinDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _SetPinDialog(),
    );
  }

  Future<bool?> _showRemovePinDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(LocaleKeys.settingsRemovePinCode.tr()),
          content: Text(LocaleKeys.settingsDisableSecurity.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(LocaleKeys.actionsCancel.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: Text(LocaleKeys.actionsConfirm.tr()),
            ),
          ],
        );
      },
    );
  }

  String _formatDateForDisplay(DateTime date, Locale locale) {
    final localeTag = _localeTag(locale);
    try {
      return DateFormat.yMMMd(localeTag).format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  DateTime? _tryParseStoredDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return iso;
    }

    final formats = [
      DateFormat('dd.MM.yyyy'),
      DateFormat('yyyy-MM-dd'),
    ];

    for (final format in formats) {
      try {
        return format.parseStrict(raw);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _localeTag(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }

  void _clearPersonalControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _dateController.clear();
    _selectedDateIso = null;
  }

  void _showResetPersonalDataDialog(
    BuildContext context,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsResetPersonalConfirmTitle.tr()),
        content: Text(LocaleKeys.settingsResetPersonalConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await settingsService.saveUserProfile(UserProfile());
              if (mounted) {
                _clearPersonalControllers();
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (context.mounted) {
                Helpers.showSnackBar(
                  context,
                  LocaleKeys.settingsResetPersonalSuccess.tr(),
                  backgroundColor: AppColors.success,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(LocaleKeys.actionsConfirm.tr()),
          ),
        ],
      ),
    );
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

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.settingsSetPinCode.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: LocaleKeys.settingsEnterPinCode.tr(),
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.length != 4) {
                    return LocaleKeys.settingsPinCodeMustBe4Digits.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: LocaleKeys.settingsConfirmPinCode.tr(),
                  counterText: '',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.length != 4) {
                    return LocaleKeys.settingsPinCodeMustBe4Digits.tr();
                  }
                  if (value != _pinController.text) {
                    return LocaleKeys.settingsPinCodesNotMatch.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.actionsCancel.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _pinController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: Text(LocaleKeys.actionsConfirm.tr()),
        ),
      ],
    );
  }
}
