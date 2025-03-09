import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:my_aptechka/screens/models/reminder_status.dart';
import 'package:my_aptechka/services/notification_service.dart';

class DatabaseService {
  static Database? _database;

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
        time TEXT,
        selectTime TEXT
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
        if (oldVersion < 13) {
          await db.execute('ALTER TABLE users ADD COLUMN name TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN surname TEXT');
        }
        if (oldVersion < 14) {
          await db.execute(
              'ALTER TABLE measurements_table ADD COLUMN selectTime TEXT');
        }
        if (oldVersion < 15) {
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN type TEXT DEFAULT "tablet"');
        }
        if (oldVersion < 16) {
          await db.execute(
              'ALTER TABLE reminders_table ADD COLUMN isCompleted INTEGER');
        }
        if (oldVersion < 17) {
          await db
              .execute('ALTER TABLE actions_table ADD COLUMN quantity TEXT');
          await db.execute(
              'ALTER TABLE actions_table ADD COLUMN scheduleType TEXT');
          await db.execute(
              'ALTER TABLE actions_table ADD COLUMN notification TEXT');
          await db.execute(
              'ALTER TABLE actions_table ADD COLUMN isCompleted INTEGER');
        }
        if (oldVersion < 18) {
          await db.execute(
              'ALTER TABLE actions_table RENAME COLUMN scheduleType TO schedule_type');
        }
        if (oldVersion < 19) {
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN interval_value INTEGER');
          } catch (e) {
            print('Column interval_value already exists in actions_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN interval_unit TEXT');
          } catch (e) {
            print('Column interval_unit already exists in actions_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
          } catch (e) {
            print(
                'Column selected_days_mask already exists in actions_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN cycle_duration INTEGER');
          } catch (e) {
            print('Column cycle_duration already exists in actions_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN cycle_break INTEGER');
          } catch (e) {
            print('Column cycle_break already exists in actions_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE actions_table ADD COLUMN cycle_break_unit TEXT');
          } catch (e) {
            print(
                'Column cycle_break_unit already exists in actions_table: $e');
          }
          // Добавляем недостающие столбцы в measurements_table
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN schedule_type TEXT');
          } catch (e) {
            print(
                'Column schedule_type already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN interval_value INTEGER');
          } catch (e) {
            print(
                'Column interval_value already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN interval_unit TEXT');
          } catch (e) {
            print(
                'Column interval_unit already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
          } catch (e) {
            print(
                'Column selected_days_mask already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN cycle_duration INTEGER');
          } catch (e) {
            print(
                'Column cycle_duration already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN cycle_break INTEGER');
          } catch (e) {
            print(
                'Column cycle_break already exists in measurements_table: $e');
          }
          try {
            await db.execute(
                'ALTER TABLE measurements_table ADD COLUMN cycle_break_unit TEXT');
          } catch (e) {
            print(
                'Column cycle_break_unit already exists in measurements_table: $e');
          }
        }
      },
      version: 19,
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users(
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password TEXT,
      is_logged_in INTEGER,
      name TEXT,
      surname TEXT
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS measurements_table(
      id INTEGER PRIMARY KEY,
      name TEXT,
      startDate TEXT,
      endDate TEXT,
      isLifelong INTEGER,
      courseid INTEGER REFERENCES courses_table(id),
      user_id TEXT REFERENCES users(id),
      time TEXT,
      selectTime TEXT,
      type TEXT DEFAULT 'measurments',
      schedule_type TEXT,
      interval_value INTEGER,
      interval_unit TEXT,
      selected_days_mask INTEGER DEFAULT 0,
      cycle_duration INTEGER,
      cycle_break INTEGER,
      cycle_break_unit TEXT
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
      type TEXT DEFAULT 'action',
      selectTime TEXT,
      quantity TEXT,
      schedule_type TEXT,
      interval_value INTEGER,
      interval_unit TEXT,
      selected_days_mask INTEGER DEFAULT 0,
      cycle_duration INTEGER,
      cycle_break INTEGER,
      cycle_break_unit TEXT,
      notification TEXT,
      isCompleted INTEGER
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
      type TEXT DEFAULT 'tablet',
      isCompleted INTEGER,
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

  static Future<void> updateUserDetails(String userId,
      {String? name,
      String? surname,
      String? phone,
      String? email,
      String? password}) async {
    final db = database;
    final Map<String, dynamic> updates = {};

    if (name != null) updates['name'] = name;
    if (surname != null) updates['surname'] = surname;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (password != null) updates['password'] = password;

    await db.update(
      'users',
      updates,
      where: 'id = ?',
      whereArgs: [userId],
    );
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

  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
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

  Future<List<Map<String, dynamic>>> getRemindersByDate(
      String userId, DateTime date) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final reminders = await db.rawQuery('''
      SELECT r.*,
        CASE
          WHEN schedule_type = 'interval' THEN
            (CAST((julianday(?) - julianday(r.startDate)) AS INTEGER) % r.interval_value = 0)
          WHEN schedule_type = 'weekly' THEN
            (1 << (CAST(strftime('%w', ?) AS INTEGER) - 1)) & r.selected_days_mask != 0
          WHEN schedule_type = 'cyclic' THEN
            (CAST((julianday(?) - julianday(r.startDate)) AS INTEGER) % (r.cycle_duration + r.cycle_break) < r.cycle_duration)
          WHEN schedule_type = 'single' THEN
            -- Проверяем, совпадает ли текущая дата с startDate
            date(?) = date(r.startDate)
          ELSE 1
        END as is_scheduled_day
      FROM reminders_table r
      WHERE r.user_id = ? 
        AND date(r.startDate) <= ? 
        AND (date(r.endDate) >= ? OR r.endDate IS NULL OR r.isLifelong = 1)
  ''', [
      dateString,
      dateString,
      dateString,
      dateString,
      userId,
      dateString,
      dateString
    ]);

    return reminders.where((r) => r['is_scheduled_day'] == 1).toList();
  }

  Future<void> updateReminderStatus(
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

  Future<void> updateAllRemindersCompletionStatus(
      String userId, DateTime date, bool isCompleted) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final reminders = await db.query(
      'reminders_table',
      where:
          'user_id = ? AND type IN ("tablet", "action") AND date(startDate) <= ? AND (date(endDate) >= ? OR isLifelong = 1)',
      whereArgs: [userId, dateString, dateString],
    );

    print('Found ${reminders.length} reminders to update for $dateString');

    for (var reminder in reminders) {
      await db.insert(
        'reminder_statuses',
        {
          'reminder_id': reminder['id'],
          'date': dateString,
          'is_completed': isCompleted ? 1 : 0,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Updated status for reminder ${reminder['id']} to $isCompleted');
    }
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

  Future<Map<int, Map<DateTime, ReminderStatus>>> getReminderStatusesForDates(
      String userId, List<DateTime> dates) async {
    final db = database;
    final Map<int, Map<DateTime, ReminderStatus>> statuses = {};

    for (final date in dates) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final List<Map<String, dynamic>> reminders = await db.rawQuery('''
      SELECT r.id as reminder_id, rs.is_completed 
      FROM reminders_table r
      LEFT JOIN reminder_statuses rs ON r.id = rs.reminder_id AND rs.date = ? AND rs.user_id = ?
      WHERE r.user_id = ? AND date(r.startDate) <= ? AND (date(r.endDate) >= ? OR r.endDate IS NULL)
    ''', [dateString, userId, userId, dateString, dateString]);

      print('Raw statuses for $dateString: $reminders');

      for (var reminder in reminders) {
        int reminderId = reminder['reminder_id'] as int;
        ReminderStatus status = reminder['is_completed'] == null
            ? ReminderStatus.none
            : (reminder['is_completed'] == 1
                ? ReminderStatus.complete
                : ReminderStatus.incomplete);

        if (!statuses.containsKey(reminderId)) {
          statuses[reminderId] = {};
        }
        statuses[reminderId]![date] = status;
      }
    }

    print('Processed statuses: $statuses');
    return statuses;
  }

  Map<String, List<Map<String, dynamic>>> groupRemindersByTime(
      List<Map<String, dynamic>> reminders) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var reminder in reminders) {
      String time = reminder['time'] ?? reminder['selectTime'] ?? 'Не указано';
      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }
      grouped[time]!.add(reminder);
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

  static Future<void> addMeasurement(
      Map<String, dynamic> measurement, String userId) async {
    final Map<String, dynamic> measurementToInsert = {
      'name': measurement['name'],
      'time': measurement['time'],
      'selectTime': measurement['selectTime'],
      'startDate': measurement['startDate'],
      'endDate': measurement['endDate'],
      'isLifelong': measurement['isLifelong'] == 1 ? true : false,
      'courseid': measurement['courseid'],
      'user_id': userId,
    };

    await _database!.insert(
      'measurements_table',
      measurementToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMeasurementsByDate(
      String userId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final result = await _database!.rawQuery('''
      SELECT * 
      FROM measurements_table 
      WHERE user_id = ? AND (
        (startDate = ? OR (endDate IS NULL AND isLifelong = 1)) OR
        (endDate IS NOT NULL AND isLifelong = 0 AND endDate >= ?)
      )
    ''', [userId, dateString, dateString]);

    // Создаем новый список с изменяемыми картами
    final modifiedResult = result.map((item) {
      final newItem = Map<String, dynamic>.from(item); // Создаем копию карты
      newItem['isLifelong'] =
          newItem['isLifelong'] == 1; // Преобразуем int в bool
      return newItem;
    }).toList();

    return modifiedResult;
  }

  // Методы для работы с напоминаниями (reminders)
  Future<int> addReminder(Map<String, dynamic> reminder, String userId) async {
    final db = database;
    final Map<String, dynamic> reminderToInsert = {
      'name': reminder['name'],
      'time': reminder['time'],
      'dosage': reminder['dosage'],
      'unit': reminder['unit'],
      'selectTime': reminder['selectTime'],
      'startDate': reminder['startDate'],
      'endDate': reminder['endDate'],
      'isLifelong': reminder['isLifelong'],
      'schedule_type': reminder['schedule_type'],
      'interval_value': reminder['interval_value'],
      'interval_unit': reminder['interval_unit'],
      'selected_days_mask': reminder['selected_days_mask'],
      'cycle_duration': reminder['cycle_duration'],
      'cycle_break': reminder['cycle_break'],
      'cycle_break_unit': reminder['cycle_break_unit'] ?? 'дней',
      'type': reminder['type'] ?? 'tablet',
      'courseid': reminder['courseid'],
      'user_id': userId,
    };

    reminderToInsert
        .removeWhere((key, value) => key != 'courseid' && value == null);

    final insertedReminderId = await db.insert(
      'reminders_table',
      reminderToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Планирование уведомления
    if (reminder['selectTime'] != null && reminder['startDate'] != null) {
      final timeParts = reminder['selectTime'].toString().split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final scheduledDate = DateTime(
        DateTime.parse(reminder['startDate']).year,
        DateTime.parse(reminder['startDate']).month,
        DateTime.parse(reminder['startDate']).day,
        hour,
        minute,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: insertedReminderId,
          title: 'Напоминание',
          body: 'Пришло время принять ${reminder['name']}!',
          scheduledDate: scheduledDate,
        );
      } else {
        print(
            'Scheduled date is in the past: ${scheduledDate.toIso8601String()}');
      }
    }

    return insertedReminderId;
  }

  Future<List<Map<String, dynamic>>> getReminders(String userId) async {
    final db = database;
    return await db
        .query('reminders_table', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> updateReminder(
      Map<String, dynamic> reminder, String userId) async {
    final db = database;
    await db.update(
      'reminders_table',
      {...reminder, 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminder['id'], userId],
    );
  }

  Future<void> deleteReminder(int id, String userId) async {
    final db = database;
    await db.delete(
      'reminders_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getRemindersByCourseId(
      int courseId, String userId) async {
    final db = database;
    return await db.query(
      'reminders_table',
      where: 'courseid = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
  }

  Future<ReminderStatus?> getReminderStatusForDate(
      int reminderId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final db = database;
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

  Future<void> updateReminderCompletionStatus(
      int reminderId, bool isCompleted, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final db = database; // Может выбросить исключение, если не инициализировано

    try {
      final reminder = await db.query(
        'reminders_table',
        columns: ['user_id'],
        where: 'id = ?',
        whereArgs: [reminderId],
        limit: 1,
      );
      if (reminder.isEmpty) {
        print('Reminder $reminderId not found in database');
        throw Exception('Reminder not found');
      }
      final userId = reminder.first['user_id'] as String;

      await db.transaction((txn) async {
        print('Inserting status for reminder $reminderId, date $dateString');
        await txn.insert(
          'reminder_statuses',
          {
            'reminder_id': reminderId,
            'date': dateString,
            'is_completed': isCompleted ? 1 : 0,
            'user_id': userId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (isCompleted) {
          print('Cancelling notification for reminder $reminderId');
          await NotificationService.cancelNotification(reminderId);
        }
      });
      print('Successfully updated status for reminder $reminderId');
    } catch (e) {
      print('Error in updateReminderCompletionStatus: $e');
      rethrow; // Перебрасываем исключение для обработки в UI
    }
  }

  // Методы для работы с действиями (actions)
  Future<int> addActionOrHabit(
      Map<String, dynamic> action, String userId) async {
    final db = database;
    action['user_id'] = userId;
    return await db.insert('actions_table', action);
  }

  Future<void> updateAction(Map<String, dynamic> action, String userId) async {
    final db = database;
    await db.update(
      'actions_table',
      {...action, 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [action['id'], userId],
    );
  }

  Future<void> updateActionStatus(int id, bool isCompleted) async {
    final db = database;
    await db.update(
      'actions_table',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getActionsByDate(
      String userId, DateTime date) async {
    final db = database;
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return await db.rawQuery('''
        SELECT * FROM actions_table 
        WHERE user_id = ? AND startDate <= ? AND (endDate >= ? OR endDate IS NULL)
      ''', [userId, dateString, dateString]);
  }

  static Future<List<Map<String, dynamic>>> getMeasurements(
      String userId) async {
    final List<Map<String, dynamic>> result = await _database!.query(
      'measurements_table',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Создаём новый список с копиями карт
    return result.map((measurement) {
      final mutableMeasurement =
          Map<String, dynamic>.from(measurement); // Создаём копию
      mutableMeasurement['isLifelong'] =
          mutableMeasurement['isLifelong'] == 1; // Преобразуем
      return mutableMeasurement;
    }).toList();
  }

  Future<void> updateMeasurement(
      Map<String, dynamic> measurement, String userId) async {
    final db = database;
    await db.update(
      'measurements_table',
      {
        ...measurement,
        'user_id': userId,
        'time':
            jsonEncode(measurement['time']), // Преобразуем список времен в JSON
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [measurement['id'], userId],
    );
  }

  Future<void> deleteMeasurement(int id, String userId) async {
    final db = database;
    await db.delete(
      'measurements_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPulseDataForPeriod(
      String userId, String startDate, String endDate, String period) async {
    final db = database;
    String groupByClause;
    int intervals;
    switch (period) {
      case 'Дни':
        groupByClause = "strftime('%H', date)";
        intervals = 24;
        break;
      case 'Недели':
        groupByClause = "date(date)";
        intervals = 7;
        break;
      case 'Месяцы':
        groupByClause = "strftime('%d', date)";
        intervals = 30;
        break;
      default:
        return [];
    }

    final result = await db.rawQuery('''
    SELECT $groupByClause as period, MIN(value) as min_value, MAX(value) as max_value
    FROM pulse_data
    WHERE user_id = ? AND date BETWEEN ? AND ?
    GROUP BY $groupByClause
    ORDER BY period
  ''', [userId, startDate, endDate]);

    print(
        'Raw pulse data for userId $userId, period $period, $startDate to $endDate: $result'); // Отладка сырых данных

    List<Map<String, dynamic>> data = [];
    if (period == 'Дни') {
      for (int i = 0; i < intervals; i++) {
        final hour = i.toString().padLeft(2, '0');
        final entry = result.firstWhere((e) => e['period'] == hour,
            orElse: () => {'period': hour, 'min_value': 0, 'max_value': 0});
        data.add({
          'label': '$hour:00',
          'min': entry['min_value'] ?? 0,
          'max': entry['max_value'] ?? 0,
        });
      }
    } else if (period == 'Недели') {
      DateTime start = DateTime.parse(startDate);
      for (int i = 0; i < intervals; i++) {
        final date = start.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final entry = result.firstWhere((e) => e['period'] == dateStr,
            orElse: () => {'period': dateStr, 'min_value': 0, 'max_value': 0});
        data.add({
          'label': DateFormat('dd/MM').format(date),
          'min': entry['min_value'] ?? 0,
          'max': entry['max_value'] ?? 0,
        });
      }
    } else if (period == 'Месяцы') {
      for (int i = 1; i <= intervals; i++) {
        final day = i.toString();
        final entry = result.firstWhere(
            (e) => e['period'] == day.padLeft(2, '0'),
            orElse: () => {'period': day, 'min_value': 0, 'max_value': 0});
        data.add({
          'label': i % 7 == 0 || i == 1 ? '$i' : '',
          'min': entry['min_value'] ?? 0,
          'max': entry['max_value'] ?? 0,
        });
      }
    }
    print(
        'Processed graph data for $period: $data'); // Отладка обработанных данных
    return data;
  }

  static Future<Map<String, dynamic>> getPulseSummary(
      String userId, String startDate, String endDate) async {
    final db = database;
    final result = await db.rawQuery('''
      SELECT MIN(value) as min_value, AVG(value) as avg_value, MAX(value) as max_value
      FROM pulse_data
      WHERE user_id = ? AND date BETWEEN ? AND ?
    ''', [userId, startDate, endDate]);

    final data = result.isNotEmpty
        ? {
            'min': (result[0]['min_value'] as int? ?? 0),
            'avg': (result[0]['avg_value'] as double? ?? 0).round(),
            'max': (result[0]['max_value'] as int? ?? 0),
          }
        : {'min': 0, 'avg': 0, 'max': 0};
    print('Summary data: $data');
    return data;
  }

  static Future<List<Map<String, dynamic>>> getPulseComments(
      String userId, String startDate, String endDate) async {
    final db = database;
    final result = await db.query(
      'pulse_data',
      where: 'user_id = ? AND date BETWEEN ? AND ? AND comment IS NOT NULL',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );
    print('Comments data: $result');
    return result;
  }
  // В классе DatabaseService добавляем:

  static Future<List<Map<String, dynamic>>> getUnattachedReminders(
      String userId) async {
    final db = database;
    return await db.query(
      'reminders_table',
      where: '(courseid IS NULL OR courseid = -1) AND user_id = ?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnattachedActions(
      String userId) async {
    final db = database;
    return await db.query(
      'actions_table',
      where: '(courseid IS NULL OR courseid = -1) AND user_id = ?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnattachedMeasurements(
      String userId) async {
    final db = database;
    return await db.query(
      'measurements_table',
      where: '(courseid IS NULL OR courseid = -1) AND user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateCourseName(
      int courseId, String newName, String userId) async {
    final db = database;
    await db.update(
      'courses_table',
      {'name': newName},
      where: 'id = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
  }

  Future<void> deleteCourse(int courseId, String userId) async {
    final db = database;
    // Удаляем связанные напоминания
    await db.delete(
      'reminders_table',
      where: 'courseid = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
    // Удаляем курс
    await db.delete(
      'courses_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
  }
}
