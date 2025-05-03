import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_status.dart';
import '/styles.dart'; // Импортируем AppColors

class DateCarousel extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, DayStatus> reminderStatuses;

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
    return SizedBox(
      height: 90,
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
    final dayStatus = widget.reminderStatuses[dateKey];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () => widget.onDateSelected(date),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE', 'ru').format(
                  date), 
              style: _getDayNameStyle(date, today, dayStatus),
            ),
            const SizedBox(height: 8.0), 
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getBackgroundColor(date, today),
                shape: BoxShape.circle,
                border: _getBorder(date, today),
              ),
              alignment: Alignment.center,
              child: Text(
                DateFormat('d').format(date).padLeft(2, '0'),
                style: _getNumberStyle(date, today, dayStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getDayNameStyle(DateTime date, DateTime today, DayStatus? status) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    // Базовый стиль для названия дня недели: Commissioner W400, 12, height: 1
    TextStyle style = const TextStyle(
      fontFamily: 'Commissioner',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12, 
      color: Color(0xFF6B7280), // Серый по умолчанию
    );

    // Если это сегодня, цвет чёрный
    if (isToday) {
      style = style.copyWith(color: const Color(0xFF0B102B));
    }

    // Если дата выбрана, цвет названия дня совпадает с фоном (синий) или статусом
    if (isSelected) {
      if (status != null) {
        switch (status) {
          case DayStatus.green:
            style = style.copyWith(color: Colors.green);
            break;
          case DayStatus.yellow:
            style = style.copyWith(color: Colors.yellow);
            break;
          case DayStatus.red:
            style = style.copyWith(color: Colors.red);
            break;
          case DayStatus.none:
            style =
                style.copyWith(color: AppColors.primaryBlue); 
            break;
        }
      } else {
        style = style.copyWith(color: AppColors.primaryBlue);
      }
    } else if (status != null) {
      // Если дата не выбрана, но есть статус, меняем цвет названия дня
      switch (status) {
        case DayStatus.green:
          style = style.copyWith(color: Colors.green);
          break;
        case DayStatus.yellow:
          style = style.copyWith(color: Colors.yellow);
          break;
        case DayStatus.red:
          style = style.copyWith(color: Colors.red);
          break;
        case DayStatus.none:
          break;
      }
    }

    return style;
  }

  TextStyle _getNumberStyle(DateTime date, DateTime today, DayStatus? status) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    // Базовый стиль для цифры: Commissioner W500, 14, height: 18/14
    TextStyle style = const TextStyle(
      fontFamily: 'Commissioner',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 18 / 14, 
      color: Color(0xFF6B7280), 
    );

    // Если это сегодня, цвет чёрный
    if (isToday) {
      style = style.copyWith(color: const Color(0xFF0B102B));
    }

    // Если дата выбрана, цвет зависит от статуса или белый
    if (isSelected) {
      if (status != null) {
        switch (status) {
          case DayStatus.green:
            style = style.copyWith(color: Colors.green);
            break;
          case DayStatus.yellow:
            style = style.copyWith(color: Colors.yellow);
            break;
          case DayStatus.red:
            style = style.copyWith(color: Colors.red);
            break;
          case DayStatus.none:
            style = style.copyWith(color: Colors.white);
            break;
        }
      } else {
        style = style.copyWith(color: Colors.white);
      }
    } else if (status != null) {
      // Если дата не выбрана, но есть статус, меняем цвет цифры
      switch (status) {
        case DayStatus.green:
          style = style.copyWith(color: Colors.green);
          break;
        case DayStatus.yellow:
          style = style.copyWith(color: Colors.yellow);
          break;
        case DayStatus.red:
          style = style.copyWith(color: Colors.red);
          break;
        case DayStatus.none:
          break;
      }
    }

    return style;
  }

  Color _getBackgroundColor(DateTime date, DateTime today) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    if (isSelected) {
      return AppColors.primaryBlue; // Синий для выбранной даты
    } else if (isToday) {
      return const Color(0xFFE0E0E0); // Серый для сегодняшнего дня
    } else if (date.isBefore(today)) {
      return Colors.white; // Белый для прошлых дней
    } else {
      return const Color(0xFFE0E0E0); // Серый для будущих дней
    }
  }

  Border? _getBorder(DateTime date, DateTime today) {
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isSelected = date.year == widget.selectedDate.year &&
        date.month == widget.selectedDate.month &&
        date.day == widget.selectedDate.day;

    if (isSelected) {
      return Border.all(
          color: AppColors.primaryBlue,
          width: 2); // Синяя каёмка для выбранной даты
    } else if (isToday) {
      return Border.all(
          color: Colors.white, width: 2); // Белая каёмка для сегодняшнего дня
    }
    return null; // Без каёмки для остальных дней
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
