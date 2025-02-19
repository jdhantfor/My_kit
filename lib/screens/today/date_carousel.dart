import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_status.dart';

class DateCarousel extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, ReminderStatus> reminderStatuses;

  const DateCarousel({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.reminderStatuses,
  }) : super(key: key);

  @override
  DateCarouselState createState() => DateCarouselState();
}

class DateCarouselState extends State<DateCarousel> {
  late ScrollController _scrollController;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToToday());

    final DateTime now = DateTime.now();
    final DateTime fifteenDaysAgo = now.subtract(const Duration(days: 15));
    _dates =
        List.generate(31, (index) => fifteenDaysAgo.add(Duration(days: index)));
  }

  void updateCarousel() {
    if (mounted) {
      setState(() {});
    }
  }

  void scrollToToday() {
    const itemWidth = 56.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final offset = (15 * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'DateCarousel build called. Reminder statuses: ${widget.reminderStatuses}');
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          return _buildCalendarDay(date, DateTime.now());
        },
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, DateTime today) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final reminderStatus =
        widget.reminderStatuses[dateKey] ?? ReminderStatus.none;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () => widget.onDateSelected(date),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE', 'ru').format(date),
              style: _getTextStyle(date, today, reminderStatus),
            ),
            const SizedBox(height: 4.0),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getBackgroundColor(date, today),
                shape: BoxShape.circle,
                border: date.year == today.year &&
                        date.month == today.month &&
                        date.day == today.day
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                DateFormat('d').format(date),
                style: _getTextStyle(date, today, reminderStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(DateTime date, DateTime today) {
    if (date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day) {
      return const Color(0xFF197FF2); // Выбранный день
    } else if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return Colors.white; // Сегодняшний день
    } else if (date.isBefore(today)) {
      return Colors.white; // Прошедшие дни
    } else {
      return const Color(0xFFE0E0E0); // Будущие дни
    }
  }

  TextStyle _getTextStyle(
      DateTime date, DateTime today, ReminderStatus? status) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    TextStyle style = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    if (isSelected) {
      style = style.copyWith(color: Colors.white);
    }

    if (status == ReminderStatus.incomplete) {
      style = style.copyWith(
          color: date.isBefore(today) ? Colors.red : Colors.amber);
    } else if (status == ReminderStatus.complete) {
      style = style.copyWith(color: Colors.green);
    }

    return style;
  }
}
