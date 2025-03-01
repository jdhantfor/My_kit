import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:postgres/postgres.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_aptechka/screens/medecine/medicine_card.dart';
import 'package:my_aptechka/screens/medecine/medecine_search2_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class Barcodes2Screen extends StatefulWidget {
  final String userId;

  const Barcodes2Screen({Key? key, required this.userId}) : super(key: key);

  @override
  _Barcodes2ScreenState createState() => _Barcodes2ScreenState();
}

class _Barcodes2ScreenState extends State<Barcodes2Screen> {
  late PostgreSQLConnection _conn;
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false; // Добавляем флаг для контроля сканирования

  int successScans = 0;
  int failedScans = 0;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Разрешение на использование камеры отклонено')),
      );
    }
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
      Fluttertoast.showToast(msg: 'Connected to PostgreSQL database!');
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error connecting to PostgreSQL database: $e');
    }
  }

  Future<void> _processScannedCode(String scannedCode) async {
    if (isScanning) {
      return; // Игнорируем, если уже идет сканирование
    }
    setState(() => isScanning = true); // Устанавливаем флаг перед обработкой

    try {
      final results = await _conn.query(
        'SELECT id, "Name" FROM "Medicines" WHERE "Barcodes" = @barcode',
        substitutionValues: {'barcode': int.parse(scannedCode)},
      );

      if (results.isNotEmpty) {
        final medicineId = results.first[0] as int;
        final medicineName = results.first[1] as String;

        // Останавливаем камеру перед переходом
        cameraController.stop();

        // Переходим на MedicineCard
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineCard(
                medicineId: medicineId, userId: widget.userId),
          ),
        ).then((_) {
          // После возвращения возобновляем камеру и разрешаем сканирование
          cameraController.start();
          setState(() {
            successScans++;
            isScanning = false; // Сбрасываем флаг сразу после возвращения
          });
        });
      } else {
        // Если лекарство не найдено, добавляем задержку и показываем диалог
        await Future.delayed(const Duration(seconds: 2));
        _showMedicineNotFoundDialog();
        setState(() {
          failedScans++;
        });
      }
    } catch (e) {
      print('Error processing scanned code: $e');
      await Future.delayed(const Duration(seconds: 2));
      _showMedicineNotFoundDialog();
      setState(() {
        failedScans++;
      });
    } finally {
      // Сбрасываем флаг после задержки в случае ошибки или ненайденного кода
      await Future.delayed(const Duration(seconds: 2));
      setState(() => isScanning = false);
    }
  }

  void _showMedicineNotFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Лекарство не найдено'),
          content: const Text('Хотите добавить это лекарство вручную?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Добавить'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToMedicineSearch2Screen();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToMedicineSearch2Screen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineSearch2Screen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (!isScanning) { // Проверяем флаг перед вызовом обработки
                  await _processScannedCode(barcode.rawValue ?? '');
                }
              }
            },
          ),
          Positioned(
            top: 40.0,
            left: 16.0,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  SizedBox(width: 8.0),
                  Text(
                    'Отсканируйте штрих код',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Наведите камеру на штрих-код препарата',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Логика для выбора из галереи
                          },
                          icon: const Icon(Icons.photo_library,
                              color: Color(0xFF0B102B)),
                          label: const Text('Выбрать из галереи',
                              style: TextStyle(color: Color(0xFF0B102B))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ElevatedButton.icon(
                          onPressed: _navigateToMedicineSearch2Screen,
                          icon: const Icon(Icons.search,
                              color: Color(0xFF0B102B)),
                          label: const Text('Найти вручную',
                              style: TextStyle(color: Color(0xFF0B102B))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _conn.close();
    super.dispose();
  }
}