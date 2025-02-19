import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'table_method_screen.dart';

class Medicine {
  final int id;
  final String name;

  Medicine({required this.id, required this.name});
}

class MedicineRepository {
  Future<List<Medicine>> searchMedicinesStartingWith(
    PostgreSQLConnection conn,
    String query,
  ) async {
    const limit = 20;
    if (conn.isClosed) {
      throw PostgreSQLException("Connection is not open");
    }
    final results = await conn.query(
      'SELECT id, "Name" FROM "Medicines" '
      'WHERE LOWER("Name") LIKE LOWER(@query || \'%\') '
      'ORDER BY "Name" '
      'LIMIT @limit',
      substitutionValues: {
        'query': query,
        'limit': limit,
      },
    );
    return results
        .map((row) => Medicine(
              id: row[0] as int,
              name: row[1] as String,
            ))
        .toList();
  }
}

class MedicineSearchScreen extends StatefulWidget {
  final String userId;
  final int courseId;

  const MedicineSearchScreen({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  _MedicineSearchScreenState createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends State<MedicineSearchScreen> {
  final _searchController = TextEditingController();
  final List<Medicine> _medicines = [];
  late PostgreSQLConnection _conn;
  late MedicineRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = MedicineRepository();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    _conn = PostgreSQLConnection(
      '62.113.37.96',
      5432,
      'gorzdrav',
      username: 'postgres',
      password: 'Lissec123',
    );
    _repository = MedicineRepository();
    try {
      await _conn.open();
      Fluttertoast.showToast(
        msg: 'Connected to PostgreSQL database!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      await _loadInitialMedicines();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error connecting to PostgreSQL database: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _loadInitialMedicines() async {
    try {
      final medicines = await _repository.searchMedicinesStartingWith(
        _conn,
        'А',
      );
      setState(() {
        _medicines.addAll(medicines);
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading medicines: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _searchMedicines(String query) async {
    try {
      final medicines = await _repository.searchMedicinesStartingWith(
        _conn,
        query,
      );
      setState(() {
        _medicines.clear();
        _medicines.addAll(medicines);
        if (_medicines.isEmpty) {
          _medicines.add(Medicine(
              id: -1,
              name: 'Препарат не найден,\nвы можете добавить его сами'));
        }
        _medicines.add(Medicine(id: -2, name: query));
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading medicines: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Выбор препарата',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0B102B),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введите название препарата',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (text) {
                _searchMedicines(text);
              },
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0B102B),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.separated(
                itemCount: _medicines.length,
                itemBuilder: (context, index) {
                  final medicine = _medicines[index];
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            medicine.name,
                            style: medicine.id == -2
                                ? const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF197FF2),
                                  )
                                : const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0B102B),
                                  ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (medicine.id == -1) const SizedBox(),
                        if (medicine.id == -2)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TableMethodScreen(
                                    name: medicine.name,
                                    userId: widget.userId,
                                    courseId: widget.courseId,
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF0B102B),
                              size: 16,
                            ),
                          ),
                        if (medicine.id != -1 && medicine.id != -2)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TableMethodScreen(
                                    name: medicine.name,
                                    userId: widget.userId,
                                    courseId: widget.courseId,
                                  ),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF0B102B),
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFFE0E0E0),
                  thickness: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _conn.close();
    super.dispose();
  }
}
