import 'package:flutter/material.dart';

// Класс для глобальных цветов
class AppColors {
  static const Color primaryBlue = Color(0xFF197FF2); // rgba(25, 127, 242, 1)
  static const Color secondaryGrey =
      Color(0xFF818499); // rgba(129, 132, 153, 1) для текста
  static const Color fieldBackground =
      Color(0x1A818499); // rgba(129, 132, 153, 0.1) для фона полей
  static const Color activeFieldBlue =
      Color(0x14197FF2); // rgba(25, 127, 242, 0.08)
  static const Color errorFieldRed = Color(0x1AFF6065); // rgba(255, 96, 101, 0.1)

  static const Color primaryText = Color(0xFF0B102B);
  static const Color errorRed = Color(0xFFE54045); // Цвет текста ошибки
}

// Класс для стилей TextField
class AppTextFieldStyles {
  // Отступы для TextField
  static const EdgeInsets textFieldPadding = EdgeInsets.only(top: 21, bottom: 19, left: 16, right: 16   // Отступы сверху и снизу
  );

  // Основной стиль для TextField
  static InputDecoration defaultTextFieldDecoration(
    BuildContext context, {
    String? hintText,
    bool hasError = false,
    bool isFocused = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryGrey,
          ),
      filled: true,
      fillColor: hasError
          ? AppColors.errorFieldRed
          : isFocused
              ? AppColors.activeFieldBlue
              : AppColors.fieldBackground,
      contentPadding: textFieldPadding, // Отступы определяют высоту
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Стиль для текста внутри TextField
  static TextStyle textFieldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: AppColors.primaryText,
        );
  }

  // Стиль для текста ошибки
  static TextStyle errorTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
          color: AppColors.errorRed,
        );
  }
}

// Глобальная тема приложения
class AppTheme {
  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 247, 247, 247),
        fontFamily: 'Commissioner',
        textTheme: const TextTheme(
          // title 24
          displayLarge: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w600, // semibold
            fontSize: 24,
            height: 28 / 24, // 28/24
            color: Color(0xFF0B102B),
          ),
          // title 20
          displayMedium: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w600, // semibold
            fontSize: 20,
            height: 24 / 20, // 24/20
            color: Color(0xFF0B102B),
          ),
          // body 16
          bodyLarge: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w600, // semibold
            fontSize: 16,
            height: 22 / 16, // 22/16
            color: Color(0xFF0B102B),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w500, // medium
            fontSize: 16,
            height: 22 / 16, // 22/16
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          bodySmall: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w400, // regular
            fontSize: 16,
            height: 22 / 16, // 22/16
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          // footnote 13
          labelLarge: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w600, // semibold
            fontSize: 13,
            height: 16 / 13, // 16/13
            color: Color(0xFF0B102B),
          ),
          labelMedium: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w500, // medium
            fontSize: 13,
            height: 16 / 13, // 16/13
            color: Color(0xFF0B102B),
          ),
          labelSmall: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w400, // regular
            fontSize: 13,
            height: 16 / 13, // 16/13
            color: Color(0xFF0B102B),
          ),
          // caption 12
          titleSmall: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w400, // regular
            fontSize: 12,
            height: 16 / 12, // 16/12
            color: Color(0xFF0B102B),
          ),
          titleMedium: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w500, // medium
            fontSize: 12,
            height: 16 / 12, // 16/12
            color: Color(0xFF0B102B),
          ),
        ),
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 247, 247, 247),
          elevation: 0, // Убрали тень
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.w600, // semibold
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        // Стили для кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0, // Убрали тень
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Commissioner',
              fontWeight: FontWeight.w600, // semibold
              fontSize: 16,
            ),
            minimumSize: const Size(double.infinity, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            textStyle: const TextStyle(
              fontFamily: 'Commissioner',
              fontWeight: FontWeight.w600, // semibold
              fontSize: 16,
            ),
          ),
        ),
        // Стили для TextField (глобальные, если нужно)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
        ),
      );
}