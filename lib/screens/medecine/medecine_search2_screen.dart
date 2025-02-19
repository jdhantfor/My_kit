import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';
import 'package:my_aptechka/screens/medecine/medicine_card.dart';

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
      'SELECT id, "Name" FROM "Medicines" WHERE LOWER("Name") LIKE LOWER(@query || \'%\') ORDER BY "Name" LIMIT @limit',
      substitutionValues: {
        'query': query,
        'limit': limit,
      },
    );
    return results
        .map((row) => Medicine(id: row[0] as int, name: row[1] as String))
        .toList();
  }
}

class MedicineSearch2Screen extends StatefulWidget {
  final String userId;

  const MedicineSearch2Screen({super.key, required this.userId});

  @override
  _MedicineSearch2ScreenState createState() => _MedicineSearch2ScreenState();
}

class _MedicineSearch2ScreenState extends State<MedicineSearch2Screen> {
  final _searchController = TextEditingController();
  final List<Medicine> _medicines = [];
  late PostgreSQLConnection _conn;

  @override
  void initState() {
    super.initState();
    _initializeDatabase().then((_) {
      _searchMedicines('');
    });
  }

  Future<void> _initializeDatabase() async {
    _conn = PostgreSQLConnection(
      '62.113.37.96',
      5432,
      'gorzdrav',
      username: 'postgres',
      password: 'Lissec123',
    );
    try {
      await _conn.open();
      Fluttertoast.showToast(
        msg: 'Connected to PostgreSQL database!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error connecting to PostgreSQL database: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _searchMedicines(String query) async {
    try {
      final medicines = await MedicineRepository().searchMedicinesStartingWith(
        _conn,
        query,
      );
      setState(() {
        _medicines.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Выбор препарата'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Введите название препарата',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchMedicines,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.separated(
                itemCount: _medicines.length,
                itemBuilder: (context, index) {
                  final medicine = _medicines[index];
                  return ListTile(
                    title: Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (medicine.id > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineCard(
                              medicineId: medicine.id,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
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
