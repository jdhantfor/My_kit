enum ReminderStatus {
  none, // Статус не определен
  incomplete, // Напоминание не выполнено
  complete, // Напоминание выполнено
}

enum ReminderType {
  tablet, // Приём препарата
  measurement, // Измерение
  action, // Действие/привычка
}

enum DayStatus {
  none, // По умолчанию (чёрный, нет напоминаний)
  yellow, // Частичное выполнение (есть complete и incomplete)
  green, // Полное выполнение (все complete)
  red, // Ничего не выполнено (все incomplete)
}