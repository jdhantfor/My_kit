import 'package:flutter/material.dart';

class ActionScheduleBox extends StatefulWidget {
  final Function() onNavigateToScheduleScreen;
  final String selectedMealTime;
  final Function(String) onMealTimeSelected;
  final String selectedNotification;
  final Function(String) onNotificationSelected;
  final String selectedScheduleType;

  const ActionScheduleBox({
    super.key,
    required this.onNavigateToScheduleScreen,
    required this.selectedMealTime,
    required this.onMealTimeSelected,
    required this.selectedNotification,
    required this.onNotificationSelected,
    required this.selectedScheduleType,
  });

  @override
  _ActionScheduleBoxState createState() => _ActionScheduleBoxState();
}

class _ActionScheduleBoxState extends State<ActionScheduleBox> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Выполнение',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'График выполнения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      InkWell(
                        onTap: widget.onNavigateToScheduleScreen,
                        child: Row(
                          children: [
                            Text(
                              widget.selectedScheduleType == 'daily'
                                  ? 'Ежедневно'
                                  : widget.selectedScheduleType == 'interval'
                                      ? 'С равными интервалами'
                                      : widget.selectedScheduleType == 'weekly'
                                          ? 'В определенные дни недели'
                                          : widget.selectedScheduleType ==
                                                  'cyclic'
                                              ? 'Циклично'
                                              : widget.selectedScheduleType ==
                                                      'single'
                                                  ? 'Однократное выполнение'
                                                  : 'Ежедневно',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF197FF2),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF197FF2),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'В какое время',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showMealTimePicker(context);
                        },
                        child: Row(
                          children: [
                            Text(
                              widget.selectedMealTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF197FF2),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF197FF2),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Уведомлять',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _showNotificationPicker(context);
                        },
                        child: Row(
                          children: [
                            Text(
                              widget.selectedNotification,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF197FF2),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF197FF2),
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMealTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              const Text(
                'Когда выполнять',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B102B),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMealTimeOption('До еды', () {
                        widget.onMealTimeSelected('До еды');
                        Navigator.of(context).pop();
                      }),
                      _buildMealTimeOption('Во время еды', () {
                        widget.onMealTimeSelected('Во время еды');
                        Navigator.of(context).pop();
                      }),
                      _buildMealTimeOption('После еды', () {
                        widget.onMealTimeSelected('После еды');
                        Navigator.of(context).pop();
                      }),
                      _buildMealTimeOption('Натощак перед сном', () {
                        widget.onMealTimeSelected('Натощак перед сном');
                        Navigator.of(context).pop();
                      }),
                      _buildMealTimeOption('В любое время дня', () {
                        widget.onMealTimeSelected('В любое время дня');
                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              const Text(
                'Уведомлять',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B102B),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNotificationOption('Не уведомлять', () {
                        widget.onNotificationSelected('Не уведомлять');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('В момент выполнения', () {
                        widget.onNotificationSelected('В момент выполнения');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 5 минут до выполнения', () {
                        widget
                            .onNotificationSelected('За 5 минут до выполнения');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 10 минут до выполнения', () {
                        widget.onNotificationSelected(
                            'За 10 минут до выполнения');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 15 минут до выполнения', () {
                        widget.onNotificationSelected(
                            'За 15 минут до выполнения');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 30 минут до выполнения', () {
                        widget.onNotificationSelected(
                            'За 30 минут до выполнения');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За час до выполнения', () {
                        widget.onNotificationSelected('За час до выполнения');
                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealTimeOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildNotificationOption(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
