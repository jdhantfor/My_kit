import 'package:flutter/material.dart';
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ScheduleBox extends StatefulWidget {
  final Function() onNavigateToScheduleScreen;
  final String selectedMealTime;
  final Function(String) onMealTimeSelected;
  final String selectedNotification;
  final Function(String) onNotificationSelected;
  final String selectedScheduleType;

  const ScheduleBox({
    super.key,
    required this.onNavigateToScheduleScreen,
    required this.selectedMealTime,
    required this.onMealTimeSelected,
    required this.selectedNotification,
    required this.onNotificationSelected,
    required this.selectedScheduleType,
  });

  @override
  _ScheduleBoxState createState() => _ScheduleBoxState();
}

class _ScheduleBoxState extends State<ScheduleBox> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'Прием',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryGrey,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 16, bottom: 8, left: 4, right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'График приёма',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryText,
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
                                        : widget.selectedScheduleType ==
                                                'weekly'
                                            ? 'В определенные дни недели'
                                            : widget.selectedScheduleType ==
                                                    'cyclic'
                                                ? 'Циклично'
                                                : widget.selectedScheduleType ==
                                                        'single'
                                                    ? 'Однократный прием'
                                                    : 'Ежедневно',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/arrow_forward_blue.svg',
                                width: 20,
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 16, right: 16),
                    child: Divider(
                      color: AppColors.fieldBackground,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'В какое время',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryText,
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
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/arrow_forward_blue.svg',
                                width: 20,
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: AppColors.fieldBackground,
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Уведомлять',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryText,
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
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/arrow_forward_blue.svg',
                                width: 20,
                                height: 20,
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
      ),
    );
  }

  void _showMealTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Когда принимать',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Уведомлять',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNotificationOption('Не уведомлять', () {
                        widget.onNotificationSelected('Не уведомлять');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('В момент приёма', () {
                        widget.onNotificationSelected('В момент приёма');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 5 минут до приёма', () {
                        widget.onNotificationSelected('За 5 минут до приёма');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 10 минут до приёма', () {
                        widget.onNotificationSelected('За 10 минут до приёма');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 15 минут до приёма', () {
                        widget.onNotificationSelected('За 15 минут до приёма');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За 30 минут до приёма', () {
                        widget.onNotificationSelected('За 30 минут до приёма');
                        Navigator.of(context).pop();
                      }),
                      _buildNotificationOption('За час до приёма', () {
                        widget.onNotificationSelected('За час до приёма');
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
      ),
      trailing: SvgPicture.asset(
        'assets/arrow_forward_blue.svg',
        width: 20,
        height: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildNotificationOption(String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
        ),
      ),
      trailing: SvgPicture.asset(
        'assets/arrow_forward_blue.svg',
        width: 20,
        height: 20,
      ),
      onTap: onTap,
    );
  }
}
