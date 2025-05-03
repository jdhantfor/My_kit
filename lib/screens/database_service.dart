import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:my_aptechka/screens/models/reminder_status.dart';
import 'package:my_aptechka/services/notification_service.dart';

class DatabaseService {
  static Database? _database;

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _serverUrl = 'http://62.113.37.96:5002/api/sync';

  Future<void> syncWithServer(String userId) async {
  const int maxRetries = 3;
  const Duration timeoutDuration = Duration(seconds: 20);
  int attempt = 0;

  while (attempt < maxRetries) {
    try {
      final data = await _collectUserData(userId);
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': userId,
          'data': data,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        print('Синхронизация успешна для userId: $userId');
        // Опционально: загрузка актуальных данных с сервера после отправки
        await _updateFromServer(userId);
        return;
      } else {
        print('Ошибка синхронизации с сервером: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to sync: ${response.statusCode}');
      }
    } catch (e) {
      attempt++;
      if (attempt == maxRetries) {
        print('Ошибка синхронизации после $maxRetries попыток: $e');
        return;
      }
      print('Попытка $attempt/$maxRetries: Ошибка синхронизации: $e. Повтор через 2 секунды...');
      await Future.delayed(Duration(seconds: 2));
    }
  }
}

Future<void> _updateFromServer(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('$_serverUrl?uid=$userId&requester_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 20));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      if (data != null && data['users'] != null && data['users'].isNotEmpty) {
        final serverUser = data['users'].firstWhere(
          (user) => user['user_id'] == userId,
          orElse: () => null,
        );
        if (serverUser != null) {
          // Преобразуем subscribe из bool в int
          int? subscribeValue;
          if (serverUser['subscribe'] is bool) {
            subscribeValue = serverUser['subscribe'] ? 1 : 0;
          } else if (serverUser['subscribe'] is int) {
            subscribeValue = serverUser['subscribe'];
          }

          await updateUserDetails(
            userId,
            name: serverUser['name'],
            surname: serverUser['surname'],
            phone: serverUser['phone'],
            email: serverUser['email'],
            password: serverUser['password'],
            subscribe: subscribeValue, // Передаём int
          );
          print('Локальная база обновлена с сервера для userId: $userId');
        }
      }
    } else {
      print('Ошибка получения данных с сервера: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Ошибка при обновлении данных с сервера: $e');
  }
}

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
  final db = database;
  final users = await db.query('users', where: 'user_id = ?', whereArgs: [userId]);
  final modifiedUsers = users.map((user) {
    final modifiedUser = Map<String, dynamic>.from(user);
    modifiedUser['subscribe'] = user['subscribe'] == 1 ? true : false;
    return modifiedUser;
  }).toList();

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
    'users': modifiedUsers,
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
    bool dbExists = await File(databasePath).exists();
  
    _database = await openDatabase(
      databasePath,
      onCreate: (db, version) async {
        await _createTables(db);
        await db.execute('CREATE INDEX idx_reminder_statuses ON reminder_statuses(reminder_id, date)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE reminders_table ADD COLUMN endDate TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              user_id TEXT PRIMARY KEY,
              phone TEXT UNIQUE,
              is_logged_in INTEGER
            )
          ''');
          await db.execute('ALTER TABLE medicines_table ADD COLUMN user_id TEXT REFERENCES users(user_id)');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN user_id TEXT REFERENCES users(user_id)');
          await db.execute('ALTER TABLE courses_table ADD COLUMN user_id TEXT REFERENCES users(user_id)');
          await db.execute('ALTER TABLE pulse_data ADD COLUMN user_id TEXT REFERENCES users(user_id)');
          await db.execute('ALTER TABLE blood_pressure_data ADD COLUMN user_id TEXT REFERENCES users(user_id)');
          await db.execute('ALTER TABLE steps_data ADD COLUMN user_id TEXT REFERENCES users(user_id)');
        }
        if (oldVersion < 7) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_reminder_statuses ON reminder_statuses(reminder_id, date)');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE reminders_table ADD COLUMN schedule_type TEXT');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN interval_value INTEGER');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN interval_unit TEXT');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN cycle_duration INTEGER');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN cycle_break INTEGER');
          await db.execute('ALTER TABLE reminders_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
        }
        if (oldVersion < 9) {
          await db.execute('ALTER TABLE reminders_table ADD COLUMN cycle_break_unit TEXT');
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
              user_id TEXT REFERENCES users(user_id),
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
              user_id TEXT REFERENCES users(user_id),
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
          await db.execute('ALTER TABLE measurements_table ADD COLUMN selectTime TEXT');
        }
        if (oldVersion < 15) {
          await db.execute('ALTER TABLE reminders_table ADD COLUMN type TEXT DEFAULT "tablet"');
        }
        if (oldVersion < 16) {
          await db.execute('ALTER TABLE reminders_table ADD COLUMN isCompleted INTEGER');
        }
        if (oldVersion < 17) {
          await db.execute('ALTER TABLE actions_table ADD COLUMN quantity TEXT');
          await db.execute('ALTER TABLE actions_table ADD COLUMN scheduleType TEXT');
          await db.execute('ALTER TABLE actions_table ADD COLUMN notification TEXT');
          await db.execute('ALTER TABLE actions_table ADD COLUMN isCompleted INTEGER');
        }
        if (oldVersion < 18) {
          await db.execute('ALTER TABLE actions_table RENAME COLUMN scheduleType TO schedule_type');
        }
        if (oldVersion < 19) {
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN interval_value INTEGER');
          } catch (e) {
            print('Column interval_value already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN interval_unit TEXT');
          } catch (e) {
            print('Column interval_unit already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
          } catch (e) {
            print('Column selected_days_mask already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN cycle_duration INTEGER');
          } catch (e) {
            print('Column cycle_duration already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN cycle_break INTEGER');
          } catch (e) {
            print('Column cycle_break already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE actions_table ADD COLUMN cycle_break_unit TEXT');
          } catch (e) {
            print('Column cycle_break_unit already exists in actions_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN schedule_type TEXT');
          } catch (e) {
            print('Column schedule_type already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN interval_value INTEGER');
          } catch (e) {
            print('Column interval_value already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN interval_unit TEXT');
          } catch (e) {
            print('Column interval_unit already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN selected_days_mask INTEGER DEFAULT 0');
          } catch (e) {
            print('Column selected_days_mask already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN cycle_duration INTEGER');
          } catch (e) {
            print('Column cycle_duration already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN cycle_break INTEGER');
          } catch (e) {
            print('Column cycle_break already exists in measurements_table: $e');
          }
          try {
            await db.execute('ALTER TABLE measurements_table ADD COLUMN cycle_break_unit TEXT');
          } catch (e) {
            print('Column cycle_break_unit already exists in measurements_table: $e');
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
            await db.execute('ALTER TABLE actions_table_temp RENAME TO actions_table');
          } catch (e) {
            print('Error during migration of actions_table mealTime to time: $e');
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
              user_id TEXT REFERENCES users(user_id),
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
              user_id TEXT REFERENCES users(user_id),
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
        if (oldVersion < 24) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS user_health_data (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT REFERENCES users(user_id),
              steps TEXT,
              heart_rate TEXT,
              timestamp TEXT
            )
          ''');
        }
        if (oldVersion < 25) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notification_settings (
              user_id TEXT PRIMARY KEY REFERENCES users(user_id),
              allow_push_notifications INTEGER DEFAULT 1,
              expiration_notifications INTEGER DEFAULT 1,
              medication_reminders INTEGER DEFAULT 1,
              vaccination_reminders INTEGER DEFAULT 1,
              measurement_reminders INTEGER DEFAULT 1,
              third_party_notifications INTEGER DEFAULT 1
            )
          ''');
        }
        if (oldVersion < 26) {
        await db.execute('ALTER TABLE users ADD COLUMN subscribe INTEGER DEFAULT 0');
      }
      if (oldVersion < 27) {
        await db.execute('ALTER TABLE reminders_table ADD COLUMN medicineId INTEGER REFERENCES medicines_table(id)');
      }
    },
    version: 27,
  );
  if (!dbExists) {
    final userId = await getCurrentUserId();
    if (userId != null) {
      await loadBackupFromServer(userId);
    }
  }
}

Future<void> deleteRemindersByNameAndCourseId(String name, int courseId, String userId) async {
  final db = database;

  // Получаем все напоминания, которые собираемся удалить, чтобы отменить их уведомления
  final reminders = await db.query(
    'reminders_table',
    where: 'name = ? AND courseid = ? AND user_id = ?',
    whereArgs: [name, courseId, userId],
  );

  // Отменяем уведомления для каждого напоминания
  for (var reminder in reminders) {
    final reminderId = reminder['id'] as int;
    await NotificationService.cancelNotification(reminderId);
    print('Cancelled notification for reminderId: $reminderId');
  }

  // Удаляем напоминания из базы
  await db.delete(
    'reminders_table',
    where: 'name = ? AND courseid = ? AND user_id = ?',
    whereArgs: [name, courseId, userId],
  );

  await syncWithServer(userId);
}

  static Future<String?> getCurrentUserId() async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'is_logged_in = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['user_id'] as String? : null;
  }

static Future<void> loadBackupFromServer(String userId) async {
  const int maxRetries = 3;
  const Duration timeoutDuration = Duration(seconds: 20);
  int attempt = 0;
  final client = http.Client();

  while (attempt < maxRetries) {
    try {
      // Передаём оба параметра: uid и requester_id
      final request = http.Request(
        'GET',
        Uri.parse('$_serverUrl?uid=$userId&requester_id=$userId'),
      )..headers['Content-Type'] = 'application/json';

      final streamedResponse = await client.send(request).timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      // Проверяем статус ответа
      if (response.statusCode != 200) {
        print('Ошибка загрузки данных с сервера: ${response.statusCode} - ${response.body}');
        return;
      }

      // Парсим данные
      final data = jsonDecode(response.body);
      if (data['data'] == null) {
        print('Данные не найдены для userId $userId');
        return;
      }

      final serverData = data['data'];
      print('Данные с сервера: $serverData');

      // Обновляем локальную базу
      final db = database;

      // Проходим по всем таблицам в serverData
      for (var table in serverData.keys) {
        final rows = serverData[table];
        if (rows is List && rows.isNotEmpty) {
          // Для таблиц с id (medicines_table, reminders_table и т.д.)
          if (table != 'users' && table != 'notification_settings') {
            for (var row in rows) {
              final existing = await db.query(
                table,
                where: 'id = ? AND user_id = ?',
                whereArgs: [row['id'], userId],
                limit: 1,
              );

              if (existing.isNotEmpty) {
                // Обновляем существующую запись
                await db.update(
                  table,
                  row,
                  where: 'id = ? AND user_id = ?',
                  whereArgs: [row['id'], userId],
                );
              } else {
                // Добавляем новую запись
                await db.insert(table, row);
              }
            }
          }
        }
      }

      // Особая обработка для таблицы users
      if (serverData['users'] != null && serverData['users'].isNotEmpty) {
        for (var user in serverData['users']) {
          if (user['user_id'] == userId) {
            // Преобразуем user в изменяемый Map и конвертируем bool в int
            final userToInsert = Map<String, dynamic>.from(user);
            if (userToInsert['subscribe'] is bool) {
              userToInsert['subscribe'] = userToInsert['subscribe'] == true ? 1 : 0;
            }
            if (userToInsert['is_logged_in'] is bool) {
              userToInsert['is_logged_in'] = userToInsert['is_logged_in'] == true ? 1 : 0;
            }

            final existing = await db.query(
              'users',
              where: 'user_id = ?',
              whereArgs: [userId],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              await db.update(
                'users',
                userToInsert,
                where: 'user_id = ?',
                whereArgs: [userId],
              );
            } else {
              await db.insert('users', userToInsert);
            }
          }
        }
      }

      // Особая обработка для notification_settings
      if (serverData['notification_settings'] != null) {
        final settings = Map<String, dynamic>.from(serverData['notification_settings']);
        // Преобразуем bool в int
        settings.forEach((key, value) {
          if (value is bool) {
            settings[key] = value ? 1 : 0;
          }
        });
        await db.insert(
          'notification_settings',
          settings,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('Локальная база успешно обновлена для userId $userId');
      return;
    } catch (e) {
      attempt++;
      if (attempt == maxRetries) {
        print('Ошибка загрузки данных после $maxRetries попыток: $e');
        return;
      }
      print('Попытка $attempt/$maxRetries: Ошибка загрузки: $e. Повтор через 2 секунды...');
      await Future.delayed(Duration(seconds: 2));
    } finally {
      client.close();
    }
  }
}



  static Future<void> restoreBackup(Map<String, dynamic> backupData) async {
    final db = database;
    await clearDatabase();
    for (var table in backupData.keys) {
      final rows = backupData[table];
      if (rows is List && rows.isNotEmpty) {
        for (var row in rows) {
          await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_settings (
        user_id TEXT PRIMARY KEY REFERENCES users(user_id),
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
        user_id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        password TEXT,
        phone TEXT UNIQUE,
        is_logged_in INTEGER,
        name TEXT,
        surname TEXT,
        subscribe INTEGER DEFAULT 0
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
        user_id TEXT REFERENCES users(user_id),
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
        user_id TEXT REFERENCES users(user_id),
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
        unit TEXT,
        user_id TEXT REFERENCES users(user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS courses_table(
        id INTEGER PRIMARY KEY, 
        name TEXT, 
        user_id TEXT REFERENCES users(user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS course_medicines(
        id INTEGER PRIMARY KEY,
        courseid INTEGER REFERENCES courses_table(id),
        medicine_id INTEGER REFERENCES medicines_table(id),
        dosage TEXT,
        unit TEXT,
        user_id TEXT REFERENCES users(user_id)
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
      user_id TEXT REFERENCES users(user_id),
      medicineId INTEGER REFERENCES medicines_table(id)
    )
  ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_statuses(
        id INTEGER PRIMARY KEY,
        reminder_id INTEGER REFERENCES reminders_table(id),
        date TEXT,
        is_completed INTEGER,
        user_id TEXT REFERENCES users(user_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pulse_data(
        id INTEGER PRIMARY KEY, 
        date TEXT, 
        value INTEGER, 
        user_id TEXT REFERENCES users(user_id),
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
        user_id TEXT REFERENCES users(user_id),
        pulse INTEGER,
        comment TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS steps_data(
        id INTEGER PRIMARY KEY, 
        date TEXT, 
        count INTEGER, 
        user_id TEXT REFERENCES users(user_id),
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

  static Future<void> updateUserDetails(String userId,
    {String? name,
    String? surname,
    String? phone,
    String? email,
    String? password,
    int? subscribe}) async {
  final db = database;
  final Map<String, dynamic> updates = {};
  final existing = await db.query('users', where: 'user_id = ?', whereArgs: [userId], limit: 1);
  if (existing.isEmpty) {
    await db.insert(
        'users',
        {
          'user_id': userId,
          'is_logged_in': 0,
          'subscribe': subscribe ?? 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  if (name != null) updates['name'] = name;
  if (surname != null) updates['surname'] = surname;
  if (phone != null) updates['phone'] = phone;
  if (email != null) updates['email'] = email;
  if (password != null) updates['password'] = password;
  if (subscribe != null) updates['subscribe'] = subscribe;

  if (updates.isNotEmpty) {
    await db.update(
      'users',
      updates,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

Future<Map<String, dynamic>?> getMedicineById(String userId, int medicineId) async {
  final db = database;
  final result = await db.query(
    'medicines_table',
    where: 'id = ? AND user_id = ?',
    whereArgs: [medicineId, userId],
    limit: 1,
  );
  return result.isNotEmpty ? result.first : null;
}

static Future<bool> getSubscribeStatus(String userId) async {
  final db = database;
  final result = await db.query(
    'users',
    columns: ['subscribe'],
    where: 'user_id = ?',
    whereArgs: [userId],
    limit: 1,
  );
  return result.isNotEmpty && result.first['subscribe'] == 1;
}

  static Future<String?> getUserIdByEmail(String email) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['user_id'] as String : null;
  }

  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<String?> getUserIdByEmailAndPassword(String email, String password) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first['user_id'] as String : null;
  }

  static Future<bool> isLoggedIn(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty && result.first['is_logged_in'] == 1;
  }

  static Future<String?> getUserPhone(String userId) async {
    final db = database;
    final result = await db.query(
      'users',
      columns: ['phone'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first['phone'] as String? : null;
  }

  static Future<void> logout(String userId) async {
    try {
      final db = database;
      await db.update(
        'users',
        {'is_logged_in': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      print('Успешный выход для userId: $userId');
    } catch (e) {
      print('Ошибка при выходе в DatabaseService.logout: $e');
      rethrow;
    }
  }

  static Future<int> addCourse(Map<String, dynamic> course, String userId) async {
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
    return await db.query('courses_table', where: 'user_id = ?', whereArgs: [userId]);
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

  Future<int> addMedicine(
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

  final medicineId = await db!.insert(
    'medicines_table',
    medicineData,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  await syncWithServer(userId);

  return medicineId; 
}

  Future<void> updateMedicineQuantity(String userId, int id, int newPackageCount) async {
    final db = _database;
    await db!.update(
      'medicines_table',
      {'packageCount': newPackageCount},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    await syncWithServer(userId);
  }

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

    await syncWithServer(userId);
  }

  Future<Map<String, dynamic>> getMedicinesWithAccess(String userId, String currentUserId) async {
    if (userId == currentUserId) {
      final db = _database;
      final medicines = await db!.query(
        'medicines_table',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return {'medicines': medicines, 'access_type': 'edit'};
    } else {
      const int maxRetries = 3;
      const Duration timeoutDuration = Duration(seconds: 20);
      int attempt = 0;
      final client = http.Client();

      while (attempt < maxRetries) {
        try {
          final request = http.Request(
              'GET', Uri.parse('$_serverUrl?uid=$userId&requester_id=$currentUserId'))
            ..headers['Content-Type'] = 'application/json';

          final streamedResponse = await client.send(request).timeout(timeoutDuration);
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode != 200) {
            print('Ошибка получения данных с сервера для userId $userId: ${response.statusCode} - ${response.body}');
            return {
              'medicines': <Map<String, dynamic>>[],
              'access_type': 'view_only'
            };
          }

          final data = jsonDecode(response.body);
          final userData = data['data'] ?? {};
          final accessType = data['access_type'] ?? 'view_only';
          final medicinesRaw = userData['medicines_table'] ?? [];

          final medicines = medicinesRaw.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();

          return {
            'medicines': medicines,
            'access_type': accessType
          };
        } catch (e) {
          attempt++;
          if (attempt == maxRetries) {
            print('Ошибка при загрузке данных с сервера для userId $userId после $maxRetries попыток: $e');
            return {
              'medicines': <Map<String, dynamic>>[],
              'access_type': 'view_only'
            };
          }
          print('Попытка $attempt/$maxRetries: Ошибка при загрузке данных для userId $userId: $e. Повтор через 2 секунды...');
          await Future.delayed(Duration(seconds: 2));
        } finally {
          client.close();
        }
      }
      return {
        'medicines': <Map<String, dynamic>>[],
        'access_type': 'view_only'
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMedicines(String userId, String currentUserId) async {
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
          final request = http.Request('GET', Uri.parse('$_serverUrl?uid=$userId'))
            ..headers['Content-Type'] = 'application/json';

          final streamedResponse = await client.send(request).timeout(timeoutDuration);
          final response = await http.Response.fromStream(streamedResponse);

          print('Ответ сервера для userId $userId: status=${response.statusCode}, body=${response.body}');

          if (response.statusCode != 200) {
            print('Ошибка получения данных с сервера для userId $userId: ${response.statusCode} - ${response.body}');
            return [];
          }

          final data = jsonDecode(response.body);
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
            print('Ошибка при загрузке данных с сервера для userId $userId после $maxRetries попыток: $e');
            return [];
          }
          print('Попытка $attempt/$maxRetries: Ошибка при загрузке данных для userId $userId: $e. Повтор через 2 секунды...');
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
    return await db.query('actions_table', where: 'user_id = ?', whereArgs: [userId]);
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
    return result.isNotEmpty ? result.first['user_id'] as String : null;
  }

  static Future<void> updateUserLoginStatus(
      String userId, bool isLoggedIn) async {
    final db = database;
    await db.update(
      'users',
      {'is_logged_in': isLoggedIn ? 1 : 0},
      where: 'user_id = ?',
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
      'isLifelong': measurement['isLifelong'],
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
    'medicineId': reminder['medicineId'],
  };

  reminderToInsert.removeWhere((key, value) => key != 'courseid' && value == null);

  final insertedReminderId = await db.insert(
    'reminders_table',
    reminderToInsert,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

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
    return; // Измерения не влияют на лекарства
  } else if (reminderId >= 100000) {
    tableName = 'actions_table';
    originalId -= 100000;
  } else {
    tableName = 'reminders_table';
  }

  // Запрашиваем только те столбцы, которые точно есть в обеих таблицах
  final reminder = await db.query(
    tableName,
    columns: ['user_id', 'type'],
    where: 'id = ?',
    whereArgs: [originalId],
    limit: 1,
  );
  if (reminder.isEmpty) {
    throw Exception('Reminder not found for ID: $originalId in $tableName');
  }
  final userId = reminder.first['user_id'] as String;
  final type = reminder.first['type'] as String?;
  int? medicineId;

  // Если это напоминание (reminders_table), дополнительно запрашиваем medicineId
  if (tableName == 'reminders_table') {
    final reminderWithMedicineId = await db.query(
      'reminders_table',
      columns: ['medicineId'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [originalId, userId],
      limit: 1,
    );
    if (reminderWithMedicineId.isNotEmpty) {
      medicineId = reminderWithMedicineId.first['medicineId'] as int?;
    }
  }

  await db.transaction((txn) async {
    // Удаляем старую запись статуса
    await txn.delete(
      'reminder_statuses',
      where: 'reminder_id = ? AND date = ? AND user_id = ?',
      whereArgs: [reminderId, dateString, userId],
    );

    // Добавляем новую запись статуса
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

    // Если это tablet и есть medicineId, обновляем количество в medicines_table
    if (type == 'tablet' && medicineId != null) {
      final medicine = await txn.query(
        'medicines_table',
        columns: ['packageCount'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [medicineId, userId],
        limit: 1,
      );
      if (medicine.isNotEmpty) {
        int currentCount = medicine.first['packageCount'] as int? ?? 0;
        int newCount = isCompleted ? currentCount - 1 : currentCount + 1;

        if (newCount < 0) newCount = 0; // Предотвращаем отрицательное количество

        await txn.update(
          'medicines_table',
          {'packageCount': newCount},
          where: 'id = ? AND user_id = ?',
          whereArgs: [medicineId, userId],
        );
        print(
            'Updated medicine $medicineId packageCount to $newCount for user $userId');
      }
    }

    if (isCompleted) {
      await NotificationService.cancelNotification(reminderId);
    }
  });

  // Синхронизируем с сервером после изменения
  await syncWithServer(userId);

  print('Updated status for reminder $reminderId on $dateString: $isCompleted');
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

  Future<void> updateCourseName(int courseId, String newName, String userId) async {
  final db = database;
  await db.update(
    'courses_table',
    {'name': newName},
    where: 'id = ? AND user_id = ?',
    whereArgs: [courseId, userId],
  );

  // Синхронизируем с сервером, как в deleteCourse
  await syncWithServer(userId);
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
  final db = await database;

  // Удаляем напоминания без синхронизации
  final reminders = await db.query(
    'reminders_table',
    where: 'courseid = ? AND user_id = ?',
    whereArgs: [courseId, userId],
  );
  for (var reminder in reminders) {
    final reminderId = reminder['id'] as int;
    await db.delete(
      'reminders_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId],
    );
  }

  await db.delete(
    'measurements_table',
    where: 'courseid = ? AND user_id = ?',
    whereArgs: [courseId, userId],
  );

  await db.delete(
    'actions_table',
    where: 'courseid = ? AND user_id = ?',
    whereArgs: [courseId, userId],
  );

  await db.delete(
    'courses_table',
    where: 'id = ? AND user_id = ?',
    whereArgs: [courseId, userId],
  );

  // Синхронизируем один раз в конце
  await syncWithServer(userId);
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

  Future<void> restoreFromServer(String userId) async {
    try {
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

      final db = database;
      await db.delete('users', where: 'user_id = ?', whereArgs: [userId]);
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
  Future<void> deleteReminder(int id, String userId) async {
  final db = database;

  // Отменяем уведомление для этого напоминания
  await NotificationService.cancelNotification(id);
  print('Cancelled notification for reminderId: $id');

  // Удаляем напоминание из базы
  await db.delete(
    'reminders_table',
    where: 'id = ? AND user_id = ?',
    whereArgs: [id, userId],
  );

  await syncWithServer(userId);
}
  
Future<void> delReminder(int reminderId, String userId) async {
    final db = await database;
    await db.delete(
      'reminders_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId],
    );
    await syncWithServer(userId);
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

    Future<void> updateReminderEndDate(int reminderId, String endDate, String userId) async {
    final db = database;
    await db.update(
      'reminders_table',
      {'endDate': endDate},
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminderId, userId],
    );
    await syncWithServer(userId);
  }

  Future<void> updateActionEndDate(int actionId, String endDate, String userId) async {
    final db = database;
    await db.update(
      'actions_table',
      {'endDate': endDate},
      where: 'id = ? AND user_id = ?',
      whereArgs: [actionId, userId],
    );
    await syncWithServer(userId);
  }

  Future<void> updateMeasurementEndDate(int measurementId, String endDate, String userId) async {
    final db = database;
    await db.update(
      'measurements_table',
      {'endDate': endDate},
      where: 'id = ? AND user_id = ?',
      whereArgs: [measurementId, userId],
    );
    await syncWithServer(userId);
  }
  
  static Future<void> deleteUser(String userId) async {
  final db = database;

  // 1. Отменяем уведомления для всех напоминаний пользователя
  final reminders = await db.query(
    'reminders_table',
    where: 'user_id = ?',
    whereArgs: [userId],
  );
  for (var reminder in reminders) {
    final reminderId = reminder['id'] as int;
    await NotificationService.cancelNotification(reminderId);
    print('Cancelled notification for reminderId: $reminderId');
  }

  // 2. Удаляем данные из всех таблиц
  await db.delete('users', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('medicines_table', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('courses_table', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('reminders_table', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('measurements_table', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('actions_table', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('reminder_statuses', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('pulse_data', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('blood_pressure_data', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('steps_data', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('notification_settings', where: 'user_id = ?', whereArgs: [userId]);
  await db.delete('user_health_data', where: 'user_id = ?', whereArgs: [userId]);

  // 3. Отправляем запрос на сервер для удаления данных пользователя
  const int maxRetries = 3;
  const Duration timeoutDuration = Duration(seconds: 20);
  int attempt = 0;

  while (attempt < maxRetries) {
    try {
      final response = await http.delete(
        Uri.parse('$_serverUrl?uid=$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        print('Данные пользователя $userId успешно удалены с сервера');
        break;
      } else {
        print('Ошибка удаления данных с сервера: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete user data on server: ${response.statusCode}');
      }
    } catch (e) {
      attempt++;
      if (attempt == maxRetries) {
        print('Ошибка удаления данных с сервера после $maxRetries попыток: $e');
        throw Exception('Failed to delete user data on server after $maxRetries attempts: $e');
      }
      print('Попытка $attempt/$maxRetries: Ошибка удаления: $e. Повтор через 2 секунды...');
      await Future.delayed(Duration(seconds: 2));
    }
  }

  print('Пользователь $userId и все его данные успешно удалены из локальной базы');
}
}
