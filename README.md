#  Обновление 0.6.1 b
- Добавлен  path_provider: ^2.0.11 и file_picker: ^5.2.7 для корректного прикрепления файлов
- Исправлен запрос к памяти READ_EXTERNAL_STORAGE
WRITE_EXTERNAL_STORAGE
- Исправлено packageCount для сортировки таблеток в аптечке по убыванию
-  Параллелью начинаю чистить от заглушек код, и лишних старых кусков разработки, привожу порядок, исправлены мелкие добавленные для условности кнопки и триггеры в разделе здоровье и лечение
____________________________________________________________________
Обновление 0.5.6 beta
- изменен модуль камеры с google_ml_kit на простой mobile_scaner в связи с несовместимостью многих устройств
- Исправлено отображение измерений и напоминаний
- Добавлена привязка измерений и действий к курсу лекарств.
- Добавлено регистрирование по емейл и паролю. Логика пока закомменчина, нужен pop или smtp домен почты. Поставим когда получим домен.
- Исправлено визуальное отображение измерений и действий. убран чекбокс, добавлена стрелка для перехода к добавлению измерений.
- Страница здоровье, начал потихоньку включать модули, убраны лишние кнопки и демонстрационные заглушки, могут быть ошибки.
-Добавлен вызов списка лекарств без привязки к курсу, если лекарств без курса нет то кнопка сразу трегирит добавления нового лекарства. В измерениях и действиях добавили ту же логику.
- Мелкие изменения с user-provider из за смены метода регистрации. проверка базы теперь осуществляется через secure шифровку пароля.


# aptechka

"Моя Аптечка" – это удобное мобильное приложение, созданное для управления вашими лекарствами и заботы о здоровье. С его помощью вы сможете легко контролировать запасы медикаментов, отслеживать сроки годности, получать напоминания о приёме лекарств и заботиться о здоровье своих близких. Приложение также предлагает персонализированные рекомендации и помогает соблюдать курсы лечения, делая заботу о здоровье простой и эффективной. 

"Моя Аптечка" – ваш надежный помощник в поддержании здоровья и порядка в домашней аптечке.
