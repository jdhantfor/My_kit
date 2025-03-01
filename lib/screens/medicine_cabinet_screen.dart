import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/medecine/barcodes2_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/screens/medecine/search_medic.dart';

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  _MedicineCabinetScreenState createState() => _MedicineCabinetScreenState();
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

class _MedicineCabinetScreenState extends State<MedicineCabinetScreen> {
  List<Map<String, dynamic>> medicinesList = [];
  Set<String> selectedCategories = {};
  bool isSortedByDeficit = false; // Флаг для отслеживания состояния сортировки

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _updateMedicineQuantity(
      String userId, int id, int newPackageCount) async {
    if (newPackageCount > 0) {
      await DatabaseService.updateMedicineQuantity(userId, id, newPackageCount);
    } else {
      await DatabaseService.deleteMedicine(userId, id);
    }
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final loadedMedicines = await DatabaseService.getMedicines(userId);
      setState(() {
        medicinesList = loadedMedicines;
      });
    }
  }

  void _navigateToSearchScreen() {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchMedicScreen(userId: userId),
        ),
      );
    }
  }

  void _navigateToBarcodes2Screen() {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Barcodes2Screen(userId: userId),
        ),
      );
    }
  }

  Widget _buildFilterAndSortButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
            label:
                const Text('Категории', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(100, 40),
            ),
            onPressed: () => _showFilterModal(),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.swap_vert, color: Colors.black),
            label: const Text(
              'Сначала те, что в дефиците',
              style: TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              minimumSize: const Size(200, 40),
            ),
            onPressed: () {
              _toggleSortByDeficit(); // Переключаем сортировку
            },
          ),
        ],
      ),
    );
  }

  void _toggleSortByDeficit() {
    setState(() {
      isSortedByDeficit = !isSortedByDeficit; // Переключаем флаг
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FilterModal(
        categories: medicinesList
            .map((medicine) => medicine['releaseForm'] as String?)
            .where((form) => form != null && form.isNotEmpty)
            .cast<String>()
            .toSet(),
        selectedCategories: selectedCategories,
        onApply: (selected) {
          setState(() {
            selectedCategories = selected;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Пожалуйста, войдите в систему')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Аптечка'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search,
                  color: Color.fromARGB(255, 112, 111, 111)),
              onPressed: _navigateToSearchScreen,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz,
                  color: Color.fromARGB(255, 105, 105, 105)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (medicinesList.length > 3) _buildFilterAndSortButtons(),
          Expanded(
            child: medicinesList.isEmpty
                ? _buildEmptyList()
                : _buildMedicineList(userId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToBarcodes2Screen,
        backgroundColor: const Color(0xFF197FF2),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tablet.png',
            width: 164,
            height: 164,
          ),
          const SizedBox(height: 14),
          const Text(
            'На данном экране будут принимаемые препараты',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте первый препарат',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _navigateToBarcodes2Screen,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF197FF2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            ),
            child: const Text(
              'Добавить',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList(String userId) {
    var filteredMedicines = selectedCategories.isEmpty
        ? List.from(medicinesList) // Создаем копию списка
        : medicinesList
            .where((medicine) =>
                selectedCategories.contains(medicine['releaseForm']))
            .toList();

    if (isSortedByDeficit) {
      filteredMedicines.sort((a, b) {
        int countA = a['packageCount'] ?? 0;
        int countB = b['packageCount'] ?? 0;
        return countA.compareTo(countB); // Сортировка по возрастанию
      });
    }

    return ListView.builder(
      itemCount: filteredMedicines.length,
      itemBuilder: (context, index) {
        final medicine = filteredMedicines[index];
        int packageCount = medicine['packageCount'] ?? 0;
        String medicineName = medicine['name'].toString();

        return Card(
          margin: const EdgeInsets.all(8.0),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
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
                : Image.asset('assets/default_box.png', width: 50, height: 50),
            title: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black, Colors.transparent],
                  stops: [0.85, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Text(
                medicineName.length > 20
                    ? medicineName.substring(0, 20)
                    : medicineName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
            ),
            subtitle: Text(
              [
                if (medicine['releaseForm'] != null &&
                    medicine['releaseForm'].toString().isNotEmpty)
                  medicine['releaseForm'],
                if (medicine['quantityInPackage'] != null &&
                    medicine['quantityInPackage'].toString().isNotEmpty &&
                    medicine['quantityInPackage'] != '0')
                  '${medicine['quantityInPackage']} в уп.',
              ].join(' '),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 214, 214),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (packageCount > 0) {
                            _updateMedicineQuantity(
                                userId, medicine['id'], packageCount - 1);
                          }
                        },
                        padding: EdgeInsets.zero,
                        iconSize: 24,
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 214, 214),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text('$packageCount',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 214, 214, 214),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _updateMedicineQuantity(
                              userId, medicine['id'], packageCount + 1);
                        },
                        padding: EdgeInsets.zero,
                        iconSize: 24,
                      ),
                    ),
                  ],
                ),
                if (medicine['releaseForm'] != null &&
                    medicine['releaseForm'].toString().isNotEmpty)
                  SizedBox(
                    width: 94,
                    child: Text(
                      medicine['releaseForm'].toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}