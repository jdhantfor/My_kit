import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'table_method_screen.dart';
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    if (conn.isClosed) {
      throw PostgreSQLException("Connection is not open");
    }
    final results = await conn.query(
      'SELECT id, "Name" FROM "Medicines" '
      'WHERE LOWER("Name") LIKE LOWER(@query || \'%\') '
      'ORDER BY "Name"',
      substitutionValues: {
        'query': query,
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

  // Настраиваемые отступы
  final double horizontalPadding = 16.0;
  final double verticalPadding = 12.0;
  final double searchFieldBottomPadding = 8.0;
  final double containerLeftPadding = 4.0;
  final double dividerHorizontalPadding = 16.0;
  final double listTileVerticalPadding = 8.0;
  final double letterListWidth = 20.0;
  final double letterListHorizontalPadding = 8.0;
  final double letterListRightPadding = 4.0;
  final double iconSize = 20.0;
  final double appBarTopPadding = 40.0;
  final double appBarTitleSpacing = 8.0;

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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: appBarTopPadding,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/arrow_back.svg',
                          width: iconSize + 4,
                          height: iconSize + 4,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        SizedBox(width: appBarTitleSpacing),
                        Text(
                          'Выбор препарата',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalPadding),
            // Поле поиска
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: searchFieldBottomPadding,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      'assets/search.svg',
                      width: iconSize + 16,
                      height: iconSize + 16,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.secondaryGrey,
                            size: iconSize,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchMedicines('');
                            });
                          },
                        )
                      : null,
                  hintText: 'Введите название препарата',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryGrey,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                ),
                onChanged: (text) {
                  _searchMedicines(text);
                },
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.separated(
                          itemCount: _medicines.length,
                          itemBuilder: (context, index) {
                            final medicine = _medicines[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 0,
                              ),
                              title: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TableMethodScreen(
                                              name: medicine.name,
                                              userId: widget.userId,
                                              courseId: widget.courseId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        medicine.name,
                                        style: medicine.id == -2
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.primaryBlue,
                                                )
                                            : Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  if (medicine.id == -1) const SizedBox(),
                                  if (medicine.id == -2)
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TableMethodScreen(
                                              name: medicine.name,
                                              userId: widget.userId,
                                              courseId: widget.courseId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: SvgPicture.asset(
                                        'assets/arrow_forward.svg',
                                        width: iconSize,
                                        height: iconSize,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                  if (medicine.id != -1 && medicine.id != -2)
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TableMethodScreen(
                                              name: medicine.name,
                                              userId: widget.userId,
                                              courseId: widget.courseId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: SvgPicture.asset(
                                        'assets/arrow_forward.svg',
                                        width: iconSize,
                                        height: iconSize,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: dividerHorizontalPadding),
                              child: Divider(
                                color: AppColors.fieldBackground,
                                thickness: 1,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: letterListHorizontalPadding),
                  SizedBox(
                    height: double.infinity,
                    width: letterListWidth,
                    child: ListView.builder(
                      itemCount: 33,
                      itemBuilder: (context, index) {
                        final letter = String.fromCharCode(1040 + index);
                        return GestureDetector(
                          onVerticalDragUpdate: (details) {
                            _searchMedicines(letter);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              letter,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: letterListRightPadding),
                ],
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
