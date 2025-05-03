
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../styles.dart';
import 'medecine/barcodes2_screen.dart';
import 'database_service.dart';
import 'user_provider.dart';
import 'medecine/search_medic.dart';
import 'profile_screen.dart';
import 'package:printing/printing.dart';

class MedicineCabinetScreen extends StatefulWidget {
  const MedicineCabinetScreen({super.key});

  @override
  _MedicineCabinetScreenState createState() => _MedicineCabinetScreenState();
}

class FamilyMember {
  final String id;
  final String? name; // Может быть null
  final String email;
  String? avatarUrl;

  FamilyMember({
    required this.id,
    this.name,
    required this.email,
    this.avatarUrl,
  });

  // Геттер для отображаемого имени
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return email;
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
            icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Категории препарата',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B102B),
              ),
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
                    style: const TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0B102B),
                    ),
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
                  activeColor: AppColors.primaryBlue,
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
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => widget.onApply(_selectedCategories),
              child: Text(
                'Применить',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
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
  bool isSortedByDeficit = false;
  final databaseService = DatabaseService();
  List<FamilyMember> familyMembers = [];
  FamilyMember? selectedMember;
  bool isFamilyListVisible = false;
  bool isLoading = true;
  String accessType = 'edit'; // Добавляем переменную для прав доступа

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final userEmail = userProvider.email;

    if (userId == null || userEmail == null) {
      print(
          'Ошибка: ID или email пользователя не указан. userId: $userId, userEmail: $userEmail');
      setState(() => isLoading = false);
      return;
    }

    try {
      final currentUser = FamilyMember(
        id: userId,
        name: userProvider.name ?? 'Имя не указано',
        email: userEmail,
        avatarUrl: userProvider.avatarUrl,
      );

      final response = await http.get(
        Uri.parse('http://62.113.37.96:5002/family_members?user_id=$userId'),
      );

      print('--- Отладка загрузки членов семьи ---');
      print('userId: $userId');
      print(
          'URL запроса: http://62.113.37.96:5002/family_members?user_id=$userId');
      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> familyData = responseData['members'] ?? [];
        print('Данные членов семьи (familyData): $familyData');

        final List<FamilyMember> members = familyData.map((data) {
          return FamilyMember(
            id: data['user_id']?.toString() ?? '',
            name: data['name']?.toString() ?? 'Имя не указано',
            email: data['email']?.toString() ?? '',
            avatarUrl: data['avatar_url']?.toString(),
          );
        }).toList();

        print('Список членов семьи после обработки (members): $members');

        setState(() {
          familyMembers = [currentUser, ...members];
          selectedMember = currentUser;
        });
      } else {
        print('Ошибка загрузки членов семьи: статус ${response.statusCode}');
        setState(() {
          familyMembers = [currentUser];
          selectedMember = currentUser;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке членов семьи: $e');
      setState(() {
        familyMembers = [
          FamilyMember(
            id: userId,
            name: userProvider.name ?? 'Имя не указано',
            email: userEmail,
            avatarUrl: userProvider.avatarUrl,
          )
        ];
        selectedMember = familyMembers.first;
      });
    } finally {
      setState(() => isLoading = false);
      _loadMedicines();
    }
  }

  Future<void> _updateMedicineQuantity(
      String userId, int id, int newPackageCount) async {
    if (newPackageCount > 0) {
      await databaseService.updateMedicineQuantity(userId, id, newPackageCount);
    } else {
      await databaseService.deleteMedicine(userId, id);
    }
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    if (selectedMember == null) return;

    final userId = selectedMember!.id;
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).userId;
    if (currentUserId == null) return;

    final result = await databaseService.getMedicinesWithAccess(userId, currentUserId);
    setState(() {
      medicinesList = (result['medicines'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
      accessType = result['access_type'] as String;
    });
  }

  void _navigateToSearchScreen() {
    if (selectedMember == null || accessType != 'edit') return;

    final userId = selectedMember!.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchMedicScreen(userId: userId),
      ),
    ).then((_) => _loadMedicines());
  }

  void _navigateToBarcodes2Screen() async {
    if (selectedMember == null || accessType != 'edit') return;

    final userId = selectedMember!.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Barcodes2Screen(userId: userId),
      ),
    ).then((_) => _loadMedicines());
  }

  Future<void> _exportMedicineCabinet() async {
  final pdf = pw.Document();

  final fontRegularData =
      await rootBundle.load('fonts/commissioner/Commissioner-Regular.ttf');
  final fontBoldData =
      await rootBundle.load('fonts/commissioner/Commissioner-Bold.ttf');
  final defaultImageData = await rootBundle.load('assets/default_box.png');
  final emptyImageData = await rootBundle.load('assets/tablet.png');

  final fontRegular = pw.Font.ttf(fontRegularData);
  final fontBold = pw.Font.ttf(fontBoldData);
  final defaultImage = pw.MemoryImage(defaultImageData.buffer.asUint8List());
  final emptyImage = pw.MemoryImage(emptyImageData.buffer.asUint8List());

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Аптечка',
                style: pw.TextStyle(font: fontBold, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Дата: ${DateTime.now().toIso8601String().split('T')[0]}',
                style: pw.TextStyle(
                    font: fontRegular, fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            if (medicinesList.isEmpty)
              pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(emptyImage, width: 164, height: 164),
                  pw.SizedBox(height: 14),
                  pw.Text('На данном экране будут\nпринимаемые препараты',
                      style: pw.TextStyle(font: fontBold, fontSize: 24)),
                  pw.SizedBox(height: 10),
                  pw.Text('Добавьте первый препарат',
                      style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 16,
                          color: PdfColors.grey600)),
                ],
              )
            else
              pw.ListView.builder(
                itemCount: medicinesList.length,
                itemBuilder: (context, index) {
                  final medicine = medicinesList[index];
                  int packageCount = medicine['packageCount'] ?? 0;
                  String medicineName = medicine['name'].toString();
                  String? releaseForm = medicine['releaseForm']?.toString();
                  String? quantityInPackage =
                      medicine['quantityInPackage']?.toString();

                  pw.Widget imageWidget =
                      pw.Image(defaultImage, width: 50, height: 50);

                  return pw.Container(
                    margin: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(width: 8),
                        imageWidget,
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                medicineName.length > 20
                                    ? medicineName.substring(0, 20)
                                    : medicineName,
                                style: pw.TextStyle(font: fontBold, fontSize: 16),
                                maxLines: 1,
                              ),
                              pw.Text(
                                [
                                  if (releaseForm != null &&
                                      (releaseForm.isNotEmpty))
                                    releaseForm,
                                  if (quantityInPackage != null &&
                                      quantityInPackage != '0')
                                    '$quantityInPackage в уп.'
                                ].join(' '),
                                style: pw.TextStyle(font: fontRegular, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 30,
                              height: 30,
                              margin: const pw.EdgeInsets.all(2),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey300,
                                borderRadius: pw.BorderRadius.circular(5),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '$packageCount',
                                  style: pw.TextStyle(
                                      font: fontBold, fontSize: 16),
                                ),
                              ),
                            ),
                            if (releaseForm != null &&
                                (releaseForm.isNotEmpty))
                              pw.SizedBox(
                                width: 94,
                                child: pw.Text(
                                  releaseForm,
                                  style: pw.TextStyle(
                                      font: fontRegular,
                                      fontSize: 12,
                                      color: PdfColors.grey600),
                                  textAlign: pw.TextAlign.center,
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                        pw.SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    ),
  );

  // Используем Printing.layoutPdf для открытия PDF, как в TreatmentDetailsScreen
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

  void _showPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Пожалуйста, войдите в систему',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: GestureDetector(
              onTap: () {
                setState(() {
                  isFamilyListVisible = !isFamilyListVisible;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Аптечка',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(width: 8),
                  if (familyMembers.length > 1)
                    SvgPicture.asset(
                      isFamilyListVisible
                          ? 'assets/arrow_down.svg'
                          : 'assets/arrow_down.svg',
                      width: 24,
                      height: 24,
                    ),
                ],
              ),
            ),
            actions: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: InkWell(
                  onTap: accessType == 'edit' ? _navigateToSearchScreen : null,
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: SvgPicture.asset(
                      'assets/search.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'export') {
                      _exportMedicineCabinet();
                    } else if (value == 'privacy') {
                      _showPrivacySettings();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'export',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(
                          'Экспортировать аптечку',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0B102B),
                              ),
                        ),
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    PopupMenuItem<String>(
                      value: 'privacy',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(
                          'Настройки приватности семьи',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF0B102B),
                              ),
                        ),
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: SvgPicture.asset(
                      'assets/more.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
          body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          if (isFamilyListVisible && familyMembers.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: familyMembers.map((member) {
                    return ListTile(
                      title: Text(
                        member.displayName, // Используем displayName вместо email
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF0B102B),
                            ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedMember = member;
                          isFamilyListVisible = false;
                        });
                        _loadMedicines();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          if (medicinesList.length > 3) _buildFilterAndSortButtons(),
          Expanded(
            child: medicinesList.isEmpty
                ? _buildEmptyList()
                : _buildMedicineList(selectedMember?.id ?? ''),
          ),
        ],
      ),
          floatingActionButton: accessType == 'edit'
              ? FloatingActionButton(
                  onPressed: _navigateToBarcodes2Screen,
                  backgroundColor: AppColors.primaryBlue,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterAndSortButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(
              Icons.filter_alt_outlined,
              color: Color(0xFF0B102B),
            ),
            label: const Text(
              'Категории',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0B102B),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: const Size(100, 40),
            ),
            onPressed: () => _showFilterModal(),
          ),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.swap_vert,
              color: Color(0xFF0B102B),
            ),
            label: const Text(
              'Сначала те, что в дефиците',
              style: TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF0B102B),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0E0E0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(100, 40),
            ),
            onPressed: () {
              _toggleSortByDeficit();
            },
          ),
        ],
      ),
    );
  }

  void _toggleSortByDeficit() {
    setState(() {
      isSortedByDeficit = !isSortedByDeficit;
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
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'На данном экране будут принимаемые препараты',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: const Color(0xFF0B102B),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Добавьте первый препарат',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
          if (accessType == 'edit') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToBarcodes2Screen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: const Size(0, 48),
              ),
              child: Text(
                'Добавить',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicineList(String userId) {
    var filteredMedicines = selectedCategories.isEmpty
        ? List.from(medicinesList)
        : medicinesList
            .where((medicine) =>
                selectedCategories.contains(medicine['releaseForm']))
            .toList();

    if (isSortedByDeficit) {
      filteredMedicines.sort((a, b) {
        int countA = a['packageCount'] ?? 0;
        int countB = b['packageCount'] ?? 0;
        return countA.compareTo(countB);
      });
    }

    return ListView.builder(
      itemCount: filteredMedicines.length,
      itemBuilder: (context, index) {
        final medicine = filteredMedicines[index];
        int packageCount = medicine['packageCount'] ?? 0;
        String medicineName = medicine['name'].toString();

        return Card(
          margin: const EdgeInsets.all(4.0),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
                style: const TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B102B),
                ),
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
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (accessType == 'edit') ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(129, 132, 153, 0.08),
                          borderRadius: BorderRadius.circular(6),
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
                          iconSize: 16,
                          color: const Color(0xFF0B102B),
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 24,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(129, 132, 153, 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$packageCount',
                          style: const TextStyle(
                            fontFamily: 'Commissioner',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0B102B),
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(129, 132, 153, 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            _updateMedicineQuantity(
                                userId, medicine['id'], packageCount + 1);
                          },
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          color: const Color(0xFF0B102B),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: 32,
                    height: 24,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(129, 132, 153, 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$packageCount',
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                  ),
                ],
                if (medicine['releaseForm'] != null &&
                    medicine['releaseForm'].toString().isNotEmpty)
                  SizedBox(
                    width: 94,
                    child: Text(
                      medicine['releaseForm'].toString(),
                      style: const TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                      ),
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