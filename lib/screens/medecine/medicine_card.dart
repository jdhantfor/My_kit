import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:postgres/postgres.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/home_screen.dart';
import 'package:my_aptechka/screens/medecine/treatment_course_modal.dart';

class InstructionDetailScreen extends StatelessWidget {
  final String title;
  final String? content;

  const InstructionDetailScreen({super.key, required this.title, this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Card(
            color: Colors.white, // Устанавливаем белый цвет для карточки
            elevation: 1, // Убираем тень, чтобы карточка сливалась с фоном
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                content ?? "Информация отсутствует",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
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

  const MedicineCard(
      {super.key, required this.medicineId, required this.userId});

  @override
  _MedicineCardState createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  late Medicine medicine;
  bool isLoading = true;
  TextEditingController packageCountController =
      TextEditingController(text: "1");
  DateTime expirationDate = DateTime(2026, 1, 1);

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
        msg: 'Error loading medicine details: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {
                print('Настройки');
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            if (medicine.imagePath != null && medicine.imagePath!.isNotEmpty)
              Image.network(
                'http://aaa-consulting.pro/image/${medicine.imagePath}',
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Image.asset('assets/default_box.png');
                },
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            else
              Image.asset('assets/default_box.png'),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                medicine.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "${medicine.releaseForm ?? ''} ${medicine.quantityInPackage ?? ''}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 20, 20, 20)),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Количество и сроки",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              child: Column(
                children: [
                  ListTile(
                    title: const Text("Осталось единиц",
                        style: TextStyle(fontSize: 16)),
                    trailing: Container(
                      width: 50,
                      height: 40,
                      alignment: Alignment.center,
                      child: TextField(
                        controller: packageCountController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 18),
                        textAlign: TextAlign.right, // Добавляем это свойство
                        onChanged: (value) {
                          int? count = int.tryParse(value);
                          if (count == null || count < 1) {
                            packageCountController.text = '1';
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(
                    color: Color.fromARGB(255, 224, 224, 224),
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    title: const Text("Срок годности",
                        style: TextStyle(fontSize: 18)),
                    trailing: GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: expirationDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null && picked != expirationDate) {
                          setState(() {
                            expirationDate = picked;
                          });
                        }
                      },
                      child: Text(
                        "${expirationDate.day.toString().padLeft(2, '0')}.${expirationDate.month.toString().padLeft(2, '0')}.${expirationDate.year}",
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 18),
                      ),
                    ),
                  ),
                  const Divider(
                    color: Color.fromARGB(255, 214, 213, 213),
                    indent: 16,
                    endIndent: 16,
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.4,
                            minChildSize: 0.2,
                            maxChildSize: 0.75,
                            expand: false,
                            builder: (_, controller) => TreatmentCourseModal(
                              userId: widget.userId,
                              medicineId: medicine.id,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "+ Добавить в курс лечения",
                        style: TextStyle(fontSize: 18, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Инструкция",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
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
                  _buildInstructionItem(
                      "Применение при беременности", medicine.oregnancyUsage),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: MaterialButton(
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

              await DatabaseService.addMedicine(
                medicine.name,
                finalReleaseForm,
                finalQuantityInPackage,
                finalImagePath,
                packageCount,
                widget.userId,
              );
              Fluttertoast.showToast(
                msg: 'Medicine added successfully',
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
                msg: 'Error adding medicine: $e',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
              );
            }
          },
          color: Colors.blue,
          textColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: const Text(
            "+ Добавить в аптечку",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String title, String? content) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Color.fromARGB(255, 211, 210, 210),
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
        const Divider(
          color: Color.fromARGB(255, 224, 224, 224),
          indent: 16,
          endIndent: 16,
        ),
      ],
    );
  }
}
