import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_aptechka/styles.dart';
import 'package:postgres/postgres.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/home_screen.dart';
import 'package:my_aptechka/screens/medecine/treatment_course_modal.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math; // Для использования pi

class InstructionDetailScreen extends StatelessWidget {
  final String title;
  final String? content;

  const InstructionDetailScreen({super.key, required this.title, this.content});

  // Настраиваемые отступы (копируем из MedicineSearchScreen)
  final double horizontalPadding = 16.0;
  final double appBarTopPadding = 40.0;
  final double iconSize = 32.0; // Увеличиваем размер иконки до 32

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кастомный AppBar
            Padding(
              padding: EdgeInsets.only(
                top: appBarTopPadding,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/arrow_back.svg',
                      width: iconSize,
                      height: iconSize,
                      // Убираем color, так как SVG уже нужного цвета
                    ),
                  ),
                  const SizedBox(width: 32, height: 32), // Для выравнивания
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        content ?? "Информация отсутствует",
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Medicine {
  final int id;
  final String name;
  final String? imagePath;
  final String? releaseForm;
  final String? originCountry;
  final String? activeIngredients;
  final String? vacationProcedure;
  final String? quantityInPackage;
  final int? barcodes;
  final String? composition;
  final String? description;
  final String? pharmacologicalEffect;
  final String? pharmacokinetics;
  final String? indications;
  final String? contraindications;
  final String? safetyPrecautions;
  final String? oregnancyUsage;
  final String? methodApplicationDosage;
  final String? sideEffects;
  final String? overdose;
  final String? drugsInteraction;
  final String? specialInstructions;
  final String? storageConditions;

  Medicine({
    required this.id,
    required this.name,
    this.imagePath,
    this.releaseForm,
    this.originCountry,
    this.activeIngredients,
    this.vacationProcedure,
    this.quantityInPackage,
    this.barcodes,
    this.composition,
    this.description,
    this.pharmacologicalEffect,
    this.pharmacokinetics,
    this.indications,
    this.contraindications,
    this.safetyPrecautions,
    this.oregnancyUsage,
    this.methodApplicationDosage,
    this.sideEffects,
    this.overdose,
    this.drugsInteraction,
    this.specialInstructions,
    this.storageConditions,
  });
}

class MedicineRepository {
  Future<Medicine> getMedicineDetails(PostgreSQLConnection conn, int id) async {
    if (conn.isClosed) {
      throw PostgreSQLException("Connection is not open");
    }
    final results = await conn.query(
      'SELECT "id", "Name", "ImagePath", "ReleaseForm", "OriginCountry", "ActiveIngredients", "VacationProcedure", "QuantityInPackage", "Barcodes", "Composition", "Description", "PharmacologicalEffect", "Pharmacokinetics", "Indications", "Contraindications", "SafetyPrecautions", "OregnancyUsage", "MethodApplicationDosage", "SideEffects", "Overdose", "DrugsInteraction", "SpecialInstructions", "StorageConditions" FROM "Medicines" WHERE "id" = @id',
      substitutionValues: {
        'id': id,
      },
    );
    if (results.isEmpty) {
      throw Exception("Medicine not found");
    }
    final row = results.first;
    return Medicine(
      id: row[0] as int,
      name: row[1] as String,
      imagePath: row[2] as String?,
      releaseForm: row[3] as String?,
      originCountry: row[4] as String?,
      activeIngredients: row[5] as String?,
      vacationProcedure: row[6] as String?,
      quantityInPackage: row[7] as String?,
      barcodes: row[8] as int?,
      composition: row[9] as String?,
      description: row[10] as String?,
      pharmacologicalEffect: row[11] as String?,
      pharmacokinetics: row[12] as String?,
      indications: row[13] as String?,
      contraindications: row[14] as String?,
      safetyPrecautions: row[15] as String?,
      oregnancyUsage: row[16] as String?,
      methodApplicationDosage: row[17] as String?,
      sideEffects: row[18] as String?,
      overdose: row[19] as String?,
      drugsInteraction: row[20] as String?,
      specialInstructions: row[21] as String?,
      storageConditions: row[22] as String?,
    );
  }
}

class MedicineCard extends StatefulWidget {
  final int medicineId;
  final String userId;

  const MedicineCard({
    super.key,
    required this.medicineId,
    required this.userId,
  });

  @override
  _MedicineCardState createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  late Medicine medicine;
  bool isLoading = true;
  TextEditingController packageCountController =
      TextEditingController(text: "1");
  DateTime expirationDate = DateTime(2026, 1, 1);
  final databaseService = DatabaseService();

  // Настраиваемые отступы (копируем из MedicineSearchScreen)
  final double horizontalPadding = 16.0;
  final double appBarTopPadding = 40.0;
  final double iconSize = 32.0; // Увеличиваем размер иконки до 32

  @override
  void initState() {
    super.initState();
    _loadMedicineDetails();
  }

  Future<void> _loadMedicineDetails() async {
    try {
      final conn = PostgreSQLConnection(
        '62.113.37.96',
        5432,
        'gorzdrav',
        username: 'postgres',
        password: 'Lissec123',
      );
      await conn.open();
      medicine = await MedicineRepository()
          .getMedicineDetails(conn, widget.medicineId);
      setState(() => isLoading = false);
      await conn.close();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Ошибка загрузки данных о лекарстве: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showExpirationDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: AppColors.primaryText),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        expirationDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кастомный AppBar
            Padding(
              padding: EdgeInsets.only(
                top: 0,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/arrow_back.svg',
                      width: iconSize,
                      height: iconSize,
                      // Убираем color, так как SVG уже нужного цвета
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero, // Убираем внутренние отступы
                      icon: Transform.rotate(
                        angle: math.pi / 2, // Поворот на 90 градусов
                        child: SvgPicture.asset(
                          'assets/more.svg',
                          width: 32,
                          height: 32,
                          // Убираем color, так как SVG уже нужного цвета
                        ),
                      ),
                      onPressed: () {
                        print('Настройки');
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Картинка в белом контейнере
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Center(
                        child: medicine.imagePath != null &&
                                medicine.imagePath!.isNotEmpty
                            ? Image.network(
                                'http://aaa-consulting.pro/image/${medicine.imagePath}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Error loading image: $error');
                                  return Image.asset(
                                    'assets/default_box.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                'assets/default_box.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        medicine.name,
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontFamily: 'Commissioner',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0B102B),
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        [
                          if (medicine.releaseForm != null &&
                              medicine.releaseForm!.isNotEmpty)
                            medicine.releaseForm!,
                          if (medicine.quantityInPackage != null &&
                              medicine.quantityInPackage!.isNotEmpty &&
                              medicine.quantityInPackage != '0')
                            '${medicine.quantityInPackage} в уп.',
                        ].join(' '),
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.only(left: 16, bottom: 4),
                            child: Text(
                              'Количество и сроки',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, bottom: 8, left: 4, right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          'Осталось единиц',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            SizedBox(
  width: 48,
  child: TextField(
    controller: packageCountController,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ],
    onChanged: (value) {
      // Убираем принудительный сброс на "1", чтобы пользователь мог свободно вводить
      if (value.isEmpty) {
        packageCountController.text = '';
      }
    },
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryBlue,
    ),
    decoration: const InputDecoration(
      border: InputBorder.none,
      filled: true,
      fillColor: Color.fromARGB(0, 97, 97, 97),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    ),
  ),
),
                                            const SizedBox(width: 8),
                                            Text(
                                              medicine.releaseForm ?? "шт",
                                              style: const TextStyle(
                                                fontFamily: 'Commissioner',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                                height: 22 / 16,
                                                color: Color.fromARGB(
                                                    141, 0, 0, 0),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        top: 8, left: 16, right: 16, bottom: 0),
                                    child: Divider(
                                      color: AppColors.fieldBackground,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Срок годности',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            _showExpirationDatePicker(context);
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                DateFormat('dd.MM.yyyy')
                                                    .format(expirationDate),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.primaryBlue,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              SvgPicture.asset(
                                                'assets/arrow_forward_blue.svg',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(
                                        top: 8, left: 16, right: 16, bottom: 0),
                                    child: Divider(
                                      color: AppColors.fieldBackground,
                                      thickness: 1,
                                    ),
                                  ),
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(24)),
                                          ),
                                          builder: (context) =>
                                              DraggableScrollableSheet(
                                            initialChildSize: 0.4,
                                            minChildSize: 0.2,
                                            maxChildSize: 0.75,
                                            expand: false,
                                            builder: (_, controller) =>
                                                TreatmentCourseModal(
                                              userId: widget.userId,
                                              medicineId: medicine.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "+ Добавить в курс лечения",
                                        style: TextStyle(
                                          fontFamily: 'Commissioner',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Инструкция",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'Commissioner',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          _buildInstructionItem(
                              "Показания к применению", medicine.indications),
                          _buildInstructionItem(
                              "Противопоказания", medicine.contraindications),
                          _buildInstructionItem("Способ применения и дозы",
                              medicine.methodApplicationDosage),
                          _buildInstructionItem("Состав", medicine.composition),
                          _buildInstructionItem(
                              "Побочные действия", medicine.sideEffects),
                          _buildInstructionItem("Фармакологическое действие",
                              medicine.pharmacologicalEffect),
                          _buildInstructionItem(
                              "Условия хранения", medicine.storageConditions),
                          _buildInstructionItem("Применение при беременности",
                              medicine.oregnancyUsage),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: ElevatedButton(
          onPressed: () async {
            int packageCount = int.tryParse(packageCountController.text) ?? 0;
            if (packageCount <= 0) {
              Fluttertoast.showToast(
                msg: 'Количество "осталось единиц" должно быть больше 0',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
              );
              return;
            }

            try {
              String finalReleaseForm = medicine.releaseForm ?? "";
              String? finalQuantityInPackage = medicine.quantityInPackage;
              String finalImagePath = medicine.imagePath ?? "";

              await databaseService.addMedicine(
                medicine.name,
                finalReleaseForm,
                finalQuantityInPackage,
                finalImagePath,
                packageCount,
                widget.userId,
              );
              Fluttertoast.showToast(
                msg: 'Лекарство успешно добавлено в аптечку',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 2),
                ),
              );
            } catch (e) {
              Fluttertoast.showToast(
                msg: 'Ошибка при добавлении лекарства: $e',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Text(
            '+ Добавить в аптечку',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String title, String? content) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0B102B),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Color(0xFF6B7280),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    InstructionDetailScreen(title: title, content: content),
              ),
            );
          },
        ),
        Divider(
          color: Colors.grey[300],
          indent: 16,
          endIndent: 16,
          height: 1,
        ),
      ],
    );
  }
}
