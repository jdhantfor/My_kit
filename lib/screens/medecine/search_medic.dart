import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/medecine/barcodes2_screen.dart';
import 'package:my_aptechka/screens/medecine/medicine_card.dart';
import 'package:provider/provider.dart';

class SearchMedicScreen extends StatefulWidget {
  final String userId;

  const SearchMedicScreen({super.key, required this.userId});

  @override
  _SearchMedicScreenState createState() => _SearchMedicScreenState();
}

class _SearchMedicScreenState extends State<SearchMedicScreen> {
  late PostgreSQLConnection _conn;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _localMedicines = [];
  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _searchResults = [];
  Set<String> _categories = {};
  Set<String> _selectedCategories = {};
  final databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeDatabase().then((_) => _loadAllMedicines());
    _loadLocalMedicines();
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

  Future<void> _loadLocalMedicines() async {
    try {
      final currentUserId =
          Provider.of<UserProvider>(context, listen: false).userId;
      if (currentUserId == null) {
        Fluttertoast.showToast(
          msg: 'Пожалуйста, войдите в систему',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      final loadedMedicines =
          await databaseService.getMedicines(widget.userId, currentUserId);
      setState(() {
        _localMedicines = loadedMedicines;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading local medicines: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _loadAllMedicines() async {
    try {
      final results = await _conn.query(
          'SELECT id, "Name", "ImagePath", "ReleaseForm" FROM "Medicines"');
      setState(() {
        _allMedicines = results
            .map((row) => {
                  'id': row[0],
                  'name': row[1],
                  'imagePath': row[2],
                  'releaseForm': row[3] as String?,
                })
            .toList();

        _searchResults = List.from(_allMedicines);

        _categories = _allMedicines
            .map((medicine) => medicine['releaseForm'] as String?)
            .where((form) => form != null && form.isNotEmpty)
            .cast<String>()
            .toSet();
      });
    } catch (e) {
      print('Error loading medicines from database: $e');
      Fluttertoast.showToast(
        msg: 'Error loading medicines from database: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategories.isEmpty) {
        _searchResults = List.from(_allMedicines);
      } else {
        _searchResults = _allMedicines.where((medicine) {
          bool matchesQuery = query.isEmpty ||
              (medicine['name']
                      ?.toString()
                      .toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false);
          bool matchesCategory = _selectedCategories.isEmpty ||
              _selectedCategories.contains(medicine['releaseForm']);
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterModal(
        categories: _categories,
        selectedCategories: _selectedCategories,
        onApply: (selected) {
          setState(() {
            _selectedCategories = selected;
            _performSearch(_searchController.text);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _openMedicineCard(int medicineId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineCard(
          medicineId: medicineId,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Поиск препарата',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск лекарств...',
                        border: InputBorder.none,
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.black),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Barcodes2Screen(userId: widget.userId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 180, // Ограничиваем ширину кнопки
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.filter_alt_outlined,
                          color: Colors.black),
                      label: const Text('Категории',
                          style: TextStyle(color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _showFilterModal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedCategories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(category),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategories.remove(category);
                                  _performSearch(_searchController.text);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                // Секция "В аптечке"
                if (_localMedicines.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                    child: const Text(
                      'В аптечке',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  ..._localMedicines.map((medicine) {
                    return ListTile(
                      onTap: () => _openMedicineCard(medicine['id']),
                      leading: medicine['imagePath'] != null &&
                              medicine['imagePath'].isNotEmpty
                          ? Image.network(
                              'http://aaa-consulting.pro/image/${medicine['imagePath']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/default_box.png',
                                    width: 50, height: 50);
                              },
                            )
                          : Image.asset('assets/default_box.png',
                              width: 50, height: 50),
                      title: Text(
                        medicine['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (medicine['releaseForm'] != null &&
                              medicine['releaseForm'].toString().isNotEmpty)
                            medicine['releaseForm'],
                        ].join(' '),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }).toList(),
                ],
                // Секция "Найдено в аптеке"
                if (_searchResults.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                    child: const Text(
                      'Найдено в аптеке',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  ..._searchResults.map((medicine) {
                    return ListTile(
                      onTap: () => _openMedicineCard(medicine['id']),
                      leading: medicine['imagePath'] != null &&
                              medicine['imagePath'].isNotEmpty
                          ? Image.network(
                              'http://aaa-consulting.pro/image/${medicine['imagePath']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/default_box.png',
                                    width: 50, height: 50);
                              },
                            )
                          : Image.asset('assets/default_box.png',
                              width: 50, height: 50),
                      title: Text(
                        medicine['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (medicine['releaseForm'] != null &&
                              medicine['releaseForm'].toString().isNotEmpty)
                            medicine['releaseForm'],
                        ].join(' '),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _conn.close();
    super.dispose();
  }
}

class FilterModal extends StatefulWidget {
  final Set<String> categories;
  final Set<String> selectedCategories;
  final Function(Set<String>) onApply;

  const FilterModal({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onApply,
  });

  @override
  _FilterModalState createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = Set.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Категории препарата',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: widget.categories.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[300],
                height: 1,
              ),
              itemBuilder: (context, index) {
                final category = widget.categories.elementAt(index);
                return CheckboxListTile(
                  title: Text(
                    category,
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: _selectedCategories.contains(category),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                  activeColor: Colors.blue,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.trailing,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => widget.onApply(_selectedCategories),
              child: const Text(
                'Применить',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
