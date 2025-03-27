import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
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

  // URL сервера (замени на свой адрес Flask-сервера)
  static const String _serverUrl = 'http://62.113.37.96:5002/api/sync';

  // Метод для синхронизации данных с сервером
  Future<void> syncWithServer(String userId) async {
    try {
      // Собираем данные из всех таблиц для пользователя
      final data = await _collectUserData(userId);

      // Отправляем данные на сервер
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': userId,
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        print(
            'Ошибка синхронизации с сервером: ${response.statusCode} - ${response.body}');
      } else {
        print('Синхронизация успешна для userId: $userId');
      }
    } catch (e) {
      print('Ошибка при синхронизации: $e');
    }
  }

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    final db = database;

    // Собираем данные из всех таблиц
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    final medicines = await getMedicines(userId, userId);
    final courses = await getCourses(userId);
    final reminders = await getReminders(userId);
    final measurements = await getMeasurements(userId);
    final actions = await getActions(userId);
    final reminderStatuses = await getAllReminderStatuses();
    final pulseData = await getPulseData(userId);
    final bloodPressureData = await getBloodPressureData(userId);
    final stepsData = await getStepsData(userId);
    final notificationSettings = await getNotificationSettings(userId);

    return {
      'users': users,
      'medicines_table': medicines,
      'courses_table': courses,
      'reminders_table': reminders,
      'measurements_table': measurements,
      'actions_table': actions,
      'reminder_statuses': reminderStatuses,
      'pulse_data': pulseData,
      'blood_pressure_data': bloodPressureData,
      'steps_data': stepsData,
      'notification_settings': notificationSettings,
    };
  }

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
        if (oldVersion < 3) {
          await db
              .execute('ALTER TABLE reminders_table ADD COLUMN endDate TEXT');
        }
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
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT UNIQUE');
          await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
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
        if (oldVersion < 20) {
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN times TEXT');
          } catch (e) {}
        }
        if (oldVersion < 21) {
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN time TEXT');
            await db.execute('UPDATE actions_table SET time = mealTime');
            await db.execute('''
            CREATE TABLE actions_table_temp AS 
            SELECT id, name, startDate, endDate, isLifelong, courseid, user_id, 
                   time, type, selectTime, quantity, schedule_type, interval_value, 
                   interval_unit, selected_days_mask, cycle_duration, cycle_break, 
                   cycle_break_unit, notification, isCompleted, times 
            FROM actions_table
          ''');
            await db.execute('DROP TABLE actions_table');
            await db.execute(
                'ALTER TABLE actions_table_temp RENAME TO actions_table');
          } catch (e) {
            print(
                'Error during migration of actions_table mealTime to time: $e');
          }
        }
        if (oldVersion < 22) {
          await db.execute('DROP TABLE IF EXISTS actions_table');
          await db.execute('''
          CREATE TABLE actions_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            startDate TEXT,
            endDate TEXT,
            isLifelong INTEGER,
            courseid INTEGER REFERENCES courses_table(id),
            user_id TEXT REFERENCES users(id),
            time TEXT,
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
            isCompleted INTEGER,
            times TEXT
          )
        ''');

          await db.execute('DROP TABLE IF EXISTS measurements_table');
          await db.execute('''
          CREATE TABLE measurements_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            startDate TEXT,
            endDate TEXT,
            isLifelong INTEGER,
            courseid INTEGER REFERENCES courses_table(id),
            user_id TEXT REFERENCES users(id),
            time TEXT,
            selectTime TEXT,
            type TEXT DEFAULT 'measurement',
            schedule_type TEXT,
            interval_value INTEGER,
            interval_unit TEXT,
            selected_days_mask INTEGER DEFAULT 0,
            cycle_duration INTEGER,
            cycle_break INTEGER,
            cycle_break_unit TEXT
          )
        ''');
        }
        if (oldVersion < 23) {
          await db.execute('ALTER TABLE users ADD COLUMN password TEXT');
        }
        if (oldVersion < 24) {
          await db.execute('''
      CREATE TABLE IF NOT EXISTS user_health_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT REFERENCES users(id),
        steps TEXT,
        heart_rate TEXT,
        timestamp TEXT
      )
    ''');
        }
        if (oldVersion < 25) {
          // Добавляем таблицу notification_settings
          await db.execute('''
          CREATE TABLE IF NOT EXISTS notification_settings (
            user_id TEXT PRIMARY KEY REFERENCES users(id),
            allow_push_notifications INTEGER DEFAULT 1,
            expiration_notifications INTEGER DEFAULT 1,
            medication_reminders INTEGER DEFAULT 1,
            vaccination_reminders INTEGER DEFAULT 1,
            measurement_reminders INTEGER DEFAULT 1,
            third_party_notifications INTEGER DEFAULT 1
          )
        ''');
        }
      },
      version: 25, // Увеличиваем версию базы данных
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS notification_settings (
      user_id TEXT PRIMARY KEY REFERENCES users(id),
      allow_push_notifications INTEGER DEFAULT 1,
      expiration_notifications INTEGER DEFAULT 1,
      medication_reminders INTEGER DEFAULT 1,
      vaccination_reminders INTEGER DEFAULT 1,
      measurement_reminders INTEGER DEFAULT 1,
      third_party_notifications INTEGER DEFAULT 1
    )
  ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS users(
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password TEXT,
      phone TEXT UNIQUE,
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
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      startDate TEXT,
      endDate TEXT,
      isLifelong INTEGER,
      courseid INTEGER REFERENCES courses_table(id),
      user_id TEXT REFERENCES users(id),
      time TEXT,
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
      isCompleted INTEGER,
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
      unit TEXT,  -- Добавляем поле unit
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

    // Проверяем, существует ли пользователь
    final existing =
        await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (existing.isEmpty) {
      await db.insert(
          'users',
          {
            'id': userId,
            'is_logged_in': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    if (name != null) updates['name'] = name;
    if (surname != null) updates['surname'] = surname;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (password != null) updates['password'] = password;

    if (updates.isNotEmpty) {
      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
    }
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
    try {
      final db = database;
      if (db == null) {
        throw Exception('База данных не инициализирована');
      }
      await db.update(
        'users',
        {'is_logged_in': 0},
        where: 'id = ?',
        whereArgs: [userId],
      );
      print('Успешный выход для userId: $userId');
    } catch (e) {
      print('Ошибка при выходе в DatabaseService.logout: $e');
      rethrow;
    }
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

  Future<void> addMedicine(
      String name,
      String? releaseForm,
      String? quantityInPackage,
      String? imagePath,
      int packageCount,
      String userId,
      {String? unit}) async {
    final db = _database;
    final Map<String, dynamic> medicineData = {
      'name': name,
      'releaseForm': releaseForm,
      'imagePath': imagePath,
      'packageCount': packageCount,
      'unit': unit,
      'user_id': userId
    };

    if (quantityInPackage != null && quantityInPackage.isNotEmpty) {
      medicineData['quantityInPackage'] = quantityInPackage;
    }

    await db!.insert(
      'medicines_table',
      medicineData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Синхронизируем с сервером после добавления
    await syncWithServer(userId);
  }

  Future<void> updateMedicineQuantity(
      String userId, int id, int newPackageCount) async {
    final db = _database;
    await db!.update(
      'medicines_table',
      {'packageCount': newPackageCount},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    // Синхронизируем с сервером после обновления
    await syncWithServer(userId);
  }

  // Новый метод для обновления unit
  Future<void> updateMedicineUnit(String userId, int id, String unit) async {
    final db = _database;
    await db!.update(
      'medicines_table',
      {'unit': unit},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> deleteMedicine(String userId, int id) async {
    final db = database;
    await db.delete(
      'medicines_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    // Синхронизируем с сервером после удаления
    await syncWithServer(userId);
  }

  Future<List<Map<String, dynamic>>> getMedicines(
      String userId, String currentUserId) async {
    if (userId == currentUserId) {
      final db = _database;
      return await db!.query(
        'medicines_table',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      const int maxRetries = 3;
      const Duration timeoutDuration = Duration(seconds: 20);
      int attempt = 0;
      final client = http.Client();

      while (attempt < maxRetries) {
        try {
          final request =
              http.Request('GET', Uri.parse('$_serverUrl?uid=$userId'))
                ..headers['Content-Type'] = 'application/json';

          final streamedResponse =
              await client.send(request).timeout(timeoutDuration);
          final response = await http.Response.fromStream(streamedResponse);

          print(
              'Ответ сервера для userId $userId: status=${response.statusCode}, body=${response.body}');

          if (response.statusCode != 200) {
            print(
                'Ошибка получения данных с сервера для userId $userId: ${response.statusCode} - ${response.body}');
            return [];
          }

          final data = jsonDecode(response.body);
          // Ожидаем структуру {"data": {...}}
          if (data['data'] == null) {
            print('Данные для userId $userId не найдены в ответе сервера');
            return [];
          }

          final userData = data['data'];
          final medicines = userData['medicines_table'] ?? [];
          return List<Map<String, dynamic>>.from(medicines);
        } catch (e) {
          attempt++;
          if (attempt == maxRetries) {
            print(
                'Ошибка при загрузке данных с сервера для userId $userId после $maxRetries попыток: $e');
            return [];
          }
          print(
              'Попытка $attempt/$maxRetries: Ошибка при загрузке данных для userId $userId: $e. Повтор через 2 секунды...');
          await Future.delayed(Duration(seconds: 2));
        } finally {
          client.close();
        }
      }
      return [];
    }
  }

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
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final dateString = DateFormat('yyyy-MM-dd').format(normalizedDate);

      final List<Map<String, dynamic>> reminders = await db.rawQuery('''
      SELECT rs.reminder_id, rs.is_completed 
      FROM reminder_statuses rs
      WHERE rs.user_id = ? AND rs.date = ?
    ''', [userId, dateString]);

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
        statuses[reminderId]![normalizedDate] = status;
      }
    }

    print('Loaded statuses for dates: $statuses');
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
      'isLifelong':
          measurement['isLifelong'], // Принимаем как есть (уже int: 1 или 0)
      'schedule_type': measurement['schedule_type'],
      'interval_value': measurement['interval_value'],
      'interval_unit': measurement['interval_unit'],
      'selected_days_mask': measurement['selected_days_mask'],
      'cycle_duration': measurement['cycle_duration'],
      'cycle_break': measurement['cycle_break'],
      'cycle_break_unit': measurement['cycle_break_unit'],
      'courseid': measurement['courseid'],
      'user_id': userId,
    };

    // Удаляем null значения, кроме courseid
    measurementToInsert
        .removeWhere((key, value) => key != 'courseid' && value == null);

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
      (date(?) >= date(startDate) AND 
       (endDate IS NULL OR (date(?) <= date(endDate) AND isLifelong = 0)) OR
       (isLifelong = 1))
    )
  ''', [userId, dateString, dateString]);

    final modifiedResult = result.map((item) {
      final newItem = Map<String, dynamic>.from(item);
      newItem['isLifelong'] = newItem['isLifelong'] == 1;
      return newItem;
    }).toList();

    return modifiedResult;
  }

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
          type: '',
        );
      }
    }

    // Синхронизируем с сервером после добавления
    await syncWithServer(userId);

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

    const validColumns = {
      'id',
      'name',
      'time',
      'dosage',
      'unit',
      'selectTime',
      'startDate',
      'endDate',
      'isLifelong',
      'schedule_type',
      'interval_value',
      'interval_unit',
      'selected_days_mask',
      'cycle_duration',
      'cycle_break',
      'cycle_break_unit',
      'type',
      'isCompleted',
      'courseid',
      'user_id',
    };

    final filteredReminder = Map<String, dynamic>.from(reminder)
      ..removeWhere((key, value) => !validColumns.contains(key));

    filteredReminder['user_id'] = userId;

    await db.update(
      'reminders_table',
      filteredReminder,
      where: 'id = ? AND user_id = ?',
      whereArgs: [filteredReminder['id'], userId],
    );

    // Синхронизируем с сервером после обновления
    await syncWithServer(userId);
  }

  Future<void> deleteReminder(int id, String userId) async {
    final db = database;
    await db.delete(
      'reminders_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    // Синхронизируем с сервером после удаления
    await syncWithServer(userId);
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
    final db = database;

    String tableName;
    int originalId = reminderId;
    if (reminderId >= 200000) {
      tableName = 'measurements_table';
      originalId -= 200000;
      return;
    } else if (reminderId >= 100000) {
      tableName = 'actions_table';
      originalId -= 100000;
    } else {
      tableName = 'reminders_table';
    }

    final reminder = await db.query(
      tableName,
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [originalId],
      limit: 1,
    );
    if (reminder.isEmpty) {
      throw Exception('Reminder not found for ID: $originalId in $tableName');
    }
    final userId = reminder.first['user_id'] as String;

    await db.transaction((txn) async {
      await txn.delete(
        'reminder_statuses',
        where: 'reminder_id = ? AND date = ? AND user_id = ?',
        whereArgs: [reminderId, dateString, userId],
      );

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
        await NotificationService.cancelNotification(reminderId);
      }
    });

    print(
        'Updated status for reminder $reminderId on $dateString: $isCompleted');
  }

  static Future<int> addActionOrHabit(
      Map<String, dynamic> action, String userId) async {
    final db = await database;
    final Map<String, dynamic> actionToInsert = {
      'name': action['name'],
      'time': action['time'],
      'selectTime': action['selectTime'],
      'startDate': action['startDate'],
      'endDate': action['endDate'],
      'isLifelong': action['isLifelong'],
      'schedule_type': action['schedule_type'],
      'interval_value': action['interval_value'],
      'interval_unit': action['interval_unit'],
      'selected_days_mask': action['selected_days_mask'],
      'cycle_duration': action['cycle_duration'],
      'cycle_break': action['cycle_break'],
      'cycle_break_unit': action['cycle_break_unit'],
      'courseid': action['courseid'],
      'user_id': userId,
    };

    actionToInsert
        .removeWhere((key, value) => key != 'courseid' && value == null);

    final insertedId = await db.insert(
      'actions_table',
      actionToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return insertedId;
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

    final actions = await db.rawQuery('''
    SELECT 
      (id + 100000) as id,
      name, startDate, endDate, isLifelong, courseid, user_id, time, 
      selectTime, quantity, schedule_type, interval_value, interval_unit, 
      selected_days_mask, cycle_duration, cycle_break, cycle_break_unit, 
      notification, isCompleted, times
    FROM actions_table 
    WHERE user_id = ? AND startDate <= ? AND (endDate >= ? OR endDate IS NULL)
  ''', [userId, dateString, dateString]);

    print('Loaded actions with prefixed IDs: $actions');
    return actions;
  }

  static Future<List<Map<String, dynamic>>> getMeasurements(
      String userId) async {
    final List<Map<String, dynamic>> result = await _database!.query(
      'measurements_table',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((measurement) {
      final mutableMeasurement = Map<String, dynamic>.from(measurement);
      mutableMeasurement['isLifelong'] = mutableMeasurement['isLifelong'] == 1;
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
        'time': jsonEncode(measurement['time']),
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

    print('Извлекаем данные пульса для периода: $period');
    print('UserId: $userId');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final result = await db.query(
      'pulse_data',
      columns: ['date', 'value'],
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Сырые данные из базы для периода $period: $result');

    final preparedData = result.map((item) {
      return {
        'date': item['date'] as String,
        'value': item['value'] as int,
      };
    }).toList();

    print('Подготовленные данные для передачи: $preparedData');
    return preparedData;
  }

  static Future<Map<String, dynamic>> getPulseSummary(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос сводки пульса для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.rawQuery('''
    SELECT MIN(value) as min_value, AVG(value) as avg_value, MAX(value) as max_value
    FROM pulse_data
    WHERE user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)
  ''', [userId, startDate, endDate]);

    print('Результат запроса сводки: $result');

    return result.isNotEmpty
        ? {
            'min': (result[0]['min_value'] as int? ?? 0),
            'avg': (result[0]['avg_value'] as double? ?? 0).round(),
            'max': (result[0]['max_value'] as int? ?? 0),
          }
        : {'min': 0, 'avg': 0, 'max': 0};
  }

  static Future<List<Map<String, dynamic>>> getPulseComments(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос комментариев для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.query(
      'pulse_data',
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?) AND comment IS NOT NULL',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Результат запроса комментариев: $result');
    return result;
  }

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

  Future<ReminderStatus?> getActionStatusForDate(
      int actionId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final db = database;
    final result = await db.query(
      'reminder_statuses',
      where:
          'reminder_id = ? AND date = ? AND user_id = (SELECT user_id FROM actions_table WHERE id = ?)',
      whereArgs: [actionId, dateString, actionId],
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

  Future<void> deleteCourse(int courseId, String userId) async {
    final db = database;
    await db.delete(
      'reminders_table',
      where: 'courseid = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
    await db.delete(
      'courses_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getBloodPressureDataForPeriod(
      String userId, String startDate, String endDate, String period) async {
    final db = database;

    print('Извлекаем данные давления для периода: $period');
    print('UserId: $userId');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final result = await db.query(
      'blood_pressure_data',
      columns: ['date', 'systolic', 'diastolic'],
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Сырые данные из базы для периода $period: $result');

    final preparedData = result.map((item) {
      return {
        'date': item['date'] as String,
        'systolic': item['systolic'] as int?,
        'diastolic': item['diastolic'] as int?,
      };
    }).toList();

    print('Подготовленные данные для передачи: $preparedData');
    return preparedData;
  }

  static Future<Map<String, dynamic>> getBloodPressureSummary(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос сводки давления для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.rawQuery('''
    SELECT 
      MIN(systolic) as min_systolic, AVG(systolic) as avg_systolic, MAX(systolic) as max_systolic,
      MIN(diastolic) as min_diastolic, AVG(diastolic) as avg_diastolic, MAX(diastolic) as max_diastolic
    FROM blood_pressure_data
    WHERE user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)
  ''', [userId, startDate, endDate]);

    print('Результат запроса сводки: $result');

    return result.isNotEmpty
        ? {
            'systolic': {
              'min': (result[0]['min_systolic'] as int? ?? 0),
              'avg': (result[0]['avg_systolic'] as double? ?? 0).round(),
              'max': (result[0]['max_systolic'] as int? ?? 0),
            },
            'diastolic': {
              'min': (result[0]['min_diastolic'] as int? ?? 0),
              'avg': (result[0]['avg_diastolic'] as double? ?? 0).round(),
              'max': (result[0]['max_diastolic'] as int? ?? 0),
            },
          }
        : {
            'systolic': {'min': 0, 'avg': 0, 'max': 0},
            'diastolic': {'min': 0, 'avg': 0, 'max': 0},
          };
  }

  static Future<List<Map<String, dynamic>>> getStepsDataForPeriod(
      String userId, String startDate, String endDate, String period) async {
    final db = database;

    print('Извлекаем данные шагов для периода: $period');
    print('UserId: $userId');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final result = await db.query(
      'steps_data',
      columns: ['date', 'count'],
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Сырые данные из базы для периода $period: $result');

    final preparedData = result.map((item) {
      return {
        'date': item['date'] as String,
        'count': item['count'] as int?,
      };
    }).toList();

    print('Подготовленные данные для передачи: $preparedData');
    return preparedData;
  }

  static Future<Map<String, dynamic>> getStepsSummary(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос сводки шагов для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.rawQuery('''
    SELECT 
      SUM(count) as total, AVG(count) as average
    FROM steps_data
    WHERE user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?)
  ''', [userId, startDate, endDate]);

    print('Результат запроса сводки: $result');

    return result.isNotEmpty
        ? {
            'total': (result[0]['total'] as int? ?? 0),
            'average': (result[0]['average'] as double? ?? 0).round(),
          }
        : {'total': 0, 'average': 0};
  }

  static Future<List<Map<String, dynamic>>> getBloodPressureComments(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос комментариев давления для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.query(
      'blood_pressure_data',
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?) AND comment IS NOT NULL',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Результат запроса комментариев: $result');
    return result;
  }

  static Future<List<Map<String, dynamic>>> getStepsComments(
      String userId, String startDate, String endDate) async {
    final db = database;
    print('Запрос комментариев шагов для UserId: $userId');
    print('Диапазон: $startDate - $endDate');

    final result = await db.query(
      'steps_data',
      where:
          'user_id = ? AND datetime(date) BETWEEN datetime(?) AND datetime(?) AND comment IS NOT NULL',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date',
    );

    print('Результат запроса комментариев: $result');
    return result;
  }

  static Future<void> saveSteps(String userId, String steps) async {
    final db = await database;
    await db.insert(
      'user_health_data',
      {
        'user_id': userId,
        'steps': steps,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveHeartRate(String userId, String heartRate) async {
    final db = await database;
    await db.insert(
      'user_health_data',
      {
        'user_id': userId,
        'heart_rate': heartRate,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Метод для восстановления данных с сервера
  Future<void> restoreFromServer(String userId) async {
    try {
      // Запрашиваем данные с сервера
      final response = await http.get(
        Uri.parse('$_serverUrl?uid=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print(
            'Ошибка получения данных с сервера: ${response.statusCode} - ${response.body}');
        return;
      }

      final data = jsonDecode(response.body)['data'];

      // Очищаем локальную базу для пользователя
      final db = database;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      await db
          .delete('medicines_table', where: 'user_id = ?', whereArgs: [userId]);
      await db
          .delete('courses_table', where: 'user_id = ?', whereArgs: [userId]);
      await db
          .delete('reminders_table', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('measurements_table',
          where: 'user_id = ?', whereArgs: [userId]);
      await db
          .delete('actions_table', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('reminder_statuses',
          where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('pulse_data', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('blood_pressure_data',
          where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('steps_data', where: 'user_id = ?', whereArgs: [userId]);

      // Вставляем данные с сервера
      for (var user in data['users']) {
        await db.insert('users', user,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var medicine in data['medicines_table']) {
        await db.insert('medicines_table', medicine,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var course in data['courses_table']) {
        await db.insert('courses_table', course,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var reminder in data['reminders_table']) {
        await db.insert('reminders_table', reminder,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var measurement in data['measurements_table']) {
        await db.insert('measurements_table', measurement,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var action in data['actions_table']) {
        await db.insert('actions_table', action,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var status in data['reminder_statuses']) {
        await db.insert('reminder_statuses', status,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var pulse in data['pulse_data']) {
        await db.insert('pulse_data', pulse,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var bp in data['blood_pressure_data']) {
        await db.insert('blood_pressure_data', bp,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var step in data['steps_data']) {
        await db.insert('steps_data', step,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      print('Данные успешно восстановлены для userId: $userId');
    } catch (e) {
      print('Ошибка при восстановлении данных: $e');
    }
  }

  // Получение настроек уведомлений для пользователя
  static Future<Map<String, dynamic>> getNotificationSettings(
      String userId) async {
    final db = database;
    final result = await db.query(
      'notification_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      // Если настроек нет, создаём запись с значениями по умолчанию
      await db.insert(
        'notification_settings',
        {
          'user_id': userId,
          'allow_push_notifications': 1,
          'expiration_notifications': 1,
          'medication_reminders': 1,
          'vaccination_reminders': 1,
          'measurement_reminders': 1,
          'third_party_notifications': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return {
        'allow_push_notifications': true, // Возвращаем bool
        'expiration_notifications': true,
        'medication_reminders': true,
        'vaccination_reminders': true,
        'measurement_reminders': true,
        'third_party_notifications': true,
      };
    }

    return {
      'allow_push_notifications': result.first['allow_push_notifications'] == 1,
      'expiration_notifications': result.first['expiration_notifications'] == 1,
      'medication_reminders': result.first['medication_reminders'] == 1,
      'vaccination_reminders': result.first['vaccination_reminders'] == 1,
      'measurement_reminders': result.first['measurement_reminders'] == 1,
      'third_party_notifications':
          result.first['third_party_notifications'] == 1,
    };
  }

// Обновление настроек уведомлений
  static Future<void> updateNotificationSettings(
      String userId, Map<String, dynamic> settings) async {
    final db = database;
    final settingsToInsert = {
      'user_id': userId,
      'allow_push_notifications': settings['allow_push_notifications'] ? 1 : 0,
      'expiration_notifications': settings['expiration_notifications'] ? 1 : 0,
      'medication_reminders': settings['medication_reminders'] ? 1 : 0,
      'vaccination_reminders': settings['vaccination_reminders'] ? 1 : 0,
      'measurement_reminders': settings['measurement_reminders'] ? 1 : 0,
      'third_party_notifications':
          settings['third_party_notifications'] ? 1 : 0,
    };

    await db.insert(
      'notification_settings',
      settingsToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Синхронизируем с сервером после обновления
    await DatabaseService().syncWithServer(userId);
  }
}
