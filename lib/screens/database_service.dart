import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'database/reminder_service.dart'; // Импортируем новый файл
import 'package:my_aptechka/screens/models/reminder_status.dart';

class DatabaseService {
  static Database? _database;
  late ReminderService _reminderService;

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Инициализация базы данных
  static Future<void> initializeDatabase() async {
    final dbPath = await getDatabasesPath();
    final databasePath = path.join(dbPath, 'medecine_database.db');

    _database = await openDatabase(
      databasePath,
      onCreate: (db, version) async {
        await _createTables(db);
        await db.execute(
            'CREATE INDEX idx_reminder_statuses ON reminder_statuses(reminder_id, date)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id TEXT PRIMARY KEY,
              phone TEXT UNIQUE,
              is_logged_in INTEGER
            )
          ''');
          await db.execute(
              'ALTER TABLE medicines_table ADD COLUMN user_id TEXT REFERENCES users(id)');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN user_id TEXT REFERENCES users(id)');
          await db.execute(
              'ALTER TABLE courses_table ADD COLUMN user_id TEXT REFERENCES users(id)');
          await db.execute(
              'ALTER TABLE pulse_data ADD COLUMN user_id TEXT REFERENCES users(id)');
          await db.execute(
              'ALTER TABLE blood_pressure_data ADD COLUMN user_id TEXT REFERENCES users(id)');
          await db.execute(
              'ALTER TABLE steps_data ADD COLUMN user_id TEXT REFERENCES users(id)');
        }
        if (oldVersion < 3) {
          await db
              .execute('ALTER TABLE reminders_table ADD COLUMN endDate TEXT');
        }
        if (oldVersion < 7) {
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_reminder_statuses ON reminder_statuses(reminder_id, date)');
        }
        if (oldVersion < 8) {
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN schedule_type TEXT');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN interval_value INTEGER');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN interval_unit TEXT');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN cycle_duration INTEGER');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN cycle_break INTEGER');
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
        }
        if (oldVersion < 9) {
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN cycle_break_unit TEXT');
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS measurements_table(
              id INTEGER PRIMARY KEY,
              name TEXT,
              startDate TEXT,
              endDate TEXT,
              isLifelong INTEGER,
              courseid INTEGER REFERENCES courses_table(id),
              user_id TEXT REFERENCES users(id),
              mealTime TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS actions_table(
              id INTEGER PRIMARY KEY,
              name TEXT,
              startDate TEXT,
              endDate TEXT,
              isLifelong INTEGER,
              courseid INTEGER REFERENCES courses_table(id),
              user_id TEXT REFERENCES users(id),
              mealTime TEXT
            )
          ''');
        }
        if (oldVersion < 12) {
          await db
              .execute('ALTER TABLE measurements_table ADD COLUMN times TEXT');
        }
      },
      version: 12,
    );

    // Инициализируем ReminderService после создания базы данных
    _instance._reminderService = ReminderService(_database!);
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users(
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password TEXT,
      is_logged_in INTEGER
    )
  ''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS measurements_table(
  id INTEGER PRIMARY KEY,
  name TEXT,
  startDate TEXT,
  endDate TEXT,
  isLifelong INTEGER,
  courseid INTEGER DEFAULT -1,
  user_id TEXT REFERENCES users(id),
  mealTime TEXT,
  times TEXT
)
''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS actions_table(
        id INTEGER PRIMARY KEY,
        name TEXT,
        startDate TEXT,
        endDate TEXT,
        isLifelong INTEGER,
        courseid INTEGER REFERENCES courses_table(id),
        user_id TEXT REFERENCES users(id),
        mealTime TEXT,
        times TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicines_table(
        id INTEGER PRIMARY KEY, 
        name TEXT, 
        releaseForm TEXT, 
        quantityInPackage TEXT, 
        imagePath TEXT, 
        packageCount INTEGER, 
        user_id TEXT REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS courses_table(
        id INTEGER PRIMARY KEY, 
        name TEXT, 
        user_id TEXT REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS course_medicines(
        id INTEGER PRIMARY KEY,
        courseid INTEGER REFERENCES courses_table(id),
        medicine_id INTEGER REFERENCES medicines_table(id),
        dosage TEXT,
        unit TEXT,
        user_id TEXT REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders_table(
        id INTEGER PRIMARY KEY, 
        name TEXT,  
        time TEXT, 
        dosage TEXT, 
        unit TEXT, 
        selectTime TEXT, 
        startDate TEXT, 
        endDate TEXT,
        isLifelong INTEGER,
        schedule_type TEXT,
        interval_value INTEGER,
        interval_unit TEXT,
        selected_days_mask INTEGER,
        cycle_duration INTEGER,
        cycle_break INTEGER,
        cycle_break_unit TEXT,
        courseid INTEGER REFERENCES courses_table(id), 
        user_id TEXT REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_statuses(
        id INTEGER PRIMARY KEY,
        reminder_id INTEGER REFERENCES reminders_table(id),
        date TEXT,
        is_completed INTEGER,
        user_id TEXT REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pulse_data(
        id INTEGER PRIMARY KEY, 
        date TEXT, 
        value INTEGER, 
        user_id TEXT REFERENCES users(id),
        systolic INTEGER,
        diastolic INTEGER,
        comment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS blood_pressure_data(
        id INTEGER PRIMARY KEY, 
        date TEXT, 
        systolic INTEGER, 
        diastolic INTEGER, 
        user_id TEXT REFERENCES users(id),
        pulse INTEGER,
        comment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS steps_data(
        id INTEGER PRIMARY KEY, 
        date TEXT, 
        count INTEGER, 
        user_id TEXT REFERENCES users(id),
        comment TEXT
      )
    ''');
  }

  static Future<void> clearDatabase() async {
    final db = database;
    await db.delete('medicines_table');
    await db.delete('reminders_table');
    await db.delete('courses_table');
    await db.delete('course_medicines');
    await db.delete('pulse_data');
    await db.delete('blood_pressure_data');
    await db.delete('steps_data');
    await db.delete('users');
  }

  static Future<String> createUser(String email, String password) async {
    final db = database;
    final String userId = const Uuid().v4();
    await db.insert(
      'users',
      {'id': userId, 'email': email, 'password': password, 'is_logged_in': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return userId;
  }

  static Future<String?> getUserIdByEmail(String email) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['id'] as String : null;
  }

  static Future<String?> getUserIdByEmailAndPassword(
      String email, String password) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first['id'] as String : null;
  }

  static Future<bool> isLoggedIn(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty && result.first['is_logged_in'] == 1;
  }

  static Future<String?> getUserPhone(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      columns: ['phone'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['phone'] as String? : null;
  }

  static Future<void> logout(String userId) async {
    final db = database;
    await db.update(
      'users',
      {'is_logged_in': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<int> addCourse(
      Map<String, dynamic> course, String userId) async {
    final db = database;
    course['user_id'] = userId;
    return await db.insert(
      'courses_table',
      course,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCourses(String userId) async {
    final db = database;
    return await db
        .query('courses_table', where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<String> getCourseName(int courseId, String userId) async {
    final db = database;
    final result = await db.query(
      'courses_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [courseId, userId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['name'] as String;
    }
    return '';
  }

  static Future<void> addMedicine(
    String name,
    String? releaseForm,
    String? quantityInPackage,
    String? imagePath,
    int packageCount,
    String userId,
  ) async {
    final db = database;
    final Map<String, dynamic> medicineData = {
      'name': name,
      'releaseForm': releaseForm,
      'imagePath': imagePath,
      'packageCount': packageCount,
      'user_id': userId
    };

    if (quantityInPackage != null && quantityInPackage.isNotEmpty) {
      medicineData['quantityInPackage'] = quantityInPackage;
    }

    await db.insert(
      'medicines_table',
      medicineData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateMedicineQuantity(
      String userId, int id, int newPackageCount) async {
    final db = database;
    await db.update(
      'medicines_table',
      {'packageCount': newPackageCount},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<void> deleteMedicine(String userId, int id) async {
    final db = database;
    await db.delete(
      'medicines_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getMedicines(String userId) async {
    final db = database;
    return await db.query(
      'medicines_table',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Метод для конвертации дней недели в битовую маску
  static int daysToMask(List<String> days) {
    const dayMap = {
      'Пн': 1,
      'Вт': 2,
      'Ср': 4,
      'Чт': 8,
      'Пт': 16,
      'Сб': 32,
      'Вс': 64
    };
    return days.fold(0, (mask, day) => mask | (dayMap[day] ?? 0));
  }

  // Метод для конвертации битовой маски в дни недели
  // static List<String> maskToDays(int mask) {
  // const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  // return days.where((day, i) => (mask & (1 << i)) != 0).toList();
  //}

  static Future<List<Map<String, dynamic>>> getActions(String userId) async {
    final db = database;
    return await db
        .query('actions_table', where: 'user_id = ?', whereArgs: [userId]);
  }

  static Future<List<Map<String, dynamic>>> getRemindersByDate(
      String userId, DateTime date) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final reminders = await db.rawQuery('''
      SELECT r.*,
        CASE
          WHEN schedule_type = 'weekly' THEN
            (1 << (CAST(strftime('%w', ?) AS INTEGER) - 1)) & selected_days_mask != 0
          ELSE 1
        END as is_scheduled_day
      FROM reminders_table r
      WHERE r.user_id = ? 
        AND date(r.startDate) <= ? 
        AND (date(r.endDate) >= ? OR r.endDate IS NULL OR r.isLifelong = 1)
    ''', [dateString, userId, dateString, dateString]);

    return reminders.where((r) => r['is_scheduled_day'] == 1).toList();
  }

  static Future<void> updateReminderStatus(
      int reminderId, bool isCompleted, DateTime date) async {
    await updateReminderCompletionStatus(reminderId, isCompleted, date);

    // Получаем userId для этого напоминания
    final reminder = await database.query('reminders_table',
        where: 'id = ?', whereArgs: [reminderId], limit: 1);
    if (reminder.isNotEmpty) {
      final userId = reminder.first['user_id'] as String;

      // Обновляем статусы для этой даты
      final statuses = await getReminderStatusesForDates(userId, [date]);
      print('Updated reminder statuses: $statuses');
    }
  }

  static Future<Map<DateTime, bool?>> getReminderStatusesForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    final db = database;
    final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateString = DateFormat('yyyy-MM-dd').format(endDate);

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT date, is_completed
    FROM reminder_statuses
    WHERE user_id = ? AND date BETWEEN ? AND ?
  ''', [userId, startDateString, endDateString]);

    return Map.fromEntries(result.map((row) =>
        MapEntry(DateTime.parse(row['date']), row['is_completed'] == 1)));
  }

  static Future<void> updateAllRemindersCompletionStatus(
      String userId, DateTime date, bool isCompleted) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    await db.transaction((txn) async {
      await txn.update(
        'reminders_table',
        {'isCompleted': isCompleted ? 1 : 0},
        where: '''
        user_id = ? AND 
        (
          (date(startDate) <= ? AND (endDate IS NULL OR date(endDate) >= ?)) OR
          isLifelong = 1
        )
      ''',
        whereArgs: [userId, dateString, dateString],
      );

      final reminders = await txn.query(
        'reminders_table',
        where: '''
        user_id = ? AND 
        (
          (date(startDate) <= ? AND (endDate IS NULL OR date(endDate) >= ?)) OR
          isLifelong = 1
        )
      ''',
        whereArgs: [userId, dateString, dateString],
      );

      for (var reminder in reminders) {
        await txn.insert(
          'reminder_statuses',
          {
            'reminder_id': reminder['id'],
            'date': dateString,
            'is_completed': isCompleted ? 1 : 0,
            'user_id': userId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<String?> getUserIdByPhone(String phone) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['id'] as String : null;
  }

  static Future<void> updateUserLoginStatus(
      String userId, bool isLoggedIn) async {
    final db = database;
    await db.update(
      'users',
      {'is_logged_in': isLoggedIn ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getTreatmentCoursesWithReminders(
      String userId) async {
    final db = database;
    final courses = await db
        .query('courses_table', where: 'user_id = ?', whereArgs: [userId]);

    List<Map<String, dynamic>> coursesWithReminders = [];

    for (var course in courses) {
      final reminders = await db.query(
        'reminders_table',
        where: 'courseid = ? AND user_id = ?',
        whereArgs: [course['id'], userId],
      );

      coursesWithReminders.add({
        ...course,
        'reminders': reminders,
      });
    }

    print('Courses with reminders: $coursesWithReminders');
    return coursesWithReminders;
  }

  static Future<void> addPulseData(String date, int value, String userId,
      {int? systolic, int? diastolic, String? comment}) async {
    final db = database;
    await db.insert(
      'pulse_data',
      {
        'date': date,
        'value': value,
        'user_id': userId,
        'systolic': systolic,
        'diastolic': diastolic,
        'comment': comment,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPulseData(String userId) async {
    final db = database;
    return await db.query('pulse_data',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: 7);
  }

  static Future<void> addBloodPressureData(
      String date, int systolic, int diastolic, String userId,
      {int? pulse, String? comment}) async {
    final db = database;
    await db.insert(
      'blood_pressure_data',
      {
        'date': date,
        'systolic': systolic,
        'diastolic': diastolic,
        'user_id': userId,
        'pulse': pulse,
        'comment': comment,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getBloodPressureData(
      String userId) async {
    final db = database;
    return await db.query('blood_pressure_data',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: 7);
  }

  static Future<void> addStepsData(String date, int count, String userId,
      {String? comment}) async {
    final db = database;
    await db.insert(
      'steps_data',
      {
        'date': date,
        'count': count,
        'user_id': userId,
        'comment': comment,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getStepsData(String userId) async {
    final db = database;
    return await db.query('steps_data',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
        limit: 7);
  }

  static Future<Map<int, Map<DateTime, bool?>>> getReminderStatusesForDates(
      String userId, List<DateTime> dates) async {
    final db = database;
    final Map<int, Map<DateTime, bool?>> statuses = {}; // Изменили тип

    for (final date in dates) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      final List<Map<String, dynamic>> reminders = await db.rawQuery('''
    SELECT r.id as reminder_id, rs.is_completed 
    FROM reminders_table r
    LEFT JOIN reminder_statuses rs ON r.id = rs.reminder_id AND rs.date = ? AND rs.user_id = ?
    WHERE r.user_id = ? AND date(r.startDate) <= ? AND (date(r.endDate) >= ? OR r.endDate IS NULL)
    ''', [dateString, userId, userId, dateString, dateString]);

      for (var reminder in reminders) {
        int reminderId = reminder['reminder_id'] as int;
        bool? isCompleted = reminder['is_completed'] == null
            ? null
            : (reminder['is_completed'] == 1);

        if (!statuses.containsKey(reminderId)) {
          statuses[reminderId] = {};
        }

        statuses[reminderId]![date] = isCompleted;
      }
    }

    return statuses;
  }

  Map<String, List<Map<String, dynamic>>> groupRemindersByTime(
      List<Map<String, dynamic>> reminders) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var reminder in reminders) {
      if (reminder.containsKey('times')) {
        final times = reminder['times'] as List<dynamic>;
        for (var time in times) {
          if (!grouped.containsKey(time)) {
            grouped[time] = [];
          }
          grouped[time]!.add(reminder);
        }
      } else {
        String time = reminder['selectTime'] ?? 'Не указано';
        if (!grouped.containsKey(time)) {
          grouped[time] = [];
        }
        grouped[time]!.add(reminder);
      }
    }
    return grouped;
  }

  static Future<List<Map<String, dynamic>>> getAllReminderStatuses() async {
    final db = database;
    return await db.query('reminder_statuses');
  }

  static Database get database {
    if (_database != null) {
      return _database!;
    } else {
      throw Exception('Database is not initialized');
    }
  }

  static Future<ReminderStatus?> getReminderStatusForDate(
      int reminderId, DateTime date) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final result = await db.query(
      'reminder_statuses',
      where: 'reminder_id = ? AND date = ?',
      whereArgs: [reminderId, dateString],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final statusValue = result.first['is_completed'];
      return statusValue == 1
          ? ReminderStatus.complete
          : ReminderStatus.incomplete;
    } else {
      return null;
    }
  }

  // Прокси-методы для обратной совместимости
  static Future<int> addReminder(
          Map<String, dynamic> reminder, String userId) =>
      _instance._reminderService.addReminder(reminder, userId);

  static Future<List<Map<String, dynamic>>> getReminders(String userId) =>
      _instance._reminderService.getReminders(userId);

  static Future<void> updateReminder(
          Map<String, dynamic> reminder, String userId) =>
      _instance._reminderService.updateReminder(reminder, userId);

  static Future<void> deleteReminder(int id, String userId) =>
      _instance._reminderService.deleteReminder(id, userId);

  static Future<List<Map<String, dynamic>>> getRemindersByCourseId(
          int courseId, String userId) =>
      _instance._reminderService.getRemindersByCourseId(courseId, userId);

  static Future<void> updateReminderCompletionStatus(
          int reminderId, bool isCompleted, DateTime date) =>
      _instance._reminderService
          .updateReminderCompletionStatus(reminderId, isCompleted, date);

  static Future<int> addActionOrHabit(
          Map<String, dynamic> action, String userId) =>
      _instance._reminderService.addActionOrHabit(action, userId);

  static Future<void> updateAction(
          Map<String, dynamic> action, String userId) =>
      _instance._reminderService.updateAction(action, userId);

  static Future<void> updateActionStatus(int id, bool isCompleted) =>
      _instance._reminderService.updateActionStatus(id, isCompleted);

  static Future<List<Map<String, dynamic>>> getActionsByDate(
          String userId, DateTime date) =>
      _instance._reminderService.getActionsByDate(userId, date);

  static Future<int> addMeasurement(
      Map<String, dynamic> measurement, String userId) async {
    final Map<String, dynamic> measurementToInsert = {
      'name': measurement['name'],
      'isLifelong': measurement['isLifelong'] ? 1 : 0,
      'startDate': measurement['startDate'],
      'endDate': measurement['endDate'],
      'courseid': measurement['courseid'],
      'user_id': userId,
      'mealTime': measurement['mealTime'],
      'times':
          jsonEncode(measurement['times']), // Преобразуем список времен в JSON
    };

    // Используем _reminderService.db
    return await _instance._reminderService.db.insert(
      'measurements_table',
      measurementToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getMeasurements(String userId) =>
      _instance._reminderService.getMeasurements(userId);

  static Future<void> updateMeasurementStatus(int id, bool isCompleted) =>
      _instance._reminderService.updateMeasurementStatus(id, isCompleted);

  static Future<List<Map<String, dynamic>>> getMeasurementsByDate(
      String userId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final result = await DatabaseService.database.rawQuery('''
    SELECT * 
    FROM measurements_table 
    WHERE user_id = ? AND (
      (startDate <= ? AND (endDate >= ? OR endDate IS NULL)) OR
      isLifelong = 1
    )
  ''', [userId, dateString, dateString]);

    // Преобразуем JSON-строки обратно в списки
    for (var measurement in result) {
      if (measurement['times'] != null) {
        measurement['times'] = jsonDecode(measurement['times'] as String);
      } else {
        measurement['times'] = [];
      }
    }

    // Преобразуем данные в изменяемый формат
    return result.map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
