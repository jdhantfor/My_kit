import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingItem(
              'Разрешить push-уведомления',
              value: allowPushNotifications,
              onChanged: (value) {
                setState(() {
                  allowPushNotifications = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              'Истечение срока годности',
              subtitle: 'напомним, когда препарат станет непригодным',
              value: expirationNotifications,
              onChanged: (value) {
                setState(() {
                  expirationNotifications = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              'Напоминания о приемах препаратов',
              value: medicationReminders,
              onChanged: (value) {
                setState(() {
                  medicationReminders = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              'Напоминания о прививках',
              value: vaccinationReminders,
              onChanged: (value) {
                setState(() {
                  vaccinationReminders = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              'Напоминания об измерениях',
              value: measurementReminders,
              onChanged: (value) {
                setState(() {
                  measurementReminders = value;
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSettingItem(
              'Сторонние уведомления',
              subtitle: 'акции и выгодные предложения',
              value: thirdPartyNotifications,
              onChanged: (value) {
                setState(() {
                  thirdPartyNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title,
      {String? subtitle,
      required bool value,
      required Function(bool) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
