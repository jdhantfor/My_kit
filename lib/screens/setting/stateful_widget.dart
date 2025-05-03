import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/styles.dart';
import 'package:my_aptechka/screens/database_service.dart';
import '/services/notification_service.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  final String userId; // Добавляем userId
  const NotificationsSettingsScreen({super.key, required this.userId});

  @override
  _NotificationsSettingsScreenState createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool allowPushNotifications = true;
  bool expirationNotifications = true;
  bool medicationReminders = true;
  bool vaccinationReminders = true;
  bool measurementReminders = true;
  bool thirdPartyNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Загружаем настройки при старте
  }

  // Загрузка настроек из базы данных
  Future<void> _loadSettings() async {
    final settings =
        await DatabaseService.getNotificationSettings(widget.userId);
    setState(() {
      allowPushNotifications = settings['allow_push_notifications'] as bool;
      expirationNotifications = settings['expiration_notifications'] as bool;
      medicationReminders = settings['medication_reminders'] as bool;
      vaccinationReminders = settings['vaccination_reminders'] as bool;
      measurementReminders = settings['measurement_reminders'] as bool;
      thirdPartyNotifications = settings['third_party_notifications'] as bool;
    });
  }

  // Сохранение настроек в базу данных
  Future<void> _saveSettings() async {
    await DatabaseService.updateNotificationSettings(widget.userId, {
      'allow_push_notifications': allowPushNotifications,
      'expiration_notifications': expirationNotifications,
      'medication_reminders': medicationReminders,
      'vaccination_reminders': vaccinationReminders,
      'measurement_reminders': measurementReminders,
      'third_party_notifications': thirdPartyNotifications,
    });
  }

  // Обработчик для "Разрешить push-уведомления"
  Future<void> _handlePushNotifications(bool value) async {
    setState(() {
      allowPushNotifications = value;
    });
    if (!value) {
      // Если выключаем push-уведомления, отменяем все уведомления
      await NotificationService.cancelAllNotifications();
    } else {
      // Если включаем, нужно заново запланировать уведомления
      print('Need to reschedule notifications');
    }
    await _saveSettings();
  }

  // Обработчик для остальных переключателей
  Future<void> _handleNotificationType(
      String type, bool value, Function(bool) updateState) async {
    updateState(value);
    if (!value) {
      // Отменяем уведомления этого типа
      await NotificationService.cancelNotificationsByType(type);
    } else {
      // Нужно запланировать уведомления этого типа
      print('Need to schedule notifications for type: $type');
    }
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Уведомления',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Первый пункт в отдельном контейнере
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16.0),
              child: _buildSettingItem(
                'Разрешить push-уведомления',
                value: allowPushNotifications,
                onChanged: _handlePushNotifications,
              ),
            ),
            const SizedBox(height: 16),
            // Остальные пункты в одном общем контейнере
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSettingItem(
                    'Истечение срока годности',
                    subtitle: 'напомним, когда препарат\nстанет непригодным',
                    value: expirationNotifications,
                    onChanged: allowPushNotifications
                        ? (value) => _handleNotificationType(
                            NotificationService.expirationType,
                            value,
                            (v) => setState(() => expirationNotifications = v))
                        : null,
                  ),
                  Divider(color: Colors.grey[300]),
                  _buildSettingItem(
                    'Напоминания о приемах\nпрепаратов',
                    value: medicationReminders,
                    onChanged: allowPushNotifications
                        ? (value) => _handleNotificationType(
                            NotificationService.medicationType,
                            value,
                            (v) => setState(() => medicationReminders = v))
                        : null,
                  ),
                  Divider(color: Colors.grey[300]),
                  _buildSettingItem(
                    'Напоминания о прививках',
                    value: vaccinationReminders,
                    onChanged: allowPushNotifications
                        ? (value) => _handleNotificationType(
                            NotificationService.vaccinationType,
                            value,
                            (v) => setState(() => vaccinationReminders = v))
                        : null,
                  ),
                  Divider(color: Colors.grey[300]),
                  _buildSettingItem(
                    'Напоминания об измерениях',
                    value: measurementReminders,
                    onChanged: allowPushNotifications
                        ? (value) => _handleNotificationType(
                            NotificationService.measurementType,
                            value,
                            (v) => setState(() => measurementReminders = v))
                        : null,
                  ),
                  Divider(color: Colors.grey[300]),
                  _buildSettingItem(
                    'Сторонние уведомления',
                    subtitle: 'акции и выгодные предложения',
                    value: thirdPartyNotifications,
                    onChanged: allowPushNotifications
                        ? (value) => _handleNotificationType(
                            NotificationService.thirdPartyType,
                            value,
                            (v) => setState(() => thirdPartyNotifications = v))
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title,
      {String? subtitle,
      required bool value,
      required Function(bool)? onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryGrey,
                ),
              ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (onChanged == null) {
              return AppColors.secondaryGrey;
            }
            return value ? AppColors.primaryBlue : AppColors.secondaryGrey;
          }),
        ),
      ],
    );
  }
}
